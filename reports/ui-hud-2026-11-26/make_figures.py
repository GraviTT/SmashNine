"""Figures of the HUD as picked (2026-11-26): the audit's capture of a scene above the same scene now.

Usage:  python reports/ui-hud-2026-11-26/make_figures.py <captures dir>
The captures dir holds ko_1280/, en_1280/, ko_1470/ (capture_ui_audit.gd) and practice_ko/,
practice_en/ (capture_practice.gd), all taken from the exported web pack. The "before" pictures
are the audit's own figures (reports/ui-audit-2026-11-25/img), pink boxes and all.
Output: img/ next to this file.
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
OUT = HERE / "img"
AUDIT = HERE.parent / "ui-audit-2026-11-25" / "img"
FONT_PATH = HERE.parents[1] / "smash-nine-prototype" / "assets" / "fonts" / "NotoSansKR-UI.ttf"
BAR = 34
QUALITY = 82
BEFORE = "점검 때 (2026-11-25, 분홍 상자는 점검에서 찾은 문제)"
AFTER = "지금 (2026-11-26, 웹 빌드의 팩에서 찍음)"


def font(size):
    return ImageFont.truetype(str(FONT_PATH), size)


def label_bar(width, text, color):
    bar = Image.new("RGB", (width, BAR), color)
    draw = ImageDraw.Draw(bar)
    draw.text((12, 5), text, font=font(18), fill="white")
    return bar


def stack(parts, name):
    """parts: [(image, label, colour)] top to bottom, each under its label bar."""
    width = max(image.width for image, _, _ in parts)
    height = sum(image.height + BAR for image, _, _ in parts)
    sheet = Image.new("RGB", (width, height), (12, 12, 20))
    y = 0
    for image, text, color in parts:
        sheet.paste(label_bar(width, text, color), (0, y))
        sheet.paste(image, (0, y + BAR))
        y += image.height + BAR
    sheet.save(OUT / (name + ".jpg"), quality=QUALITY, optimize=True)


def before_after(before, after, name):
    stack([
        (Image.open(AUDIT / before).convert("RGB"), BEFORE, (90, 40, 60)),
        (Image.open(after).convert("RGB"), AFTER, (30, 70, 50)),
    ], name)


def zoom(source, rect, scale):
    x, y, w, h = rect
    crop = Image.open(source).convert("RGB").crop((x, y, x + w, y + h))
    return crop.resize((w * scale, h * scale), Image.NEAREST)


def main(captures):
    ko = captures / "ko_1280"
    en = captures / "en_1280"
    wide = captures / "ko_1470"
    OUT.mkdir(exist_ok=True)
    before_after("05-hud.jpg", ko / "13_match_fight.png", "01-fight")
    before_after("07-hud-card-offer.jpg", ko / "15_match_card_offer.png", "02-cards")
    before_after("08-hud-warning.jpg", ko / "21_match_collapse_warning.png", "03-warning")
    before_after("11-hud-spectate.jpg", ko / "26_match_spectating.png", "04-spectate")
    before_after("12-hud-wide.jpg", wide / "13_match_fight.png", "05-wide")
    before_after("18-story-hud.jpg", ko / "52_story_hud_rival.png", "06-story")
    stack([
        (Image.open(en / "15_match_card_offer.png").convert("RGB"), "English: soul cards (the control hints give way to them)", (30, 50, 80)),
        (Image.open(en / "28_match_xion_skill_bar.png").convert("RGB"), "English: Xion's five slots, the control hints in two lines", (30, 50, 80)),
    ], "07-english")
    practice = captures / "practice_ko"
    stack([
        (Image.open(practice / "04_after_a_hit_ko.png").convert("RGB"), "연습: 서 있는 허수아비를 한 번 벤 뒤 (안내 판은 오른쪽 아래, 소울 줄에 가진 카드)", (60, 40, 90)),
        (Image.open(practice / "09_cards_page_3_ko.png").convert("RGB"), "연습: 카드 목록 3쪽 (경기의 카드 열을 시간 막대 없이, 두 줄 설명도 끝까지)", (60, 40, 90)),
    ], "08-practice")


if __name__ == "__main__":
    main(Path(sys.argv[1]))
