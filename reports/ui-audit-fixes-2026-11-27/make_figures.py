"""Before/after pairs for reports/ui-audit-fixes-2026-11-27 (the UI audit's medium items, batch by batch).

Captures come from smash-nine-prototype/tests/analysis/ui_audit/later_screens_capture.gd run windowed
(the window may stand off screen: --position -4000,-4000) before and after a batch; each run saves
<NN-screen>-<lang>.jpg at 1280x720.
Run from the repo root:
  python reports/ui-audit-fixes-2026-11-27/make_figures.py <before dir> <after dir>
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
FONT = "C:/Windows/Fonts/malgunbd.ttf"
SIDE = (960, 540)
GAP = 16
BAR = 46
# (output name, capture stem, language, caption)
PAIRS = [
    ("b1-01-results", "09-results", "ko", "경기 결과"),
    ("b1-02-options-hints", "01-options", "en", "설정 (키 안내 줄)"),
    ("b1-03-map-hints", "03-story-map", "ko", "스토리 지도 (키 안내 줄)"),
]


def pair(before: Path, after: Path, caption: str, out: Path) -> None:
    sheet = Image.new("RGB", (SIDE[0] * 2 + GAP, SIDE[1] + BAR), (24, 26, 32))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.truetype(FONT, 20)
    for index, (path, label) in enumerate([(before, "전"), (after, "지금")]):
        x = index * (SIDE[0] + GAP)
        sheet.paste(Image.open(path).convert("RGB").resize(SIDE, Image.LANCZOS), (x, BAR))
        draw.text((x + 12, 11), f"{caption} · {label}", font=font, fill=(240, 236, 224))
    sheet.save(out, quality=88)
    print(out.name, sheet.size)


def main() -> None:
    before_dir, after_dir = Path(sys.argv[1]), Path(sys.argv[2])
    (HERE / "img").mkdir(exist_ok=True)
    for name, stem, lang, caption in PAIRS:
        pair(before_dir / f"{stem}-{lang}.jpg", after_dir / f"{stem}-{lang}.jpg", caption, HERE / "img" / f"{name}.jpg")


if __name__ == "__main__":
    main()
