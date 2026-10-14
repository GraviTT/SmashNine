"""Process the card-permitted second generation for rows that failed once."""

import json

import process


process.ROWS["rising_slash"]["initial"] = .22
process.ROWS["low_sweep"]["initial"] = .28
process.ROWS["air_slash"]["initial"] = .28
process.ROWS["dimension_slash"]["initial"] = .28
process.ROWS["infinity_overdrive"]["initial"] = .23

failures = {}
for name, pick, lift, grounded in (("jump", 0, 12, False), ("fall", 1, 12, False), ("hurt", 2, 0, True)):
	try:
		process.process_pose(name, pick, 1, lift, grounded)
	except Exception as error:
		failures[name] = str(error)

for name in ("shield", "mana_combo", "rising_slash", "low_sweep", "air_slash", "dimension_slash", "infinity_overdrive"):
	try:
		process.process_row(name, process.ROWS[name])
	except Exception as error:
		failures[name] = str(error)

try:
	process.process_attack()
except Exception as error:
	failures["attack"] = str(error)

(process.REPORT / "retry2-failures.json").write_text(json.dumps(failures, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
