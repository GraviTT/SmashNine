"""Builds the game's UI font: Noto Sans KR at weight 500, cut down to the characters the game needs.

User 2026-10-22: "폰트 부분 글꼴로 줄이는 것도 진행해" (the full variable font was 10.4 MB in the
web build). Kept characters:
  - ASCII, Latin-1, general punctuation, arrows and a few symbols
  - Hangul compatibility jamo and the 2,350 KS X 1001 syllables (everyday Korean)
  - every character in assets/i18n/strings.csv and in the game's .gd files (so a rare syllable
    used by a translation is never missing)

Run it again after adding Korean text (tests/test_font_coverage.gd fails when a character in
the translation table is missing from the font):

  python -m venv fontenv && fontenv/Scripts/python -m pip install fonttools
  fontenv/Scripts/python tools/font_subset/make_ui_font.py [path/to/NotoSansKR-VF.ttf]

The source is the Noto Sans KR variable font (SIL OFL 1.1; on this PC in C:/Windows/Fonts).
"""

import pathlib
import sys

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROOT = pathlib.Path(__file__).resolve().parents[2]
PROJECT = ROOT / "smash-nine-prototype"
SOURCE = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path("C:/Windows/Fonts/NotoSansKR-VF.ttf")
OUTPUT = PROJECT / "assets" / "fonts" / "NotoSansKR-UI.ttf"
WEIGHT = 500


def wanted_codepoints() -> set[int]:
	codes: set[int] = set()
	ranges = [
		(0x20, 0x7E),  # ASCII
		(0xA0, 0xFF),  # Latin-1 supplement (·, ×, accents)
		(0x2010, 0x2027),  # dashes, quotes, bullet, ellipsis
		(0x2030, 0x203A),  # per mille, primes, angle quotes
		(0x2190, 0x2199),  # arrows
		(0x3131, 0x318E),  # Hangul compatibility jamo
	]
	for low, high in ranges:
		codes.update(range(low, high + 1))
	codes.update([0x20A9, 0x2122, 0x2605, 0x2606, 0x25B2, 0x25B6, 0x25BC, 0x25C0, 0x3000, 0x3001, 0x3002, 0x300C, 0x300D])
	# The 2,350 syllables of KS X 1001 are the ones EUC-KR writes in two bytes (Python's codec
	# also writes every other syllable as an 8-byte jamo sequence, which must not count).
	for code in range(0xAC00, 0xD7A4):
		try:
			if len(chr(code).encode("euc-kr")) == 2:
				codes.add(code)
		except UnicodeEncodeError:
			pass
	# Everything the game actually writes.
	sources = [PROJECT / "assets" / "i18n" / "strings.csv"]
	for folder in ("scripts", "characters"):
		sources.extend((PROJECT / folder).rglob("*.gd"))
	for path in sources:
		for char in path.read_text(encoding="utf-8"):
			if ord(char) >= 0x20:
				codes.add(ord(char))
	return codes


def main() -> None:
	font = TTFont(SOURCE)
	static = instancer.instantiateVariableFont(font, {"wght": WEIGHT})
	codes = wanted_codepoints()
	options = subset.Options()
	options.hinting = False
	options.desubroutinize = True
	options.layout_features = ["kern", "liga", "calt", "ccmp", "locl", "mark", "mkmk"]
	options.name_IDs = ["*"]
	options.name_languages = ["*"]
	subsetter = subset.Subsetter(options=options)
	subsetter.populate(unicodes=codes)
	subsetter.subset(static)
	OUTPUT.parent.mkdir(parents=True, exist_ok=True)
	static.save(OUTPUT)
	kept = len(static.getBestCmap())
	print(f"{OUTPUT.relative_to(ROOT)}: {OUTPUT.stat().st_size / 1024:.0f} KB, {kept} characters, weight {WEIGHT}")


if __name__ == "__main__":
	main()
