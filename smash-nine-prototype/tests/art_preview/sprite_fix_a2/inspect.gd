extends SceneTree

const ROWS := 7
const ALPHA_CUT := 56

const SOURCES := {
	"rio_female": "res://assets/art/rio/rio_female_v2_rework_source.png",
	"frey": "res://assets/art/frey/frey_v2_source.png",
	"nova_female": "res://assets/art/nova/nova_female_v2_source.png",
}

func _initialize() -> void:
	var out_dir := ProjectSettings.globalize_path("res://tests/art_preview/sprite_fix_a2/inspect")
	DirAccess.make_dir_recursive_absolute(out_dir)
	for id: String in SOURCES:
		var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCES[id]))
		image.convert(Image.FORMAT_RGBA8)
		var bounds := _row_boundaries(image)
		print("INSPECT %s size=%s bounds=%s" % [id, image.get_size(), bounds])
		for row in [4, 5]:
			if (id == "frey" or id == "nova_female") and row == 5:
				continue
			var y0: int = bounds[row]
			var y1: int = bounds[row + 1]
			var span := _occupied_span(image, y0, y1)
			print("  %s r%d span=%s" % [id, row, span])
			var crop := image.get_region(Rect2i(0, y0, image.get_width(), y1 - y0))
			crop.resize(crop.get_width() * 2, crop.get_height() * 2, Image.INTERPOLATE_NEAREST)
			crop.save_png(out_dir.path_join("%s_source_r%d_2x.png" % [id, row]))
			var grid := crop.duplicate()
			for source_x in range(0, image.get_width(), 25):
				var color := Color(1.0, 0.2, 0.2, 0.55) if source_x % 100 == 0 else Color(1.0, 0.85, 0.15, 0.35)
				for y in grid.get_height():
					grid.set_pixel(source_x * 2, y, color)
			grid.save_png(out_dir.path_join("%s_source_r%d_grid_2x.png" % [id, row]))
	quit()

func _occupied_span(image: Image, y0: int, y1: int) -> Vector2i:
	var first := image.get_width()
	var last := -1
	for x in image.get_width():
		for y in range(y0, y1):
			if image.get_pixel(x, y).a8 >= ALPHA_CUT:
				first = mini(first, x)
				last = maxi(last, x)
				break
	return Vector2i(first, last)

func _row_boundaries(image: Image) -> PackedInt32Array:
	var w := image.get_width()
	var h := image.get_height()
	var counts := PackedInt32Array()
	counts.resize(h)
	for y in h:
		var count := 0
		for x in w:
			if image.get_pixel(x, y).a8 >= ALPHA_CUT:
				count += 1
		counts[y] = count
	var boundaries := PackedInt32Array([0])
	var radius := maxi(24, roundi(float(h) / 18.0))
	for split in range(1, ROWS):
		var expected := roundi(float(split) * h / ROWS)
		var best := expected
		for y in range(maxi(1, expected - radius), mini(h - 1, expected + radius + 1)):
			if counts[y] < counts[best] or (counts[y] == counts[best] and absi(y - expected) < absi(best - expected)):
				best = y
		boundaries.append(best)
	boundaries.append(h)
	return boundaries
