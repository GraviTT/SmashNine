"""Xion stand-in art (2026-11-18): Nova's female body recoloured black, silver and crimson.

Xion has no art yet (the base sheet comes from the image/sprite owner, the skill rows from Codex).
Until then she borrows Nova's female drawings, which hold no weapon, recoloured so she does not
read as Nova: blue and purple become charcoal, cyan glow becomes crimson, white plates silver;
skin stays. The move sheet keeps only the rows Xion plays, under Xion's own row names.

Usage (from the repo root): python reports/xion-kit-2026-11-18/make_standin_art.py
"""
import pathlib

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
NOVA = ROOT / "smash-nine-prototype/assets/art/nova"
OUT = ROOT / "smash-nine-prototype/assets/art/xion"
CELL = 192
# Xion's row name <- Nova female move-sheet row index (Nova.MOVE_SHEET_ROWS order).
MOVE_ROWS = [
    ("shot", 10),  # gravity_beam: arm out
    ("shot_alt", 9),  # orb_throw: the other arm out
    ("shot_up", 12),  # zero_gravity: arms up
    ("shot_down", 2),  # compression_stomp: low
    ("shot_air_down", 4),  # meteor_kick: pointing down
    ("tumble", 8),  # tumble: the roll, and strong launches
    ("recoil_jump", 1),  # vector_upper: rising
    ("double_cast", 7),  # slingshot_start: casting forward
    ("dive", 5),  # vector_shift: flying level
    ("barrage", 6),  # gravity_brake: arms spread
    ("double_float", 11),  # field_fly: floating (the doppelganger)
]
STRIPS = ["jump", "fall", "land", "victory", "defeat", "portrait"]


def recolour(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    alpha = np.asarray(rgba)[..., 3]
    hsv = np.asarray(rgba.convert("RGB").convert("HSV")).astype(np.float32)
    h = hsv[..., 0] * 360.0 / 255.0
    s = hsv[..., 1] / 255.0
    v = hsv[..., 2] / 255.0
    skin = (h >= 5) & (h <= 45) & (s >= 0.12) & (s <= 0.7) & (v >= 0.42)
    glow = (h >= 160) & (h < 206) & (s >= 0.3) & (v >= 0.3) & ~skin
    cloth = (h >= 206) & (h <= 300) & (s >= 0.12) & ~skin
    plate = (s < 0.16) & (v >= 0.62) & ~skin
    nh, ns, nv = h.copy(), s.copy(), v.copy()
    nh[glow], ns[glow], nv[glow] = 352.0, np.maximum(s[glow], 0.78), v[glow] * 0.9
    nh[cloth], ns[cloth], nv[cloth] = 340.0, s[cloth] * 0.14, v[cloth] * 0.6
    nh[plate], ns[plate], nv[plate] = 225.0, 0.06, v[plate] * 0.93
    out = np.stack([nh * 255.0 / 360.0, ns * 255.0, nv * 255.0], axis=-1).clip(0, 255).astype(np.uint8)
    rgb = Image.fromarray(out, "HSV").convert("RGB")
    result = rgb.convert("RGBA")
    result.putalpha(Image.fromarray(alpha))
    return result


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    recolour(Image.open(NOVA / "nova_female_sheet.png")).save(OUT / "xion_sheet.png")
    moves = recolour(Image.open(NOVA / "nova_female_moves_sheet.png"))
    sheet = Image.new("RGBA", (moves.width, CELL * len(MOVE_ROWS)), (0, 0, 0, 0))
    for index, (_name, source_row) in enumerate(MOVE_ROWS):
        sheet.paste(moves.crop((0, source_row * CELL, moves.width, (source_row + 1) * CELL)), (0, index * CELL))
    sheet.save(OUT / "xion_moves_sheet.png")
    for strip in STRIPS:
        source = NOVA / f"nova_female_{strip}.png"
        if source.exists():
            recolour(Image.open(source)).save(OUT / f"xion_{strip}.png")
    print("saved", sorted(path.name for path in OUT.glob("*.png")))


main()
