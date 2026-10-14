"""Retry only rows whose first normalization was blocked by generated background residue."""

import json

import process


failures = {}
for name, pick, lift, grounded in (("jump", 0, 12, False), ("fall", 1, 12, False), ("hurt", 2, 0, True)):
	try:
		process.process_pose(name, pick, 1, lift, grounded)
	except Exception as error:
		failures[name] = str(error)

for name in ("rising_slash", "air_slash", "dimension_slash"):
	try:
		process.process_row(name, process.ROWS[name])
	except Exception as error:
		failures[name] = str(error)

(process.REPORT / "retry-failures.json").write_text(json.dumps(failures, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
