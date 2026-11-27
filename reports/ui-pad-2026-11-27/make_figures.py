"""Figures for reports/ui-pad-2026-11-27 (the gamepad's names as badges, the controls screen's pad tab,
the practice menu). Captures come from smash-nine-prototype/tests/analysis/ui_audit/pad_badges_capture.gd,
run windowed on the pre-change web pack (--main-pack, main 23b8ff7c) for "before" and on the
project for "after"; each run saves <NN-name>-<lang>.jpg at 1280x720.
Run from the repo root:
  python reports/ui-pad-2026-11-27/make_figures.py <before dir> <after dir>
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
FONT = "C:/Windows/Fonts/malgunbd.ttf"
GAP = 16
BAR = 46
BACK = (24, 26, 32)
WORDS = (240, 236, 224)
# The skill bar's slots and their key badges in a 1280x720 capture.
SKILL_BAR = (455, 612, 800, 708)


def sheet(panels: list, out: Path) -> None:
    """Panels side by side: each (image, caption)."""
    font = ImageFont.truetype(FONT, 20)
    width = sum(image.width for image, _ in panels) + GAP * (len(panels) - 1)
    height = max(image.height for image, _ in panels) + BAR
    canvas = Image.new("RGB", (width, height), BACK)
    draw = ImageDraw.Draw(canvas)
    x = 0
    for image, caption in panels:
        canvas.paste(image, (x, BAR))
        draw.text((x + 12, 11), caption, font=font, fill=WORDS)
        x += image.width + GAP
    canvas.save(out, quality=88)
    print(out.name, canvas.size)


def frame(path: Path, size=(960, 540)) -> Image.Image:
    return Image.open(path).convert("RGB").resize(size, Image.LANCZOS)


def crop(path: Path, box, scale: int) -> Image.Image:
    part = Image.open(path).convert("RGB").crop(box)
    return part.resize((part.width * scale, part.height * scale), Image.NEAREST)


def main() -> None:
    before, after = Path(sys.argv[1]), Path(sys.argv[2])
    img = HERE / "img"
    img.mkdir(exist_ok=True)
    sheet([(crop(before / "03-hud-pad-en.jpg", SKILL_BAR, 2), "전: 패드를 쓰는 중 (밝은 키 판에 글자만)"),
           (crop(after / "03-hud-pad-en.jpg", SKILL_BAR, 2), "지금: 패드를 쓰는 중 (버튼 모양)"),
           (crop(after / "04-hud-keys-en.jpg", SKILL_BAR, 2), "지금: 키보드로 돌아옴")], img / "01-hud-badges.jpg")
    sheet([(frame(after / "01-controls-ko.jpg"), "조작법 · 키보드 탭"),
           (frame(after / "02-controls-pad-ko.jpg"), "조작법 · 게임패드 탭 (새로)")], img / "02-controls-tabs.jpg")
    sheet([(frame(after / "02-controls-pad-en.jpg"), "게임패드 탭 (영어)")], img / "03-controls-pad-en.jpg")
    sheet([(frame(before / "05-practice-menu-en.jpg"), "연습 메뉴 · 전"),
           (frame(after / "05-practice-menu-en.jpg"), "연습 메뉴 · 지금")], img / "04-practice-menu.jpg")
    sheet([(frame(after / "05-practice-menu-ko.jpg"), "연습 메뉴 · 키보드 (한국어)"),
           (frame(after / "06-practice-menu-pad-ko.jpg"), "연습 메뉴 · 패드를 쓰는 중 (키 표시 없음)")], img / "05-practice-menu-ko.jpg")
    sheet([(frame(before / "07-practice-skills-ko.jpg"), "기술 목록 · 전"),
           (frame(after / "07-practice-skills-ko.jpg"), "기술 목록 · 지금 (키보드)"),
           ], img / "06-practice-skills.jpg")
    sheet([(frame(after / "08-practice-skills-pad-ko.jpg"), "기술 목록 · 패드를 쓰는 중 (버튼 배지)")], img / "07-practice-skills-pad.jpg")


if __name__ == "__main__":
    main()
