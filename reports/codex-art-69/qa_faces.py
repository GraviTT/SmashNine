from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
FORMS = {
	"frey": ("art/bakeoff/frey/frey-idle-v2.png", "art/bakeoff/frey/frey-defeat-v1.png"),
	"luna": ("art/bakeoff/luna/luna-idle-v3.png", "art/bakeoff/luna/luna-defeat-v1.png"),
	"luna_brave": ("art/bakeoff/luna/luna_brave-idle-v4.png", "art/bakeoff/luna/luna_brave-defeat-v1.png"),
	"yuki": ("art/bakeoff/yuki/yuki-idle-v2.png", "art/bakeoff/yuki/yuki-defeat-v1.png"),
	"nova_male": ("art/bakeoff/nova/nova_male-idle-v2.png", "art/bakeoff/nova/nova_male-defeat-v1.png"),
	"nova_female": ("art/bakeoff/nova/nova_female-idle-v2.png", "art/bakeoff/nova/nova_female-defeat-v1.png"),
	"rio_male": ("art/bakeoff/rio/rio_male-idle-v2.png", "art/bakeoff/rio/rio_male-defeat-v1.png"),
	"rio_female": ("art/bakeoff/rio/rio_female-idle-v2.png", "art/bakeoff/rio/rio_female-defeat-v1.png"),
}


def frame(path: Path, index: int, cell: int) -> Image.Image:
	image = Image.open(path).convert("RGBA")
	return image.crop((index * cell, 0, (index + 1) * cell, cell))


def subject_bbox(image: Image.Image) -> tuple[int, int, int, int]:
	box = image.getchannel("A").getbbox()
	if box is None:
		raise ValueError("empty frame")
	return box


def face_crop(image: Image.Image, crop_size: int = 64) -> tuple[Image.Image, tuple[int, int, int, int]]:
	x0, y0, x1, y1 = subject_bbox(image)
	w = x1 - x0
	h = y1 - y0
	# All eight forms face right. The face sits in the upper-right part of the
	# opaque figure for the upright anchor and defeat frames 1-3.
	cx = round(x0 + w * 0.68)
	cy = round(y0 + h * 0.22)
	left = max(0, min(image.width - crop_size, cx - crop_size // 2))
	top = max(0, min(image.height - crop_size, cy - crop_size // 2))
	box = (left, top, left + crop_size, top + crop_size)
	return image.crop(box), box


def checker(size: tuple[int, int]) -> Image.Image:
	result = Image.new("RGBA", size, (31, 39, 55, 255))
	draw = ImageDraw.Draw(result)
	for y in range(0, size[1], 8):
		for x in range(0, size[0], 8):
			if (x // 8 + y // 8) % 2:
				draw.rectangle((x, y, x + 7, y + 7), fill=(40, 50, 69, 255))
	return result


def scaled_grid(crop: Image.Image, scale: int = 8) -> Image.Image:
	base = checker(crop.size)
	base.alpha_composite(crop)
	pixels = base.resize((crop.width * scale, crop.height * scale), Image.Resampling.NEAREST)
	margin = 32
	large = Image.new("RGBA", (pixels.width + margin, pixels.height + margin), (15, 19, 28, 255))
	large.alpha_composite(pixels, (margin, margin))
	draw = ImageDraw.Draw(large)
	for p in range(0, crop.width + 1):
		colour = (120, 140, 170, 110) if p % 4 else (210, 220, 235, 165)
		x = margin + p * scale
		draw.line((x, margin, x, large.height), fill=colour, width=1)
	for p in range(0, crop.height + 1):
		colour = (120, 140, 170, 110) if p % 4 else (210, 220, 235, 165)
		y = margin + p * scale
		draw.line((margin, y, large.width, y), fill=colour, width=1)
	for p in range(0, crop.width, 4):
		draw.text((margin + p * scale + 1, 16), str(p), fill=(235, 240, 248, 255))
	for p in range(0, crop.height, 4):
		draw.text((1, margin + p * scale), str(p), fill=(235, 240, 248, 255))
	return large


def main() -> None:
	out_root = Path(__file__).resolve().parent
	metadata: dict[str, list[dict[str, object]]] = {}
	for stem, (anchor_rel, candidate_rel) in FORMS.items():
		anchor_path = ROOT / anchor_rel
		candidate_path = ROOT / candidate_rel
		if not candidate_path.exists():
			continue
		inputs = [("ANCHOR", frame(anchor_path, 0, 128))]
		inputs += [(f"F{i + 1}", frame(candidate_path, i, 192)) for i in range(3)]
		panels: list[Image.Image] = []
		rows: list[dict[str, object]] = []
		for label, source in inputs:
			crop, box = face_crop(source)
			panel = scaled_grid(crop)
			header = Image.new("RGBA", (panel.width, 28), (15, 19, 28, 255))
			ImageDraw.Draw(header).text((8, 7), f"{label} crop={box}", fill=(255, 255, 255, 255))
			joined = Image.new("RGBA", (panel.width, panel.height + header.height))
			joined.alpha_composite(header)
			joined.alpha_composite(panel, (0, header.height))
			panels.append(joined)
			rows.append({"label": label, "crop": box})
		board = Image.new("RGBA", (sum(p.width for p in panels), max(p.height for p in panels)), (15, 19, 28, 255))
		x = 0
		for panel in panels:
			board.alpha_composite(panel, (x, 0))
			x += panel.width
		board.save(out_root / f"{stem}-faces-grid.png")
		metadata[stem] = rows
	(out_root / "face-crops.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
	main()
