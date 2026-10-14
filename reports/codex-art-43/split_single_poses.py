from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
source = ROOT / "art" / "raw" / "luna-43" / "luna-jump-fall-hurt-normalized-01.png"
output = ROOT / "art" / "bakeoff" / "luna"
names = ("luna-jump-v1.png", "luna-fall-v1.png", "luna-hurt-v1.png")

with Image.open(source).convert("RGBA") as strip:
	for index, name in enumerate(names):
		strip.crop((index * 128, 0, (index + 1) * 128, 128)).save(output / name)
