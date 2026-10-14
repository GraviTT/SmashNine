from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "art" / "raw" / "mainart-47"
REPORT = ROOT / "reports" / "codex-art-47"

ITEMS = [
	("frey", 1, "Frey 1"),
	("frey", 2, "Frey 2"),
	("luna", 1, "Luna 1"),
	("luna", 2, "Luna 2"),
	("luna_brave", 1, "Brave Luna 1"),
	("luna_brave", 2, "Brave Luna 2"),
]

# Square source crops. The final crop is reduced to 256x256 with LANCZOS.
# These are intentionally per-pose: eyes land close to 40% of the crop height.
FACE_BOXES = {
	("frey", 1): (350, 75, 862, 587),
	("frey", 2): (540, 180, 924, 564),
	("luna", 1): (350, 65, 862, 577),
	("luna", 2): (385, 75, 897, 587),
	("luna_brave", 1): (355, 55, 867, 567),
	("luna_brave", 2): (405, 60, 917, 572),
}


def _border_key(rgb: np.ndarray, width: int = 12) -> np.ndarray:
	border = np.concatenate(
		[
			rgb[:width].reshape(-1, 3),
			rgb[-width:].reshape(-1, 3),
			rgb[:, :width].reshape(-1, 3),
			rgb[:, -width:].reshape(-1, 3),
		],
		axis=0,
	)
	return np.median(border, axis=0)


def chroma_extract(source: Path) -> tuple[Image.Image, list[int]]:
	rgb = np.asarray(Image.open(source).convert("RGB"), dtype=np.float32)
	key = _border_key(rgb)
	excess = rgb[:, :, 1] - np.maximum(rgb[:, :, 0], rgb[:, :, 2])
	# The generator's green is lightly textured (roughly 215-250 points of
	# green dominance). 180 keeps that whole field transparent while retaining
	# a soft transition through dark line-art and fine hair edges.
	alpha = np.clip(1.0 - excess / 180.0, 0.0, 1.0)
	alpha[alpha < 0.035] = 0.0
	alpha[alpha > 0.985] = 1.0

	denom = np.maximum(alpha[:, :, None], 1.0 / 255.0)
	foreground = (rgb - (1.0 - alpha[:, :, None]) * key[None, None, :]) / denom
	foreground = np.clip(foreground, 0.0, 255.0)

	# Remove the last green-screen reflection only on partially transparent edges.
	edge = alpha < 0.96
	limit = np.maximum(foreground[:, :, 0], foreground[:, :, 2]) + 8.0
	foreground[:, :, 1] = np.where(edge, np.minimum(foreground[:, :, 1], limit), foreground[:, :, 1])
	foreground[alpha == 0.0] = 0.0

	rgba = np.dstack((foreground, alpha * 255.0)).round().astype(np.uint8)
	return Image.fromarray(rgba, "RGBA"), [int(round(v)) for v in key]


def premultiplied_resize(image: Image.Image, size: tuple[int, int]) -> Image.Image:
	a = np.asarray(image, dtype=np.float32) / 255.0
	premul = a.copy()
	premul[:, :, :3] *= premul[:, :, 3:4]
	resized = np.asarray(
		Image.fromarray((premul * 255.0).round().astype(np.uint8), "RGBA").resize(size, Image.Resampling.LANCZOS),
		dtype=np.float32,
	) / 255.0
	alpha = resized[:, :, 3:4]
	rgb = np.divide(resized[:, :, :3], alpha, out=np.zeros_like(resized[:, :, :3]), where=alpha > 1.0 / 255.0)
	out = np.concatenate((np.clip(rgb, 0.0, 1.0), np.clip(alpha, 0.0, 1.0)), axis=2)
	out[out[:, :, 3] < 1.0 / 255.0] = 0.0
	return Image.fromarray((out * 255.0).round().astype(np.uint8), "RGBA")


def bleed_soft_edge_rgb(arr: np.ndarray) -> np.ndarray:
	alpha = arr[:, :, 3]
	filled = alpha >= 160
	target = (alpha > 0) & ~filled
	colors = arr[:, :, :3].astype(np.float32)
	h, w = alpha.shape
	for _ in range(8):
		if not target.any():
			break
		sums = np.zeros_like(colors)
		counts = np.zeros((h, w), dtype=np.float32)
		for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (-1, 1), (1, -1), (1, 1)):
			y0, y1 = max(0, -dy), min(h, h - dy)
			x0, x1 = max(0, -dx), min(w, w - dx)
			source_filled = filled[y0 + dy:y1 + dy, x0 + dx:x1 + dx]
			sums[y0:y1, x0:x1] += colors[y0 + dy:y1 + dy, x0 + dx:x1 + dx] * source_filled[:, :, None]
			counts[y0:y1, x0:x1] += source_filled
		new = target & (counts > 0)
		colors[new] = sums[new] / counts[new][:, None]
		filled[new] = True
		target[new] = False
	out = arr.copy()
	soft = (alpha > 0) & (alpha < 160)
	out[soft, :3] = np.clip(colors[soft], 0, 255).round().astype(np.uint8)
	return out


def fit_subject(image: Image.Image) -> Image.Image:
	a = np.asarray(image.getchannel("A"))
	ys, xs = np.where(a >= 8)
	box = (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)
	subject = image.crop(box)
	target_h = 1352  # 88.0% of 1536
	target_w = 972
	scale = min(target_h / subject.height, target_w / subject.width, 1.0)
	new_size = (max(1, round(subject.width * scale)), max(1, round(subject.height * scale)))
	subject = premultiplied_resize(subject, new_size)
	canvas = Image.new("RGBA", (1024, 1536), (0, 0, 0, 0))
	x = (1024 - subject.width) // 2
	y = (1536 - subject.height) // 2
	canvas.alpha_composite(subject, (x, y))
	# LANCZOS can re-introduce a few green-ish RGB samples at soft edges even
	# with premultiplication. None of these three characters has green design
	# elements, so remove only strong green dominance after the final resize.
	arr = np.asarray(canvas).copy()
	rgb = arr[:, :, :3].astype(np.int16)
	alpha = arr[:, :, 3]
	maximum_rb = np.maximum(rgb[:, :, 0], rgb[:, :, 2])
	spill = (alpha > 0) & (rgb[:, :, 1] > maximum_rb + 40)
	arr[:, :, 1] = np.where(spill, np.minimum(rgb[:, :, 1], maximum_rb + 8), rgb[:, :, 1]).astype(np.uint8)
	arr = bleed_soft_edge_rgb(arr)
	arr[alpha == 0, :3] = 0
	return Image.fromarray(arr, "RGBA")


def dilate(mask: np.ndarray, radius: int) -> np.ndarray:
	out = mask.copy()
	h, w = mask.shape
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			y0, y1 = max(0, -dy), min(h, h - dy)
			x0, x1 = max(0, -dx), min(w, w - dx)
			out[y0:y1, x0:x1] |= mask[y0 + dy:y1 + dy, x0 + dx:x1 + dx]
	return out


def measure(image: Image.Image, key: list[int]) -> dict[str, object]:
	a = np.asarray(image)
	alpha = a[:, :, 3]
	ys, xs = np.where(alpha > 0)
	box = [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1]
	transparent = alpha == 0
	near = dilate(transparent, 2) & ~transparent
	rgb = a[:, :, :3].astype(np.int16)
	key_rgb = np.array(key, dtype=np.int16)
	key_distance = np.max(np.abs(rgb - key_rgb[None, None, :]), axis=2)
	green_like = (rgb[:, :, 1] > 180) & (rgb[:, :, 1] > rgb[:, :, 0] + 60) & (rgb[:, :, 1] > rgb[:, :, 2] + 60)
	return {
		"size": list(image.size),
		"mode": image.mode,
		"source_key_rgb": key,
		"alpha_range": [int(alpha.min()), int(alpha.max())],
		"nonzero_alpha_pixels": int((alpha > 0).sum()),
		"soft_alpha_pixels": int(((alpha > 0) & (alpha < 255)).sum()),
		"bbox_alpha_gt_0": box,
		"subject_height_percent": round((box[3] - box[1]) / 1536.0 * 100.0, 2),
		"margins_ltrb": [box[0], box[1], 1024 - box[2], 1536 - box[3]],
		"border_nonzero_alpha_pixels": int(
			(alpha[0] > 0).sum() + (alpha[-1] > 0).sum() + (alpha[:, 0] > 0).sum() + (alpha[:, -1] > 0).sum()
		),
		"key_match_within_2px_of_transparency": int((near & (key_distance <= 12)).sum()),
		"green_like_within_2px_of_transparency": int((near & green_like).sum()),
	}


def checker(size: tuple[int, int], cell: int = 16) -> Image.Image:
	w, h = size
	y, x = np.indices((h, w))
	board = ((x // cell + y // cell) % 2).astype(np.uint8)
	arr = np.where(board[:, :, None] == 0, np.array([54, 59, 72]), np.array([78, 84, 99])).astype(np.uint8)
	return Image.fromarray(arr, "RGB").convert("RGBA")


def make_contact() -> None:
	columns = []
	try:
		font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 24)
	except OSError:
		font = ImageFont.load_default()
	for stem, variant, label in ITEMS:
		folder = ROOT / "art" / "bakeoff" / ("frey" if stem == "frey" else "luna") / "main"
		illustration = Image.open(folder / f"{stem}_illustration-v{variant}.png").convert("RGBA").resize((256, 384), Image.Resampling.LANCZOS)
		face = Image.open(folder / f"{stem}_face-v{variant}.png").convert("RGBA")
		column = Image.new("RGBA", (256, 680), (28, 31, 40, 255))
		body_bg = checker((256, 384))
		body_bg.alpha_composite(illustration)
		face_bg = checker((256, 256))
		face_bg.alpha_composite(face)
		column.alpha_composite(body_bg, (0, 34))
		column.alpha_composite(face_bg, (0, 424))
		draw = ImageDraw.Draw(column)
		bbox = draw.textbbox((0, 0), label, font=font)
		draw.text(((256 - (bbox[2] - bbox[0])) // 2, 4), label, fill=(245, 247, 255, 255), font=font)
		columns.append(column)
	contact = Image.new("RGBA", (256 * len(columns), 680), (28, 31, 40, 255))
	for i, column in enumerate(columns):
		contact.alpha_composite(column, (i * 256, 0))
	contact.convert("RGB").save(REPORT / "contact.png")


def main() -> None:
	REPORT.mkdir(parents=True, exist_ok=True)
	metrics: dict[str, object] = {}
	for stem, variant, _label in ITEMS:
		identifier = f"{stem}-v{variant}"
		source = RAW / f"{identifier}-green.png"
		output_folder = ROOT / "art" / "bakeoff" / ("frey" if stem == "frey" else "luna") / "main"
		output_folder.mkdir(parents=True, exist_ok=True)
		illustration, key = chroma_extract(source)
		illustration = fit_subject(illustration)
		illustration_path = output_folder / f"{stem}_illustration-v{variant}.png"
		illustration.save(illustration_path)

		face_box = FACE_BOXES[(stem, variant)]
		face = illustration.crop(face_box).resize((256, 256), Image.Resampling.LANCZOS)
		face_path = output_folder / f"{stem}_face-v{variant}.png"
		face.save(face_path)

		metrics[identifier] = {
			"illustration": measure(illustration, key),
			"face": {
				"size": list(face.size),
				"mode": face.mode,
				"crop_box_before_lanczos": list(face_box),
			},
		}
	(REPORT / "measurements.json").write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
	make_contact()


if __name__ == "__main__":
	main()
