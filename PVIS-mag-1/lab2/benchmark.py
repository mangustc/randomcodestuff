import argparse
import csv
import matplotlib
import statistics
from pathlib import Path

matplotlib.use("Agg")
import matplotlib.pyplot as plt

from main import Config, process_video

FIELD_NAMES: dict = {
    "video": "Video name",
    "resolution": "Video resolution",
    "duration_s": "Video duration, s",
    "threads": "Thread amount",
    "run": "Run number",
    "time_total_s": "Total processing time, s",
}

FIELDS = (FIELD_NAMES["video"], FIELD_NAMES["resolution"], FIELD_NAMES["duration_s"], FIELD_NAMES["threads"],
          FIELD_NAMES["run"],
          FIELD_NAMES["time_total_s"])


def times_of(rows, resolution=None, duration=None, threads=None):
    return [r[FIELD_NAMES["time_total_s"]] for r in rows
            if (resolution is None or r[FIELD_NAMES["resolution"]] == resolution)
            and (duration is None or r[FIELD_NAMES["duration_s"]] == duration)
            and (threads is None or r[FIELD_NAMES["threads"]] == threads)]


def resolutions_of(rows) -> list[str]:
    return sorted({r[FIELD_NAMES["resolution"]] for r in rows},
                  key=lambda res: int(res.split("x")[0]))


def durations_of(rows) -> list[int]:
    return sorted({r[FIELD_NAMES["duration_s"]] for r in rows}, reverse=True)


def runs_of(rows) -> list[int]:
    return sorted({r[FIELD_NAMES["run"]] for r in rows}, reverse=True)


def benchmark(videos: list[Path], threads_list: list[int], runs: int, cfg: Config):
    """runs algorithm `runs` times on each video with each thread amount"""
    rows = []
    for video in videos:
        resolution, duration = video.stem.rsplit("_", 1)
        duration_s = int(duration.rstrip("s"))
        print(f"{video.name} ({resolution}, {duration_s} s)", flush=True)
        for threads in threads_list:
            times = []
            for run in range(1, runs + 1):
                result = process_video(video, cfg, threads)
                times.append(result.total_time)
                rows.append({
                    FIELD_NAMES["video"]: video.name,
                    FIELD_NAMES["resolution"]: resolution,
                    FIELD_NAMES["duration_s"]: duration_s,
                    FIELD_NAMES["threads"]: threads,
                    FIELD_NAMES["run"]: run,
                    FIELD_NAMES["time_total_s"]: round(result.total_time, 4),
                })
                print(f"\tthreads={threads}"
                      f", run={run}"
                      f", total={result.total_time:.3f} s"
                      f", mean={statistics.mean(times):.3f} s"
                      f", median={statistics.median(times):.3f} s",
                      flush=True)
    return rows


def write_csv(rows, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(rows)
    print(f"results saved to {path}")


def plot_threads(rows, out_dir: Path, threads_list: list[int]) -> None:
    """creates 1 graph per resolution"""
    resolutions = resolutions_of(rows)
    durations = durations_of(rows)
    runs = runs_of(rows)
    for resolution in resolutions:
        fig, ax = plt.subplots(figsize=(7, 4.5))
        for duration in durations:
            xs, mean, low, high = [], [], [], []
            for threads in threads_list:
                values = times_of(rows, resolution, duration, threads)
                if not values:
                    continue
                xs.append(threads)
                mean.append(statistics.mean(values))
                low.append(min(values))
                high.append(max(values))
            ax.plot(xs, mean, marker="o", label=f"{duration} с")
            ax.fill_between(xs, low, high, alpha=0.15)
        ax.set_xlabel("количество потоков")
        ax.set_ylabel("Время выполнения, с")
        ax.set_title(f"Время выполнения от количества потоков, {resolution}, {runs[0]} повторений")
        ax.set_xticks(threads_list)
        ax.set_xlim(min(threads_list) - 1, max(threads_list) + 1)
        ax.set_ylim(bottom=0)
        ax.grid(True, alpha=0.3)
        ax.legend(title="длина видео")
        fig.tight_layout()
        path = out_dir / f"times_{resolution}.png"
        fig.savefig(path, dpi=150)
        plt.close(fig)
        print(f"graph saved to {path}")


def plot_boxplots(rows, out_dir: Path) -> None:
    """creates 1 boxplot for each video duration"""
    resolutions = resolutions_of(rows)
    durations = durations_of(rows)
    runs = runs_of(rows)
    for duration in durations:
        data = [times_of(rows, resolution, duration) for resolution in resolutions]
        if not any(data):
            continue
        fig, ax = plt.subplots(figsize=(7, 4.5))
        ax.boxplot(data, showmeans=True, meanprops={"marker": "x", "color": "red"})
        ax.set_xticks(range(1, len(resolutions) + 1), resolutions)
        ax.set_xlabel("разрешение видео")
        ax.set_ylabel("время выполнения, с")
        ax.set_title(f"Разброс времени, длина видео {duration} с, {runs[0]} повторений")
        ax.grid(True, axis="y", alpha=0.3)
        ax.set_ylim(0, max(max(d) for d in data if d) * 1.3)
        for i, values in enumerate(data, start=1):
            if not values:
                continue
            ax.annotate(f"ср. арифм. {statistics.mean(values):.2f}\n"
                        f"медиана {statistics.median(values):.2f}",
                        xy=(i, max(values)), xytext=(0, 6),
                        textcoords="offset points", ha="center", fontsize=8)
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
    parser.add_argument("-t", "--threads",
                        default="12,6,3",
                        help="comma separated thread amounts to test")
    parser.add_argument("-r", "--runs", type=int, default=5,
                        help="measurements per video and thread amount")
    parser.add_argument("--min-area", type=int, default=Config.min_area,
                        help="S: minimal significant region size in pixels")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    videos = sorted(Path(args.videos).glob("*.mp4"))
    if not videos:
        raise SystemExit(f"no videos found in {args.videos}")
    threads_list = sorted(int(x) for x in args.threads.split(","))
    cfg = Config(min_area=args.min_area)
    out_dir = Path(args.out)

    rows = benchmark(videos, threads_list, args.runs, cfg)
    write_csv(rows, out_dir / "results.csv")
    plot_threads(rows, out_dir, threads_list)
    plot_boxplots(rows, out_dir)


if __name__ == "__main__":
    main()
