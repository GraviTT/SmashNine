from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
REPORT = Path(__file__).resolve().parent / "walk"
CELL = 128
SOURCES = [
	REPORT / "frame-01-attempt2/frame-01.png",
	REPORT / "frame-02/frame-02.png",
	REPORT / "frame-03-finaltry/frame-03.png",
	REPORT / "frame-04-finaltry/frame-04.png",
	REPORT / "frame-05-attempt3/frame-05.png",
	REPORT / "frame-06-finaltry/frame-06.png",
	REPORT / "frame-07-finaltry/frame-07.png",
	REPORT / "frame-08-finaltry/frame-08.png",
]


strip = Image.new("RGBA", (CELL * 8, CELL))
for index, source in enumerate(SOURCES):
	frame = Image.open(source).convert("RGBA").crop((0, 0, CELL, CELL))
	strip.alpha_composite(frame, (index * CELL, 0))
strip.save(REPORT / "prebob.png")
