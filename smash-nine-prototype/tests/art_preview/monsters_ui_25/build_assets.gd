extends SceneTree
## CODEX-ART-25 source cleanup. ImageGen provides the design; this script enforces the
## runtime contracts with Godot's Image API: exact grid, nearest-neighbour downsampling,
## transparent cells and stable feet/pivot placement. It never enlarges source pixels.

const MONSTER_DIR := "res://assets/art/monsters"
const UI_DIR := "res://assets/art/ui"
const FRAME_COUNTS := [4, 6, 4, 1]
const CELL := Vector2i(96, 96)
const FEET_Y := 72

const SHEETS := {
	"asgard_aegis_ram": "asgard_aegis_ram_source.png",
	"niflheim_frost_owl": "niflheim_frost_owl_source.png",
	"alfheim_moon_moth": "alfheim_moon_moth_source.png",
	"svartalfheim_gear_beetle": "svartalfheim_gear_beetle_source.png",
	"vanaheim_vine_hound": "vanaheim_vine_hound_source.png",
	"jotunheim_rune_golem": "jotunheim_rune_golem_source.png",
	"yggdrasil_root_oracle": "yggdrasil_root_oracle_source.png",
}

const PROJECTILES := {
	"niflheim_frost_owl_projectile": "niflheim_frost_bolt_source.png",
	"alfheim_moon_moth_projectile": "alfheim_moon_seed_source.png",
	"yggdrasil_root_oracle_projectile": "yggdrasil_soul_seed_source.png",
}

const EMBLEMS := [
	"asgard", "midgard", "niflheim", "alfheim", "muspelheim",
	"svartalfheim", "vanaheim", "jotunheim", "yggdrasil_heart",
]
const STATUS_ICONS := [
	"super_armor", "stun", "luna_star_charge", "frey_pursuit_mark", "shield_break", "low_hp",
]
const FRAMES := {
	"skill_slot": {"size": Vector2i(72, 72), "margin": 10},
	"hp_bar": {"size": Vector2i(320, 32), "margin": 8},
	"card_panel": {"size": Vector2i(240, 112), "margin": 14},
	"result_panel": {"size": Vector2i(960, 520), "margin": 18},
	"menu_button": {"size": Vector2i(360, 56), "margin": 10},
}

func _initialize() -> void:
	for skin: String in SHEETS:
		_build_sheet(skin, str(SHEETS[skin]))
	for projectile: String in PROJECTILES:
		_build_projectile(projectile, str(PROJECTILES[projectile]))
	for emblem: String in EMBLEMS:
		_build_icon("realm_emblems", emblem, Vector2i(32, 32), Vector2i(28, 28))
	for icon: String in STATUS_ICONS:
		_build_icon("status", icon, Vector2i(24, 24), Vector2i(20, 20))
	for frame: String in FRAMES:
		_build_frame(frame, FRAMES[frame])
	_build_title_background()
	print("ART25_BUILD_OK sheets=%d projectiles=%d emblems=%d status=%d frames=%d title=1" % [
		SHEETS.size(), PROJECTILES.size(), EMBLEMS.size(), STATUS_ICONS.size(), FRAMES.size()
	])
	quit(0)

func _build_icon(folder: String, name: String, canvas_size: Vector2i, content_limit: Vector2i) -> void:
	var source_path := "%s/%s/%s_source.png" % [UI_DIR, folder, name]
	var source := Image.load_from_file(source_path)
	if source == null or source.is_empty():
		push_error("Cannot load UI icon source %s" % source_path)
		quit(1)
		return
	_prepare_alpha(source)
	_keep_largest_component(source)
	var bounds := _alpha_bounds(source)
	if bounds.size == Vector2i.ZERO:
		push_error("UI icon source became empty: %s" % source_path)
		quit(1)
		return
	var piece := source.get_region(bounds)
	var scale := minf(minf(float(content_limit.x) / float(piece.get_width()), float(content_limit.y) / float(piece.get_height())), 1.0)
	var target := Vector2i(maxi(1, int(round(piece.get_width() * scale))), maxi(1, int(round(piece.get_height() * scale))))
	piece.resize(target.x, target.y, Image.INTERPOLATE_NEAREST)
	var output := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	output.blend_rect(piece, Rect2i(Vector2i.ZERO, target), (canvas_size - target) / 2)
	var out_path := "%s/%s/%s.png" % [UI_DIR, folder, name]
	var error := output.save_png(out_path)
	if error != OK:
		push_error("Could not save %s (%s)" % [out_path, error])
		quit(1)
	print("icon %s/%s source=%s target=%s alpha=%d" % [folder, name, source.get_size(), target, _opaque_pixels(output)])

func _build_frame(name: String, settings: Dictionary) -> void:
	var source_path := "%s/frames/%s_source.png" % [UI_DIR, name]
	var source := Image.load_from_file(source_path)
	if source == null or source.is_empty():
		push_error("Cannot load frame source %s" % source_path)
		quit(1)
		return
	_prepare_alpha(source)
	var bounds := _alpha_bounds(source)
	if bounds.size == Vector2i.ZERO:
		push_error("Frame source became empty: %s" % source_path)
		quit(1)
		return
	var output: Image = source.get_region(bounds)
	var target: Vector2i = settings["size"]
	output.resize(target.x, target.y, Image.INTERPOLATE_NEAREST)
	var margin: int = settings["margin"]
	output.fill_rect(Rect2i(margin, margin, target.x - margin * 2, target.y - margin * 2), Color.TRANSPARENT)
	var out_path := "%s/frames/%s.png" % [UI_DIR, name]
	var error := output.save_png(out_path)
	if error != OK:
		push_error("Could not save %s (%s)" % [out_path, error])
		quit(1)
	print("frame %s source=%s target=%s margin=%d alpha=%d" % [name, source.get_size(), target, margin, _opaque_pixels(output)])

func _build_title_background() -> void:
	var source_path := "%s/title_bg_source.png" % UI_DIR
	var source := Image.load_from_file(source_path)
	if source == null or source.is_empty():
		push_error("Cannot load title source %s" % source_path)
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	var output := Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
	output.fill(Color("06152f"))
	var copy_size := Vector2i(mini(source.get_width(), 1920), mini(source.get_height(), 1080))
	var source_at := (source.get_size() - copy_size) / 2
	var target_at := (Vector2i(1920, 1080) - copy_size) / 2
	output.blit_rect(source, Rect2i(source_at, copy_size), target_at)
	var out_path := "%s/title_bg.png" % UI_DIR
	var error := output.save_png(out_path)
	if error != OK:
		push_error("Could not save %s (%s)" % [out_path, error])
		quit(1)
	print("title source=%s target=%s scale=1.000" % [source.get_size(), output.get_size()])

func _opaque_pixels(image: Image) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a >= 0.16:
				count += 1
	return count

func _build_sheet(skin: String, source_name: String) -> void:
	var source := Image.load_from_file("%s/%s" % [MONSTER_DIR, source_name])
	if source == null or source.is_empty():
		push_error("Cannot load monster source %s" % source_name)
		quit(1)
		return
	var source_cell := Vector2i(source.get_width() / 6, source.get_height() / 4)
	if source_cell.x <= 0 or source_cell.y <= 0:
		push_error("Invalid source grid %s: %s" % [source_name, source.get_size()])
		quit(1)
		return
	var cells: Array[Image] = []
	var bounds: Array[Rect2i] = []
	var max_size := Vector2i.ZERO
	for row in 4:
		for column in FRAME_COUNTS[row]:
			var frame := source.get_region(Rect2i(Vector2i(column, row) * source_cell, source_cell))
			_prepare_alpha(frame)
			_keep_largest_component(frame)
			var rect := _alpha_bounds(frame)
			cells.append(frame)
			bounds.append(rect)
			max_size.x = maxi(max_size.x, rect.size.x)
			max_size.y = maxi(max_size.y, rect.size.y)
	var scale := minf(minf(82.0 / maxf(1.0, float(max_size.x)), 68.0 / maxf(1.0, float(max_size.y))), 1.0)
	var sheet := Image.create(576, 384, false, Image.FORMAT_RGBA8)
	sheet.fill(Color.TRANSPARENT)
	var used := 0
	for row in 4:
		for column in FRAME_COUNTS[row]:
			var rect: Rect2i = bounds[used]
			if rect.size.x > 0 and rect.size.y > 0:
				var piece: Image = cells[used].get_region(rect)
				var target := Vector2i(maxi(1, int(round(rect.size.x * scale))), maxi(1, int(round(rect.size.y * scale))))
				piece.resize(target.x, target.y, Image.INTERPOLATE_NEAREST)
				var at := Vector2i(column * CELL.x + (CELL.x - target.x) / 2, row * CELL.y + FEET_Y - target.y)
				sheet.blend_rect(piece, Rect2i(Vector2i.ZERO, target), at)
			used += 1
	var out_path := "%s/%s_sheet.png" % [MONSTER_DIR, skin]
	var error := sheet.save_png(out_path)
	if error != OK:
		push_error("Could not save %s (%s)" % [out_path, error])
		quit(1)
	print("sheet %s source=%s cell=%s scale=%.3f" % [skin, source.get_size(), source_cell, scale])

func _build_projectile(name: String, source_name: String) -> void:
	var source := Image.load_from_file("%s/%s" % [MONSTER_DIR, source_name])
	if source == null or source.is_empty():
		push_error("Cannot load projectile source %s" % source_name)
		quit(1)
		return
	_prepare_alpha(source)
	_keep_largest_component(source)
	var bounds := _alpha_bounds(source)
	if bounds.size == Vector2i.ZERO:
		push_error("Projectile source became empty: %s" % source_name)
		quit(1)
		return
	var piece := source.get_region(bounds)
	var scale := minf(minf(22.0 / float(piece.get_width()), 18.0 / float(piece.get_height())), 1.0)
	var target := Vector2i(maxi(1, int(round(piece.get_width() * scale))), maxi(1, int(round(piece.get_height() * scale))))
	piece.resize(target.x, target.y, Image.INTERPOLATE_NEAREST)
	var output := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	output.blend_rect(piece, Rect2i(Vector2i.ZERO, target), Vector2i((24 - target.x) / 2, (24 - target.y) / 2))
	var out_path := "%s/%s.png" % [MONSTER_DIR, name]
	var error := output.save_png(out_path)
	if error != OK:
		push_error("Could not save %s (%s)" % [out_path, error])
		quit(1)
	print("projectile %s source=%s target=%s" % [name, source.get_size(), target])

## Transparent generations are kept as-is. Opaque ImageGen backgrounds are smooth fields;
## flood-filling their gently changing pixels from the four edges removes them without
## selecting the hard pixel-art outline.
func _prepare_alpha(image: Image) -> void:
	image.convert(Image.FORMAT_RGBA8)
	var transparent := 0
	var total := image.get_width() * image.get_height()
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < 0.5:
				transparent += 1
	if transparent > total / 20:
		for y in image.get_height():
			for x in image.get_width():
				var color := image.get_pixel(x, y)
				if color.a < 0.16:
					image.set_pixel(x, y, Color.TRANSPARENT)
		return
	_flood_clear_background(image)

func _flood_clear_background(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var queue := PackedInt32Array()
	for x in width:
		queue.append(x)
		queue.append((height - 1) * width + x)
	for y in height:
		queue.append(y * width)
		queue.append(y * width + width - 1)
	var head := 0
	while head < queue.size():
		var index := queue[head]
		head += 1
		if visited[index] != 0:
			continue
		visited[index] = 1
		var x := index % width
		var y := index / width
		var current := image.get_pixel(x, y)
		for offset: int in [-1, 1, -width, width]:
			var next: int = index + offset
			if next < 0 or next >= visited.size() or visited[next] != 0:
				continue
			var nx: int = next % width
			var ny: int = next / width
			if absi(nx - x) + absi(ny - y) != 1:
				continue
			if _rgb_distance(current, image.get_pixel(nx, ny)) <= 0.075:
				queue.append(next)
	for index in visited.size():
		if visited[index] != 0:
			image.set_pixel(index % width, index / width, Color.TRANSPARENT)

func _rgb_distance(a: Color, b: Color) -> float:
	var delta := Vector3(a.r - b.r, a.g - b.g, a.b - b.b)
	return delta.length()

## Background speckles and detached generation noise are discarded. Animation readability
## comes from the character's connected silhouette; attack projectiles have their own files.
func _keep_largest_component(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var seen := PackedByteArray()
	seen.resize(width * height)
	var largest := PackedInt32Array()
	for start in seen.size():
		if seen[start] != 0 or image.get_pixel(start % width, start / width).a < 0.16:
			continue
		var component := PackedInt32Array()
		var queue := PackedInt32Array([start])
		seen[start] = 1
		var head := 0
		while head < queue.size():
			var index := queue[head]
			head += 1
			component.append(index)
			var x := index % width
			var y := index / width
			for offset: int in [-1, 1, -width, width]:
				var next: int = index + offset
				if next < 0 or next >= seen.size() or seen[next] != 0:
					continue
				var nx: int = next % width
				var ny: int = next / width
				if absi(nx - x) + absi(ny - y) != 1:
					continue
				if image.get_pixel(nx, ny).a >= 0.16:
					seen[next] = 1
					queue.append(next)
		if component.size() > largest.size():
			largest = component
	var keep := PackedByteArray()
	keep.resize(width * height)
	for index in largest:
		keep[index] = 1
	for index in keep.size():
		if keep[index] == 0:
			image.set_pixel(index % width, index / width, Color.TRANSPARENT)

func _alpha_bounds(image: Image) -> Rect2i:
	var minimum := Vector2i(image.get_width(), image.get_height())
	var maximum := Vector2i(-1, -1)
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a >= 0.16:
				minimum.x = mini(minimum.x, x)
				minimum.y = mini(minimum.y, y)
				maximum.x = maxi(maximum.x, x)
				maximum.y = maxi(maximum.y, y)
	if maximum.x < minimum.x:
		return Rect2i()
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)
