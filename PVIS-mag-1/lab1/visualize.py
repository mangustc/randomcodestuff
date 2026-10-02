import argparse
import cv2
import numpy as np
from pathlib import Path

from main import Config, get_blur_kernel, get_boxes_mask, get_color_mask, get_connected_boxes, process_frame


def steps(video: Path, frame_index: int, cfg: Config, out_dir: Path) -> None:
    """saves intermediate results in directory out_dir"""
    cap = cv2.VideoCapture(str(video))
    frame = None
    for i in range(frame_index + 1):
        ok, frame = cap.read()
        if not ok:
            break
    cap.release()
    if frame is None:
        raise SystemExit(f"cannot read frame {frame_index} of {video}")

    mask = get_color_mask(frame, cfg)
    boxes = get_connected_boxes(mask, cfg.min_area)
    inside = get_boxes_mask(frame.shape[:2], boxes)
    result = process_frame(frame, cfg)

    # the found pixels in green, the rectangles in red
    highlighted = frame.copy()
    highlighted[mask] = 0.35 * highlighted[mask] + 0.65 * np.array([0, 255, 0])
    for x, y, w, h in boxes:
        cv2.rectangle(highlighted, (x, y), (x + w - 1, y + h - 1), (0, 0, 255), 1)

    # the blurred part of the frame in grey, the rectangles in red (this is BGR)
    areas = np.full((*frame.shape[:2], 3), 200, dtype=np.uint8)
    areas[inside] = (0, 0, 255)

    blurred = cv2.filter2D(frame, -1, get_blur_kernel(cfg.blur_size),
                           borderType=cv2.BORDER_REFLECT)

    panels = [
        ("01_original.png", frame),
        ("02_mask.png", highlighted),
        ("03_areas.png", areas),
        ("04_blurred.png", blurred),
        ("05_result.png", result),
    ]

    out_dir.mkdir(parents=True, exist_ok=True)
    for name, image in panels:
        path = out_dir / name
        if not cv2.imwrite(str(path), image):
            raise SystemExit(f"cannot write {path}")
        print(f"steps of frame {frame_index} saved to {path}")


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
    steps(Path(args.video), args.frame, Config(), out_dir)


if __name__ == "__main__":
    main()
