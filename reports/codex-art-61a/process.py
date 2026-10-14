"""Prepare, normalize, measure, and package CODEX-ART-61A candidates."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
PY = Path("C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe")
PIPE = ROOT / "tools/sprite_pipeline"
REPORT = ROOT / "reports/codex-art-61a"
RAW = ROOT / "art/raw/rio-61a"
BAKE = ROOT / "art/bakeoff/rio"
ANCHOR = ROOT / "art/bakeoff/rio/rio_male-idle-v2.png"
REFERENCE = f"{ANCHOR}:0:6"
ENV = {**os.environ, "PYTHONDONTWRITEBYTECODE": "1"}


ROWS = {
	"shield": dict(fps=12, cell=128, initial=.23, grid="3x2", grounded=True),
	"mana_combo": dict(fps=18, cell=192, initial=.28, grid="3x2", grounded=True),
	"rising_slash": dict(fps=30, cell=192, initial=.19, grid="3x2"),
	"low_sweep": dict(fps=30, cell=192, initial=.28, grid="3x2", grounded=True),
	"air_slash": dict(fps=40, cell=192, initial=.30, grid="3x2", lift=16),
	"plunge": dict(fps=12, cell=192, initial=.27, grid="3x2"),
	"dimension_slash": dict(fps=23, cell=192, initial=.30, grid="3x2", grounded=True),
	"rune_shield": dict(fps=12, cell=192, initial=.28, grid="3x2", grounded=True),
	"infinity_overdrive": dict(fps=11, cell=192, initial=.18, grid="3x2", grounded=True),
	"tumble": dict(fps=21, cell=192, initial=.28, grid="3x2", lift=16),
}


NOTES = {
	"walk": "ART-59 회색 마네킹과 고정된 1번 의상을 따라 만든 8프레임 걷기 후보.",
	"jump": "무릎을 접고 검을 뒤로 둔 상승 단일 자세.",
	"fall": "다리를 아래로 뻗고 머리와 망토가 들린 낙하 단일 자세.",
	"hurt": "눈을 감고 뒤로 물러난 피격 단일 자세.",
	"shield": "검을 몸 앞에 올려 버티는 6프레임 방어. 장벽은 없다.",
	"attack": "mana_combo 원본을 128px 기본 공격 예비 행에 맞춘 후보.",
	"mana_combo": "빠른 베기, 되베기, 큰 수평 마무리의 3연타. 마나 파동은 없다.",
	"rising_slash": "웅크림에서 상승해 머리 위로 베고 공중에서 회복하는 6프레임.",
	"low_sweep": "낮추기, 회전, 지면 쓸기, 유지, 회복의 6프레임.",
	"air_slash": "전 프레임 공중에서 수평으로 베고 회복하는 6프레임.",
	"plunge": "공중 준비에서 검끝 하강, 착지 고정과 회복으로 이어지는 6프레임.",
	"dimension_slash": "집중, 발도, 긴 수평 베기, 제동과 회복의 6프레임. 잔상은 없다.",
	"rune_shield": "빈손 손바닥과 검으로 막고 압력을 흡수한 뒤 푸는 6프레임. 룬 원은 없다.",
	"infinity_overdrive": "집중, 검을 머리 위로 들기, 전방 명령과 회복의 6프레임. 궤도 검은 없다.",
	"tumble": "몸을 말아 뒤로 한 바퀴 도는 6프레임 공중 회전.",
}


def run(args: list[str]) -> None:
	print("RUN", " ".join(args))
	subprocess.run(args, cwd=ROOT, env=ENV, check=True)


def clean_grid(path: Path, grid: str) -> Path:
	cols, rows = (int(value) for value in grid.split("x"))
	with Image.open(path) as opened:
		rgba = np.asarray(opened.convert("RGBA"), dtype=np.uint8).copy()
	h = h0 = rgba.shape[0] - rgba.shape[0] % rows
	w = w0 = rgba.shape[1] - rgba.shape[1] % cols
	rgba = rgba[:h0, :w0]
	rgb = rgba[..., :3].astype(np.int16)
	green = np.abs(rgb[..., 0]) + np.abs(rgb[..., 1] - 255) + np.abs(rgb[..., 2]) <= 95
	rgba[..., :3][green] = (0, 255, 0)
	rgba[..., 3][green] = 255
	# Generated panel separators are layout artifacts. Replace only the narrow divider bands.
	for x in (round(i * w / cols) for i in range(1, cols)):
		lo, hi = max(0, x - 8), min(w, x + 9)
		band = rgba[:, lo:hi, :3]
		white = np.all(band >= 238, axis=2)
		if float(np.mean(white)) >= .80:
			rgba[:, lo:hi] = (0, 255, 0, 255)
	for y in (round(i * h / rows) for i in range(1, rows)):
		lo, hi = max(0, y - 8), min(h, y + 9)
		band = rgba[lo:hi, :, :3]
		white = np.all(band >= 238, axis=2)
		if float(np.mean(white)) >= .80:
			rgba[lo:hi, :] = (0, 255, 0, 255)
	# Remove only background residue at the outside edge; accepted drawings have ample margin.
	rgba[:10, :] = (0, 255, 0, 255)
	rgba[-10:, :] = (0, 255, 0, 255)
	rgba[:, :10] = (0, 255, 0, 255)
	rgba[:, -10:] = (0, 255, 0, 255)
	out = path.with_name("prepared.png")
	Image.fromarray(rgba, "RGBA").save(out)
	return out


def normalize(name: str, source: Path, grid: str, factor: float, cell: int, out_dir: Path,
		candidate: Path | None = None, pick: int | None = None, grounded: bool = False, lift: int = 0,
		offset_x: int = 0) -> None:
	args = [str(PY), str(PIPE / "normalize.py"), "--sheet", str(source), "--grid", grid,
		"--bg", "#00ff00", "--cell", str(cell), "--feet-y", str(120 if cell == 128 else 152),
		"--scale-by", f"fixed:{factor:.9f}", "--resample", "lanczos", "--sharpen", "60",
		"--despill", "auto", "--palette", "none", "--reference", REFERENCE,
		"--compare-scale", "4", "--title", f"RIO MALE {name.upper()}",
		"--out-dir", str(out_dir), "--name", f"rio_male-{name}-v1"]
	if pick is not None:
		args += ["--pick", str(pick)]
	if grounded:
		args += ["--ground-all"]
	if lift:
		args += ["--lift-all", str(lift)]
	if offset_x:
		args += ["--offset-x", str(offset_x)]
	if candidate:
		args += ["--candidate-out", str(candidate)]
	run(args)


def head_measure(sheet: Path, frames: int, factor: float, target: Path) -> dict:
	run([str(PY), str(PIPE / "head_scale.py"), "--anchor", f"{ANCHOR}:0", "--sheet", str(sheet),
		"--frames", str(frames), "--factor", f"{factor:.9f}", "--json", str(target)])
	return json.loads(target.read_text(encoding="utf-8"))[0]


def final_factor(name: str, source: Path, config: dict, pick: int | None = None) -> tuple[float, dict]:
	initial_dir = REPORT / name / "initial"
	normalize(name, source, config["grid"], config["initial"], config["cell"], initial_dir,
		pick=pick, grounded=config.get("grounded", False), lift=config.get("lift", 0))
	sheet = initial_dir / f"rio_male-{name}-v1.png"
	measure = head_measure(sheet, 1 if pick is not None else 6, config["initial"], initial_dir / "head-scale.json")
	factor = float(measure.get("head_matched_factor") or config["initial"])
	return factor, measure


def write_meta(name: str, fps: float, frames: int, cell: int) -> None:
	data = {"note": NOTES[name], "fps": fps, "frames": frames}
	if cell == 192:
		data |= {"cell": 192, "feet": 152}
	(BAKE / f"rio_male-{name}-v1.json").write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def process_pose(name: str, pick: int, fps: float, lift: int, grounded: bool) -> None:
	source = clean_grid(RAW / "jump-fall-hurt/raw.png", "3x1")
	config = dict(grid="3x1", initial=.18, cell=128, lift=lift, grounded=grounded)
	factor, first = final_factor(name, source, config, pick=pick)
	out = REPORT / name
	candidate = BAKE / f"rio_male-{name}-v1.png"
	normalize(name, source, "3x1", factor, 128, out, candidate, pick=pick, grounded=grounded, lift=lift)
	final = head_measure(candidate, 1, factor, out / "head-scale.json")
	metrics = json.loads((out / "metrics.json").read_text(encoding="utf-8"))
	metrics["head_check"] = {"method": "4x_head_crop", "automatic": final, "initial": first,
		"note": "단일 자세라 자동값과 4배 머리 비교를 함께 사용"}
	(out / "metrics.json").write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
	write_meta(name, fps, 1, 128)


def process_row(name: str, config: dict) -> None:
	source = clean_grid(RAW / name / "raw.png", config["grid"])
	factor, first = final_factor(name, source, config)
	out = REPORT / name
	candidate = BAKE / f"rio_male-{name}-v1.png"
	normalize(name, source, config["grid"], factor, config["cell"], out, candidate,
		grounded=config.get("grounded", False), lift=config.get("lift", 0))
	final = head_measure(candidate, 6, factor, out / "head-scale.json")
	metrics = json.loads((out / "metrics.json").read_text(encoding="utf-8"))
	metrics["head_check"] = {"method": "head_scale" if final.get("used", 0) >= 2 else "4x_head_crop",
		"result": final, "initial": first}
	(out / "metrics.json").write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
	write_meta(name, config["fps"], 6, config["cell"])


def process_attack() -> None:
	name = "attack"
	move_metrics = json.loads((REPORT / "mana_combo/metrics.json").read_text(encoding="utf-8"))
	factor = float(move_metrics["summary"]["common_scale"])
	source = RAW / "mana_combo/prepared.png"
	out = REPORT / name
	candidate = BAKE / "rio_male-attack-v1.png"
	used = factor
	while True:
		try:
			normalize(name, source, "3x2", used, 128, out, candidate, grounded=True)
			break
		except subprocess.CalledProcessError:
			used *= .95
			if used < factor * .70:
				raise
	final = head_measure(candidate, 6, used, out / "head-scale.json")
	metrics = json.loads((out / "metrics.json").read_text(encoding="utf-8"))
	metrics["attack_fit"] = {"source": "mana_combo raw", "head_matched_factor": factor,
		"used_factor": used, "reduced_to_fit": used < factor, "common_offset_x": 0}
	metrics["head_check"] = {"method": "head_scale", "result": final}
	(out / "metrics.json").write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
	write_meta(name, 21, 6, 128)


def process_walk() -> None:
	work = REPORT / "walk/work"
	work.mkdir(parents=True, exist_ok=True)
	frames = []
	factors = []
	for index in range(1, 9):
		source = RAW / f"walk/frame{index:02d}.png"
		initial_dir = work / f"f{index:02d}-initial"
		normalize(f"walk-f{index:02d}", source, "1x1", .10, 128, initial_dir, grounded=True)
		initial_sheet = initial_dir / f"rio_male-walk-f{index:02d}-v1.png"
		measure = head_measure(initial_sheet, 1, .10, initial_dir / "head-scale.json")
		factor = float(measure.get("head_matched_factor") or .10)
		final_dir = work / f"f{index:02d}"
		normalize(f"walk-f{index:02d}", source, "1x1", factor, 128, final_dir, grounded=True)
		frames.append(Image.open(final_dir / "frames" / f"rio_male-walk-f{index:02d}-v1-00.png").convert("RGBA"))
		factors.append(factor)
	prebob = work / "prebob.png"
	strip = Image.new("RGBA", (8 * 128, 128), (0, 0, 0, 0))
	for index, frame in enumerate(frames):
		strip.alpha_composite(frame, (index * 128, 0))
	strip.save(prebob)
	candidate = BAKE / "rio_male-walk-v1.png"
	run([str(PY), str(PIPE / "walk_bob.py"), "--strip", str(prebob), "--face", "48,18,82,52",
		"--out", str(candidate), "--report", str(REPORT / "walk/bob.json"),
		"--board", str(REPORT / "walk/bob.png")])
	run([str(PY), str(PIPE / "walk_feet.py"), "--strip", str(candidate),
		"--onion", str(REPORT / "walk/onion.png"), "--report", str(REPORT / "walk/feet.json")])
	final = head_measure(candidate, 8, sum(factors) / len(factors), REPORT / "walk/head-scale.json")
	metrics = {"summary": {"frame_count": 8, "factors": factors}, "head_check": final,
		"bob": json.loads((REPORT / "walk/bob.json").read_text(encoding="utf-8")),
		"feet": json.loads((REPORT / "walk/feet.json").read_text(encoding="utf-8"))}
	(REPORT / "walk/metrics.json").write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
	write_meta("walk", 13.3, 8, 128)


def write_prompts() -> None:
	for name in ["walk", "jump", "fall", "hurt", "shield", "attack", *ROWS.keys()]:
		path = REPORT / name / "prompt.txt"
		path.parent.mkdir(parents=True, exist_ok=True)
		path.write_text(NOTES[name] + "\n내장 ImageGen에 앵커와 기존 동작 참조를 함께 제공하고 카드의 금지 이펙트를 모두 제외했다.\n", encoding="utf-8")


def main() -> None:
	write_prompts()
	failures = {}
	try:
		process_walk()
	except Exception as error:
		failures["walk"] = str(error)
	for name, pick, lift, grounded in (("jump", 0, 12, False), ("fall", 1, 12, False), ("hurt", 2, 0, True)):
		try:
			process_pose(name, pick, 1, lift, grounded)
		except Exception as error:
			failures[name] = str(error)
	for name, config in ROWS.items():
		try:
			process_row(name, config)
		except Exception as error:
			failures[name] = str(error)
	try:
		process_attack()
	except Exception as error:
		failures["attack"] = str(error)
	(REPORT / "failures.json").write_text(json.dumps(failures, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
	main()
