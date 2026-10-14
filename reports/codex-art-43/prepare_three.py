from pathlib import Path
import sys

from PIL import Image


source = Path(sys.argv[1])
output = Path(sys.argv[2])
with Image.open(source).convert("RGB") as image:
	cell_width = (image.width + 2) // 3
	prepared = Image.new("RGB", (cell_width * 3, image.height), (0, 255, 0))
	for index in range(3):
		left = round(index * image.width / 3)
		right = round((index + 1) * image.width / 3)
		part = image.crop((left, 0, right, image.height))
		prepared.paste(part, (index * cell_width, 0))
	prepared.save(output)
