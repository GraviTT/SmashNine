"""Before / after crops for the bug fixes B1-B8 of the UI audit (2026-11-25).

Usage:  python reports/ui-audit-2026-11-25/make_fix_figures.py <captures before> <captures after>
Both dirs hold ko_1280/, en_1280/ and ko_1470/ from capture_ui_audit.gd. Output: img/fix-*.png.
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
OUT = HERE / "img"
FONT_PATH = HERE.parents[1] / "smash-nine-prototype" / "assets" / "fonts" / "NotoSansKR-UI.ttf"


def font(size):
    return ImageFont.truetype(str(FONT_PATH), size)


def crop(path, rect, scale=1, resample=Image.NEAREST):
    x, y, w, h = rect
    image = Image.open(path).convert("RGB").crop((x, y, x + w, y + h))
    return image.resize((w * scale, h * scale), resample) if scale != 1 else image


def pair(name, before, after, labels=("고치기 전", "고친 뒤"), vertical=False):
    gap, head = 10, 28
    if vertical:
        width = max(before.width, after.width)
        sheet = Image.new("RGB", (width, before.height + after.height + head * 2 + gap), (20, 22, 30))
        spots = [(0, head), (0, before.height + head * 2 + gap)]
    else:
        height = max(before.height, after.height)
        sheet = Image.new("RGB", (before.width + after.width + gap, height + head), (20, 22, 30))
        spots = [(0, head), (before.width + gap, head)]
    draw = ImageDraw.Draw(sheet)
    for image, spot, label in zip((before, after), spots, labels):
        sheet.paste(image, spot)
        draw.text((spot[0] + 6, spot[1] - head + 2), label, font=font(18), fill=(236, 236, 240))
    sheet.save(OUT / (name + ".png"), optimize=True)


def main():
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    before, after = Path(sys.argv[1]), Path(sys.argv[2])
    OUT.mkdir(parents=True, exist_ok=True)
    # B1: the skill bar on a 1470 px window.
    pair("fix-b1-skill-bar-wide", crop(before / "ko_1470/13_match_fight.png", (930, 620, 540, 100)),
         crop(after / "ko_1470/13_match_fight.png", (930, 620, 540, 100)), vertical=True)
    # B2: the English minimap, 3x.
    pair("fix-b2-minimap-en", crop(before / "en_1280/21_match_collapse_warning.png", (20, 48, 226, 124), 3),
         crop(after / "en_1280/21_match_collapse_warning.png", (20, 48, 226, 124), 3))
    # B3: the quick-start row of the controls screen.
    pair("fix-b3-controls", crop(before / "ko_1280/07_controls.png", (100, 484, 660, 40)),
         crop(after / "ko_1280/07_controls.png", (100, 484, 660, 40)), vertical=True)
    # B4: the table and the award.
    pair("fix-b4-award", crop(before / "ko_1280/27_results_lost.png", (350, 150, 420, 480)),
         crop(after / "ko_1280/27_results_lost.png", (350, 150, 420, 480)))
    # B5: the options notice.
    pair("fix-b5-options", crop(before / "ko_1280/06_options.png", (300, 80, 640, 104)),
         crop(after / "ko_1280/06_options.png", (300, 80, 640, 104)), vertical=True)
    # B6: the kit rows, English and Korean.
    pair("fix-b6-kit-en", crop(before / "en_1280/04_select_xion.png", (742, 128, 502, 510)),
         crop(after / "en_1280/04_select_xion.png", (742, 128, 502, 510)))
    pair("fix-b6-kit-ko", crop(before / "ko_1280/04_select_xion.png", (742, 128, 502, 510)),
         crop(after / "ko_1280/04_select_xion.png", (742, 128, 502, 510)))
    # B7: the status text and the HP bar, 2x.
    pair("fix-b7-status", crop(before / "ko_1280/13_match_fight.png", (800, 4, 480, 96), 2),
         crop(after / "ko_1280/13_match_fight.png", (800, 4, 480, 96), 2), vertical=True)
    # B8: the left edge of Asgard and the right edge of Niflheim.
    pair("fix-b8-asgard", crop(before / "ko_1280/20_match_hazard_warning.png", (0, 180, 420, 540)),
         crop(after / "ko_1280/20_match_hazard_warning.png", (0, 180, 420, 540)))
    pair("fix-b8-niflheim", crop(before / "ko_1280/12_match_hud_plain.png", (860, 200, 420, 520)),
         crop(after / "ko_1280/12_match_hud_plain.png", (860, 200, 420, 520)))
    files = sorted(OUT.glob("fix-*.png"))
    print("fix figures: %d files, %.1f MB" % (len(files), sum(f.stat().st_size for f in files) / 1e6))


if __name__ == "__main__":
    main()
