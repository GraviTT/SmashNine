from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "art" / "raw" / "mainart-50"
OUT = ROOT / "art" / "bakeoff" / "yuki" / "main"
REPORT = ROOT / "reports" / "codex-art-50"
CANVAS = (1024, 1536)
TARGET_HEIGHT = round(CANVAS[1] * 0.88)


def despill_transparent_edges(image: Image.Image) -> Image.Image:
	array = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
	partial = (array[..., 3] > 0) & (array[..., 3] < 255)
	max_rb = np.maximum(array[..., 0], array[..., 2])
	array[..., 1][partial] = np.minimum(array[..., 1][partial], max_rb[partial])
	array[..., :3][array[..., 3] == 0] = 0
	return Image.fromarray(array, "RGBA")


def chroma_key(path: Path) -> Image.Image:
	"""Recover a soft-alpha foreground composited over uniform #00ff00."""
	rgba = np.asarray(Image.open(path).convert("RGBA"), dtype=np.float32)
	rgb = rgba[..., :3]
	red, green, blue = (rgb[..., index] for index in range(3))
	green_excess = np.clip(green - np.maximum(red, blue), 0.0, 255.0)
	raw_alpha = 1.0 - green_excess / 255.0
	# Image generation leaves a few percent of low-contrast variation in an
	# apparently flat chroma field. Remove that floor, then stretch the genuine
	# antialias ramp back to the full range.
	alpha = np.clip((raw_alpha - 0.12) / 0.88, 0.0, 1.0)

	# Reverse the green-screen composite. This both preserves a soft edge and
	# removes green spill from semi-transparent hair and cloth pixels.
	safe = np.maximum(raw_alpha, 1.0 / 255.0)
	foreground = np.empty_like(rgb)
	foreground[..., 0] = red / safe
	foreground[..., 2] = blue / safe
	foreground[..., 1] = (green - 255.0 * (1.0 - alpha)) / safe
	foreground = np.clip(foreground, 0.0, 255.0)
	foreground[alpha == 0.0] = 0.0
	result = np.dstack((foreground, alpha * 255.0)).round().astype(np.uint8)
	return Image.fromarray(result, "RGBA")


def fit_subject(image: Image.Image) -> Image.Image:
	alpha = image.getchannel("A")
	bbox = alpha.getbbox()
	if bbox is None:
		raise ValueError("empty keyed image")
	subject = image.crop(bbox)
	scale = TARGET_HEIGHT / subject.height
	width = round(subject.width * scale)
	resized = subject.resize((width, TARGET_HEIGHT), Image.Resampling.LANCZOS)
	canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
	x = (CANVAS[0] - width) // 2
	y = (CANVAS[1] - TARGET_HEIGHT) // 2
	canvas.alpha_composite(resized, (x, y))
	return despill_transparent_edges(canvas)


def crop_face(image: Image.Image, center_x: int, eye_y: int, crop_size: int = 512) -> Image.Image:
	left = round(center_x - crop_size / 2)
	top = round(eye_y - crop_size * 0.40)
	box = (left, top, left + crop_size, top + crop_size)
	face = image.crop(box).resize((256, 256), Image.Resampling.LANCZOS)
	return despill_transparent_edges(face)


def alpha_edge(alpha: np.ndarray, radius: int = 2) -> np.ndarray:
	inside = alpha > 0
	near_clear = np.zeros_like(inside)
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if dx == 0 and dy == 0:
				continue
			shifted = np.zeros_like(inside)
			y0 = max(0, dy); y1 = inside.shape[0] + min(0, dy)
			x0 = max(0, dx); x1 = inside.shape[1] + min(0, dx)
			shifted[y0:y1, x0:x1] = ~inside[y0 - dy:y1 - dy, x0 - dx:x1 - dx]
			near_clear |= shifted
	return inside & near_clear


def metrics(path: Path) -> dict[str, object]:
	image = Image.open(path).convert("RGBA")
	array = np.asarray(image)
	alpha = array[..., 3]
	bbox = image.getchannel("A").getbbox()
	if bbox is None:
		raise ValueError(f"empty image: {path}")
	red = array[..., 0].astype(np.int16)
	green = array[..., 1].astype(np.int16)
	blue = array[..., 2].astype(np.int16)
	distance = np.abs(red) + np.abs(green - 255) + np.abs(blue)
	fringe = alpha_edge(alpha, 2) & (distance <= 80)
	left, top, right, bottom = bbox
	return {
		"path": path.relative_to(ROOT).as_posix(),
		"size": list(image.size),
		"mode": image.mode,
		"alpha_bbox": list(bbox),
		"subject_height_px": bottom - top,
		"subject_height_percent": round((bottom - top) * 100.0 / image.height, 2),
		"margins_px": {"left": left, "top": top, "right": image.width - right, "bottom": image.height - bottom},
		"alpha_values": int(np.unique(alpha).size),
		"transparent_pixels": int(np.count_nonzero(alpha == 0)),
		"soft_alpha_pixels": int(np.count_nonzero((alpha > 0) & (alpha < 255))),
		"green_key_fringe_within_2px": int(np.count_nonzero(fringe)),
		"cropped": bool(left == 0 or top == 0 or right == image.width or bottom == image.height),
	}


def label(draw: ImageDraw.ImageDraw, x: int, y: int, value: str) -> None:
	font = ImageFont.load_default(size=20)
	box = draw.textbbox((0, 0), value, font=font)
	w = box[2] - box[0]
	draw.text((x + (256 - w) // 2, y), value, fill=(245, 245, 245, 255), font=font)


def make_contact(yuki_images: list[Image.Image], yuki_faces: list[Image.Image]) -> None:
	items = [
		("Frey", Image.open(ROOT / "smash-nine-prototype/assets/art/frey/frey_illustration.png").convert("RGBA"), Image.open(ROOT / "smash-nine-prototype/assets/art/frey/frey_face.png").convert("RGBA")),
		("Luna", Image.open(ROOT / "smash-nine-prototype/assets/art/luna/luna_illustration.png").convert("RGBA"), Image.open(ROOT / "smash-nine-prototype/assets/art/luna/luna_face.png").convert("RGBA")),
		("Yuki 1", yuki_images[0], yuki_faces[0]),
		("Yuki 2", yuki_images[1], yuki_faces[1]),
	]
	column_width = 280
	contact = Image.new("RGBA", (column_width * len(items), 690), (28, 30, 38, 255))
	draw = ImageDraw.Draw(contact)
	for index, (name, illustration, face) in enumerate(items):
		x = index * column_width + 12
		thumb = illustration.resize((256, 384), Image.Resampling.LANCZOS)
		contact.alpha_composite(thumb, (x, 42))
		label(draw, x, 12, name)
		contact.alpha_composite(face, (x, 434))
	contact.convert("RGB").save(REPORT / "contact.png", optimize=True)


def make_anatomy_check(yuki_images: list[Image.Image]) -> None:
	check = Image.new("RGBA", (2048, 1280), (28, 30, 38, 255))
	draw = ImageDraw.Draw(check)
	font = ImageFont.load_default(size=24)
	for index, image in enumerate(yuki_images):
		x = index * 1024
		upper = image.crop((0, 80, 1024, 850))
		check.alpha_composite(upper, (x, 42))
		feet = image.crop((180, 1040, 850, 1536))
		check.alpha_composite(feet, (x + 177, 784))
		draw.text((x + 18, 10), f"Yuki {index + 1}: arms / hands / sleeves / feet at 1x", fill=(245, 245, 245, 255), font=font)
	check.convert("RGB").save(REPORT / "anatomy-check-1x.png", optimize=True)


def main() -> None:
	OUT.mkdir(parents=True, exist_ok=True)
	REPORT.mkdir(parents=True, exist_ok=True)
	inputs = [RAW / "yuki-v1-chroma.png", RAW / "yuki-v2-chroma.png"]
	# Eye positions are measured on the fitted canvases; 40% of a 512px crop
	# puts them at the requested face-frame height.
	face_landmarks = [(604, 277), (603, 280)]
	yuki_images: list[Image.Image] = []
	yuki_faces: list[Image.Image] = []
	all_metrics: list[dict[str, object]] = []
	for index, (source, (center_x, eye_y)) in enumerate(zip(inputs, face_landmarks), start=1):
		illustration = fit_subject(chroma_key(source))
		illustration_path = OUT / f"yuki_illustration-v{index}.png"
		illustration.save(illustration_path, optimize=True)
		face = crop_face(illustration, center_x, eye_y)
		face_path = OUT / f"yuki_face-v{index}.png"
		face.save(face_path, optimize=True)
		yuki_images.append(illustration)
		yuki_faces.append(face)
		all_metrics.extend((metrics(illustration_path), metrics(face_path)))

	make_contact(yuki_images, yuki_faces)
	make_anatomy_check(yuki_images)
	face_check = Image.new("RGBA", (1024, 512), (28, 30, 38, 255))
	face_check.alpha_composite(yuki_faces[0].resize((512, 512), Image.Resampling.NEAREST), (0, 0))
	face_check.alpha_composite(yuki_faces[1].resize((512, 512), Image.Resampling.NEAREST), (512, 0))
	face_check.convert("RGB").save(REPORT / "face-check-2x.png", optimize=True)
	(REPORT / "metrics.json").write_text(json.dumps(all_metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
	print(json.dumps(all_metrics, ensure_ascii=False, indent=2))


if __name__ == "__main__":
	main()
