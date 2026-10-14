"""Make head-only diagnostic copies for head_scale.py when exposed legs win skin detection."""

import argparse
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("--stage", choices=("initial", "final"), default="final")
	args = parser.parse_args()
	out = ROOT / f"art/raw/walk-55/luna-head-masks-{args.stage}"
	out.mkdir(parents=True, exist_ok=True)
	for index in range(1, 9):
		source = ROOT / f"art/raw/walk-55/luna-single-{args.stage}-{index:02d}/luna-frame-{index:02d}-{args.stage}.png"
		image = Image.open(source).convert("RGBA").crop((0, 0, 128, 128))
		pixels = image.load()
		for y in range(88, 128):
			for x in range(128):
				pixels[x, y] = (0, 0, 0, 0)
		image.save(out / f"frame-{index:02d}.png")


if __name__ == "__main__":
	main()
