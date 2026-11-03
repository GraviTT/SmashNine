"""Board of the lead's playtest-prep picks (2026-11-03): the adopted body rows and Frey's K icon.

Run from the repository root: python reports/playtest-prep-2026-11-03/board.py
The strips are the candidate files as adopted (192-px cells), drawn at half size.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
BAKEOFF = ROOT / "art" / "bakeoff"
OUT = Path(__file__).resolve().parent / "board.png"
FONT = "C:/Windows/Fonts/malgun.ttf"

ROWS = [
    ("Frey · 발키리의 날개 정지 · wing_hover", "frey/frey-wing_hover-v1"),
    ("Luna · K 반짝 도약 · star_warp", "luna/luna-star_warp-v1"),
    ("Brave Luna · K 혜성 붙잡기 · brave_grab", "luna/luna_brave-brave_grab-v1"),
    ("Nova 남 · K 중력 구체 · orb_throw", "nova/nova_male-orb_throw-v1"),
    ("Nova 여 · K 중력 구체 · orb_throw", "nova/nova_female-orb_throw-v1"),
    ("Nova 남 · U 중력 광선 · gravity_beam", "nova/nova_male-gravity_beam-v1"),
    ("Nova 여 · U 중력 광선 · gravity_beam", "nova/nova_female-gravity_beam-v1"),
    ("Nova 남 · L 필드 시전 · zero_gravity", "nova/nova_male-zero_gravity-v1"),
    ("Nova 여 · L 필드 시전 · zero_gravity", "nova/nova_female-zero_gravity-v1"),
    ("Nova 남 · 필드 안 비행 · field_fly", "nova/nova_male-field_fly-v1"),
    ("Nova 여 · 필드 안 비행 · field_fly", "nova/nova_female-field_fly-v1"),
]
CELL = 96
LABEL_H = 30
PAD = 16
BG = (34, 34, 42)
CELL_BG = (52, 52, 64)
TEXT = (235, 235, 240)
DIM = (170, 170, 185)

title_font = ImageFont.truetype(FONT, 26)
label_font = ImageFont.truetype(FONT, 18)

strip_w = CELL * 6
icon_block_h = 40 * 4 + LABEL_H + PAD
width = PAD * 2 + strip_w
height = PAD + 74 + len(ROWS) * (LABEL_H + CELL + PAD) + icon_block_h + PAD
board = Image.new("RGB", (width, height), BG)
draw = ImageDraw.Draw(board)
draw.text((PAD, PAD), "플레이 테스트 전 리드 선택 (2026-11-03)", font=title_font, fill=TEXT)
draw.text((PAD, PAD + 40), "칸 1개 = 동작 그림 1장 (실제 크기의 1/2)", font=label_font, fill=DIM)

y = PAD + 74
for label, stem in ROWS:
    draw.text((PAD, y), label, font=label_font, fill=TEXT)
    y += LABEL_H
    strip = Image.open(BAKEOFF / f"{stem}.png").convert("RGBA")
    half = strip.resize((strip_w, CELL), Image.Resampling.BOX)
    for frame in range(6):
        draw.rectangle((PAD + frame * CELL, y, PAD + (frame + 1) * CELL - 2, y + CELL - 2), fill=CELL_BG)
    board.paste(half, (PAD, y), half)
    y += CELL + PAD

draw.text((PAD, y), "Frey K 아이콘 · 왼쪽 A(적용) · 오른쪽 B(남김)", font=label_font, fill=TEXT)
y += LABEL_H
for index, name in enumerate(("frey_k-a-v1", "frey_k-b-v1")):
    icon = Image.open(BAKEOFF / "skill_icons" / "frey" / f"{name}.png").convert("RGBA")
    big = icon.resize((160, 160), Image.Resampling.NEAREST)
    x = PAD + index * 200
    draw.rectangle((x, y, x + 159, y + 159), fill=CELL_BG)
    board.paste(big, (x, y), big)
board.save(OUT)
print(f"{OUT.name}: {board.size}")
