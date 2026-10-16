"""Build the Rio head-scale comparison board used by QA-19."""
from __future__ import annotations

import importlib.util
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[3]


def load_audit():
	path = Path(__file__).with_name("audit_assets.py")
	spec = importlib.util.spec_from_file_location("qa19_audit", path)
	module = importlib.util.module_from_spec(spec)
	assert spec.loader is not None
	spec.loader.exec_module(module)
	return module


def get_frame(audit, form: str, sheet: str, row_name: str, index: int):
	cfg = audit.FORMS[form]
	path = cfg[sheet]
	specs = audit.BASE_ROWS if sheet == "base" else audit.MOVE_ROWS[cfg["prefix"]]
	cell = 128 if sheet == "base" else 192
	row = next(r for r in audit.split_rows(path, specs, cell) if r[0] == row_name)
	return row[-1][index]


def main() -> None:
	audit = load_audit()
	items = [
		("GOOD male idle / 1.00", "rio_male", "base", "idle", 0),
		("PROBLEM male base attack / 0.76", "rio_male", "base", "attack", 2),
		("GOOD female idle / 1.02", "rio_female", "base", "idle", 0),
		("PROBLEM female base attack / 0.86", "rio_female", "base", "attack", 2),
		("GOOD female mana combo / 1.00", "rio_female", "moves", "mana_combo", 2),
		("PROBLEM female low sweep / 0.72", "rio_female", "moves", "low_sweep", 2),
		("GOOD female rune shield / 1.00", "rio_female", "moves", "rune_shield", 2),
		("PROBLEM female dimension slash / 0.72", "rio_female", "moves", "dimension_slash", 2),
	]
	tile = 600; label_h = 32
	board = audit.checker((tile * 4, (tile + label_h) * 2), 16)
	draw = ImageDraw.Draw(board)
	for i, (label, form, sheet, row, frame) in enumerate(items):
		image = get_frame(audit, form, sheet, row, frame)
		bbox = image.getbbox()
		crop = image.crop(bbox)
		scale = 3
		crop = crop.resize((crop.width * scale, crop.height * scale), Image.Resampling.NEAREST)
		x = (i % 4) * tile; y = (i // 4) * (tile + label_h)
		draw.text((x + 6, y + 7), label, font=audit.FONT_SMALL, fill=(255, 232, 150, 255))
		board.alpha_composite(crop, (x + (tile - crop.width) // 2, y + label_h + (tile - crop.height) // 2))
	board.convert("RGB").save(ROOT / "reports/codex-qa-19/boards/rio-head-scale-3x.png", optimize=True)


if __name__ == "__main__":
	main()
