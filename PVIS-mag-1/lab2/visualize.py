import argparse
import cv2
import numpy as np
from pathlib import Path

from kernels import METHODS, cpu_reference, make_backend


def steps(video: Path, frame_index: int, out_dir: Path) -> None:
    """saves intermediate results of one frame in directory out_dir"""
    cap = cv2.VideoCapture(str(video))
    frame = None
    for _ in range(frame_index + 1):
        ok, frame = cap.read()
        if not ok:
            frame = None
            break
    cap.release()
    if frame is None:
        raise SystemExit(f"cannot read frame {frame_index} of {video}")

    batch = frame[np.newaxis]
    gray = (frame.astype(np.uint16).sum(axis=-1) // 3).astype(np.uint8)
    panels = [
        ("01_original.png", frame),
        ("02_gray.png", gray),
        ("03_result.png", cpu_reference(batch)[0]),
    ]
    for method in METHODS:
        result, _ = make_backend(method).process(batch)
        panels.append((f"04_result_{method}.png", result[0]))

    out_dir.mkdir(parents=True, exist_ok=True)
    for name, image in panels:
        path = out_dir / name
        if not cv2.imwrite(str(path), image):
            raise SystemExit(f"cannot write {path}")
        print(f"frame {frame_index} saved to {path}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("video", nargs="?", default="videos/640x272_30s.mp4",
                        help="video used for the step visualisation")
    parser.add_argument("-o", "--out", default="visualization",
                        help="directory for the pictures")
    parser.add_argument("-f", "--frame", type=int, default=200,
                        help="index of the frame to visualise")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    out_dir = Path(args.out) / f"frame_{args.frame:06d}"
    steps(Path(args.video), args.frame, out_dir)


if __name__ == "__main__":
    main()
