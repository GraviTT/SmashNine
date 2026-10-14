from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "art" / "raw" / "mainart-62"
OUT = ROOT / "art" / "bakeoff" / "rio" / "main"
REPORT = ROOT / "reports" / "codex-art-62"
CANVAS = (1024, 1536)
TARGET_HEIGHT = 1352

ITEMS = [
	("male", 1, "Rio 남 1", (729, 251)),
	("male", 2, "Rio 남 2", (745, 242)),
	("female", 1, "Rio 여 1", (650, 294)),
	("female", 2, "Rio 여 2", (642, 322)),
]

# Manually placed on final 1024x1536 canvases at 1x. Loose spikes and the
# female ponytails are excluded; these are main crown-to-chin measurements.
MANUAL_HEAD_BOX_Y = {
	("male", 1): (127, 330),
	("male", 2): (120, 317),
	("female", 1): (177, 371),
	("female", 2): (199, 381),
}


def premultiplied_resize(image: Image.Image, size: tuple[int, int]) -> Image.Image:
	array = np.asarray(image.convert("RGBA"), dtype=np.float32) / 255.0
	premultiplied = array.copy()
	premultiplied[:, :, :3] *= premultiplied[:, :, 3:4]
	resized = np.asarray(
		Image.fromarray((premultiplied * 255.0).round().astype(np.uint8), "RGBA").resize(
			size, Image.Resampling.LANCZOS
		),
		dtype=np.float32,
	) / 255.0
	alpha = resized[:, :, 3:4]
	rgb = np.divide(
		resized[:, :, :3], alpha, out=np.zeros_like(resized[:, :, :3]), where=alpha > 1.0 / 255.0
	)
	result = np.concatenate((np.clip(rgb, 0.0, 1.0), np.clip(alpha, 0.0, 1.0)), axis=2)
	result[result[:, :, 3] < 2.0 / 255.0] = 0.0
	return Image.fromarray((result * 255.0).round().astype(np.uint8), "RGBA")


def fit_subject(source: Path) -> Image.Image:
	image = Image.open(source).convert("RGBA")
	array = np.asarray(image).copy()
	# Built-in ImageGen returned true alpha. Remove only isolated near-zero
	# alpha dust; there is no chroma key and no colour despill step.
	array[array[:, :, 3] < 8] = 0
	array[array[:, :, 3] >= 254, 3] = 255
	image = Image.fromarray(array, "RGBA")
	alpha = np.asarray(image.getchannel("A"))
	ys, xs = np.where(alpha > 0)
	if not len(xs):
		raise ValueError(f"empty source: {source}")
	bbox = (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)
	subject = image.crop(bbox)
	scale = TARGET_HEIGHT / subject.height
	new_size = (round(subject.width * scale), TARGET_HEIGHT)
	if new_size[0] > CANVAS[0]:
		raise ValueError(f"subject too wide after exact ART-53 fit: {source}: {new_size}")
	subject = premultiplied_resize(subject, new_size)
	canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
	x = (CANVAS[0] - subject.width) // 2
	y = (CANVAS[1] - subject.height) // 2
	canvas.alpha_composite(subject, (x, y))
	final = np.asarray(canvas).copy()
	final[final[:, :, 3] < 2] = 0
	final[final[:, :, 3] >= 254, 3] = 255
	final[final[:, :, 3] == 0, :3] = 0
	return Image.fromarray(final, "RGBA")


def crop_face(image: Image.Image, center_x: int, eye_y: int, crop_size: int = 512) -> Image.Image:
	left = round(center_x - crop_size / 2)
	top = round(eye_y - crop_size * 0.40)
	face = image.crop((left, top, left + crop_size, top + crop_size))
	face = premultiplied_resize(face, (256, 256))
	array = np.asarray(face).copy()
	array[array[:, :, 3] == 0, :3] = 0
	return Image.fromarray(array, "RGBA")


def dilate(mask: np.ndarray, radius: int) -> np.ndarray:
	result = mask.copy()
	h, w = mask.shape
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			y0, y1 = max(0, -dy), min(h, h - dy)
			x0, x1 = max(0, -dx), min(w, w - dx)
			result[y0:y1, x0:x1] |= mask[y0 + dy:y1 + dy, x0 + dx:x1 + dx]
	return result


def measure(image: Image.Image) -> dict[str, object]:
	array = np.asarray(image.convert("RGBA"))
	alpha = array[:, :, 3]
	ys, xs = np.where(alpha > 0)
	left, top, right, bottom = int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1
	transparent = alpha == 0
	near_clear = dilate(transparent, 2) & ~transparent
	rgb = array[:, :, :3].astype(np.int16)
	green_dominant = near_clear & (rgb[:, :, 1] > 180) & (rgb[:, :, 1] > rgb[:, :, 0] + 60) & (
		rgb[:, :, 1] > rgb[:, :, 2] + 60
	)
	return {
		"size": list(image.size),
		"mode": image.mode,
		"alpha_range": [int(alpha.min()), int(alpha.max())],
		"alpha_bbox": [left, top, right, bottom],
		"subject_height_px": bottom - top,
		"subject_height_percent": round((bottom - top) * 100.0 / image.height, 2),
		"margins_ltrb_px": [left, top, image.width - right, image.height - bottom],
		"border_nonzero_alpha_pixels": int(
			(alpha[0] > 0).sum() + (alpha[-1] > 0).sum() + (alpha[:, 0] > 0).sum() + (alpha[:, -1] > 0).sum()
		),
		"soft_alpha_pixels": int(((alpha > 0) & (alpha < 255)).sum()),
		"transparent_rgb_nonzero_pixels": int(np.any(array[:, :, :3] != 0, axis=2)[transparent].sum()),
		"source_background_key_removed": None,
		"removed_key_fringe_within_2px": 0,
		"green_dominant_edge_pixels_from_cyan_design": int(green_dominant.sum()),
		"cropped": bool(left == 0 or top == 0 or right == image.width or bottom == image.height),
	}


def checker(size: tuple[int, int], cell: int = 16) -> Image.Image:
	w, h = size
	y, x = np.indices((h, w))
	board = ((x // cell + y // cell) % 2).astype(np.uint8)
	array = np.where(board[:, :, None] == 0, np.array([54, 59, 72]), np.array([78, 84, 99])).astype(np.uint8)
	return Image.fromarray(array, "RGB").convert("RGBA")


def font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
	for candidate in ("C:/Windows/Fonts/malgunbd.ttf", "C:/Windows/Fonts/malgun.ttf"):
		try:
			return ImageFont.truetype(candidate, size)
		except OSError:
			pass
	return ImageFont.load_default()


def make_contact(images: dict[tuple[str, int], Image.Image], faces: dict[tuple[str, int], Image.Image]) -> None:
	entries: list[tuple[str, Image.Image, Image.Image]] = []
	for body, variant, label, _landmark in ITEMS:
		entries.append((label, images[(body, variant)], faces[(body, variant)]))
	entries.extend([
		("Frey 기준", Image.open(ROOT / "smash-nine-prototype/assets/art/frey/frey_illustration.png").convert("RGBA"), Image.open(ROOT / "smash-nine-prototype/assets/art/frey/frey_face.png").convert("RGBA")),
		("Nova 남 기준", Image.open(ROOT / "smash-nine-prototype/assets/art/nova/nova_male_illustration.png").convert("RGBA"), Image.open(ROOT / "smash-nine-prototype/assets/art/nova/nova_male_face.png").convert("RGBA")),
	])
	column_width = 280
	contact = Image.new("RGBA", (column_width * len(entries), 704), (28, 31, 40, 255))
	draw = ImageDraw.Draw(contact)
	label_font = font(24)
	for index, (label, illustration, face) in enumerate(entries):
		x = index * column_width + 12
		body_panel = checker((256, 384))
		body_panel.alpha_composite(illustration.resize((256, 384), Image.Resampling.LANCZOS))
		face_panel = checker((256, 256))
		face_panel.alpha_composite(face)
		contact.alpha_composite(body_panel, (x, 42))
		contact.alpha_composite(face_panel, (x, 434))
		box = draw.textbbox((0, 0), label, font=label_font)
		draw.text((x + (256 - (box[2] - box[0])) // 2, 8), label, fill=(245, 247, 255), font=label_font)
	contact.convert("RGB").save(REPORT / "contact.png", optimize=True)


def make_face_check(faces: dict[tuple[str, int], Image.Image]) -> None:
	check = Image.new("RGBA", (512 * len(ITEMS), 548), (28, 31, 40, 255))
	draw = ImageDraw.Draw(check)
	label_font = font(22)
	for index, (body, variant, label, _landmark) in enumerate(ITEMS):
		x = index * 512
		panel = checker((512, 512), 24)
		panel.alpha_composite(faces[(body, variant)].resize((512, 512), Image.Resampling.NEAREST))
		check.alpha_composite(panel, (x, 36))
		draw.text((x + 12, 5), f"{label} · 얼굴 2배", fill=(245, 247, 255), font=label_font)
	(REPORT / "inspection").mkdir(parents=True, exist_ok=True)
	check.convert("RGB").save(REPORT / "inspection" / "faces-2x.png", optimize=True)


def main() -> None:
	OUT.mkdir(parents=True, exist_ok=True)
	REPORT.mkdir(parents=True, exist_ok=True)
	images: dict[tuple[str, int], Image.Image] = {}
	faces: dict[tuple[str, int], Image.Image] = {}
	measurements: dict[str, object] = {}
	for body, variant, _label, (center_x, eye_y) in ITEMS:
		key = (body, variant)
		illustration = fit_subject(RAW / f"rio_{body}-v{variant}-raw.png")
		illustration.save(OUT / f"rio_{body}_illustration-v{variant}.png", optimize=True)
		face = crop_face(illustration, center_x, eye_y)
		face.save(OUT / f"rio_{body}_face-v{variant}.png", optimize=True)
		images[key] = illustration
		faces[key] = face
		measurements[f"rio_{body}-v{variant}"] = {
			"illustration": measure(illustration),
			"face": measure(face),
			"face_landmark": {"center_x": center_x, "eye_y": eye_y, "eye_height_percent": 40.0},
			"manual_head_measurement": {
				"method": "1x visual main-crown-to-chin points; loose spikes and ponytail excluded",
				"y_top_chin": list(MANUAL_HEAD_BOX_Y[key]),
				"head_height_px": MANUAL_HEAD_BOX_Y[key][1] - MANUAL_HEAD_BOX_Y[key][0],
				"subject_height_in_heads": round(TARGET_HEIGHT / (MANUAL_HEAD_BOX_Y[key][1] - MANUAL_HEAD_BOX_Y[key][0]), 2),
			},
		}
	(REPORT / "measurements.json").write_text(json.dumps(measurements, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
	make_contact(images, faces)
	make_face_check(faces)
	print(json.dumps(measurements, ensure_ascii=False, indent=2))


if __name__ == "__main__":
	main()
