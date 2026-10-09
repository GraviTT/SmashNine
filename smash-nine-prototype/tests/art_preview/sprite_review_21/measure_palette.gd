extends SceneTree

const CELL := 128
const USED := [4, 6, 1, 1, 4, 6, 1]
const SHEETS := {
	"frey": "res://assets/art/frey/frey_sheet.png",
	"luna": "res://assets/art/luna/luna_sheet.png",
	"luna_brave": "res://assets/art/luna/luna_brave_sheet.png",
}

func _initialize() -> void:
	var report := ProjectSettings.globalize_path("res://../reports/codex-art-21")
	var lines: Array[String] = ["sheet,rank,quantized_rgb,pixels,percent"]
	for sheet_name in SHEETS:
		var image := Image.load_from_file(ProjectSettings.globalize_path(SHEETS[sheet_name]))
		image.convert(Image.FORMAT_RGBA8)
		var counts := {}
		var total := 0
		for row in 7:
			for column in USED[row]:
				for y in CELL:
					for x in CELL:
						var color := image.get_pixel(column * CELL + x, row * CELL + y)
						if color.a < 0.5:
							continue
						var r := mini(7, int(color.r * 8.0))
						var g := mini(7, int(color.g * 8.0))
						var b := mini(7, int(color.b * 8.0))
						var key := r * 64 + g * 8 + b
						counts[key] = int(counts.get(key, 0)) + 1
						total += 1
		var keys := counts.keys()
		keys.sort_custom(func(a, b): return int(counts[a]) > int(counts[b]))
		for rank in mini(12, keys.size()):
			var key: int = keys[rank]
			var r := (key / 64) as int
			var g := ((key % 64) / 8) as int
			var b := key % 8
			var rgb := "#%02X%02X%02X" % [r * 32 + 16, g * 32 + 16, b * 32 + 16]
			lines.append("%s,%d,%s,%d,%.2f" % [sheet_name, rank + 1, rgb, counts[key], 100.0 * counts[key] / total])
	var file := FileAccess.open(report.path_join("palette_summary.csv"), FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	print("ART21_PALETTE sheets=3 bins=8x8x8 top=12")
	quit(0)
