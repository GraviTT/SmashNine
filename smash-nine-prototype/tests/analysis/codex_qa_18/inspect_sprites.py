"""Build 2x inspection contacts and reproducible per-frame sprite metrics for CODEX-QA-18."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[4]
ART = ROOT / "smash-nine-prototype" / "assets" / "art"
REPORT = ROOT / "reports" / "codex-qa-18"
CONTACT = REPORT / "contact"
METRICS = REPORT / "metrics"
CELL = 128

MAIN_ROWS = [
    ("idle", 4, 7.0, True),
    ("walk", 6, 10.0, True),
    ("jump", 1, 1.0, False),
    ("fall", 1, 1.0, False),
    ("attack", 4, 14.0, False),
    ("shield", 6, 12.0, False),
    ("hurt", 1, 1.0, False),
]

MOVE_ROWS: dict[str, list[tuple[str, int, float, bool]]] = {
    "frey": [
        ("attack_up", 4, 14.0, False), ("attack_down", 4, 14.0, False),
        ("attack_air_side", 4, 14.0, False), ("dash_strike", 4, 14.0, False),
        ("rising_cleave", 5, 14.0, False), ("spike_followup", 4, 14.0, False),
        ("descent", 6, 14.0, False), ("tumble", 4, 14.0, True),
    ],
    "luna": [
        ("star_up", 4, 14.0, False), ("star_down", 4, 14.0, False),
        ("star_comet", 4, 14.0, False), ("moon_ring", 5, 14.0, False),
        ("transform", 6, 14.0, False), ("tumble", 4, 14.0, True),
    ],
    "luna_brave": [
        ("brave_combo", 6, 16.0, False), ("brave_upper", 4, 16.0, False),
        ("brave_low", 4, 16.0, False), ("brave_air_side", 4, 16.0, False),
        ("brave_dive", 4, 16.0, False), ("comet_drive", 4, 16.0, False),
        ("luna_breaker", 6, 16.0, False), ("heart_laser", 6, 12.0, False),
        ("tumble", 4, 14.0, True),
    ],
    "nova_male": [
        ("vector_side", 4, 23.5, False), ("vector_upper", 4, 22.0, False),
        ("compression_stomp", 4, 17.4, False), ("air_side", 4, 26.7, False),
        ("meteor_kick", 5, 25.0, False), ("vector_shift", 4, 18.2, False),
        ("gravity_brake", 5, 11.9, False), ("slingshot_start", 6, 14.0, False),
    ],
    "nova_female": [
        ("vector_side", 4, 23.5, False), ("vector_upper", 4, 22.0, False),
        ("compression_stomp", 4, 17.4, False), ("air_side", 4, 26.7, False),
        ("meteor_kick", 5, 25.0, False), ("vector_shift", 4, 18.2, False),
        ("gravity_brake", 5, 11.9, False), ("slingshot_start", 6, 14.0, False),
    ],
    "rio_male": [
        ("mana_combo", 6, 18.0, False), ("rising_slash", 4, 20.0, False),
        ("low_sweep", 4, 20.0, False), ("air_slash", 4, 26.7, False),
        ("plunge", 5, 10.0, False), ("dimension_slash", 5, 19.2, False),
        ("rune_shield", 6, 12.0, False), ("infinity_overdrive", 6, 11.0, False),
    ],
    "rio_female": [
        ("mana_combo", 6, 18.0, False), ("rising_slash", 4, 20.0, False),
        ("low_sweep", 4, 20.0, False), ("air_slash", 4, 26.7, False),
        ("plunge", 5, 10.0, False), ("dimension_slash", 5, 19.2, False),
        ("rune_shield", 6, 12.0, False), ("infinity_overdrive", 6, 11.0, False),
    ],
    "yuki": [
        ("talisman_side", 4, 19.0, False), ("talisman_up", 4, 16.7, False),
        ("ground_ward", 4, 15.4, False), ("talisman_air_side", 4, 22.2, False),
        ("talisman_air_down", 4, 14.8, False), ("seal_place", 5, 15.6, False),
        ("seal_activate", 5, 16.0, False), ("grand_ward", 6, 9.7, False),
    ],
}

SHEETS = {
    "frey": ART / "frey" / "frey_sheet.png",
    "luna": ART / "luna" / "luna_sheet.png",
    "luna_brave": ART / "luna" / "luna_brave_sheet.png",
    "nova_male": ART / "nova" / "nova_male_sheet.png",
    "nova_female": ART / "nova" / "nova_female_sheet.png",
    "rio_male": ART / "rio" / "rio_male_sheet.png",
    "rio_female": ART / "rio" / "rio_female_sheet.png",
    "yuki": ART / "yuki" / "yuki_sheet.png",
}

MOVE_SHEETS = {
    "frey": ART / "frey" / "frey_moves_sheet.png",
    "luna": ART / "luna" / "luna_moves_sheet.png",
    "luna_brave": ART / "luna" / "luna_brave_moves_sheet.png",
    "nova_male": ART / "nova" / "nova_male_moves_sheet.png",
    "nova_female": ART / "nova" / "nova_female_moves_sheet.png",
    "rio_male": ART / "rio" / "rio_male_moves_sheet.png",
    "rio_female": ART / "rio" / "rio_female_moves_sheet.png",
    "yuki": ART / "yuki" / "yuki_moves_sheet.png",
}


def bbox(mask: np.ndarray) -> list[int] | None:
    ys, xs = np.nonzero(mask)
    if len(xs) == 0:
        return None
    return [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())]


def frame_metrics(cell: np.ndarray, palette: set[tuple[int, int, int]]) -> dict[str, Any]:
    alpha = cell[:, :, 3]
    mask = alpha > 0
    box = bbox(mask)
    area = int(mask.sum())
    border = np.zeros((CELL, CELL), dtype=bool)
    border[[0, -1], :] = True
    border[:, [0, -1]] = True
    margin = np.zeros((CELL, CELL), dtype=bool)
    margin[:4, :] = True
    margin[-4:, :] = True
    margin[:, :4] = True
    margin[:, -4:] = True
    opaque_rgb = cell[:, :, :3][mask]
    outside = sum(tuple(int(v) for v in rgb) not in palette for rgb in opaque_rgb)
    result: dict[str, Any] = {
        "bbox": box,
        "width": 0 if box is None else box[2] - box[0] + 1,
        "height": 0 if box is None else box[3] - box[1] + 1,
        "area": area,
        "center_x": None if box is None else round((box[0] + box[2]) / 2.0, 2),
        "center_y": None if box is None else round((box[1] + box[3]) / 2.0, 2),
        "feet_y": None if box is None else box[3],
        "border_pixels": int((mask & border).sum()),
        "margin4_pixels": int((mask & margin).sum()),
        "partial_alpha_pixels": int(((alpha > 0) & (alpha < 255)).sum()),
        "outside_palette_pixels": int(outside),
        "outside_palette_ratio": round(outside / max(area, 1), 5),
    }
    return result


def pct_spread(values: list[int]) -> float:
    mean = sum(values) / max(len(values), 1)
    return round((max(values) - min(values)) / max(mean, 1.0) * 100.0, 2)


def pct_delta(value: int, reference: int) -> float:
    return round((value - reference) / max(reference, 1) * 100.0, 2)


def row_metrics(frames: list[dict[str, Any]], idle: dict[str, Any]) -> dict[str, Any]:
    widths = [f["width"] for f in frames]
    heights = [f["height"] for f in frames]
    areas = [f["area"] for f in frames]
    consecutive_area = [
        round(abs(areas[i] - areas[i - 1]) / max(areas[i - 1], 1) * 100.0, 2)
        for i in range(1, len(areas))
    ]
    consecutive_height = [abs(heights[i] - heights[i - 1]) for i in range(1, len(heights))]
    consecutive_width = [abs(widths[i] - widths[i - 1]) for i in range(1, len(widths))]
    first = frames[0]
    last = frames[-1]
    total_area = sum(areas)
    outside_palette = sum(f["outside_palette_pixels"] for f in frames)
    def vs_idle(frame: dict[str, Any]) -> dict[str, Any]:
        return {
            "width_pct": pct_delta(frame["width"], idle["width"]),
            "height_pct": pct_delta(frame["height"], idle["height"]),
            "area_pct": pct_delta(frame["area"], idle["area"]),
            "center_dx": None if frame["center_x"] is None else round(frame["center_x"] - idle["center_x"], 2),
            "center_dy": None if frame["center_y"] is None else round(frame["center_y"] - idle["center_y"], 2),
        }
    return {
        "width_range": [min(widths), max(widths)],
        "height_range": [min(heights), max(heights)],
        "area_range": [min(areas), max(areas)],
        "width_spread_pct": pct_spread(widths),
        "height_spread_pct": pct_spread(heights),
        "area_spread_pct": pct_spread(areas),
        "max_consecutive_area_jump_pct": max(consecutive_area, default=0.0),
        "max_consecutive_height_jump_px": max(consecutive_height, default=0),
        "max_consecutive_width_jump_px": max(consecutive_width, default=0),
        "first_vs_idle": vs_idle(first),
        "last_vs_idle": vs_idle(last),
        "border_pixels": sum(f["border_pixels"] for f in frames),
        "margin4_pixels": sum(f["margin4_pixels"] for f in frames),
        "partial_alpha_pixels": sum(f["partial_alpha_pixels"] for f in frames),
        "outside_palette_pixels": outside_palette,
        "outside_palette_ratio": round(outside_palette / max(total_area, 1), 5),
        "feet_y": [f["feet_y"] for f in frames],
    }


def walk_feet(image: np.ndarray) -> dict[str, Any]:
    changes: list[float] = []
    spans: list[int] = []
    for frame in range(6):
        other = (frame + 1) % 6
        p = image[128 + 100:128 + 121, frame * 128:(frame + 1) * 128, 3] > 127
        q = image[128 + 100:128 + 121, other * 128:(other + 1) * 128, 3] > 127
        union = p | q
        changes.append(float(np.count_nonzero(p != q)) / max(int(union.sum()), 1))
        stance = p[12:21, :]
        _, xs = np.nonzero(stance)
        spans.append(0 if len(xs) == 0 else int(xs.max() - xs.min()))
    return {
        "mean_feet_silhouette_change_pct": round(sum(changes) / 6.0 * 100.0, 2),
        "per_transition_pct": [round(v * 100.0, 2) for v in changes],
        "stance_width_px": spans,
    }


def checker(size: tuple[int, int], block: int = 16) -> Image.Image:
    canvas = Image.new("RGBA", size, (35, 39, 49, 255))
    draw = ImageDraw.Draw(canvas)
    for y in range(0, size[1], block):
        for x in range(0, size[0], block):
            if (x // block + y // block) % 2:
                draw.rectangle((x, y, x + block - 1, y + block - 1), fill=(48, 53, 65, 255))
    return canvas


def make_contact(
    body: str,
    kind: str,
    image: Image.Image,
    idle_frame: Image.Image,
    rows: list[tuple[str, int, float, bool]],
) -> None:
    scale = 2
    tile = CELL * scale
    label_h = 38
    left_w = 190
    row_h = tile + label_h
    canvas = checker((left_w + 7 * tile, 38 + len(rows) * row_h))
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.load_default()
    draw.text((8, 8), f"{body} {kind} | cells 2x nearest | left = idle reference", fill="white", font=font)
    idle_2x = idle_frame.resize((tile, tile), Image.Resampling.NEAREST)
    for row_index, (name, count, fps, loop) in enumerate(rows):
        y = 38 + row_index * row_h
        draw.text((8, y + 8), name, fill=(255, 255, 255), font=font)
        draw.text((8, y + 24), f"{count}f @ {fps:g}fps" + (" loop" if loop else ""), fill=(190, 205, 224), font=font)
        idle_bg = checker((tile, tile))
        idle_bg.alpha_composite(idle_2x)
        canvas.alpha_composite(idle_bg, (left_w, y))
        draw.rectangle((left_w, y, left_w + tile - 1, y + tile - 1), outline=(80, 230, 255, 255), width=2)
        draw.text((left_w + 4, y + tile + 7), "IDLE", fill=(80, 230, 255), font=font)
        for frame_index in range(count):
            crop = image.crop((frame_index * CELL, row_index * CELL, (frame_index + 1) * CELL, (row_index + 1) * CELL))
            crop = crop.resize((tile, tile), Image.Resampling.NEAREST)
            x = left_w + (frame_index + 1) * tile
            bg = checker((tile, tile))
            bg.alpha_composite(crop)
            canvas.alpha_composite(bg, (x, y))
            draw.rectangle((x, y, x + tile - 1, y + tile - 1), outline=(106, 112, 130, 255), width=1)
            draw.text((x + 4, y + tile + 7), f"F{frame_index + 1}", fill="white", font=font)
    canvas.convert("RGB").save(CONTACT / f"{body}_{kind}_2x.png", optimize=True)


def inspect_sheet(
    body: str,
    kind: str,
    path: Path,
    rows: list[tuple[str, int, float, bool]],
    idle_frame: Image.Image,
    idle_metrics: dict[str, Any],
    palette: set[tuple[int, int, int]],
) -> dict[str, Any]:
    pil = Image.open(path).convert("RGBA")
    arr = np.asarray(pil)
    expected = (CELL * 6, CELL * len(rows))
    result: dict[str, Any] = {
        "body": body,
        "kind": kind,
        "source": path.relative_to(ROOT).as_posix(),
        "image_size": list(pil.size),
        "expected_size": list(expected),
        "rows": [],
    }
    for row_index, (name, count, fps, loop) in enumerate(rows):
        frames = []
        for frame_index in range(count):
            cell = arr[row_index * CELL:(row_index + 1) * CELL, frame_index * CELL:(frame_index + 1) * CELL]
            frame = frame_metrics(cell, palette)
            frame["frame"] = frame_index + 1
            frames.append(frame)
        unused_nonempty = []
        for frame_index in range(count, 6):
            alpha = arr[row_index * CELL:(row_index + 1) * CELL, frame_index * CELL:(frame_index + 1) * CELL, 3]
            if np.any(alpha > 0):
                unused_nonempty.append(frame_index + 1)
        result["rows"].append({
            "name": name,
            "count": count,
            "fps": fps,
            "loop": loop,
            "summary": row_metrics(frames, idle_metrics),
            "unused_nonempty_frames": unused_nonempty,
            "frames": frames,
        })
    if kind == "main":
        result["walk_feet"] = walk_feet(arr)
    make_contact(body, kind, pil, idle_frame, rows)
    return result


def main() -> None:
    CONTACT.mkdir(parents=True, exist_ok=True)
    METRICS.mkdir(parents=True, exist_ok=True)
    index: dict[str, Any] = {"contract": {"cell": CELL, "feet_y": 120, "border": 1, "margin": 4}, "bodies": {}}
    for body, main_path in SHEETS.items():
        main_image = Image.open(main_path).convert("RGBA")
        main_arr = np.asarray(main_image)
        idle_frame = main_image.crop((0, 0, CELL, CELL))
        idle_cell = main_arr[:CELL, :CELL]
        palette = {tuple(int(v) for v in rgb) for rgb in main_arr[:, :, :3][main_arr[:, :, 3] > 0]}
        idle = frame_metrics(idle_cell, palette)
        main_result = inspect_sheet(body, "main", main_path, MAIN_ROWS, idle_frame, idle, palette)
        moves_result = inspect_sheet(body, "moves", MOVE_SHEETS[body], MOVE_ROWS[body], idle_frame, idle, palette)
        body_result = {
            "idle_reference": idle,
            "main_palette_color_count": len(palette),
            "main": main_result,
            "moves": moves_result,
        }
        index["bodies"][body] = body_result
        (METRICS / f"{body}.json").write_text(json.dumps(body_result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (METRICS / "index.json").write_text(json.dumps(index, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {len(SHEETS) * 2} contacts and {len(SHEETS) + 1} metric files")


if __name__ == "__main__":
    main()
