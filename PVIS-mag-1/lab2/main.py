from __future__ import annotations

import argparse
import cv2
import numpy as np
import os
import queue
import time
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from threading import Thread

VIDEO_SUFFIXES = (".mp4", ".avi", ".mkv", ".webm")


@dataclass(frozen=True)
class Config:
    r_range: tuple[int, int] = (120, 255)
    g_range: tuple[int, int] = (80, 180)
    b_range: tuple[int, int] = (60, 140)
    min_area: int = 50
    blur_size: int = 5
    draw_boxes: bool = False
    batch_size: int = 64


@dataclass
class Result:
    frames: int
    total_time: float  # decoding + processing time, s


@lru_cache(maxsize=None)
def get_blur_kernel(size: int) -> np.ndarray:
    """get gaussian blur kernel"""
    k = cv2.getGaussianKernel(size, 0)
    return (k @ k.T).astype(np.float32)


def get_color_mask(frame: np.ndarray, cfg: Config) -> np.ndarray:
    """makes a 2d matrix of true and false values where true means it is in range"""
    red, green, blue = cv2.split(frame)
    (r0, r1), (g0, g1), (b0, b1) = cfg.r_range, cfg.g_range, cfg.b_range
    return (
            (red >= r0) & (red <= r1)
            & (green >= g0) & (green <= g1)
            & (blue >= b0) & (blue <= b1)
    )


def get_connected_boxes(mask: np.ndarray, min_area: int) -> list[tuple[int, int, int, int]]:
    """get rectangle (x, y, w, h) list of connected areas with minimum min_area amount of pixels that match mask"""
    _, _, stats, _ = cv2.connectedComponentsWithStats(
        mask.astype(np.uint8), connectivity=8
    )
    boxes = []
    for x, y, w, h, area in stats[1:]:
        if area >= min_area:
            boxes.append((int(x), int(y), int(w), int(h)))
    return boxes


def get_boxes_mask(shape: tuple[int, int], boxes: list) -> np.ndarray:
    """create a 2d array where true means a pixel is in one of the boxes (for visualization only, process_frame
        does it manually)"""
    mask = np.zeros(shape, dtype=bool)
    for x, y, w, h in boxes:
        mask[y: y + h, x: x + w] = True
    return mask


def process_frame(frame: np.ndarray, cfg: Config) -> np.ndarray:
    boxes = get_connected_boxes(get_color_mask(frame, cfg), cfg.min_area)
    result = cv2.filter2D(frame, -1, get_blur_kernel(cfg.blur_size),
                          borderType=cv2.BORDER_REFLECT)
    for x, y, w, h in boxes:
        result[y:y + h, x:x + w] = frame[y:y + h, x:x + w]
    if cfg.draw_boxes:
        for x, y, w, h in boxes:
            cv2.rectangle(result, (x, y), (x + w - 1, y + h - 1), (0, 255, 0), 1)
    return result


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
    return cv2.VideoWriter(str(output), fourcc, fps, size)


def process_thread(batch: np.ndarray, frames_from: int, frames_to: int, cfg: Config):
    for f in range(frames_from, frames_to):
        batch[f] = process_frame(batch[f], cfg)


def process_video(
        path: str | Path,
        cfg: Config | None = None,
        thread_amount: int | None = None,
        output: str | Path | None = None,
) -> Result:
    """process entire video"""
    cfg = cfg or Config()
    thread_amount = thread_amount or os.cpu_count() or 1
    cv2.setNumThreads(1)
    save_video = (output is not None
                  and Path(output).suffix.lower() in VIDEO_SUFFIXES)

    start = time.perf_counter()
    total = 0
    writer = None

    cap = cv2.VideoCapture(str(path))
    if not cap.isOpened():
        raise RuntimeError(f"cannot open video {path}")
    try:
        size = (int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)),
                int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT)))
        fps = cap.get(cv2.CAP_PROP_FPS) or 25.0
        if save_video:
            writer = open_writer(Path(output), fps, size)

        while True:
            batch = read_batch(cap, cfg.batch_size)
            batch_frames_amount: int = len(batch)
            if batch_frames_amount == 0:
                break

            frames_left: int = batch_frames_amount % thread_amount
            frames_per_thread: int = batch_frames_amount // thread_amount
            if frames_per_thread == 0:
                divisions = frames_left
            else:
                divisions = thread_amount

            threads = []
            last_frame: int = 0
            for thread_id in range(divisions):
                if frames_left != 0:
                    next_frame = last_frame + frames_per_thread + 1
                    frames_left = frames_left - 1
                else:
                    next_frame = last_frame + frames_per_thread
                thread = Thread(target=process_thread, args=(batch, last_frame, next_frame, cfg))
                threads.append(thread)
                last_frame = next_frame

            for t in threads:
                t.start()
            for t in threads:
                t.join()
            if writer is not None:
                for frame in batch:
                    writer.write(frame)
            total += batch_frames_amount
    finally:
        cap.release()
        if writer is not None:
            writer.release()
    return Result(total, time.perf_counter() - start)


def parse_range(text: str) -> tuple[int, int]:
    low, high = text.split("-")
    return int(low), int(high)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", help="input video file")
    parser.add_argument("-o", "--output",
                        help="output video file")
    parser.add_argument("-t", "--threads", type=int, default=os.cpu_count(),
                        help="number of CPU threads (default: all cores)")
    parser.add_argument("--r", type=parse_range, default=(120, 255),
                        help="red range, e.g. 120-255")
    parser.add_argument("--g", type=parse_range, default=(80, 180),
                        help="green range, e.g. 80-180")
    parser.add_argument("--b", type=parse_range, default=(60, 140),
                        help="blue range, e.g. 60-140")
    parser.add_argument("-s", "--min-area", type=int, default=50,
                        help="S: minimal significant region size in pixels")
    parser.add_argument("--blur", type=int, default=5,
                        help="side of the convolution kernel in pixels")
    parser.add_argument("--batch-size", type=int, default=64,
                        help="frames decoded and processed at once")
    parser.add_argument("--draw-boxes", action="store_true",
                        help="draw the found rectangles on the result")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    cfg = Config(r_range=args.r, g_range=args.g, b_range=args.b,
                 min_area=args.min_area, blur_size=args.blur,
                 draw_boxes=args.draw_boxes, batch_size=args.batch_size)
    result = process_video(args.input, cfg, args.threads, args.output)
    print(f"input: {args.input}")
    print(f"threads: {args.threads}")
    print(f"color ranges: R={args.r} G={args.g} B={args.b}, S={args.min_area}, "
          f"kernel={args.blur}x{args.blur}")
    print(f"frames processed: {result.frames}")
    print(f"total time: {result.total_time:.3f} s")
    if args.output:
        print(f"output: {args.output}")


if __name__ == "__main__":
    main()
