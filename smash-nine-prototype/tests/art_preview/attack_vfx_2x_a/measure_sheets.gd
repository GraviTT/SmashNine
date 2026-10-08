extends SceneTree

const CELL := 128
const FILES := [
	"res://assets/art/rio/rio_male_sheet.png",
	"res://assets/art/rio/rio_female_sheet.png",
	"res://assets/art/frey/frey_sheet.png",
]

func _initialize() -> void:
	for path in FILES:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		image.convert(Image.FORMAT_RGBA8)
		print("SHEET ", path)
		for row in [0, 4, 5]:
			var count := 4 if row != 5 else 6
			var parts: Array[String] = []
			for column in count:
				var frame := image.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
				var rect := frame.get_used_rect()
				parts.append("c%d=%s feet=%d body=%s" % [column, rect, rect.end.y - 1, _dark_rect(frame)])
			print(" r%d " % row + " | ".join(parts))
	quit(0)

func _dark_rect(image: Image) -> Rect2i:
	var out := Image.create_empty(CELL, CELL, false, Image.FORMAT_RGBA8)
	for y in CELL:
		for x in CELL:
			var c := image.get_pixel(x, y)
			if c.a >= 0.5 and c.get_luminance() < 0.48:
				out.set_pixel(x, y, Color.WHITE)
	return out.get_used_rect()
