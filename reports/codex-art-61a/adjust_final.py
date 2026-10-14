"""Final factor/offset passes after measured fit checks."""

import json

import process
import segment_process


def enrich(name: str, factor: float, method: str = "head_scale") -> None:
	out = process.REPORT / name
	candidate = process.BAKE / f"rio_male-{name}-v1.png"
	head = process.head_measure(candidate, 6, factor, out / "head-scale.json")
	metrics = json.loads((out / "metrics.json").read_text(encoding="utf-8"))
	metrics["head_check"] = {"method": method, "result": head}
	(out / "metrics.json").write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


mana_factor = .293501
segment_process.normalize_frames("mana_combo", process.RAW / "mana_combo/extracted", mana_factor, 192,
	process.REPORT / "mana_combo", process.BAKE / "rio_male-mana_combo-v1.png", True, 0, -12)
enrich("mana_combo", mana_factor)
process.write_meta("mana_combo", 18, 6, 192)

attack_factor = .22
segment_process.normalize_frames("attack", process.RAW / "mana_combo/extracted", attack_factor, 128,
	process.REPORT / "attack", process.BAKE / "rio_male-attack-v1.png", True, 0, -12)
enrich("attack", attack_factor)
metrics_path = process.REPORT / "attack/metrics.json"
metrics = json.loads(metrics_path.read_text(encoding="utf-8"))
metrics["attack_fit"] = {"source": "segmented mana_combo raw", "head_matched_factor": mana_factor,
	"used_factor": attack_factor, "reduced_to_fit": True, "common_offset_x": -12}
metrics_path.write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
process.write_meta("attack", 21, 6, 128)
