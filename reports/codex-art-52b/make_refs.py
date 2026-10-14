from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / "references"
OUT.mkdir(parents=True, exist_ok=True)


def row_ref(source: Path, row: int, frames: int, name: str) -> None:
	image = Image.open(source).convert("RGBA")
	cell = 128
	strip = Image.new("RGBA", (cell * frames, cell), (0, 0, 0, 0))
	for index in range(frames):
		strip.alpha_composite(image.crop((index * cell, row * cell, (index + 1) * cell, (row + 1) * cell)), (index * cell, 0))
	strip.resize((strip.width * 4, strip.height * 4), Image.Resampling.NEAREST).save(OUT / f"{name}_4x.png")


base = ROOT / "smash-nine-prototype/assets/art/nova/nova_female_sheet.png"
moves = ROOT / "smash-nine-prototype/assets/art/nova/nova_female_moves_sheet.png"

for row, frames, name in [
	(1, 6, "walk"),
	(2, 1, "jump"),
	(3, 1, "fall"),
	(6, 1, "hurt"),
	(5, 6, "shield"),
	(4, 4, "attack"),
]:
	row_ref(base, row, frames, name)

for row, frames, name in [
	(0, 4, "vector_side"),
	(1, 4, "vector_upper"),
	(2, 4, "compression_stomp"),
	(3, 4, "air_side"),
	(4, 5, "meteor_kick"),
	(5, 4, "vector_shift"),
	(6, 5, "gravity_brake"),
	(7, 6, "slingshot_start"),
]:
	row_ref(moves, row, frames, name)

# Card row 2 is generated as one three-cell image, so make one matching motion-only reference.
parts = [Image.open(OUT / f"{name}_4x.png").convert("RGBA") for name in ("jump", "fall", "hurt")]
triptych = Image.new("RGBA", (512 * 3, 512), (0, 0, 0, 0))
for index, part in enumerate(parts):
	triptych.alpha_composite(part, (index * 512, 0))
triptych.save(OUT / "jump_fall_hurt_4x.png")

# Nova has no live tumble row yet; use the accepted Yuki row strictly as a rotation-beat reference.
tumble = Image.open(ROOT / "art/bakeoff/yuki/yuki-tumble-v2.png").convert("RGBA")
tumble.resize((tumble.width * 4, tumble.height * 4), Image.Resampling.NEAREST).save(OUT / "tumble_motion_4x.png")
