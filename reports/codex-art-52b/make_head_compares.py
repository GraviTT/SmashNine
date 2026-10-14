from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
REPORT = Path(__file__).resolve().parent


def checker(size: tuple[int, int]) -> Image.Image:
	image = Image.new("RGBA", size, (28, 36, 52, 255))
	draw = ImageDraw.Draw(image)
	for y in range(0, size[1], 8):
		for x in range(0, size[0], 8):
			if (x // 8 + y // 8) % 2:
				draw.rectangle((x, y, x + 7, y + 7), fill=(38, 48, 68, 255))
	return image


def crop_on_checker(image: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
	crop = image.crop(box)
	back = checker(crop.size)
	back.alpha_composite(crop)
	return back


anchor_sheet = Image.open(ROOT / "art/bakeoff/nova/nova_female-idle-v2.png").convert("RGBA")
anchor = crop_on_checker(anchor_sheet.crop((0, 0, 128, 128)), (35, 28, 99, 92))

for row, box in (("jump", (28, 28, 92, 92)), ("fall", (30, 4, 94, 68))):
	pose_sheet = Image.open(ROOT / f"art/bakeoff/nova/nova_female-{row}-v1.png").convert("RGBA")
	pose = crop_on_checker(pose_sheet, box)
	panel = Image.new("RGBA", (128, 64), (0, 0, 0, 0))
	panel.alpha_composite(anchor, (0, 0))
	panel.alpha_composite(pose, (64, 0))
	panel.resize((512, 256), Image.Resampling.NEAREST).save(REPORT / f"{row}/head_compare.png")

hurt_sheet = Image.open(ROOT / "art/bakeoff/nova/nova_female-hurt-v1.png").convert("RGBA")
hurt = crop_on_checker(hurt_sheet, (16, 28, 80, 92))
hurt_panel = Image.new("RGBA", (128, 64), (0, 0, 0, 0))
hurt_panel.alpha_composite(anchor, (0, 0))
hurt_panel.alpha_composite(hurt, (64, 0))
hurt_panel.resize((512, 256), Image.Resampling.NEAREST).save(REPORT / "hurt/head_compare.png")

tumble_sheet = Image.open(ROOT / "art/bakeoff/nova/nova_female-tumble-v1.png").convert("RGBA")
tumble_f0 = crop_on_checker(tumble_sheet.crop((0, 0, 192, 192)), (55, 64, 119, 128))
tumble_f5 = crop_on_checker(tumble_sheet.crop((192 * 5, 0, 192 * 6, 192)), (60, 60, 124, 124))
tumble_panel = Image.new("RGBA", (192, 64), (0, 0, 0, 0))
tumble_panel.alpha_composite(anchor, (0, 0))
tumble_panel.alpha_composite(tumble_f0, (64, 0))
tumble_panel.alpha_composite(tumble_f5, (128, 0))
tumble_panel.resize((768, 256), Image.Resampling.NEAREST).save(REPORT / "tumble/head_compare.png")
