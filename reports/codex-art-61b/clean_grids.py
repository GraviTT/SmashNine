from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
ROWS = [
	"shield", "mana_combo", "rising_slash", "low_sweep", "air_slash",
	"plunge", "dimension_slash", "rune_shield", "infinity_overdrive", "tumble",
]
GREEN = (0, 255, 0, 255)


def clean(path: Path, columns: int, rows: int) -> None:
	image = Image.open(path).convert("RGBA")
	pixels = image.load()
	cell_w = image.width // columns
	cell_h = image.height // rows
	# ImageGen inserted 3–4 px white grid rules. Clear only the grid bands;
	# the figures have visibly generous green clearance from those bands.
	for boundary in range(columns + 1):
		x = min(image.width - 1, boundary * cell_w)
		for xx in range(max(0, x - 7), min(image.width, x + 8)):
			for y in range(image.height):
				pixels[xx, y] = GREEN
	for boundary in range(rows + 1):
		y = min(image.height - 1, boundary * cell_h)
		for yy in range(max(0, y - 7), min(image.height, y + 8)):
			for x in range(image.width):
				pixels[x, yy] = GREEN
	image.save(path)


for row in ROWS:
	clean(ROOT / f"art/raw/rio-61b/{row}/prepared.png", 3, 2)
for row in ("shield", "plunge"):
	attempt = ROOT / f"art/raw/rio-61b/{row}/prepared-attempt2.png"
	if attempt.exists():
		clean(attempt, 3, 2)
clean(ROOT / "art/raw/rio-61b/jump_fall_hurt/prepared.png", 3, 1)
