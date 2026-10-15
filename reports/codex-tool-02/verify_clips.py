from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw


def main() -> int:
    clips_root = Path(sys.argv[1]).resolve()
    out_root = Path(__file__).resolve().parent
    manifest = json.loads((clips_root / "manifest.json").read_text(encoding="utf-8"))
    clips = [clip for clip in manifest["clips"] if clip.get("group") == "around"]
    if len(clips) != 19:
        raise RuntimeError(f"expected 19 around scenes, found {len(clips)}")

    cell_w, cell_h, label_h, cols = 384, 216, 28, 4
    rows = (len(clips) + cols - 1) // cols
    results = []
    for mode in ("fx", "nofx"):
        sheet = Image.new("RGB", (cell_w * cols, (cell_h + label_h) * rows), "#101522")
        draw = ImageDraw.Draw(sheet)
        for index, clip in enumerate(clips):
            path = clips_root / clip["files"][mode]
            with Image.open(path) as animation:
                if animation.n_frames != clip["frames"]:
                    raise RuntimeError(f"{path}: {animation.n_frames} != {clip['frames']}")
                middle = animation.n_frames // 2
                animation.seek(middle)
                frame = animation.convert("RGB")
            frame.thumbnail((cell_w, cell_h), Image.Resampling.NEAREST)
            x = (index % cols) * cell_w
            y = (index // cols) * (cell_h + label_h)
            sheet.paste(frame, (x + (cell_w - frame.width) // 2, y))
            draw.text((x + 6, y + cell_h + 6), f"{clip['form']}/{clip['move']} {mode} mid {middle}", fill="white")
            results.append({"form": clip["form"], "move": clip["move"], "mode": mode, "middle": middle, "frames": clip["frames"]})
        sheet.save(out_root / f"middle-frames-{mode}.png")

    event_frames = {
        "guard": [26, 36], "pursuit": [22], "spike": [18, 28], "ultimate": [16, 34],
        "star-charge": [78], "transform": [29], "aura": [22], "seals": [40, 57],
        "momentum": [24, 55], "rune": [15, 26], "status": [15, 45],
    }
    selected = [(clip, at) for clip in clips for at in event_frames.get(clip["move"], [clip["frames"] // 2]) if at < clip["frames"]]
    rows = (len(selected) + cols - 1) // cols
    sheet = Image.new("RGB", (cell_w * cols, (cell_h + label_h) * rows), "#101522")
    draw = ImageDraw.Draw(sheet)
    for index, (clip, at) in enumerate(selected):
        path = clips_root / clip["files"]["fx"]
        with Image.open(path) as animation:
            animation.seek(at)
            frame = animation.convert("RGB")
        frame.thumbnail((cell_w, cell_h), Image.Resampling.NEAREST)
        x = (index % cols) * cell_w
        y = (index // cols) * (cell_h + label_h)
        sheet.paste(frame, (x + (cell_w - frame.width) // 2, y))
        draw.text((x + 6, y + cell_h + 6), f"{clip['form']}/{clip['move']} fx frame {at}", fill="white")
    sheet.save(out_root / "event-frames-fx.png")

    detail_requests = [
        ("frey", "pursuit", 26), ("frey", "spike", 16), ("frey", "spike", 20),
        ("frey", "spike", 24), ("luna", "star-charge", 78), ("yuki", "seals", 65),
        ("frey", "status", 15), ("frey", "status", 45),
    ]
    detail_w, detail_h, detail_cols = 480, 270, 2
    detail_rows = (len(detail_requests) + detail_cols - 1) // detail_cols
    detail_sheet = Image.new("RGB", (detail_w * detail_cols, (detail_h + label_h) * detail_rows), "#101522")
    detail_draw = ImageDraw.Draw(detail_sheet)
    by_key = {(clip["form"], clip["move"]): clip for clip in clips}
    for index, (form, move, at) in enumerate(detail_requests):
        clip = by_key[(form, move)]
        with Image.open(clips_root / clip["files"]["fx"]) as animation:
            animation.seek(at)
            frame = animation.convert("RGB")
        frame.thumbnail((detail_w, detail_h), Image.Resampling.NEAREST)
        x = (index % detail_cols) * detail_w
        y = (index // detail_cols) * (detail_h + label_h)
        detail_sheet.paste(frame, (x + (detail_w - frame.width) // 2, y))
        detail_draw.text((x + 6, y + detail_h + 6), f"{form}/{move} fx frame {at}", fill="white")
    detail_sheet.save(out_root / "inspection-details.png")

    (out_root / "middle-frames.json").write_text(
        json.dumps(results, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"verified {len(clips)} pairs / {len(results)} middle frames")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
