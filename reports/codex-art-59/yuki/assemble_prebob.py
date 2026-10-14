from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "art/raw/walk-59/yuki/normalized"
OUTPUT = ROOT / "art/raw/walk-59/yuki/prebob.png"

strip = Image.new("RGBA", (1024, 128))
for index in range(8):
	path = SOURCE / f"frame-{index + 1:02d}-final.png"
	frame = Image.open(path).convert("RGBA").crop((0, 0, 128, 128))
	strip.alpha_composite(frame, (index * 128, 0))
strip.save(OUTPUT)
