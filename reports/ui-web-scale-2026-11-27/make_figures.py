"""Figures for reports/ui-web-scale-2026-11-27: the lead's capture beside the reproduced one.

Run from the repo root: python reports/ui-web-scale-2026-11-27/make_figures.py
Inputs: the lead's capture (reports/ui-hud-2026-11-26/img/10-web-853x480-before.jpg) and
img/src-zoom-reproduced.jpg (Browser pane, hidden, frames paused while the page went from
1920x1080 to 1280x720 CSS px). Both are 800x450 screenshots of a 1280x720 CSS px page.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
FONT = "C:/Windows/Fonts/malgunbd.ttf"
LEFT = REPO / "reports/ui-hud-2026-11-26/img/10-web-853x480-before.jpg"
RIGHT = HERE / "img/src-zoom-reproduced.jpg"
OUT = HERE / "img/01-lead-vs-reproduced.jpg"

LABELS = [
    "총괄이 찍은 화면 (11-27)",
    "다시 만든 화면: 프레임을 멈춘 채 창을 1920×1080에서 1280×720으로 줄임",
]
GAP = 16
BAR = 44


def centre_line(draw: ImageDraw.ImageDraw, x0: int, y0: int, w: int, h: int, font) -> None:
    x = x0 + w // 2
    for y in range(y0, y0 + h, 14):
        draw.line([(x, y), (x, min(y + 7, y0 + h))], fill=(255, 255, 255, 200), width=2)
    draw.text((x + 6, y0 + h - 30), "화면 가운데", font=font, fill=(255, 255, 255, 230))


def main() -> None:
    left = Image.open(LEFT).convert("RGB")
    right = Image.open(RIGHT).convert("RGB")
    w, h = left.size
    assert right.size == (w, h), (left.size, right.size)
    sheet = Image.new("RGB", (w * 2 + GAP, h + BAR), (24, 26, 32))
    sheet.paste(left, (0, BAR))
    sheet.paste(right, (w + GAP, BAR))
    draw = ImageDraw.Draw(sheet, "RGBA")
    label_font = ImageFont.truetype(FONT, 19)
    small_font = ImageFont.truetype(FONT, 15)
    for i, text in enumerate(LABELS):
        x0 = i * (w + GAP)
        draw.text((x0 + 10, 11), text, font=label_font, fill=(240, 236, 224))
        centre_line(draw, x0, BAR, w, h, small_font)
    sheet.save(OUT, quality=90)
    print(OUT, sheet.size)


if __name__ == "__main__":
    main()
