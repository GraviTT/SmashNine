from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).with_name("overview.png")
CELL = 256
LABEL_W = 210
ROW_GAP = 10
BG = (9, 16, 28, 255)
CHECK_A = (28, 39, 58, 255)
CHECK_B = (38, 51, 73, 255)
LINE = (76, 95, 122, 255)
FLOOR = (244, 63, 94, 255)
TEXT = (231, 237, 248, 255)


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", size)


def load_frames(path: str, count: int) -> list[Image.Image]:
    sheet = Image.open(ROOT / path).convert("RGBA")
    return [sheet.crop((i * 128, 0, (i + 1) * 128, 128)) for i in range(count)]


def checker() -> Image.Image:
    image = Image.new("RGBA", (CELL, CELL), CHECK_A)
    draw = ImageDraw.Draw(image)
    tile = 16
    for y in range(0, CELL, tile):
        for x in range(0, CELL, tile):
            if (x // tile + y // tile) % 2:
                draw.rectangle((x, y, x + tile - 1, y + tile - 1), fill=CHECK_B)
    return image


sections = [
    (
        "FREY — ACCEPTED ANCHOR + EACH CANDIDATE AT 2X",
        "art/bakeoff/frey/frey-idle-v1.png",
        [
            ("IDLE V1", "art/bakeoff/frey/frey-idle-v1.png", 4),
            ("SPIKE FOLLOWUP V2", "art/bakeoff/frey/frey-spike_followup-v2.png", 4),
            ("DESCENT V2", "art/bakeoff/frey/frey-descent-v2.png", 6),
            ("TUMBLE V2", "art/bakeoff/frey/frey-tumble-v2.png", 4),
            ("WALK V1", "art/bakeoff/frey/frey-walk-v1.png", 6),
            ("RISING CLEAVE V1", "art/bakeoff/frey/frey-rising_cleave-v1.png", 5),
            ("ATTACK V2", "art/bakeoff/frey/frey-attack-v2.png", 4),
        ],
    ),
    (
        "YUKI — NEW ANCHOR + EACH CANDIDATE AT 2X",
        "art/bakeoff/yuki/yuki-idle-v1.png",
        [
            ("IDLE V1", "art/bakeoff/yuki/yuki-idle-v1.png", 4),
            ("TALISMAN SIDE V1", "art/bakeoff/yuki/yuki-talisman_side-v1.png", 4),
        ],
    ),
]

max_cells = max(1 + count for _, _, rows in sections for _, _, count in rows)
header_h = 48
height = 20 + sum(header_h + len(rows) * (CELL + ROW_GAP) for _, _, rows in sections)
width = LABEL_W + max_cells * CELL + 12
canvas = Image.new("RGBA", (width, height), BG)
draw = ImageDraw.Draw(canvas)
label_font = font(17)
frame_font = font(14)
title_font = font(22)
tile = checker()

y = 18
for title, anchor_path, rows in sections:
    draw.text((12, y), title, font=title_font, fill=TEXT)
    y += header_h
    anchor = load_frames(anchor_path, 1)[0]
    for label, row_path, count in rows:
        draw.multiline_text((12, y + 12), label, font=label_font, fill=TEXT, spacing=3)
        frames = [anchor] + load_frames(row_path, count)
        for index, frame in enumerate(frames):
            x = LABEL_W + index * CELL
            canvas.alpha_composite(tile, (x, y))
            enlarged = frame.resize((CELL, CELL), Image.Resampling.NEAREST)
            canvas.alpha_composite(enlarged, (x, y))
            draw.rectangle((x, y, x + CELL - 1, y + CELL - 1), outline=LINE, width=1)
            draw.line((x, y + 240, x + CELL - 1, y + 240), fill=FLOOR, width=2)
            draw.text((x + 5, y + 4), "A" if index == 0 else f"F{index}", font=frame_font, fill=TEXT)
        y += CELL + ROW_GAP

canvas.convert("RGB").save(OUT)
print(f"wrote {OUT} {canvas.size[0]}x{canvas.size[1]}")
