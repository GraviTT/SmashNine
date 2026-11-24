"""Figures of the match HUD direction report (2026-11-25).

Usage:  python reports/ui-direction-2026-11-25/make_figures.py <reel dir> <stills dir>
        python reports/ui-direction-2026-11-25/make_figures.py --menu <menu tour dir>
<reel dir> holds now/, a/ and b/ with hud/, cards/ and warning/ frames (####.jpg) as written by
smash-nine-prototype/tests/analysis/ui_audit/ui_direction_capture.gd; <stills dir> holds a/ and b/
from the same script with --stills (for still_mock_cards.jpg). <menu tour dir> holds now/, a/ and
b/ with title/ and select/ frames from menu_direction_capture.gd. Output: img/ next to this file.
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
OUT = HERE / "img"
FONT_PATH = HERE.parents[1] / "smash-nine-prototype" / "assets" / "fonts" / "NotoSansKR-UI.ttf"
NAMES = {"now": "지금", "a": "A  나누어 두기", "b": "B  한곳에 모으기"}
BACK = (20, 22, 30)
# Reel frame (60 a second) -> the part's folder and file: parts start at 0, 480 and 840.
PARTS = [("hud", 0), ("cards", 480), ("warning", 840)]


def font(size):
    return ImageFont.truetype(str(FONT_PATH), size)


def frame(reel, variant, at):
    part, start = [p for p in PARTS if p[1] <= at][-1]
    return Image.open(reel / variant / part / ("%04d.jpg" % ((at - start) // 2 + 1))).convert("RGB")


def stack(images, labels, name, quality=80):
    """Full-size frames one above the other, each under its label."""
    head = 34
    width = max(image.width for image in images)
    sheet = Image.new("RGB", (width, sum(image.height + head for image in images)), BACK)
    draw = ImageDraw.Draw(sheet)
    y = 0
    for image, label in zip(images, labels):
        draw.text((10, y + 4), label, font=font(20), fill=(236, 236, 240))
        sheet.paste(image, (0, y + head))
        y += image.height + head
    sheet.save(OUT / (name + ".jpg"), quality=quality, optimize=True)


def row(images, labels, name, gap=10):
    """Crops side by side under their labels (PNG: zoomed pixels stay exact)."""
    head = 30
    height = max(image.height for image in images)
    sheet = Image.new("RGB", (sum(image.width for image in images) + gap * (len(images) - 1), height + head), BACK)
    draw = ImageDraw.Draw(sheet)
    x = 0
    for image, label in zip(images, labels):
        draw.text((x + 6, 3), label, font=font(18), fill=(236, 236, 240))
        sheet.paste(image, (x, head))
        x += image.width + gap
    sheet.save(OUT / (name + ".png"), optimize=True)


def crop(image, rect, scale=1):
    x, y, w, h = rect
    part = image.crop((x, y, x + w, y + h))
    return part.resize((w * scale, h * scale), Image.NEAREST) if scale != 1 else part


def menu_figures(tour):
    """The menu tours: the title with the focus on Story, the select screen on Nova and on Xion."""
    variants = ["now", "a", "b"]
    labels = [NAMES[v] for v in variants]
    # Title steps are 36 frames, select steps 48; a JPG every second frame.
    for name, part, number in [("10-menu-title", "title", 28), ("11-menu-select-nova", "select", 84), ("12-menu-select-xion", "select", 156)]:
        stack([Image.open(tour / v / part / ("%04d.jpg" % number)).convert("RGB") for v in variants], labels, name)


def main():
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    OUT.mkdir(parents=True, exist_ok=True)
    if sys.argv[1] == "--menu":
        menu_figures(Path(sys.argv[2]))
        print("menu figures in %s" % OUT)
        return
    reel, stills = Path(sys.argv[1]), Path(sys.argv[2])
    variants = ["now", "a", "b"]
    labels = [NAMES[v] for v in variants]
    # Four moments of the same match, the three HUDs one above the other.
    for name, at in [("01-fight", 110), ("02-cards", 716), ("03-warning-ultimate", 1040), ("04-low-hp", 1260)]:
        stack([frame(reel, v, at) for v in variants], labels, name)
    # The cards of the D54 pool (three kinds, the longest text), mocked on both prototypes.
    stack([Image.open(stills / v / "still_mock_cards.jpg").convert("RGB") for v in ["a", "b"]], [NAMES["a"], NAMES["b"]], "05-cards-d54")
    # Details at 2x: the player's own numbers, the map, the skill slots.
    calm = {v: frame(reel, v, 300) for v in variants}
    row([crop(calm["now"], (800, 4, 480, 96), 2), crop(calm["a"], (880, 4, 400, 108), 2), crop(calm["b"], (10, 592, 450, 124), 2)], labels, "06-detail-status")
    row([crop(calm["now"], (20, 48, 226, 124), 2), crop(calm["a"], (8, 6, 204, 152), 2), crop(calm["b"], (1070, 6, 204, 186), 2)], labels, "07-detail-minimap")
    low = {v: frame(reel, v, 1100) for v in variants}
    row([crop(low["now"], (1050, 628, 226, 88), 2), crop(low["a"], (1000, 616, 276, 100), 2), crop(low["b"], (456, 612, 276, 104), 2)], labels, "08-detail-skills")
    warn = {v: frame(reel, v, 960) for v in variants}
    row([crop(warn["now"], (340, 4, 600, 176)), crop(warn["a"], (340, 4, 600, 176)), crop(warn["b"], (340, 4, 600, 176))], labels, "09-detail-warning")
    files = sorted(OUT.iterdir())
    print("figures: %d files, %.1f MB in %s" % (len(files), sum(f.stat().st_size for f in files) / 1e6, OUT))


if __name__ == "__main__":
    main()
