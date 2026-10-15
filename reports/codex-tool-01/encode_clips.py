from __future__ import annotations

import time
import json
import shutil
import sys
from pathlib import Path

from PIL import Image, ImageChops


def frame_durations(count: int, fps: int) -> list[int]:
    """Integer milliseconds whose cumulative times stay locked to the requested fps."""
    return [round((i + 1) * 1000 / fps) - round(i * 1000 / fps) for i in range(count)]


def encode(paths: list[Path], target: Path, durations: list[int]) -> None:
    frames = [Image.open(path).convert("RGBA") for path in paths]
    # libwebp coalesces identical holds, which makes FX/no-FX pairs report different frame
    # counts. A one-level, one-pixel timing marker in the dark bottom corner keeps all 30 fps
    # samples addressable without changing the readable game image.
    for index, frame in enumerate(frames):
        frame.putpixel((0, frame.height - 1), (16 + index % 2, 21, 34, 255))
    # A file written a moment ago can be held briefly by another process on Windows (antivirus,
    # sync); opening it again fails with EINVAL. Retry a few times (2026-10-15).
    for attempt in range(6):
        try:
            frames[0].save(
                target,
                "WEBP",
                save_all=True,
                append_images=frames[1:],
                duration=durations,
                loop=0,
                lossless=True,
                quality=100,
                # Method 3 keeps the output lossless while making a full 72-clip refresh practical.
                method=3,
            )
            break
        except OSError:
            if attempt == 5:
                raise
            time.sleep(0.5)
    for frame in frames:
        frame.close()
    with Image.open(target) as encoded:
        if encoded.n_frames != len(paths):
            raise RuntimeError(f"{target}: encoded {encoded.n_frames} frames, expected {len(paths)}")


def main() -> int:
    clips_root = Path(sys.argv[1]).resolve()
    raw = json.loads((clips_root / "_capture.json").read_text(encoding="utf-8"))
    fps = int(raw["fps"])
    manifest = {"version": 1, "fps": fps, "clips": []}
    total_bytes = 0
    differing_pairs = 0

    for clip in raw["clips"]:
        form, move, count = clip["form"], clip["move"], int(clip["frames"])
        pair_files: dict[str, str] = {}
        pair_images: dict[str, list[Path]] = {}
        durations = frame_durations(count, fps)
        out_dir = clips_root / form
        out_dir.mkdir(parents=True, exist_ok=True)
        for mode in ("fx", "nofx"):
            paths = sorted((clips_root / "_frames" / form / move / mode).glob("*.png"))
            if len(paths) != count:
                raise RuntimeError(f"{form}/{move}/{mode}: expected {count} frames, found {len(paths)}")
            pair_images[mode] = paths
            rel = f"{form}/{move}-{mode}.webp"
            target = clips_root / rel
            encode(paths, target, durations)
            pair_files[mode] = rel
            total_bytes += target.stat().st_size
            print(f"encoded {rel}", flush=True)

        # A real effects pass should differ from the sprite-only pass on at least one frame.
        differs = False
        for fx_path, nofx_path in zip(pair_images["fx"], pair_images["nofx"]):
            with Image.open(fx_path).convert("RGBA") as fx, Image.open(nofx_path).convert("RGBA") as nofx:
                # RGBA getbbox observes a zero alpha-difference channel and can miss RGB-only
                # changes; compare the rendered colour channels explicitly.
                if ImageChops.difference(fx.convert("RGB"), nofx.convert("RGB")).getbbox() is not None:
                    differs = True
                    break
        differing_pairs += int(differs)
        manifest["clips"].append(
            {
                "form": form,
                "move": move,
                "name": clip["name"],
                "input": clip["input"],
                "duration": round(sum(durations) / 1000, 3),
                "frames": count,
                "files": pair_files,
                "rows": clip["rows"],
                "size": clip["size"],
                "fx_diff": differs,
            }
        )

    (clips_root / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    if differing_pairs == 0:
        raise RuntimeError("FX suppression did not produce a visible difference in any clip")
    shutil.rmtree(clips_root / "_frames")
    (clips_root / "_capture.json").unlink()
    print(
        f"encoded {len(manifest['clips'])} pairs / {len(manifest['clips']) * 2} files, "
        f"{total_bytes / 1024 / 1024:.2f} MiB; fx differs in {differing_pairs}/{len(manifest['clips'])} pairs"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
