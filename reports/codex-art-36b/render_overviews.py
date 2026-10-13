from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
CELL = 128


def font(size: int):
    try:
        return ImageFont.truetype("C:/Windows/Fonts/consola.ttf", size)
    except OSError:
        return ImageFont.load_default()


FONT = font(20)
SMALL = font(15)
BG = (12, 18, 30, 255)
GRID_A = (31, 43, 64, 255)
GRID_B = (41, 55, 79, 255)


def checker(scale: int) -> Image.Image:
    size = CELL * scale
    out = Image.new("RGBA", (size, size), GRID_A)
    draw = ImageDraw.Draw(out)
    block = 8 * scale
    for y in range(0, size, block):
        for x in range(0, size, block):
            if (x // block + y // block) % 2:
                draw.rectangle((x, y, x + block - 1, y + block - 1), fill=GRID_B)
    return out


def cell(path: str, index: int, row: int = 0, scale: int = 2) -> Image.Image:
    image = Image.open(ROOT / path).convert("RGBA")
    frame = image.crop((index * CELL, row * CELL, (index + 1) * CELL, (row + 1) * CELL))
    frame = frame.resize((CELL * scale, CELL * scale), Image.Resampling.NEAREST)
    bg = checker(scale)
    bg.alpha_composite(frame)
    return bg


def render_group(filename: str, rows: list[dict]) -> None:
    scale = 2
    label_w = 215
    frame_w = CELL * scale
    width = label_w + frame_w * (1 + max(row["count"] for row in rows))
    row_h = frame_w + 52
    canvas = Image.new("RGBA", (width, row_h * len(rows)), BG)
    draw = ImageDraw.Draw(canvas)
    for row_index, row in enumerate(rows):
        y = row_index * row_h
        draw.text((12, y + 14), row["label"], fill=(235, 241, 255), font=FONT)
        draw.text((12, y + 42), f"{row['version']}  factor {row['factor']}", fill=(148, 180, 220), font=SMALL)
        ax = label_w
        canvas.alpha_composite(cell(row["anchor"], row.get("anchor_index", 0), row.get("anchor_row", 0), scale), (ax, y + 35))
        draw.text((ax + 6, y + 7), "ANCHOR", fill=(255, 211, 96), font=SMALL)
        for i in range(row["count"]):
            x = label_w + frame_w * (i + 1)
            canvas.alpha_composite(cell(row["candidate"], i, 0, scale), (x, y + 35))
            draw.text((x + 6, y + 7), f"F{i}", fill=(235, 241, 255), font=SMALL)
        draw.line((0, y + row_h - 1, width, y + row_h - 1), fill=(70, 89, 120), width=1)
    canvas.convert("RGB").save(OUT / filename, optimize=True)


def render_scale_check() -> None:
    rows = [
        {
            "label": "Rio walk: clearest face F2",
            "factor": "0.22175536",
            "anchor": "art/bakeoff/rio/rio_female-idle-v1.png",
            "candidate": "art/bakeoff/rio/rio_female-walk-v2.png",
            "candidate_index": 2,
        },
        {
            "label": "Rio plunge: regenerated, clearest face F0",
            "factor": "0.22439531",
            "anchor": "art/bakeoff/rio/rio_female-idle-v1.png",
            "candidate": "art/bakeoff/rio/rio_female-plunge-v2.png",
            "candidate_index": 0,
        },
        {
            "label": "Brave Luna combo: clearest face F1",
            "factor": "0.21461755",
            "anchor": "art/bakeoff/luna/luna_brave-idle-v1.png",
            "candidate": "art/bakeoff/luna/luna_brave-brave_combo-v2.png",
            "candidate_index": 1,
        },
    ]
    scale = 3
    frame_w = CELL * scale
    width = frame_w * 2 + 48
    row_h = frame_w + 74
    canvas = Image.new("RGBA", (width, row_h * len(rows)), BG)
    draw = ImageDraw.Draw(canvas)
    for row_index, row in enumerate(rows):
        y = row_index * row_h
        draw.text((12, y + 8), f"{row['label']} / factor {row['factor']}", fill=(235, 241, 255), font=FONT)
        draw.text((12, y + 38), "ANCHOR F1", fill=(255, 211, 96), font=SMALL)
        draw.text((frame_w + 36, y + 38), "MOTION", fill=(148, 220, 255), font=SMALL)
        canvas.alpha_composite(cell(row["anchor"], 1, 0, scale), (12, y + 66))
        canvas.alpha_composite(cell(row["candidate"], row["candidate_index"], 0, scale), (frame_w + 36, y + 66))
    canvas.convert("RGB").save(OUT / "scale-check-3x.png", optimize=True)


if __name__ == "__main__":
    render_group("inspection-overview-rio.png", [
        {"label": "Rio female idle", "version": "v1 accepted", "factor": "0.18849206", "anchor": "smash-nine-prototype/assets/art/rio/rio_female_sheet.png", "candidate": "art/bakeoff/rio/rio_female-idle-v1.png", "count": 4},
        {"label": "Rio female walk", "version": "v2", "factor": "0.22175536", "anchor": "art/bakeoff/rio/rio_female-idle-v1.png", "candidate": "art/bakeoff/rio/rio_female-walk-v2.png", "count": 6},
        {"label": "Rio female air_slash", "version": "v2 regenerated", "factor": "0.18849206", "anchor": "art/bakeoff/rio/rio_female-idle-v1.png", "candidate": "art/bakeoff/rio/rio_female-air_slash-v2.png", "count": 4},
        {"label": "Rio female plunge", "version": "v2 regenerated", "factor": "0.22439531", "anchor": "art/bakeoff/rio/rio_female-idle-v1.png", "candidate": "art/bakeoff/rio/rio_female-plunge-v2.png", "count": 5},
    ])
    render_group("inspection-overview-nova.png", [
        {"label": "Nova male idle", "version": "v1 accepted", "factor": "0.17951220", "anchor": "smash-nine-prototype/assets/art/nova/nova_male_sheet.png", "candidate": "art/bakeoff/nova/nova_male-idle-v1.png", "count": 4},
        {"label": "Nova male vector_side", "version": "v1 accepted", "factor": "0.17951220", "anchor": "art/bakeoff/nova/nova_male-idle-v1.png", "candidate": "art/bakeoff/nova/nova_male-vector_side-v1.png", "count": 4},
        {"label": "Nova female idle", "version": "v1 accepted", "factor": "0.16853933", "anchor": "smash-nine-prototype/assets/art/nova/nova_female_sheet.png", "candidate": "art/bakeoff/nova/nova_female-idle-v1.png", "count": 4},
        {"label": "Nova female vector_side", "version": "v2 min-component", "factor": "0.16853933", "anchor": "art/bakeoff/nova/nova_female-idle-v1.png", "candidate": "art/bakeoff/nova/nova_female-vector_side-v2.png", "count": 4},
    ])
    render_group("inspection-overview-luna.png", [
        {"label": "Brave Luna idle", "version": "v1 accepted", "factor": "0.18242492", "anchor": "smash-nine-prototype/assets/art/luna/luna_brave_sheet.png", "candidate": "art/bakeoff/luna/luna_brave-idle-v1.png", "count": 4},
        {"label": "Brave Luna brave_combo", "version": "v2", "factor": "0.21461755", "anchor": "art/bakeoff/luna/luna_brave-idle-v1.png", "candidate": "art/bakeoff/luna/luna_brave-brave_combo-v2.png", "count": 6},
        {"label": "Luna idle", "version": "v1 new", "factor": "0.18594104", "anchor": "smash-nine-prototype/assets/art/luna/luna_sheet.png", "candidate": "art/bakeoff/luna/luna-idle-v1.png", "count": 4},
        {"label": "Luna attack", "version": "v1 new", "factor": "0.18594104", "anchor": "art/bakeoff/luna/luna-idle-v1.png", "candidate": "art/bakeoff/luna/luna-attack-v1.png", "count": 4},
    ])
    render_scale_check()
