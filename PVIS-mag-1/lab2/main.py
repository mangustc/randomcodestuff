from __future__ import annotations

import argparse
import cv2
import numpy as np
import queue
import time
from dataclasses import dataclass
from pathlib import Path
from threading import Thread

from kernels import METHODS, Backend, cpu_reference, make_backend

VIDEO_SUFFIXES = (".mp4", ".avi", ".mkv", ".webm")


@dataclass
class Result:
    frames: int
    total_time: float  # decoding + transfers + kernels + encoding, s
    kernel_time_ms: float  # sum of pure kernel times, ms


def read_batch(cap: cv2.VideoCapture, size: int) -> np.ndarray:
    """get array of frames from capture of size 'size'"""
    frames = []
    while len(frames) < size:
        ok, frame = cap.read()
        if not ok:
            break
        frames.append(frame)
    return np.array(frames)


def open_writer(output: Path, fps: float, size: tuple[int, int]) -> cv2.VideoWriter:
    output.parent.mkdir(parents=True, exist_ok=True)
    fourcc = cv2.VideoWriter_fourcc(*"mp4v")
    writer = cv2.VideoWriter(str(output), fourcc, fps, size, isColor=False)
    if not writer.isOpened():
        raise RuntimeError(f"cannot open video writer {output}")
    return writer


def reader(cap: cv2.VideoCapture, batch_size: int, out: queue.Queue) -> None:
    """decodes batches on the CPU while the GPU processes the previous one"""
    try:
        while True:
            batch = read_batch(cap, batch_size)
            out.put(batch)
            if len(batch) == 0:
                return
    except BaseException as e:  # pass errors to the main thread
        out.put(e)


def process_video(
        path: str | Path,
        method: str | Backend = "cuda-2d",
        batch_size: int = 64,
        output: str | Path | None = None,
        check: bool = False,
) -> Result:
    """process entire video; output is a video file or a directory for PNG frames"""
    backend = make_backend(method) if isinstance(method, str) else method
    output = Path(output) if output is not None else None
    save_video = output is not None and output.suffix.lower() in VIDEO_SUFFIXES
    save_frames = output is not None and not save_video
    if save_frames:
        output.mkdir(parents=True, exist_ok=True)

    start = time.perf_counter()
    total = 0
    kernel_ms = 0.0
    writer = None

    cap = cv2.VideoCapture(str(path))
    if not cap.isOpened():
        raise RuntimeError(f"cannot open video {path}")
    batches: queue.Queue = queue.Queue(maxsize=2)
    reader_thread = Thread(target=reader, args=(cap, batch_size, batches), daemon=True)
    try:
        size = (int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)),
                int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT)))
        fps = cap.get(cv2.CAP_PROP_FPS) or 25.0
        if save_video:
            writer = open_writer(output, fps, size)
        reader_thread.start()

        while True:
            batch = batches.get()
            if isinstance(batch, BaseException):
                raise batch
            if len(batch) == 0:
                break

            result, ms = backend.process(batch)
            kernel_ms += ms
            if check and not np.array_equal(result, cpu_reference(batch)):
                raise AssertionError(f"{backend.name}: GPU result differs from CPU "
                                     f"at frames {total}..{total + len(batch) - 1}")
            if writer is not None:
                for frame in result:
                    writer.write(frame)
            elif save_frames:
                for i, frame in enumerate(result, start=total):
                    cv2.imwrite(str(output / f"frame_{i:06d}.png"), frame)
            total += len(batch)
    finally:
        reader_thread.join(timeout=5)
        cap.release()
        if writer is not None:
            writer.release()
    return Result(total, time.perf_counter() - start, kernel_ms)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", help="input video file")
    parser.add_argument("-o", "--output",
                        help="output video file (.mp4, ...) or directory for PNG frames")
    parser.add_argument("-m", "--method", choices=METHODS, default="cuda-2d",
                        help="GPU API and launch configuration")
    parser.add_argument("--batch-size", type=int, default=64,
                        help="frames decoded and processed by one kernel launch")
    parser.add_argument("--check", action="store_true",
                        help="compare every GPU result with the CPU reference")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    result = process_video(args.input, args.method, args.batch_size, args.output, args.check)
    print(f"input: {args.input}")
    print(f"method: {args.method}, batch size: {args.batch_size}")
    print(f"frames processed: {result.frames}")
    print(f"total time: {result.total_time:.3f} s")
    print(f"kernel time: {result.kernel_time_ms:.3f} ms")
    if args.check:
        print("check: GPU result equals CPU reference")
    if args.output:
        print(f"output: {args.output}")


if __name__ == "__main__":
    main()
