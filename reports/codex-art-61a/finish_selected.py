"""Finish rows that need a common x shift or the card's explicit visual-head fallback."""

import json
import subprocess

import process
import segment_process


def enrich(name: str, method: str, factor: float, frames: int = 6) -> None:
	out = process.REPORT / name
	candidate = process.BAKE / f"rio_male-{name}-v1.png"
	head = process.head_measure(candidate, frames, factor, out / "head-scale.json")
	metrics = json.loads((out / "metrics.json").read_text(encoding="utf-8"))
	metrics["head_check"] = {"method": method, "result": head,
		"note": "자동 신뢰 프레임이 2개 미만이라 앵커 옆 4배 비교를 사용" if method == "4x_head_crop" else "점수 0.6 이상 자동 중앙값"}
	(out / "metrics.json").write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def shield() -> None:
	factor = .267442
	process.normalize("shield", process.RAW / "shield/prepared.png", "3x2", factor, 128,
		process.REPORT / "shield", process.BAKE / "rio_male-shield-v1.png", grounded=True, offset_x=-6)
	enrich("shield", "head_scale", factor)
	process.write_meta("shield", 12, 6, 128)


def mana() -> None:
	segment_process.do_row("mana_combo", .28, 192, True, 0, 18, -12)


def plunge() -> None:
	factor = .27
	process.normalize("plunge", process.RAW / "plunge/prepared.png", "3x2", factor, 192,
		process.REPORT / "plunge", process.BAKE / "rio_male-plunge-v1.png")
	enrich("plunge", "4x_head_crop", factor)
	process.write_meta("plunge", 12, 6, 192)


def attack() -> None:
	frames = process.RAW / "mana_combo/extracted"
	head_factor = json.loads((process.REPORT / "mana_combo/metrics.json").read_text(encoding="utf-8"))["summary"]["common_scale"]
	used = head_factor
	while used >= head_factor * .70:
		try:
			segment_process.normalize_frames("attack", frames, used, 128, process.REPORT / "attack",
				process.BAKE / "rio_male-attack-v1.png", True, 0, -6)
			break
		except subprocess.CalledProcessError:
			used -= .005
	else:
		raise RuntimeError("attack did not fit at the card's minimum practical factor")
	enrich("attack", "head_scale", used)
	metrics_path = process.REPORT / "attack/metrics.json"
	metrics = json.loads(metrics_path.read_text(encoding="utf-8"))
	metrics["attack_fit"] = {"source": "segmented mana_combo raw", "head_matched_factor": head_factor,
		"used_factor": used, "reduced_to_fit": used < head_factor, "common_offset_x": -6}
	metrics_path.write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
	process.write_meta("attack", 21, 6, 128)


failures = {}
for name, action in (("shield", shield), ("mana_combo", mana), ("plunge", plunge), ("attack", attack)):
	try:
		action()
	except Exception as error:
		failures[name] = str(error)
(process.REPORT / "finish-failures.json").write_text(json.dumps(failures, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
