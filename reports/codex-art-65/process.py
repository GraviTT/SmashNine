"""Normalise, measure, and package the four CODEX-ART-65 rows."""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
PY = Path("C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe")
PIPE = ROOT / "tools/sprite_pipeline"
REPORT = ROOT / "reports/codex-art-65"
RAW = ROOT / "art/raw/rio-65"
BAKE = ROOT / "art/bakeoff/rio"
ANCHOR = ROOT / "art/bakeoff/rio/rio_male-idle-v2.png"
REFERENCE = f"{ANCHOR}:0:6"
ENV = {**os.environ, "PYTHONDONTWRITEBYTECODE": "1"}


META = {
	"walk": {"note": "짧은 보폭과 몸에 붙인 검·망토로 셀 안에 맞춘 8프레임 걷기. 3·7번은 발목 옆을 통과하는 자세다.", "fps": 13.3, "frames": 8},
	"fall": {"note": "무릎과 팔을 몸에 모으고 망토를 짧게 접은 공중 낙하 자세.", "fps": 24, "frames": 1},
	"shield": {"note": "검을 몸 앞에 세로로 붙여 올리고 버틴 뒤 회복하는 6프레임 방어. 장벽은 없다.", "fps": 12, "frames": 6},
	"infinity_overdrive": {"note": "낮은 자세에서 검을 머리 높이까지만 비스듬히 올리고 전방을 지휘하는 필살기 시작. 궤도 검은 없다.", "fps": 11, "frames": 6, "cell": 192, "feet": 152},
}


PROMPTS = {
	"walk": """앵커의 Rio 남성 의상과 1번 프레임을 고정하고 회색 마네킹의 8개 자세만 따른다. 마네킹의 회색은 의상이 아니다. 짧은 보폭, 낮고 몸에 붙인 밝은 파란 검, 몸 뒤에 붙인 짧은 망토. 3번은 가까운 다리만 지지하고 먼 발이 발목 옆에 들리며, 7번은 먼 다리만 지지하고 가까운 발이 발목 옆에 들린다. 순수 #00FF00 배경, 한 인물, 이펙트·잔상·마나 파동·룬·장벽·궤도 검 없음.""",
	"fall": """앵커와 같은 Rio 남성의 단일 공중 낙하 자세. 양 무릎을 가슴 쪽으로 굽혀 당기고 양팔과 검을 몸에 붙이며, 머리카락은 살짝 들리고 망토는 위·뒤로 짧게 접힌다. 전체 실루엣은 캔버스 높이 약 55% 이하. 순수 #00FF00 배경, 한 얼굴·두 손·두 부츠·검 하나, 이펙트 없음.""",
	"shield": """3x2의 6프레임 Rio 남성 방어: 준비/검 올리기/양손 버티기/유지/피격 흡수/회복. 검은 몸 앞에 세로로 붙이고 끝은 머리 위를 넘지 않으며, 무릎은 살짝 굽히고 발은 어깨 너비 안쪽이다. 순수 #00FF00 배경, 장벽과 모든 이펙트 없음.""",
	"infinity_overdrive": """3x2의 6프레임 Rio 남성 필살기 시작: 집중/낮게 웅크리고 검을 머리 높이로 비스듬히 올림/유지/빈손 전방 지휘/유지/준비. 검을 수직으로 머리 위에 들지 않으며 몸과 어깨 가까이에 둔다. 순수 #00FF00 배경, 추가 검·궤도 검과 모든 이펙트 없음.""",
}


def run(args: list[str]) -> None:
	print("RUN", " ".join(args))
	subprocess.run(args, cwd=ROOT, env=ENV, check=True)


def clean_grid(source: Path, cols: int, rows: int, target: Path) -> Path:
	with Image.open(source) as opened:
		rgba = np.asarray(opened.convert("RGBA"), dtype=np.uint8).copy()
	h = rgba.shape[0] - rgba.shape[0] % rows
	w = rgba.shape[1] - rgba.shape[1] % cols
	rgba = rgba[:h, :w]
	rgb = rgba[..., :3].astype(np.int16)
	green = np.abs(rgb[..., 0]) + np.abs(rgb[..., 1] - 255) + np.abs(rgb[..., 2]) <= 95
	rgba[..., :3][green] = (0, 255, 0)
	rgba[..., 3][green] = 255
	# Only outside-edge residue and genuine nearly-white panel dividers are background artifacts.
	for x in (round(i * w / cols) for i in range(1, cols)):
		lo, hi = max(0, x - 8), min(w, x + 9)
		if float(np.mean(np.all(rgba[:, lo:hi, :3] >= 238, axis=2))) >= .80:
			rgba[:, lo:hi] = (0, 255, 0, 255)
	for y in (round(i * h / rows) for i in range(1, rows)):
		lo, hi = max(0, y - 8), min(h, y + 9)
		if float(np.mean(np.all(rgba[lo:hi, :, :3] >= 238, axis=2))) >= .80:
			rgba[lo:hi, :] = (0, 255, 0, 255)
	rgba[:8, :] = (0, 255, 0, 255)
	rgba[-8:, :] = (0, 255, 0, 255)
	rgba[:, :8] = (0, 255, 0, 255)
	rgba[:, -8:] = (0, 255, 0, 255)
	target.parent.mkdir(parents=True, exist_ok=True)
	Image.fromarray(rgba, "RGBA").save(target)
	return target


def normalize(source: Path, grid: str, factor: float, cell: int, out_dir: Path, name: str,
		candidate: Path | None = None, ground: bool = False, lift: int = 0) -> None:
	args = [str(PY), str(PIPE / "normalize.py"), "--sheet", str(source), "--grid", grid,
		"--bg", "#00ff00", "--cell", str(cell), "--feet-y", str(120 if cell == 128 else 152),
		"--scale-by", f"fixed:{factor:.9f}", "--resample", "lanczos", "--sharpen", "60",
		"--despill", "auto", "--palette", "none", "--reference", REFERENCE,
		"--compare-scale", "4", "--title", f"RIO MALE {name.upper()}",
		"--out-dir", str(out_dir), "--name", name]
	if candidate is not None:
		args += ["--candidate-out", str(candidate)]
	if ground:
		args += ["--ground-all"]
	if lift:
		args += ["--lift-all", str(lift)]
	run(args)


def measure(sheet: Path, frames: int, factor: float, target: Path) -> dict:
	run([str(PY), str(PIPE / "head_scale.py"), "--anchor", f"{ANCHOR}:0", "--sheet", str(sheet),
		"--frames", str(frames), "--factor", f"{factor:.9f}", "--json", str(target)])
	return json.loads(target.read_text(encoding="utf-8"))[0]


def matched_factor(source: Path, grid: str, initial: float, cell: int, row: str,
		frames: int, ground: bool = False, lift: int = 0) -> tuple[float, dict]:
	initial_dir = REPORT / row / "initial"
	initial_dir.mkdir(parents=True, exist_ok=True)
	name = f"rio_male-{row}-initial"
	normalize(source, grid, initial, cell, initial_dir, name, ground=ground, lift=lift)
	first = measure(initial_dir / f"{name}.png", frames, initial, initial_dir / "head-scale.json")
	return float(first.get("head_matched_factor") or initial), first


def save_meta(row: str, version: int = 1) -> None:
	(BAKE / f"rio_male-{row}-v{version}.json").write_text(
		json.dumps(META[row], ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def process_row(row: str, cell: int, initial: float, ground: bool, lift: int = 0) -> None:
	source = clean_grid(RAW / row / "raw.png", 1 if row == "fall" else 3,
		1 if row == "fall" else 2, RAW / row / "prepared.png")
	grid = "1x1" if row == "fall" else "3x2"
	frames = 1 if row == "fall" else 6
	factor, first = matched_factor(source, grid, initial, cell, row, frames, ground, lift)
	out = REPORT / row
	candidate = BAKE / f"rio_male-{row}-v1.png"
	normalize(source, grid, factor, cell, out, f"rio_male-{row}-v1", candidate, ground, lift)
	final = measure(candidate, frames, factor, out / "head-scale.json")
	metrics = json.loads((out / "metrics.json").read_text(encoding="utf-8"))
	metrics["head_check"] = {
		"method": "head_scale" if final.get("used", 0) >= 2 else "4x_head_crop",
		"initial": first,
		"result": final,
		"visual_note": "단일 낙하는 4배 머리 크롭도 앵커와 나란히 확인" if row == "fall" else "4배 비교판에서 확인",
	}
	(out / "metrics.json").write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
	save_meta(row)


def checker(width: int, height: int, tile: int = 16) -> Image.Image:
	image = Image.new("RGBA", (width, height), (20, 28, 40, 255))
	draw = ImageDraw.Draw(image)
	for y in range(0, height, tile):
		for x in range(0, width, tile):
			if (x // tile + y // tile) % 2:
				draw.rectangle((x, y, x + tile - 1, y + tile - 1), fill=(31, 43, 61, 255))
	return image


def walk_compare(strip: Image.Image) -> None:
	scale = 4
	anchor = Image.open(ANCHOR).convert("RGBA").crop((0, 0, 128, 128)).resize((512, 512), Image.Resampling.NEAREST)
	walk = strip.resize((strip.width * scale, strip.height * scale), Image.Resampling.NEAREST)
	board = checker(anchor.width + 32 + walk.width, 512)
	board.alpha_composite(anchor, (0, 0))
	board.alpha_composite(walk, (anchor.width + 32, 0))
	board.save(REPORT / "walk/compare.png")


def process_walk() -> None:
	work = REPORT / "walk/work"
	work.mkdir(parents=True, exist_ok=True)
	frames: list[Image.Image] = []
	factors: list[float] = []
	head_results: list[dict] = []
	frame_metrics: list[dict] = []
	for index in range(1, 9):
		source = RAW / "walk" / f"frame{index:02d}.png"
		initial_dir = work / f"f{index:02d}-initial"
		initial_name = f"rio_male-walk-f{index:02d}-initial"
		normalize(source, "1x1", .12, 128, initial_dir, initial_name, ground=True)
		first = measure(initial_dir / f"{initial_name}.png", 1, .12, initial_dir / "head-scale.json")
		factor = float(first.get("head_matched_factor") or .12)
		final_dir = work / f"f{index:02d}"
		name = f"rio_male-walk-f{index:02d}"
		normalize(source, "1x1", factor, 128, final_dir, name, ground=True)
		frame_sheet = final_dir / f"{name}.png"
		final_head = measure(frame_sheet, 1, factor, final_dir / "head-scale.json")
		with Image.open(final_dir / "frames" / f"{name}-00.png") as opened:
			frames.append(opened.convert("RGBA").copy())
		factors.append(factor)
		head_results.append(final_head)
		frame_metrics.append(json.loads((final_dir / "metrics.json").read_text(encoding="utf-8")))
	prebob = Image.new("RGBA", (8 * 128, 128), (0, 0, 0, 0))
	for index, frame in enumerate(frames):
		prebob.alpha_composite(frame, (index * 128, 0))
	prebob.save(REPORT / "walk/prebob.png")
	candidate = BAKE / "rio_male-walk-v1.png"
	run([str(PY), str(PIPE / "walk_bob.py"), "--strip", str(REPORT / "walk/prebob.png"),
		"--face", "45,30,83,67", "--out", str(candidate),
		"--report", str(REPORT / "walk/bob.json"), "--board", str(REPORT / "walk/bob.png")])
	run([str(PY), str(PIPE / "walk_feet.py"), "--strip", str(candidate),
		"--onion", str(REPORT / "walk/onion.png"), "--report", str(REPORT / "walk/feet.json")])
	with Image.open(candidate) as opened:
		final_strip = opened.convert("RGBA")
		walk_compare(final_strip)
	final_head = measure(candidate, 8, sum(factors) / len(factors), REPORT / "walk/head-scale.json")
	metrics = {
		"summary": {"frame_count": 8, "factors": factors},
		"head_check": {"method": "head_scale per generation plus 4x board", "frames": head_results, "strip": final_head},
		"bob": json.loads((REPORT / "walk/bob.json").read_text(encoding="utf-8")),
		"feet": json.loads((REPORT / "walk/feet.json").read_text(encoding="utf-8")),
		"frame_metrics": [item["summary"] for item in frame_metrics],
	}
	(REPORT / "walk/metrics.json").write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
	save_meta("walk")


def write_prompts() -> None:
	for row, prompt in PROMPTS.items():
		path = REPORT / row / "prompt.txt"
		path.parent.mkdir(parents=True, exist_ok=True)
		path.write_text(prompt.strip() + "\n", encoding="utf-8")


def main() -> None:
	write_prompts()
	targets = set(sys.argv[1:] or ("walk", "fall", "shield", "infinity_overdrive"))
	if "walk" in targets:
		process_walk()
	if "fall" in targets:
		process_row("fall", 128, .18, False, 12)
	if "shield" in targets:
		process_row("shield", 128, .23, True)
	if "infinity_overdrive" in targets:
		process_row("infinity_overdrive", 192, .28, True)


if __name__ == "__main__":
	main()
