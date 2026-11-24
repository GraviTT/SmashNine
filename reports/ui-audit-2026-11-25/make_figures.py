"""Figures of the UI audit (2026-11-25): numbered boxes on the captures, zoomed crops, contact sheets.

Usage:  python reports/ui-audit-2026-11-25/make_figures.py <captures dir>
The captures dir holds ko_1280/, en_1280/ and ko_1470/ as written by
smash-nine-prototype/tests/analysis/ui_audit/capture_ui_audit.gd. Output: img/ next to this file.
Box coordinates are pixels of the 1280x720 (or 1470x720) capture.
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
OUT = HERE / "img"
FONT_PATH = HERE.parents[1] / "smash-nine-prototype" / "assets" / "fonts" / "NotoSansKR-UI.ttf"
MARK = (255, 64, 129)
DARK = (12, 12, 20)
QUALITY = 82


def font(size):
    return ImageFont.truetype(str(FONT_PATH), size)


def badge(draw, x, y, number):
    radius = 13
    draw.ellipse([x - radius - 2, y - radius - 2, x + radius + 2, y + radius + 2], fill=DARK)
    draw.ellipse([x - radius, y - radius, x + radius, y + radius], fill=MARK)
    text = str(number)
    box = draw.textbbox((0, 0), text, font=font(17))
    draw.text((x - (box[2] - box[0]) / 2 - box[0], y - (box[3] - box[1]) / 2 - box[1]), text, font=font(17), fill="white")


def annotate(source, boxes, name):
    """boxes: [(number, x, y, w, h)] or [(number, x, y, w, h, badge_side)], side in {"tl","tr","bl","br"}."""
    image = Image.open(source).convert("RGB")
    draw = ImageDraw.Draw(image)
    for entry in boxes:
        number, x, y, w, h = entry[:5]
        side = entry[5] if len(entry) > 5 else "tl"
        draw.rectangle([x - 1, y - 1, x + w + 1, y + h + 1], outline=DARK, width=5)
        draw.rectangle([x, y, x + w, y + h], outline=MARK, width=3)
        bx = x if side[1] == "l" else x + w
        by = y if side[0] == "t" else y + h
        bx = min(max(bx, 16), image.width - 16)
        by = min(max(by, 16), image.height - 16)
        badge(draw, bx, by, number)
    image.save(OUT / (name + ".jpg"), quality=QUALITY, optimize=True)
    return image


def zoom(source, rect, scale, name, resample=Image.NEAREST):
    x, y, w, h = rect
    crop = Image.open(source).convert("RGB").crop((x, y, x + w, y + h))
    crop = crop.resize((w * scale, h * scale), resample)
    crop.save(OUT / (name + ".png"), optimize=True)
    return crop


def side_by_side(images, name, gap=12, labels=None):
    height = max(image.height for image in images)
    label_height = 30 if labels else 0
    width = sum(image.width for image in images) + gap * (len(images) - 1)
    sheet = Image.new("RGB", (width, height + label_height), (20, 22, 30))
    draw = ImageDraw.Draw(sheet)
    x = 0
    for index, image in enumerate(images):
        sheet.paste(image, (x, label_height))
        if labels:
            draw.text((x + 6, 3), labels[index], font=font(18), fill=(236, 236, 240))
        x += image.width + gap
    if name.endswith(".png"):
        sheet.save(OUT / name, optimize=True)
    else:
        sheet.save(OUT / (name + ".jpg"), quality=QUALITY, optimize=True)
    return sheet


def crop(source, rect):
    x, y, w, h = rect
    return Image.open(source).convert("RGB").crop((x, y, x + w, y + h))


def contact_sheet(folder, name, columns=8, thumb=(240, 135)):
    files = sorted(folder.glob("*.png"))
    rows = (len(files) + columns - 1) // columns
    label = 22
    sheet = Image.new("RGB", (columns * (thumb[0] + 6) + 6, rows * (thumb[1] + label + 6) + 6), (20, 22, 30))
    draw = ImageDraw.Draw(sheet)
    for index, path in enumerate(files):
        image = Image.open(path).convert("RGB")
        image.thumbnail(thumb, Image.LANCZOS)
        x = 6 + (index % columns) * (thumb[0] + 6)
        y = 6 + (index // columns) * (thumb[1] + label + 6)
        sheet.paste(image, (x + (thumb[0] - image.width) // 2, y))
        draw.text((x + 2, y + thumb[1] + 1), path.stem[:30], font=font(13), fill=(222, 222, 230))
    sheet.save(OUT / (name + ".jpg"), quality=76, optimize=True)


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    captures = Path(sys.argv[1])
    ko, en, wide = captures / "ko_1280", captures / "en_1280", captures / "ko_1470"
    OUT.mkdir(parents=True, exist_ok=True)

    # --- Menus ---
    annotate(ko / "01_title.png", [
        (1, 320, 668, 640, 30), (2, 462, 290, 356, 118), (3, 424, 596, 432, 28), (4, 40, 24, 130, 28, "bl"),
    ], "01-title")
    annotate(ko / "04_select_xion.png", [
        (1, 46, 144, 314, 428), (2, 52, 582, 296, 44, "tr"), (3, 764, 328, 458, 236), (4, 392, 582, 330, 48),
        (5, 40, 24, 250, 82, "tr"), (6, 360, 668, 560, 30),
    ], "02-select")
    side_by_side([crop(ko / "04_select_xion.png", (742, 128, 502, 460)), crop(en / "04_select_xion.png", (742, 128, 502, 460))],
        "02-select-kit-ko-en", labels=["한국어", "English"])
    annotate(ko / "06_options.png", [
        (1, 306, 84, 300, 94), (2, 204, 196, 428, 58, "bl"), (3, 648, 196, 428, 256, "tr"), (4, 204, 566, 214, 56),
    ], "03-options")
    annotate(ko / "07_controls.png", [
        (1, 108, 374, 660, 118), (2, 108, 492, 300, 30, "bl"), (3, 108, 112, 660, 30, "tr"),
    ], "04-controls")

    # --- Match HUD ---
    annotate(ko / "13_match_fight.png", [
        (1, 804, 34, 372, 46), (2, 20, 48, 220, 124), (3, 488, 8, 304, 74), (4, 1054, 632, 216, 54),
        (5, 936, 688, 334, 24, "bl"), (6, 776, 394, 150, 50),
    ], "05-hud")
    side_by_side([zoom(ko / "13_match_fight.png", (804, 8, 468, 82), 2, "05-hud-zoom-status")], "05-hud-zoom-status.png")
    side_by_side([zoom(ko / "13_match_fight.png", (20, 48, 220, 124), 3, "tmp-a"), zoom(en / "13_match_fight.png", (20, 48, 220, 124), 3, "tmp-b")],
        "05-hud-zoom-minimap.png", labels=["한국어 (글자 8px)", "English (수가 잘림)"])
    side_by_side([zoom(ko / "18_match_low_hp_cooldown.png", (1050, 628, 226, 88), 3, "tmp-a")], "05-hud-zoom-skillbar.png")
    annotate(ko / "10_match_start_bot_panel.png", [(1, 972, 94, 304, 284)], "06-hud-bot-panel")
    annotate(ko / "15_match_card_offer.png", [
        (1, 500, 518, 280, 28), (2, 288, 548, 704, 100, "bl"), (3, 16, 660, 250, 28),
    ], "07-hud-card-offer")
    zoom(ko / "53_story_card_offer.png", (288, 516, 704, 134), 2, "07-hud-card-zoom")
    annotate(ko / "21_match_collapse_warning.png", [
        (1, 380, 94, 520, 80), (2, 20, 48, 220, 124), (3, 16, 660, 230, 28),
    ], "08-hud-warning")
    annotate(ko / "17_match_ult_cutin.png", [(1, 0, 172, 562, 112, "tr")], "09-hud-cutin")
    annotate(ko / "34_brawl.png", [
        (1, 0, 628, 132, 92, "tr"), (2, 596, 396, 300, 324, "tl"), (3, 466, 38, 250, 26, "bl"), (4, 716, 510, 60, 26, "tr"),
    ], "10-hud-brawl")
    annotate(ko / "26_match_spectating.png", [
        (1, 836, 8, 440, 82, "bl"), (2, 1054, 632, 216, 54), (3, 16, 660, 240, 28),
    ], "11-hud-spectate")
    annotate(wide / "13_match_fight.png", [(1, 1054, 632, 216, 54), (2, 1126, 688, 334, 24, "bl")], "12-hud-wide")
    annotate(ko / "27_results_lost.png", [
        (1, 38, 98, 310, 478), (2, 782, 190, 226, 334, "tr"), (3, 356, 530, 282, 96, "bl"), (4, 356, 654, 872, 58, "tr"),
        (5, 356, 488, 760, 34, "tl"), (6, 440, 320, 60, 120, "tr"),
    ], "13-results")

    # --- Story ---
    annotate(ko / "40_story_select.png", [
        (1, 52, 236, 296, 48), (2, 392, 520, 330, 52), (3, 204, 434, 146, 136, "tr"), (4, 52, 582, 296, 44, "bl"),
    ], "14-story-select")
    annotate(ko / "41_story_map.png", [
        (1, 44, 130, 628, 492), (2, 752, 416, 290, 120), (3, 48, 254, 194, 26, "bl"),
    ], "15-story-map")
    annotate(ko / "49_story_card_rival.png", [
        (1, 488, 548, 304, 52, "tr"), (2, 222, 432, 814, 100), (3, 222, 358, 420, 68),
    ], "16-story-card")
    annotate(ko / "50_story_dialogue_rival.png", [
        (1, 934, 646, 294, 54), (2, 216, 660, 204, 26), (3, 52, 494, 146, 168),
    ], "17-story-dialogue")
    annotate(ko / "52_story_hud_rival.png", [
        (1, 20, 48, 220, 124), (2, 428, 98, 424, 50), (3, 1096, 8, 82, 28, "bl"), (4, 512, 8, 256, 30, "bl"),
    ], "18-story-hud")
    annotate(ko / "57_story_hud_escape.png", [(1, 390, 156, 500, 84)], "19-story-escape")
    side_by_side([crop(ko / "47_story_pause.png", (320, 120, 640, 500)), crop(ko / "55_story_result_clear.png", (120, 70, 1040, 570)).resize((912, 500), Image.LANCZOS)],
        "20-story-pause-result")

    # --- Skill bars of all six fighters, 3x ---
    bars = [zoom(ko / ("60_skill_bar_%s.png" % fighter), (1000, 628, 276, 60), 2, "tmp-a") for fighter in ["frey", "yuki", "luna", "nova", "rio", "xion"]]
    column = Image.new("RGB", (bars[0].width, sum(bar.height + 6 for bar in bars)), (20, 22, 30))
    y = 0
    for bar in bars:
        column.paste(bar, (0, y))
        y += bar.height + 6
    column.save(OUT / "05-hud-skillbars.png", optimize=True)
    for leftover in ["tmp-a.png", "tmp-b.png"]:
        (OUT / leftover).unlink(missing_ok=True)

    contact_sheet(ko, "sheet-ko")
    contact_sheet(en, "sheet-en")
    total = sum(path.stat().st_size for path in OUT.iterdir())
    print("figures: %d files, %.1f MB in %s" % (len(list(OUT.iterdir())), total / 1e6, OUT))


if __name__ == "__main__":
    main()
