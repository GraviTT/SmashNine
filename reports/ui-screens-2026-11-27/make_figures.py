"""Before/after pairs for reports/ui-screens-2026-11-27 (the screens after the menus in menu B's look).

Captures come from smash-nine-prototype/tests/analysis/ui_audit/later_screens_capture.gd, run
windowed twice: on the web build's pack from before the change (main 23b8ff7c, --main-pack) for
"before", and on the project for "after". Each run saves <NN-screen>-<lang>.jpg at 1280x720.
Run from the repo root:
  python reports/ui-screens-2026-11-27/make_figures.py <before dir> <after dir>
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
FONT = "C:/Windows/Fonts/malgunbd.ttf"
SIDE = (960, 540)
GAP = 16
BAR = 46
# (output name, capture stem, language, caption of the pair)
PAIRS = [
    ("01-options", "01-options", "ko", "설정"),
    ("02-controls", "02-controls", "ko", "조작법"),
    ("03-results-ko", "09-results", "ko", "경기 결과"),
    ("04-results-en", "09-results", "en", "경기 결과 (영어)"),
    ("05-story-map", "03-story-map", "ko", "스토리 지도"),
    ("06-story-pause", "04-story-pause", "ko", "스토리 일시정지"),
    ("07-story-clear", "05-story-clear", "ko", "스테이지 완료"),
    ("08-story-failed", "06-story-failed", "en", "스테이지 실패 (영어)"),
    ("09-story-card", "07-story-card", "ko", "스테이지 시작 카드 (버튼만 바뀜)"),
    ("10-story-ending", "08-story-ending", "ko", "스토리 엔딩"),
]


def pair(before: Path, after: Path, caption: str, out: Path) -> None:
    sheet = Image.new("RGB", (SIDE[0] * 2 + GAP, SIDE[1] + BAR), (24, 26, 32))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.truetype(FONT, 20)
    for index, (path, label) in enumerate([(before, "전"), (after, "지금 (메뉴 B 모양)")]):
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
