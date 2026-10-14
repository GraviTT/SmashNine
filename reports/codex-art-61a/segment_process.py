"""Extract non-overlapping generated figures, then run the standard normalizer."""

from __future__ import annotations

from collections import deque
import json
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image

import process


def extract(row: str, count: int) -> Path:
	path = process.RAW / row / "raw.png"
	image = Image.open(path).convert("RGBA")
	array = np.asarray(image, dtype=np.uint8).copy()
	if row == "mana_combo":
		# The second source uses explicit white separators; they are not artwork.
		h, w = array.shape[:2]
		for x in (round(w / 3), round(2 * w / 3)):
			array[:, x - 10:x + 11] = (0, 255, 0, 255)
		array[round(h / 2) - 10:round(h / 2) + 11, :] = (0, 255, 0, 255)
	image = Image.fromarray(array, "RGBA")
	clean, _ = process_clean(image)
	alpha = np.asarray(clean.getchannel("A"), dtype=np.uint8)
	visible = alpha > 0
	visited = np.zeros(visible.shape, dtype=bool)
	components = []
	h, w = visible.shape
	for y in range(h):
		for x in range(w):
			if not visible[y, x] or visited[y, x]:
				continue
			queue = deque([(x, y)]); visited[y, x] = True; points = []
			while queue:
				cx, cy = queue.popleft(); points.append((cx, cy))
				for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
					if 0 <= nx < w and 0 <= ny < h and visible[ny, nx] and not visited[ny, nx]:
						visited[ny, nx] = True; queue.append((nx, ny))
			if len(points) >= 800:
				xs = [p[0] for p in points]; ys = [p[1] for p in points]
				components.append((len(points), min(xs), min(ys), max(xs) + 1, max(ys) + 1, points))
	components.sort(reverse=True)
	components = components[:count]
	if len(components) != count:
		raise RuntimeError(f"{row}: expected {count} figures, found {len(components)}")
	if count == 3:
		components.sort(key=lambda item: (item[1] + item[3]) / 2)
	else:
		top = sorted(components, key=lambda item: (item[2] + item[4]) / 2)[:3]
		bottom = [item for item in components if item not in top]
		components = sorted(top, key=lambda item: (item[1] + item[3]) / 2) + sorted(bottom, key=lambda item: (item[1] + item[3]) / 2)
	out_dir = process.RAW / row / "extracted"
	out_dir.mkdir(parents=True, exist_ok=True)
	for old in out_dir.glob("*.png"):
		old.unlink()
	rgba = np.asarray(clean, dtype=np.uint8)
	for index, component in enumerate(components):
		_, x0, y0, x1, y1, points = component
		frame = np.zeros_like(rgba)
		for x, y in points:
			frame[y, x] = rgba[y, x]
		crop = Image.fromarray(frame, "RGBA").crop((x0, y0, x1, y1))
		canvas = Image.new("RGBA", (700, 700), (0, 255, 0, 255))
		canvas.alpha_composite(crop, ((700 - crop.width) // 2, (700 - crop.height) // 2))
		canvas.save(out_dir / f"f{index:02d}.png")
	return out_dir


def process_clean(image: Image.Image) -> tuple[Image.Image, dict]:
	# Importing from the checked-in pipeline keeps chroma handling identical.
	import importlib.util
	spec = importlib.util.spec_from_file_location("sprite_normalize", process.PIPE / "normalize.py")
	module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
	return module.clean_background(image, "#00ff00")


def normalize_frames(name: str, frames_dir: Path, factor: float, cell: int, out_dir: Path,
		candidate: Path | None, grounded: bool, lift: int, offset: int = 0) -> None:
	args = [str(process.PY), str(process.PIPE / "normalize.py"), "--frames", str(frames_dir),
		"--bg", "#00ff00", "--cell", str(cell), "--feet-y", str(120 if cell == 128 else 152),
		"--scale-by", f"fixed:{factor:.9f}", "--resample", "lanczos", "--sharpen", "60",
		"--despill", "auto", "--palette", "none", "--reference", process.REFERENCE,
		"--compare-scale", "4", "--title", f"RIO MALE {name.upper()}", "--out-dir", str(out_dir),
		"--name", f"rio_male-{name}-v1"]
	if grounded: args += ["--ground-all"]
	if lift: args += ["--lift-all", str(lift)]
	if offset: args += ["--offset-x", str(offset)]
	if candidate: args += ["--candidate-out", str(candidate)]
	process.run(args)


def do_row(name: str, initial: float, cell: int, grounded: bool, lift: int, fps: float, offset: int = 0) -> None:
	frames = extract(name, 6)
	initial_dir = process.REPORT / name / "segmented-initial"
	normalize_frames(name, frames, initial, cell, initial_dir, None, grounded, lift, offset)
	sheet = initial_dir / f"rio_male-{name}-v1.png"
	measure = process.head_measure(sheet, 6, initial, initial_dir / "head-scale.json")
	factor = float(measure.get("head_matched_factor") or initial)
	out = process.REPORT / name
	candidate = process.BAKE / f"rio_male-{name}-v1.png"
	normalize_frames(name, frames, factor, cell, out, candidate, grounded, lift, offset)
	final = process.head_measure(candidate, 6, factor, out / "head-scale.json")
	metrics = json.loads((out / "metrics.json").read_text(encoding="utf-8"))
	metrics["head_check"] = {"method": "head_scale" if final.get("used", 0) >= 2 else "4x_head_crop", "result": final}
	(out / "metrics.json").write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
	process.write_meta(name, fps, 6, cell)


def main() -> None:
	failures = {}
	for args in (
		("mana_combo", .28, 192, True, 0, 18, 0),
		("low_sweep", .28, 192, True, 0, 30, 0),
		("air_slash", .28, 192, False, 16, 40, 0),
		("dimension_slash", .28, 192, True, 0, 23, 0),
		("infinity_overdrive", .23, 192, True, 0, 11, 0),
	):
		try:
			do_row(*args)
		except Exception as error:
			failures[args[0]] = str(error)
	(process.REPORT / "segment-failures.json").write_text(json.dumps(failures, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
	main()
