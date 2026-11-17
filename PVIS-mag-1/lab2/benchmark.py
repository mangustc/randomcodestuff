import argparse
import csv
import matplotlib
import statistics
from pathlib import Path

matplotlib.use("Agg")
import matplotlib.pyplot as plt

from kernels import METHODS, make_backend
from main import process_video

FIELD_NAMES: dict = {
    "video": "Video name",
    "resolution": "Video resolution",
    "duration_s": "Video duration, s",
    "method": "Method",
    "run": "Run number",
    "frames": "Frames",
    "time_total_s": "Total processing time, s",
    "time_kernel_ms": "Kernel time, ms",
}

FIELDS = tuple(FIELD_NAMES.values())


def values_of(rows, field, resolution=None, duration=None, method=None):
    return [r[FIELD_NAMES[field]] for r in rows
            if (resolution is None or r[FIELD_NAMES["resolution"]] == resolution)
            and (duration is None or r[FIELD_NAMES["duration_s"]] == duration)
            and (method is None or r[FIELD_NAMES["method"]] == method)]


def resolutions_of(rows) -> list[str]:
    return sorted({r[FIELD_NAMES["resolution"]] for r in rows},
                  key=lambda res: int(res.split("x")[0]))


def durations_of(rows) -> list[int]:
    return sorted({r[FIELD_NAMES["duration_s"]] for r in rows})


def runs_of(rows) -> int:
    return max(r[FIELD_NAMES["run"]] for r in rows)


def benchmark(videos: list[Path], methods: list[str], runs: int, batch_size: int):
    """runs every method `runs` times on each video"""
    backends = {m: make_backend(m) for m in methods}
    # warm-up: compilation / context creation must not get into the measurements
    for backend in backends.values():
        process_video(videos[0], backend, batch_size)

    rows = []
    for video in videos:
        resolution, duration = video.stem.rsplit("_", 1)
        duration_s = int(duration.rstrip("s"))
        print(f"{video.name} ({resolution}, {duration_s} s)", flush=True)
        for method, backend in backends.items():
            times = []
            for run in range(1, runs + 1):
                result = process_video(video, backend, batch_size)
                times.append(result.total_time)
                rows.append({
                    FIELD_NAMES["video"]: video.name,
                    FIELD_NAMES["resolution"]: resolution,
                    FIELD_NAMES["duration_s"]: duration_s,
                    FIELD_NAMES["method"]: method,
                    FIELD_NAMES["run"]: run,
                    FIELD_NAMES["frames"]: result.frames,
                    FIELD_NAMES["time_total_s"]: round(result.total_time, 4),
                    FIELD_NAMES["time_kernel_ms"]: round(result.kernel_time_ms, 4),
                })
                print(f"\t{method:10s} run={run}"
                      f", total={result.total_time:.3f} s"
                      f", kernel={result.kernel_time_ms:.3f} ms"
                      f", median total={statistics.median(times):.3f} s",
                      flush=True)
    return rows


def write_csv(rows, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(rows)
    print(f"results saved to {path}")


def plot_by_duration(rows, out_dir: Path, methods: list[str], field: str,
                     prefix: str, ylabel: str, title: str) -> None:
    """1 graph per resolution: x = video duration, one line per method"""
    durations = durations_of(rows)
    runs = runs_of(rows)
    for resolution in resolutions_of(rows):
        fig, ax = plt.subplots(figsize=(7, 4.5))
        for method in methods:
            xs, mean, low, high = [], [], [], []
            for duration in durations:
                values = values_of(rows, field, resolution, duration, method)
                if not values:
                    continue
                xs.append(duration)
                mean.append(statistics.mean(values))
                low.append(min(values))
                high.append(max(values))
            ax.plot(xs, mean, marker="o", label=method)
            ax.fill_between(xs, low, high, alpha=0.15)
        ax.set_xlabel("длина видео, с")
        ax.set_ylabel(ylabel)
        ax.set_title(f"{title}, {resolution}, {runs} повторений")
        ax.set_xticks(durations)
        ax.set_ylim(bottom=0)
        ax.grid(True, alpha=0.3)
        ax.legend(title="метод")
        fig.tight_layout()
        path = out_dir / f"{prefix}_{resolution}.png"
        fig.savefig(path, dpi=150)
        plt.close(fig)
        print(f"graph saved to {path}")


def plot_boxplots(rows, out_dir: Path, methods: list[str]) -> None:
    """1 boxplot of kernel time for each video duration: groups = resolutions, boxes = methods"""
    resolutions = resolutions_of(rows)
    runs = runs_of(rows)
    width = 0.8 / len(methods)
    for duration in durations_of(rows):
        fig, ax = plt.subplots(figsize=(8, 4.5))
        for j, method in enumerate(methods):
            data = [values_of(rows, "time_kernel_ms", res, duration, method) for res in resolutions]
            positions = [i + (j - (len(methods) - 1) / 2) * width for i in range(len(resolutions))]
            box = ax.boxplot(data, positions=positions, widths=width * 0.9, patch_artist=True,
                             showmeans=True, meanprops={"marker": "x", "markeredgecolor": "red"})
            for patch in box["boxes"]:
                patch.set_facecolor(f"C{j}")
                patch.set_alpha(0.6)
            ax.plot([], [], color=f"C{j}", linewidth=8, alpha=0.6, label=method)
        ax.set_xticks(range(len(resolutions)), resolutions)
        ax.set_xlabel("разрешение видео")
        ax.set_ylabel("суммарное время ядра, мс")
        ax.set_title(f"Разброс времени ядра, длина видео {duration} с, {runs} повторений")
        ax.grid(True, axis="y", alpha=0.3)
        ax.set_ylim(bottom=0)
        ax.legend(title="метод")
        fig.tight_layout()
        path = out_dir / f"boxplot_{duration}s.png"
        fig.savefig(path, dpi=150)
        plt.close(fig)
        print(f"graph saved to {path}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("-v", "--videos", default="videos",
                        help="directory with the test videos")
    parser.add_argument("-o", "--out", default="results",
                        help="directory for the csv file and the graphs")
    parser.add_argument("-m", "--methods", default=",".join(METHODS),
                        help="comma separated methods to test")
    parser.add_argument("-r", "--runs", type=int, default=5,
                        help="measurements per video and method")
    parser.add_argument("--batch-size", type=int, default=64,
                        help="frames processed by one kernel launch")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    videos = sorted(Path(args.videos).glob("*.mp4"))
    if not videos:
        raise SystemExit(f"no videos found in {args.videos}")
    methods = [m for m in args.methods.split(",") if m]
    for m in methods:
        if m not in METHODS:
            raise SystemExit(f"unknown method {m}, choose from {METHODS}")
    out_dir = Path(args.out)

    rows = benchmark(videos, methods, args.runs, args.batch_size)
    write_csv(rows, out_dir / "results.csv")
    plot_by_duration(rows, out_dir, methods, "time_total_s", "times",
                     "общее время, с", "Общее время обработки")
    plot_by_duration(rows, out_dir, methods, "time_kernel_ms", "kernel",
                     "суммарное время ядра, мс", "Время работы ядра")
    plot_boxplots(rows, out_dir, methods)


if __name__ == "__main__":
    main()
