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
    # A run may refresh one group only: keep every earlier clip this capture did not redo, and
    # replace the ones it did (by form/move), so nothing is listed twice (2026-10-15).
    manifest_path = clips_root / "manifest.json"
    previous = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.exists() else {"clips": []}
    captured = {(clip["form"], clip["move"]) for clip in raw["clips"]}
    kept = []
    for old in previous.get("clips", []):
        old.setdefault("group", "j")
        if (old["form"], old["move"]) not in captured:
            kept.append(old)
    preserved_j_count = len(kept)
    manifest = {"version": 2, "fps": fps, "clips": kept}
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
        changed_frames = 0
        difference_box = None
        for fx_path, nofx_path in zip(pair_images["fx"], pair_images["nofx"]):
            with Image.open(fx_path).convert("RGBA") as fx, Image.open(nofx_path).convert("RGBA") as nofx:
                # RGBA getbbox observes a zero alpha-difference channel and can miss RGB-only
                # changes; compare the rendered colour channels explicitly.
                box = ImageChops.difference(fx.convert("RGB"), nofx.convert("RGB")).getbbox()
                if box is not None:
                    differs = True
                    changed_frames += 1
                    if difference_box is None:
                        difference_box = box
                    else:
                        difference_box = (
                            min(difference_box[0], box[0]), min(difference_box[1], box[1]),
                            max(difference_box[2], box[2]), max(difference_box[3], box[3]),
                        )
        # Only the around scenes must show an effect; a J move may draw none at 30 fps (Frey and Yuki ↓J).
        differing_pairs += int(differs or clip.get("group", "around") != "around")
        manifest["clips"].append(
            {
                "group": clip.get("group", "around"),
                "form": form,
                "move": move,
                "name": clip["name"],
                "input": clip["input"],
                "duration": round(sum(durations) / 1000, 3),
                "frames": count,
                "files": pair_files,
                "rows": clip["rows"],
                "size": clip["size"],
                "zoom": clip.get("zoom", 1.8),
                "fx_diff": differs,
                "fx_changed_frames": changed_frames,
                "fx_difference_box": list(difference_box) if difference_box else None,
            }
        )

    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    if differing_pairs != len(raw["clips"]):
        raise RuntimeError(
            f"FX suppression produced a visible difference in only {differing_pairs}/{len(raw['clips'])} around scenes"
        )
    shutil.rmtree(clips_root / "_frames")
    (clips_root / "_capture.json").unlink()
    print(
        f"encoded {len(raw['clips'])} around pairs / {len(raw['clips']) * 2} files, "
        f"{total_bytes / 1024 / 1024:.2f} MiB; fx differs in {differing_pairs}/{len(raw['clips'])} pairs; "
        f"preserved {preserved_j_count} J pairs"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
