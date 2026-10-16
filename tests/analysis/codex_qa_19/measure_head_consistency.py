"""Measure each row's head scale against that form's idle frame 1.

This uses the project's D34 multi-scale template matcher.  One representative
frame is sampled per row (strike/third where available, otherwise first); low-score
matches are retained but explicitly marked unusable rather than guessed.
"""
from __future__ import annotations

import importlib.util
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]


def load_module(path: Path, name: str):
	spec = importlib.util.spec_from_file_location(name, path)
	module = importlib.util.module_from_spec(spec)
	assert spec.loader is not None
	spec.loader.exec_module(module)
	return module


def main() -> None:
	audit = load_module(Path(__file__).with_name("audit_assets.py"), "qa19_audit")
	head = load_module(ROOT / "tools/sprite_pipeline/head_scale.py", "head_scale")
	result = {
		"method": "D34 head_scale.py template match; anchor is each form idle frame 1; sample strike frame 3 when available, otherwise frame 1; score >=0.6 is accepted",
		"forms": {},
	}
	for form, cfg in audit.FORMS.items():
		base_rows = list(audit.split_rows(cfg["base"], audit.BASE_ROWS, 128))
		anchor = base_rows[0][-1][0]
		template = head.head_template(anchor)
		rows = []
		for sheet_name, path, specs, cell in (
			("base", cfg["base"], audit.BASE_ROWS, 128),
			("moves", cfg["moves"], audit.MOVE_ROWS[cfg["prefix"]], 192),
		):
			for row_name, count, _fps, _loop, physical_row, frames in audit.split_rows(path, specs, cell):
				samples = []
				for index in [min(2, count - 1)]:
					scale, score = head.head_scale(frames[index], template)
					samples.append({
						"frame_zero_based": index,
						"relative_head_scale": scale,
						"score": round(score, 3),
						"accepted": bool(scale is not None and score >= 0.6),
					})
				accepted = [s["relative_head_scale"] for s in samples if s["accepted"]]
				rows.append({
					"sheet": sheet_name, "row": row_name, "physical_row_zero_based": physical_row,
					"samples": samples,
					"accepted_range": [min(accepted), max(accepted)] if accepted else None,
				})
		result["forms"][form] = {"target_heads_tall": cfg["ratio_target"], "rows": rows}
	out = ROOT / "reports/codex-qa-19/head_scale_measurements.json"
	out.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
	print(json.dumps({form: {"rows": len(data["rows"]), "accepted": sum(r["accepted_range"] is not None for r in data["rows"])} for form, data in result["forms"].items()}, indent=2))


if __name__ == "__main__":
	main()
