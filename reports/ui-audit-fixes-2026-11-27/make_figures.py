"""Before/after pairs for reports/ui-audit-fixes-2026-11-27 (the UI audit's medium items, batch by batch).

Captures come from smash-nine-prototype/tests/analysis/ui_audit/later_screens_capture.gd run windowed
(the window may stand off screen: --position -4000,-4000) before and after a batch; each run saves
<NN-screen>-<lang>.jpg at 1280x720.
Run from the repo root, once per batch:
  python reports/ui-audit-fixes-2026-11-27/make_figures.py b1 <before dir> <after dir>
  python reports/ui-audit-fixes-2026-11-27/make_figures.py b2 <before dir> <after dir>
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
FONT = "C:/Windows/Fonts/malgunbd.ttf"
SIDE = (960, 540)
GAP = 16
BAR = 46
# batch -> (output name, capture stem, language, caption, crop box or None, crop scale)
PAIRS = {
    "b1": [
        ("b1-01-results", "09-results", "ko", "경기 결과", None, 1),
        ("b1-02-options-hints", "01-options", "en", "설정 (키 안내 줄)", None, 1),
        ("b1-03-map-hints", "03-story-map", "ko", "스토리 지도 (키 안내 줄)", None, 1),
    ],
    "b2": [
        ("b2-01-options-hint", "01-options", "ko", "설정 (←/→ 음량 안내)", (640, 20, 1260, 70), 2),
        ("b2-02-controls-groups", "02-controls", "ko", "조작법 키보드 탭 (두 묶음)", None, 1),
        ("b2-03-card-bar", "07-story-card", "en", "시작 카드 (줄어드는 막대)", (420, 500, 860, 630), 2),
    ],
}


def load(path: Path, box, scale: int) -> Image.Image:
    image = Image.open(path).convert("RGB")
    if box is None:
        return image.resize(SIDE, Image.LANCZOS)
    part = image.crop(box)
    return part.resize((part.width * scale, part.height * scale), Image.LANCZOS)


def pair(before: Path, after: Path, caption: str, out: Path, box, scale: int) -> None:
    left, right = load(before, box, scale), load(after, box, scale)
    sheet = Image.new("RGB", (left.width + right.width + GAP, max(left.height, right.height) + BAR), (24, 26, 32))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.truetype(FONT, 20)
    for index, (image, label) in enumerate([(left, "전"), (right, "지금")]):
        x = index * (left.width + GAP)
        sheet.paste(image, (x, BAR))
        draw.text((x + 12, 11), f"{caption} · {label}", font=font, fill=(240, 236, 224))
    sheet.save(out, quality=88)
    print(out.name, sheet.size)


def main() -> None:
    batch, before_dir, after_dir = sys.argv[1], Path(sys.argv[2]), Path(sys.argv[3])
    (HERE / "img").mkdir(exist_ok=True)
    for name, stem, lang, caption, box, scale in PAIRS[batch]:
        pair(before_dir / f"{stem}-{lang}.jpg", after_dir / f"{stem}-{lang}.jpg", caption, HERE / "img" / f"{name}.jpg", box, scale)


if __name__ == "__main__":
    main()
