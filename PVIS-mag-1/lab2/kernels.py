from __future__ import annotations

import numpy as np
import warnings

METHODS = ("cuda-2d", "cuda-1d", "opencl-1d", "opencl-2d")

# ---------------------------------------------------------------- CUDA ----

CUDA_SOURCE = r"""
__device__ __forceinline__ void gray_mirror(const unsigned char* src, unsigned char* dst,
                                            int x, int y, int width, int rows) {
    if (x >= width || y >= rows) return;
    const unsigned char* p = src + ((size_t)y * width + x) * 3;
    dst[(size_t)y * width + (width - 1 - x)] =
        (unsigned char)(((unsigned int)p[0] + p[1] + p[2]) / 3);
}

// a) 2D grid of blocks, 2D threads inside a block
extern "C" __global__ void gray_mirror_2d(const unsigned char* src, unsigned char* dst,
                                          int width, int rows) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    gray_mirror(src, dst, x, y, width, rows);
}

// b) 1D grid of blocks, 2D threads inside a block
extern "C" __global__ void gray_mirror_1d(const unsigned char* src, unsigned char* dst,
                                          int width, int rows, int blocks_x) {
    int bx = blockIdx.x % blocks_x;
    int by = blockIdx.x / blocks_x;
    int x = bx * blockDim.x + threadIdx.x;
    int y = by * blockDim.y + threadIdx.y;
    gray_mirror(src, dst, x, y, width, rows);
}
"""

CUDA_BLOCK = (32, 8)

# -------------------------------------------------------------- OpenCL ----

OPENCL_SOURCE = r"""
inline void gray_mirror(__global const uchar* src, __global uchar* dst,
                        uint x, uint y, uint width, uint rows) {
    if (x >= width || y >= rows) return;
    __global const uchar* p = src + ((size_t)y * width + x) * 3;
    dst[(size_t)y * width + (width - 1 - x)] = (uchar)(((uint)p[0] + p[1] + p[2]) / 3);
}

// a) 1D work-groups, 1D work-items
__kernel void gray_mirror_1d(__global const uchar* src, __global uchar* dst,
                             uint width, uint rows) {
    size_t gid = get_global_id(0);
    gray_mirror(src, dst, (uint)(gid % width), (uint)(gid / width), width, rows);
}

// b) 2D work-groups, 2D work-items
__kernel void gray_mirror_2d(__global const uchar* src, __global uchar* dst,
                             uint width, uint rows) {
    gray_mirror(src, dst, (uint)get_global_id(0), (uint)get_global_id(1), width, rows);
}
"""

OPENCL_LOCAL_1D = 256
OPENCL_LOCAL_2D = (16, 16)


def ceil_div(a: int, b: int) -> int:
    return (a + b - 1) // b


def round_up(a: int, b: int) -> int:
    return ceil_div(a, b) * b


def cpu_reference(batch: np.ndarray) -> np.ndarray:
    """same computation on the CPU (N, H, W, 3) -> (N, H, W), for checking"""
    gray = batch.astype(np.uint16).sum(axis=-1) // 3
    return np.ascontiguousarray(gray[..., ::-1].astype(np.uint8))


class Backend:
    name: str

    def process(self, batch: np.ndarray) -> tuple[np.ndarray, float]:
        """(N, H, W, 3) uint8 BGR -> ((N, H, W) uint8, kernel time in ms)"""
        raise NotImplementedError


class CudaBackend(Backend):
    def __init__(self, mode: str):
        import cupy as cp
        if mode not in ("2d", "1d"):
            raise ValueError(mode)
        self.cp = cp
        self.mode = mode
        self.name = f"cuda-{mode}"
        module = cp.RawModule(code=CUDA_SOURCE)
        self.kernel = module.get_function(f"gray_mirror_{mode}")
        self.d_src = None
        self.d_dst = None
        self.start = cp.cuda.Event()
        self.end = cp.cuda.Event()

    def _ensure(self, n: int, h: int, w: int) -> None:
        if self.d_src is None or self.d_src.shape[0] < n or self.d_src.shape[1:3] != (h, w):
            self.d_src = self.cp.empty((n, h, w, 3), dtype=self.cp.uint8)
            self.d_dst = self.cp.empty((n, h, w), dtype=self.cp.uint8)

    def process(self, batch: np.ndarray) -> tuple[np.ndarray, float]:
        cp = self.cp
        n, h, w, _ = batch.shape
        self._ensure(n, h, w)
        src, dst = self.d_src[:n], self.d_dst[:n]
        src.set(np.ascontiguousarray(batch))

        rows = n * h
        bx, by = ceil_div(w, CUDA_BLOCK[0]), ceil_div(rows, CUDA_BLOCK[1])
        self.start.record()
        if self.mode == "2d":
            self.kernel((bx, by), CUDA_BLOCK, (src, dst, np.int32(w), np.int32(rows)))
        else:
            self.kernel((bx * by,), CUDA_BLOCK,
                        (src, dst, np.int32(w), np.int32(rows), np.int32(bx)))
        self.end.record()
        self.end.synchronize()
        kernel_ms = cp.cuda.get_elapsed_time(self.start, self.end)
        return dst.get(), kernel_ms


class OpenCLBackend(Backend):
    def __init__(self, mode: str):
        import pyopencl as cl
        if mode not in ("1d", "2d"):
            raise ValueError(mode)
        self.cl = cl
        self.mode = mode
        self.name = f"opencl-{mode}"
        device = self._pick_device()
        self.ctx = cl.Context([device])
        self.queue = cl.CommandQueue(
            self.ctx, properties=cl.command_queue_properties.PROFILING_ENABLE)
        with warnings.catch_warnings():  # NVIDIA returns a non-empty but useless build log
            warnings.simplefilter("ignore", cl.CompilerWarning)
            program = cl.Program(self.ctx, OPENCL_SOURCE).build()
        self.kernel = cl.Kernel(program, f"gray_mirror_{mode}")
        self.capacity = 0
        self.d_src = None
        self.d_dst = None

    def _pick_device(self):
        cl = self.cl
        gpus = [d for p in cl.get_platforms() for d in p.get_devices()
                if d.type & cl.device_type.GPU]
        if not gpus:
            raise RuntimeError("no OpenCL GPU device found")
        return gpus[0]

    def _ensure(self, pixels: int) -> None:
        if pixels > self.capacity:
            mf = self.cl.mem_flags
            self.d_src = self.cl.Buffer(self.ctx, mf.READ_ONLY, pixels * 3)
            self.d_dst = self.cl.Buffer(self.ctx, mf.WRITE_ONLY, pixels)
            self.capacity = pixels

    def process(self, batch: np.ndarray) -> tuple[np.ndarray, float]:
        cl = self.cl
        n, h, w, _ = batch.shape
        rows = n * h
        self._ensure(rows * w)
        cl.enqueue_copy(self.queue, self.d_src, np.ascontiguousarray(batch))

        self.kernel.set_args(self.d_src, self.d_dst, np.uint32(w), np.uint32(rows))
        if self.mode == "1d":
            global_size = (round_up(w * rows, OPENCL_LOCAL_1D),)
            local_size = (OPENCL_LOCAL_1D,)
        else:
            global_size = (round_up(w, OPENCL_LOCAL_2D[0]), round_up(rows, OPENCL_LOCAL_2D[1]))
            local_size = OPENCL_LOCAL_2D
        event = cl.enqueue_nd_range_kernel(self.queue, self.kernel, global_size, local_size)

        out = np.empty((n, h, w), dtype=np.uint8)
        cl.enqueue_copy(self.queue, out, self.d_dst, wait_for=[event])
        self.queue.finish()
        kernel_ms = (event.profile.end - event.profile.start) * 1e-6
        return out, kernel_ms


def make_backend(method: str) -> Backend:
    api, mode = method.split("-")
    if api == "cuda":
        return CudaBackend(mode)
    if api == "opencl":
        return OpenCLBackend(mode)
    raise ValueError(f"unknown method {method}")
