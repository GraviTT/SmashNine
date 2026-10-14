"""Build the failure-review boards for one ART-59 Nova walk attempt."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


CELL = 128
SCALE = 4


def font(size: int, bold: bool = False) -> ImageFont.ImageFont:
	paths = ("C:/Windows/Fonts/arialbd.ttf", "C:/Windows/Fonts/arial.ttf") if bold else ("C:/Windows/Fonts/arial.ttf",)
	for path in paths:
		try:
			return ImageFont.truetype(path, size)
		except OSError:
			pass
	return ImageFont.load_default()


def checker(size: tuple[int, int], square: int = 16) -> Image.Image:
	image = Image.new("RGBA", size, (29, 36, 51, 255))
	draw = ImageDraw.Draw(image)
	for y in range(0, size[1], square):
		for x in range(0, size[0], square):
			if (x // square + y // square) % 2:
				draw.rectangle((x, y, x + square - 1, y + square - 1), fill=(41, 49, 68, 255))
	return image


def cells(path: Path, count: int) -> list[Image.Image]:
	image = Image.open(path).convert("RGBA")
	return [image.crop((index * CELL, 0, (index + 1) * CELL, CELL)) for index in range(count)]


def build_costume(report: Path, idle_path: Path, walk_path: Path, strip_path: Path) -> None:
	items = [("IDLE", cells(idle_path, 1)[0]), ("GAME WALK", cells(walk_path, 1)[0])]
	items.extend((f"F{index + 1}", frame) for index, frame in enumerate(cells(strip_path, 8)))
	label_h = 38
	canvas = checker((len(items) * CELL * SCALE, CELL * SCALE + label_h), 16)
	draw = ImageDraw.Draw(canvas)
	for index, (label, frame) in enumerate(items):
		x = index * CELL * SCALE
		canvas.alpha_composite(frame.resize((CELL * SCALE, CELL * SCALE), Image.Resampling.NEAREST), (x, label_h))
		draw.rectangle((x, 0, x + CELL * SCALE - 1, label_h - 1), fill=(12, 17, 29, 255))
		draw.text((x + 10, 7), label, font=font(20, True), fill=(239, 244, 255, 255))
		if index:
			draw.line((x, 0, x, canvas.height), fill=(86, 98, 122, 255), width=2)
	canvas.convert("RGB").save(report / "costume.png", optimize=True)


def build_gif(report: Path, strip_path: Path) -> None:
	gif_frames: list[Image.Image] = []
	for frame in cells(strip_path, 8):
		background = checker((CELL, CELL), 8)
		background.alpha_composite(frame)
		gif_frames.append(background.resize((CELL * SCALE, CELL * SCALE), Image.Resampling.NEAREST).convert("P", palette=Image.Palette.ADAPTIVE, colors=255))
	gif_frames[0].save(report / "walk.gif", save_all=True, append_images=gif_frames[1:], duration=[80, 70] * 4, loop=0, disposal=2)


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("--report", type=Path, required=True)
	parser.add_argument("--idle", type=Path, required=True)
	parser.add_argument("--walk", type=Path, required=True)
	parser.add_argument("--strip", type=Path, required=True)
	parser.add_argument("--onion", type=Path, required=True)
	parser.add_argument("--feet", type=Path, required=True)
	parser.add_argument("--bob-board", type=Path, required=True)
	parser.add_argument("--bob-json", type=Path, required=True)
	args = parser.parse_args()
	args.report.mkdir(parents=True, exist_ok=True)
	build_costume(args.report, args.idle, args.walk, args.strip)
	build_gif(args.report, args.strip)
	shutil.copyfile(args.onion, args.report / "onion.png")
	shutil.copyfile(args.feet, args.report / "feet.json")
	shutil.copyfile(args.bob_board, args.report / "bob.png")
	shutil.copyfile(args.bob_json, args.report / "bob.json")
	json.loads((args.report / "feet.json").read_text(encoding="utf-8"))
	json.loads((args.report / "bob.json").read_text(encoding="utf-8"))


if __name__ == "__main__":
	main()
