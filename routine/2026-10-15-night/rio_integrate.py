"""Put the redrawn Rio (both bodies) into the game: sheets, row tables, tests, move READMEs.

Picks the highest non-retired version of every row candidate unless overridden:
  python rio_integrate.py [--pick rio_female-walk=v3 ...] [--dry]
"""
import argparse
import json
import re
import subprocess
from pathlib import Path

M = Path(r"C:/Users/TH/Documents/AI/GameProject/SmashNine")
G = M / "smash-nine-prototype"
BAKE = M / "art/bakeoff/rio"
PY = r"C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe"
BASE = ["idle", "walk", "jump", "fall", "attack", "shield", "hurt"]
MOVES = [("mana_combo", 6, 18.0, False), ("rising_slash", 6, 30.0, False), ("low_sweep", 6, 30.0, False),
	("air_slash", 6, 40.0, False), ("plunge", 6, 12.0, False), ("dimension_slash", 6, 23.0, False),
	("rune_shield", 6, 12.0, False), ("infinity_overdrive", 6, 11.0, False), ("tumble", 6, 21.0, True)]


def latest(stem: str, row: str, picks: dict) -> Path:
	key = f"{stem}-{row}"
	if key in picks: return BAKE / f"{key}-{picks[key]}.png"
	found = [(int(m.group(1)), p) for p in BAKE.glob(f"{key}-v*.png") if (m := re.fullmatch(rf"{re.escape(key)}-v(\d+)\.png", p.name))]
	if not found: raise SystemExit(f"no candidate for {key}")
	return max(found)[1]


def sub(path: Path, old: str, new: str) -> None:
	s = path.read_text(encoding="utf-8")
	assert s.count(old) == 1, (path.name, old[:70], s.count(old)); path.write_text(s.replace(old, new), encoding="utf-8")


def main() -> None:
	ap = argparse.ArgumentParser(); ap.add_argument("--pick", nargs="*", default=[]); ap.add_argument("--dry", action="store_true")
	args = ap.parse_args(); picks = dict(p.split("=") for p in args.pick)
	chosen = {}
	for body in ("male", "female"):
		stem = f"rio_{body}"
		chosen[stem] = {"base": [latest(stem, r, picks) for r in BASE], "moves": [latest(stem, r, picks) for r, *_ in MOVES]}
		for p in chosen[stem]["base"] + chosen[stem]["moves"]: print(stem, p.name)
	if args.dry: return
	for stem, c in chosen.items():
		subprocess.run([PY, str(M / "tools/sprite_pipeline/assemble.py"), "--cell", "128", "--out", str(G / f"assets/art/rio/{stem}_sheet.png"), *map(str, c["base"])], check=True)
		subprocess.run([PY, str(M / "tools/sprite_pipeline/assemble.py"), "--cell", "192", "--out", str(G / f"assets/art/rio/{stem}_moves_sheet.png"), *map(str, c["moves"])], check=True)
		for p in c["base"] + c["moves"]:
			meta = p.with_suffix(".json"); d = json.loads(meta.read_text(encoding="utf-8")) if meta.exists() else {}
			d["adopted"] = "2026-10-15"; meta.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
	labels = {"mana_combo": "ground J chain: slash, backhand, finisher (the game plays 1–2, 3–4, 5–6)", "rising_slash": "up J, air up J: a rising overhead cut",
		"low_sweep": "ground down J: a low sweep", "air_slash": "aerial side J: a horizontal cut", "plunge": "aerial down J: a diving plunge",
		"dimension_slash": "K: the blink slash", "rune_shield": "L: the rune shield guard", "infinity_overdrive": "ultimate start: sword raised, command",
		"tumble": "**new** strong-launch hitstun"}
	base_fps = {"idle": "6.3 (D37)", "walk": "13.3, two sheet rows", "jump": "1", "fall": "1", "attack": "21", "shield": "12", "hurt": "1"}
	base_frames = {"idle": 6, "walk": 8, "jump": 1, "fall": 1, "attack": 6, "shield": 6, "hurt": 1}
	for stem, c in chosen.items():
		body = stem.split("_")[1]
		lines = [f"# Rio {body} sheets (redrawn 2026-10-15, D33–D37)", "",
			f"Both sheets were rebuilt from the candidates in `art/bakeoff/rio/{stem}-*` (cards `design/tasks/CODEX-ART-60.md`, `CODEX-ART-61.md`, `CODEX-ART-64.md`; night routine `routine/2026-10-15-night/`) with `tools/sprite_pipeline/assemble.py`, pixel for pixel. The method is the Frey method (`reports/frey-rework-2026-10-14.md`); the walk is the 8-frame walk (`reports/walk-8frame-2026-10-15.md`).", "",
			f"## `{stem}_sheet.png`: base sheet (128 px, feet y=120, rows `Rio.SHEET_ROWS`, shared by both bodies)", "",
			"| Row | Frames | FPS | Source |", "| --- | ---: | ---: | --- |"]
		for row, path in zip(BASE, c["base"]):
			lines.append(f"| {row} | {base_frames[row]} | {base_fps[row]} | `{path.stem}`{' (the anchor, 3 heads)' if row == 'idle' else ': a fallback only' if row == 'attack' else ''} |")
		lines += ["", f"## `{stem}_moves_sheet.png`: move sheet (192 px, feet y=152, D34)", "", "| Row | Frames | FPS | Move | Source |", "| --- | ---: | ---: | --- | --- |"]
		for (row, frames, fps, loop), path in zip(MOVES, c["moves"]):
			lines.append(f"| `{row}` | {frames} | {fps:g}{', loop' if loop else ''} | {labels[row]} | `{path.stem}` |")
		(G / f"assets/art/rio/{stem}_moves_README.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
	rio = G / "characters/rio/Rio.gd"
	s = rio.read_text(encoding="utf-8")
	start = s.index("const MOVE_SHEET_ROWS := ["); end = s.index("]\n", s.index("[", start + 25)) + 2
	moves = "\n".join(f'\t["{n}", {f}, {fps}, {str(loop).lower()}],' for n, f, fps, loop in MOVES)
	block = ("## Redrawn 2026-10-15 for both bodies (D33-D37): every motion is 6 frames with its old length\n"
		"## (fps x 6 / old frames), the idle at 6.3 fps (D37), the walk 8 frames at 13.3 fps (two sheet rows).\n"
		"## The base `attack` row is only a fallback (J plays mana_combo).\n"
		'const SHEET_ROWS := [["idle", 6, 6.3, true], ["walk", 8, 13.3, true], ["jump", 1, 1.0, false], ["fall", 1, 1.0, false], ["attack", 6, 21.0, false], ["shield", 6, 12.0, false], ["hurt", 1, 1.0, false]]\n'
		"## 192-px cells (D34). `tumble` is new for Rio: strong launches play it instead of the hurt frame.\n"
		f"const MOVE_SHEET_ROWS := [\n{moves}\n]\n")
	s = s[:start] + block + s[end:]
	s = s.replace("func get_move_sheet_rows() -> Array:\n\treturn MOVE_SHEET_ROWS\n", "func get_move_sheet_rows() -> Array:\n\treturn MOVE_SHEET_ROWS\n\nfunc get_sheet_rows() -> Array:\n\treturn SHEET_ROWS\n", 1)
	rio.write_text(s, encoding="utf-8")
	t = G / "tests/test_frey_sprite.gd"
	sub(t, 'const SHARED_LAYOUT := {"idle": 4, "walk": 6, "jump": 1, "fall": 1, "attack": 4, "shield": 6, "hurt": 1}\n', "")
	sub(t, '"rio": SHARED_LAYOUT', '"rio": FREY_LAYOUT')
	sub(t, "## and Brave Luna, Yuki, Nova (both bodies).", "## and Brave Luna, Yuki, Nova and Rio (both bodies each).")
	t = G / "tests/test_sprite_frames.gd"
	sub(t, '"nova_female_sheet.png": [6, 6, 2, 1, 1, 6, 6, 1]}', '"nova_female_sheet.png": [6, 6, 2, 1, 1, 6, 6, 1], "rio_male_sheet.png": [6, 6, 2, 1, 1, 6, 6, 1], "rio_female_sheet.png": [6, 6, 2, 1, 1, 6, 6, 1]}')
	t = G / "tests/test_moves_sheet.gd"
	sub(t, '\t\t\t\t"infinity_overdrive": fighter.perform_ultimate()\n',
		'\t\t\t\t"infinity_overdrive": fighter.perform_ultimate()\n\t\t\t\t# New for Rio (2026-10-15): a strong launch plays the tumble row.\n'
		'\t\t\t\t"tumble": fighter.apply_forced_launch_hit(null, 1.0, Vector2(620.0, -260.0), 0.25, 620.0, Vector2.RIGHT)\n')
	print("integrated")


if __name__ == "__main__":
	main()
