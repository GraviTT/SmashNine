extends SceneTree

const RealmCatalog = preload("res://scripts/realms/RealmCatalog.gd")

const CONFIG := {
	"center": {
		"size": Vector2i(2880, 1620),
		"palette": "080611 0D0A19 121026 18132F 20163A 291B46 342252 412A61 513270 65417E 79518D 91609A A64AA4 BD5FBA D47BCE E79CDD 29466D 376486 4F83A0 68A7B9 7B633F A47D4D C79B61 E0BD7B",
		"band": 0.82,
	},
	"asgard": {
		"size": Vector2i(1920, 1080),
		"palette": "07101B 0D1928 142438 1D3045 263B51 314B62 45627A 59758B 71899B 8DA9B8 A9B8BF D1D5CF 805B2E A87534 C88D3D D69A42 E3AD55 F0C06C",
		"band": 0.80,
	},
	"midgard": {
		"size": Vector2i(1920, 1080),
		"palette": "140F0B 211611 2A1D16 38261D 493126 5D3A2B 744638 91583B AD6D3D C78447 D99B52 E3AD62 34444A 4D6065 687A80 89979A 102016 1B3421 2D4A2C 45633A 658052 B19A55",
		"band": 0.82,
	},
	"niflheim": {
		"size": Vector2i(1920, 1080),
		"palette": "06131A 081D27 0C2733 123442 174052 205268 2F6577 417B8B 5793A1 6FA8B4 89BAC2 A9CDD2 C6E1E2 296C70 3B8B82 55A999 77C7B8",
		"band": 0.82,
	},
	"alfheim": {
		"size": Vector2i(1920, 1080),
		"palette": "090C22 0F132D 151A3B 1E2448 292D57 353B67 414A76 53608B 66749D 7185AE 879BC0 9EADD0 B8C9DD D2DDEC 594C82 7562A1 9B83C6 B29DD5",
		"band": 0.80,
	},
	"muspelheim": {
		"size": Vector2i(1920, 1080),
		"palette": "10070A 19090C 250D10 321116 43151A 581B1D 702321 8B2D24 A83A27 C64A29 E35E2C F47B35 FF9A45 2A1B22 3C2730 56333A 704149 8E5154 BD6A5E E99170",
		"band": 0.68,
	},
	"svartalfheim": {
		"size": Vector2i(1920, 1080),
		"palette": "090C10 11161C 19212A 222D37 2D3943 394751 485760 586870 263C43 31515A 3E6870 745438 8B6440 A97945 C5904E E0AA5B F2C26D 6F4930 9A5F32 CA7734",
		"band": 0.80,
	},
	"vanaheim": {
		"size": Vector2i(1920, 1080),
		"palette": "04110E 071A16 0B251E 103129 153E32 1B4D3B 235D45 2D6F4F 39825A 489565 5BA972 70BD7E 88CF91 17383B 235057 326A6E 4B817C 78965C A3AD62 D4C46F",
		"band": 0.78,
	},
	"jotunheim": {
		"size": Vector2i(1920, 1080),
		"palette": "080B18 0D1224 131A31 1A2340 222D50 2C3961 374672 455584 566696 6978A8 7E8CBA 95A3CB ADB9DC C6D0EA 252741 343650 484965 5F5D7D 777494 9691AD",
		"band": 0.80,
	},
}

const ORDER := ["center", "asgard", "midgard", "niflheim", "alfheim", "muspelheim", "svartalfheim", "vanaheim", "jotunheim"]

func _init() -> void:
	var report_dir := "res://../reports/codex-art-15"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(report_dir + "/previews"))
	var maps := RealmCatalog.scaled_maps(1.5)
	var metrics := PackedStringArray(["realm,far_size,far_opaque,far_grid2,mid_size,mid_transparent_pct,mid_center_clear_pct,mid_grid2"])
	for realm in ORDER:
		var cfg: Dictionary = CONFIG[realm]
		var final_size: Vector2i = cfg.size
		var logical := Vector2i(final_size.x / 2, final_size.y / 2)
		var art_dir := "res://assets/art/realm_%s" % realm
		var old_far := Image.load_from_file(art_dir + "/bg_far.png")
		var old_mid := Image.load_from_file(art_dir + "/bg_mid.png")
		var old_composite := old_far.duplicate()
		old_composite.blend_rect(old_mid, Rect2i(Vector2i.ZERO, old_mid.get_size()), Vector2i.ZERO)

		var raw := Image.load_from_file(report_dir + "/raw/%s_far_generated.png" % realm)
		var far := _make_far(raw, logical, _palette(cfg.palette), float(cfg.band))
		var mid := _make_mid(old_mid, logical)
		var far_final := far.duplicate()
		far_final.resize(final_size.x, final_size.y, Image.INTERPOLATE_NEAREST)
		var mid_final := mid.duplicate()
		mid_final.resize(final_size.x, final_size.y, Image.INTERPOLATE_NEAREST)
		var far_err: Error = far_final.save_png(art_dir + "/bg_far.png")
		var mid_err: Error = mid_final.save_png(art_dir + "/bg_mid.png")
		if far_err != OK or mid_err != OK:
			push_error("Save failed for %s: far=%s mid=%s" % [realm, far_err, mid_err])

		var old_view := old_composite.duplicate()
		old_view.resize(logical.x, logical.y, Image.INTERPOLATE_NEAREST)
		var new_view := far.duplicate()
		new_view.blend_rect(mid, Rect2i(Vector2i.ZERO, logical), Vector2i.ZERO)
		var map_data: Dictionary = _find_map(maps, art_dir)
		_draw_platforms(old_view, map_data)
		_draw_platforms(new_view, map_data)
		var comparison := Image.create(logical.x * 2 + 8, logical.y, false, Image.FORMAT_RGBA8)
		comparison.fill(Color("#08090d"))
		comparison.blit_rect(old_view, Rect2i(Vector2i.ZERO, logical), Vector2i.ZERO)
		comparison.blit_rect(new_view, Rect2i(Vector2i.ZERO, logical), Vector2i(logical.x + 8, 0))
		comparison.save_png(report_dir + "/previews/%s_old_vs_new_platforms.png" % realm)

		var transparent_pct := _transparent_percent(mid_final)
		var center_clear := _center_clear_percent(mid_final)
		metrics.append("%s,%sx%s,%s,%s,%sx%s,%.2f,%.2f,%s" % [
			realm, final_size.x, final_size.y, _is_opaque(far_final), _is_grid_2(far_final),
			final_size.x, final_size.y, transparent_pct, center_clear, _is_grid_2(mid_final),
		])
		print("BUILT ", realm, " far=", final_size, " mid_transparent=", snapped(transparent_pct, 0.01), "% center_clear=", snapped(center_clear, 0.01), "%")
	var file := FileAccess.open(report_dir + "/metrics.csv", FileAccess.WRITE)
	file.store_string("\n".join(metrics) + "\n")
	file.close()
	quit(0)

func _make_far(source: Image, logical: Vector2i, palette: Array[Color], band_factor: float) -> Image:
	source.convert(Image.FORMAT_RGBA8)
	var crop_height := int(round(source.get_width() * 9.0 / 16.0))
	var crop_width := source.get_width()
	if crop_height > source.get_height():
		crop_height = source.get_height()
		crop_width = int(round(crop_height * 16.0 / 9.0))
	var crop_pos := Vector2i((source.get_width() - crop_width) / 2, (source.get_height() - crop_height) / 2)
	var image := source.get_region(Rect2i(crop_pos, Vector2i(crop_width, crop_height)))
	image.resize(logical.x, logical.y, Image.INTERPOLATE_LANCZOS)
	var cache := {}
	for y in logical.y:
		var yn := float(y) / float(logical.y - 1)
		for x in logical.x:
			var color := image.get_pixel(x, y)
			if yn >= 0.205 and yn <= 0.905:
				var edge := absf(float(x) / float(logical.x - 1) - 0.5) * 2.0
				var factor := lerpf(band_factor, minf(0.94, band_factor + 0.10), edge)
				color = Color(color.r * factor, color.g * factor, color.b * factor, 1.0)
			else:
				color.a = 1.0
			var key := color.to_rgba32()
			if not cache.has(key):
				cache[key] = _nearest(color, palette)
			image.set_pixel(x, y, cache[key])
	return image

func _make_mid(old_mid: Image, logical: Vector2i) -> Image:
	old_mid.convert(Image.FORMAT_RGBA8)
	# Resize on the logical grid, then upscale exactly 2x. This removes the old
	# irregular 2/3-pixel nearest-neighbour pattern while retaining authored silhouettes.
	old_mid.resize(logical.x, logical.y, Image.INTERPOLATE_NEAREST)
	for y in logical.y:
		for x in logical.x:
			var c := old_mid.get_pixel(x, y)
			if c.a < 0.18:
				c.a = 0.0
			elif c.a < 0.72:
				c.a = 0.5
			else:
				c.a = 1.0
			old_mid.set_pixel(x, y, c)
	return old_mid

func _palette(text: String) -> Array[Color]:
	var result: Array[Color] = []
	for token in text.split(" ", false):
		result.append(Color("#" + token))
	return result

func _nearest(color: Color, palette: Array[Color]) -> Color:
	var best := palette[0]
	var best_distance := INF
	for candidate in palette:
		var dr := color.r - candidate.r
		var dg := color.g - candidate.g
		var db := color.b - candidate.b
		var distance := dr * dr * 0.30 + dg * dg * 0.59 + db * db * 0.11
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return Color(best.r, best.g, best.b, 1.0)

func _find_map(maps: Array, art_dir: String) -> Dictionary:
	for map_data: Dictionary in maps:
		if String(map_data.art.dir) == art_dir:
			return map_data
	return {}

func _draw_platforms(image: Image, map_data: Dictionary) -> void:
	if map_data.is_empty():
		return
	var overlay := Image.create(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
	overlay.fill(Color.TRANSPARENT)
	for platform_data: Dictionary in map_data.platforms:
		var center: Vector2 = platform_data.center * 0.5
		var size: Vector2 = platform_data.size * 0.5
		var rect := Rect2i(Vector2i(roundi(center.x - size.x * 0.5), roundi(center.y - size.y * 0.5)), Vector2i(maxi(1, roundi(size.x)), maxi(2, roundi(size.y))))
		overlay.fill_rect(rect, Color(0.08, 0.04, 0.02, 0.70))
		overlay.fill_rect(Rect2i(rect.position, Vector2i(rect.size.x, 2)), Color(1.0, 0.82, 0.28, 0.95))
	image.blend_rect(overlay, Rect2i(Vector2i.ZERO, overlay.get_size()), Vector2i.ZERO)

func _is_opaque(image: Image) -> bool:
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < 0.999:
				return false
	return true

func _transparent_percent(image: Image) -> float:
	var clear := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a == 0.0:
				clear += 1
	return 100.0 * float(clear) / float(image.get_width() * image.get_height())

func _center_clear_percent(image: Image) -> float:
	var rect := Rect2i(int(image.get_width() * 0.25), int(image.get_height() * 0.20), int(image.get_width() * 0.50), int(image.get_height() * 0.70))
	var clear := 0
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if image.get_pixel(x, y).a == 0.0:
				clear += 1
	return 100.0 * float(clear) / float(rect.size.x * rect.size.y)

func _is_grid_2(image: Image) -> bool:
	if image.get_width() % 2 != 0 or image.get_height() % 2 != 0:
		return false
	for y in range(0, image.get_height(), 2):
		for x in range(0, image.get_width(), 2):
			var c := image.get_pixel(x, y)
			if c != image.get_pixel(x + 1, y) or c != image.get_pixel(x, y + 1) or c != image.get_pixel(x + 1, y + 1):
				return false
	return true
