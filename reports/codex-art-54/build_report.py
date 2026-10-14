from __future__ import annotations

import json
import statistics
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
CELL = 128
SCALE = 4


CONFIG = {
    "frey": {
        "candidate": ROOT / "art/bakeoff/frey/frey-walk-v3.png",
        "current": ROOT / "art/bakeoff/frey/frey-walk-v2.png",
        "parts": [
            ROOT / "art/raw/walk-54/frey/final-02-a/metrics.json",
            ROOT / "art/raw/walk-54/frey/final-02-b/metrics.json",
        ],
        "head": ROOT / "art/raw/walk-54/frey/head-final.json",
        "factor": 0.242131,
        "near_foot": [(89, 117), (81, 117), (81, 117), (80, 117), (85, 117), (82, 117), (45, 117), (81, 117)],
        "forward_leg": ["near", "near", "near", "near", "near", "near", "far", "near"],
        "leg_notes": [
            "near leg forward contact",
            "near leg remains forward; far foot lifted behind",
            "near leg remains forward; far foot is lifted behind rather than passing forward",
            "near leg still reads forward",
            "near leg forward again; does not reverse frame 1",
            "near leg remains forward; far foot lifted behind",
            "far foot is lifted forward, but the required near-leg passing identity is reversed",
            "near leg reads forward again",
        ],
        "leg_pass": [True, False, False, False, False, False, False, False],
    },
    "luna": {
        "candidate": ROOT / "art/bakeoff/luna/luna-walk-v2.png",
        "current": ROOT / "art/bakeoff/luna/luna-walk-v1.png",
        "parts": [
            ROOT / "art/raw/walk-54/luna/final-02-a/metrics.json",
            ROOT / "art/raw/walk-54/luna/final-02-b/metrics.json",
        ],
        "head": ROOT / "art/raw/walk-54/luna/head-final.json",
        "factor": 0.241113,
        "near_foot": [(85, 117), (82, 117), (81, 117), (85, 117), (87, 117), (81, 117), (90, 109), (81, 117)],
        "forward_leg": ["near", "near", "near", "near", "near", "near", "near", "near"],
        "leg_notes": [
            "near leg forward contact",
            "near leg remains forward; far foot lifted behind",
            "near leg remains forward; far foot is lifted behind rather than passing forward",
            "near leg still reads forward",
            "near leg forward again; does not reverse frame 1",
            "near leg remains forward; far foot lifted behind",
            "near foot is clearly lifted forward, matching the requested passing pose",
            "near leg reads forward; far foot trails behind",
        ],
        "leg_pass": [True, False, False, False, False, False, True, False],
    },
}


def font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    try:
        return ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", size)
    except OSError:
        return ImageFont.load_default()


def spread(values: list[int]) -> float:
    mean = statistics.mean(values)
    return round((max(values) - min(values)) / mean * 100.0, 2) if mean else 0.0


def build_compare(character: str, cfg: dict[str, object], report_dir: Path) -> None:
    current = Image.open(cfg["current"]).convert("RGBA")
    candidate = Image.open(cfg["candidate"]).convert("RGBA")
    canvas = Image.new("RGBA", (CELL * 8 * SCALE, CELL * 2 * SCALE), (12, 17, 29, 255))
    current_zoom = current.resize((current.width * SCALE, current.height * SCALE), Image.Resampling.NEAREST)
    candidate_zoom = candidate.resize((candidate.width * SCALE, candidate.height * SCALE), Image.Resampling.NEAREST)
    canvas.alpha_composite(current_zoom, (0, 0))
    canvas.alpha_composite(candidate_zoom, (0, CELL * SCALE))
    draw = ImageDraw.Draw(canvas)
    draw.rectangle((0, 0, 310, 42), fill=(12, 17, 29, 235))
    draw.text((12, 8), f"{character.upper()} CURRENT WALK (6F)", font=font(24), fill=(239, 244, 255, 255))
    draw.rectangle((0, CELL * SCALE, 290, CELL * SCALE + 42), fill=(12, 17, 29, 235))
    draw.text((12, CELL * SCALE + 8), f"{character.upper()} NEW WALK (8F)", font=font(24), fill=(239, 244, 255, 255))
    canvas.convert("RGB").save(report_dir / "compare.png", optimize=True)


def build_feet(cfg: dict[str, object], report_dir: Path) -> None:
    candidate = Image.open(cfg["candidate"]).convert("RGBA")
    canvas = Image.new("RGBA", (CELL * 8 * SCALE, 48 * SCALE), (12, 17, 29, 255))
    for index, (near_x, near_y) in enumerate(cfg["near_foot"]):
        frame = candidate.crop((index * CELL, 80, (index + 1) * CELL, CELL))
        frame = frame.resize((CELL * SCALE, 48 * SCALE), Image.Resampling.NEAREST)
        canvas.alpha_composite(frame, (index * CELL * SCALE, 0))
        draw = ImageDraw.Draw(canvas)
        cx = index * CELL * SCALE + near_x * SCALE
        cy = (near_y - 80) * SCALE
        radius = 10 * SCALE
        draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), outline=(42, 224, 255, 255), width=6)
        draw.text((index * CELL * SCALE + 8, 7), f"F{index + 1} N", font=font(22), fill=(42, 224, 255, 255))
        if index:
            draw.line((index * CELL * SCALE, 0, index * CELL * SCALE, 48 * SCALE), fill=(74, 87, 109, 255), width=2)
    canvas.convert("RGB").save(report_dir / "feet.png", optimize=True)


def merge_metrics(character: str, cfg: dict[str, object], report_dir: Path) -> None:
    parts = [json.loads(Path(path).read_text(encoding="utf-8")) for path in cfg["parts"]]
    frames: list[dict[str, object]] = []
    for part in parts:
        for frame in part["frames"]:
            copied = dict(frame)
            copied["index"] = len(frames)
            frames.append(copied)
    heights = [int(frame["body_height"]) for frame in frames]
    widths = [int(frame["body_width"]) for frame in frames]
    areas = [int(frame["area"]) for frame in frames]
    details = [float(frame["interior_detail"]) for frame in frames]
    colours = [int(frame["colour_count"]) for frame in frames]
    head_payload = json.loads(Path(cfg["head"]).read_text(encoding="utf-8"))[0]
    summary = {
        "frame_count": 8,
        "output_columns": 8,
        "common_scale": cfg["factor"],
        "scale_by": f"fixed:{cfg['factor']}",
        "common_offset_x": 0,
        "ground_all": True,
        "resample": "lanczos",
        "sharpen_percent": 60.0,
        "despill": "auto",
        "palette": "none",
        "body_height_range": [min(heights), max(heights)],
        "body_width_range": [min(widths), max(widths)],
        "area_range": [min(areas), max(areas)],
        "area_spread_percent": spread(areas),
        "bottom_range": [min(int(frame["bottom"]) for frame in frames), max(int(frame["bottom"]) for frame in frames)],
        "colour_count_range": [min(colours), max(colours)],
        "interior_detail_range": [round(min(details), 2), round(max(details), 2)],
        "interior_detail_mean": round(statistics.mean(details), 2),
        "remaining_spill_pixels": [int(frame["remaining_spill_pixels"]) for frame in frames],
        "alpha_binary": all(bool(frame["alpha_binary"]) for frame in frames),
        "borders_clear": all(bool(frame["border_clear"]) for frame in frames),
        "all_have_4px_margin": all(bool(frame["margin"]["has_4px_margin"]) for frame in frames),
        "contact_on_y120": all(int(frame["bottom"]) == 120 for frame in frames),
    }
    payload = {
        "input": {
            "selected_generation": 2,
            "raw": f"art/raw/walk-54/{character}/{character}-walk-generation-02.png",
            "aligned_4x2": f"art/raw/walk-54/{character}/{character}-walk-generation-02-aligned.png",
            "grid": [4, 2],
            "note": "Built-in output was 1774x887 (exact 2:1) and was proportionally aligned to the requested 2048x1024 grid before normalization.",
        },
        "summary": summary,
        "head_scale": head_payload,
        "visual_leg_check": {
            "overall_pass": False,
            "frame_1_and_5_show_different_forward_legs": False,
            "frame_3_passing_leg_clearly_lifted_forward": False,
            "frame_7_passing_leg_clearly_lifted_forward": character == "luna",
            "forward_leg_by_frame": cfg["forward_leg"],
            "frame_notes": cfg["leg_notes"],
            "frame_pass": cfg["leg_pass"],
            "basis": "visual judgment at 4x; cyan circles in feet.png mark the judged near foot",
        },
        "frames": frames,
        "outputs": {
            "candidate": str(Path(cfg["candidate"]).relative_to(ROOT)).replace("\\", "/"),
            "compare": str((report_dir / "compare.png").relative_to(ROOT)).replace("\\", "/"),
            "feet": str((report_dir / "feet.png").relative_to(ROOT)).replace("\\", "/"),
        },
    }
    (report_dir / "metrics.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    for character, cfg in CONFIG.items():
        report_dir = ROOT / f"reports/codex-art-54/{character}"
        report_dir.mkdir(parents=True, exist_ok=True)
        build_compare(character, cfg, report_dir)
        build_feet(cfg, report_dir)
        merge_metrics(character, cfg, report_dir)


if __name__ == "__main__":
    main()
