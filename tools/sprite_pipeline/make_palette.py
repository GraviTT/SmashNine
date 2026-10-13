#!/usr/bin/env python3
"""Write a lossless RGB palette collected from an existing character sheet."""

from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path

from PIL import Image


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("sheet", type=Path)
	parser.add_argument("--id", required=True, help="frey, luna, luna_brave, nova_male, nova_female, rio_male, rio_female, or yuki")
	parser.add_argument("--out-dir", type=Path, default=Path(__file__).with_name("palettes"))
	parser.add_argument("--max-colors", type=int, default=192, help="most-used opaque sheet colours to keep")
	args = parser.parse_args()
	image = Image.open(args.sheet).convert("RGBA")
	counts = Counter(pixel[:3] for pixel in image.get_flattened_data() if pixel[3] >= 128)
	if not counts:
		raise SystemExit("sheet has no opaque colours")
	args.out_dir.mkdir(parents=True, exist_ok=True)
	out = args.out_dir / f"{args.id}.json"
	selected = counts.most_common(args.max_colors)
	payload = {
		"id": args.id,
		"source": args.sheet.as_posix(),
		"source_unique_colours": len(counts),
		"count": len(selected),
		"colors": [{"rgb": list(rgb), "pixels": count} for rgb, count in selected],
	}
	out.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
	print(f"palette {args.id}: {len(selected)} of {len(counts)} source colours -> {out}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
