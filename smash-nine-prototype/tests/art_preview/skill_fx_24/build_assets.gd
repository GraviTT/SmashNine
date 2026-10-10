extends SceneTree
## CODEX-ART-24: ImageGen family atlases -> exact-size game strips.
## All cropping, nearest-neighbour resampling, alpha cleanup and palette mapping use Godot Image.

const SKILL_DIR := "res://assets/art/effects/skill"
const REALM_DIR := "res://assets/art/effects/realm"
const PORTAL_OUT := "res://assets/art/realm_center/portal_anim.png"

const LUNA_PALETTE := ["11152D", "3E285B", "8A367E", "E84DB5", "FF8BD5", "55CDE2", "B9F4FF", "F6C94C", "FFF1A8", "FFFFFF"]
const NOVA_PALETTE := ["071725", "103249", "075E73", "0797A8", "16CBD3", "92F8F1", "FFFFFF", "B66A16", "F0B43C"]
const RIO_PALETTE := ["10142D", "22265B", "3E3C93", "5553D4", "7A78FF", "6FC9FF", "D4F2FF", "FFFFFF"]
const YUKI_PALETTE := ["102039", "245079", "2C8FBE", "6AD7EE", "C9F7FF", "F6E9C4", "D94A38", "FFFFFF"]
const COMMON_PALETTE := ["142039", "28516D", "2F85AD", "53CBE6", "B8F4FF", "FFFFFF", "C99323", "FFE16A"]
const REALM_PALETTE := ["0B0918", "17112A", "261638", "3B2451", "65417E", "A64AA4", "D47BCE", "68A7B9", "C79B61", "5E171A", "A12B25", "E05628", "FF9A3C"]

## row is normalized [left, top, right, bottom]; source_frames may differ from final frames.
const SPECS := {
	"luna_star_bloom": {"source": "luna_skill_fx_source.png", "row": [0.0, 0.0, 1.0, 0.225], "source_frames": 6, "frames": 6, "cell": Vector2i(256, 256), "fit": Vector2i(204, 220), "palette": LUNA_PALETTE},
	"luna_moon_ring": {"source": "luna_skill_fx_source.png", "row": [0.0, 0.225, 1.0, 0.445], "source_frames": 6, "frames": 6, "cell": Vector2i(320, 320), "fit": Vector2i(204, 235), "palette": LUNA_PALETTE},
	"luna_brave_aura": {"source": "luna_skill_fx_source.png", "row": [0.0, 0.445, 1.0, 0.665], "source_frames": 6, "frames": 6, "cell": Vector2i(128, 128), "fit": Vector2i(116, 116), "palette": LUNA_PALETTE},
	"luna_comet_trail": {"source": "luna_skill_fx_source.png", "row": [0.0, 0.665, 1.0, 0.81], "source_frames": 4, "frames": 4, "cell": Vector2i(48, 48), "fit": Vector2i(42, 36), "palette": LUNA_PALETTE},
	"luna_comet_burst": {"source": "luna_skill_fx_source.png", "row": [0.0, 0.81, 1.0, 1.0], "source_frames": 6, "frames": 6, "cell": Vector2i(224, 224), "fit": Vector2i(198, 205), "palette": LUNA_PALETTE},
	"nova_gravity_burst": {"source": "nova_skill_fx_source.png", "row": [0.0, 0.0, 1.0, 0.175], "source_frames": 5, "frames": 6, "cell": Vector2i(512, 512), "fit": Vector2i(232, 225), "palette": NOVA_PALETTE},
	"nova_momentum_trail": {"source": "nova_skill_fx_source.png", "row": [0.0, 0.175, 1.0, 0.31], "source_frames": 4, "frames": 4, "cell": Vector2i(64, 32), "fit": Vector2i(54, 28), "palette": NOVA_PALETTE},
	"nova_vector_streak": {"source": "nova_skill_fx_source.png", "row": [0.0, 0.31, 1.0, 0.45], "source_frames": 4, "frames": 4, "cell": Vector2i(192, 48), "fit": Vector2i(180, 42), "palette": NOVA_PALETTE},
	"nova_shift_dash": {"source": "nova_skill_fx_source.png", "row": [0.0, 0.45, 1.0, 0.575], "source_frames": 4, "frames": 4, "cell": Vector2i(96, 40), "fit": Vector2i(88, 34), "palette": NOVA_PALETTE},
	"nova_shift_ready": {"source": "nova_skill_fx_source.png", "row": [0.0, 0.575, 1.0, 0.71], "source_frames": 5, "frames": 5, "cell": Vector2i(128, 128), "fit": Vector2i(116, 112), "palette": NOVA_PALETTE},
	"nova_impact_star": {"source": "nova_skill_fx_source.png", "row": [0.0, 0.71, 1.0, 0.855], "source_frames": 5, "frames": 6, "cell": Vector2i(512, 512), "fit": Vector2i(230, 225), "palette": NOVA_PALETTE},
	"nova_launch_flash": {"source": "nova_skill_fx_source.png", "row": [0.0, 0.855, 1.0, 1.0], "source_frames": 5, "frames": 5, "cell": Vector2i(256, 64), "fit": Vector2i(238, 56), "palette": NOVA_PALETTE},
	"rio_rune_guard": {"source": "rio_skill_fx_source.png", "row": [0.0, 0.0, 1.0, 0.34], "source_frames": 6, "frames": 6, "cell": Vector2i(128, 128), "fit": Vector2i(116, 116), "palette": RIO_PALETTE},
	"rio_rune_burst": {"source": "rio_skill_fx_source.png", "row": [0.0, 0.34, 1.0, 0.7], "source_frames": 6, "frames": 6, "cell": Vector2i(320, 320), "fit": Vector2i(270, 270), "palette": RIO_PALETTE},
	"rio_blink_trail": {"source": "rio_skill_fx_source.png", "row": [0.0, 0.7, 1.0, 1.0], "source_frames": 5, "frames": 5, "cell": Vector2i(256, 64), "fit": Vector2i(238, 56), "palette": RIO_PALETTE},
	"guard_bubble": {"source": "common_skill_fx_source.png", "row": [0.0, 0.0, 1.0, 0.61], "source_frames": 3, "frames": 3, "cell": Vector2i(128, 128), "fit": Vector2i(116, 116), "palette": COMMON_PALETTE},
	"attack_afterimage": {"source": "common_skill_fx_source.png", "row": [0.0, 0.61, 1.0, 1.0], "source_frames": 4, "frames": 4, "cell": Vector2i(160, 64), "fit": Vector2i(150, 56), "palette": COMMON_PALETTE},
}

const REALM_SPECS := {
	"portal_anim": {"source": "realm_markers_source.png", "row": [0.0, 0.0, 1.0, 0.335], "source_frames": 6, "frames": 6, "cell": Vector2i(96, 96), "fit": Vector2i(92, 92), "palette": REALM_PALETTE},
	"seal_barrier": {"source": "realm_markers_source.png", "row": [0.0, 0.335, 1.0, 0.635], "source_frames": 6, "frames": 6, "cell": Vector2i(256, 256), "fit": Vector2i(248, 244), "palette": REALM_PALETTE},
	"collapse_cracks": {"source": "realm_markers_source.png", "row": [0.0, 0.635, 1.0, 0.855], "source_frames": 6, "frames": 6, "cell": Vector2i(320, 128), "fit": Vector2i(286, 112), "palette": REALM_PALETTE},
	"warning_edge": {"source": "realm_markers_source.png", "row": [0.0, 0.855, 1.0, 1.0], "source_frames": 6, "frames": 6, "cell": Vector2i(320, 48), "fit": Vector2i(300, 42), "palette": REALM_PALETTE},
}

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SKILL_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REALM_DIR))
	var only := "all"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			only = argument.trim_prefix("--only=")
	var measurements: Array[String] = []
	for name: String in SPECS:
		if only != "all" and not name.begins_with(only):
			continue
		var strip := _build_strip(SKILL_DIR.path_join(str(SPECS[name].source)), SPECS[name])
		strip.save_png(SKILL_DIR.path_join("%s.png" % name))
		measurements.append(_measure(name, strip, SPECS[name]))
	if only == "all" or only == "yuki":
		_build_yuki_grand_ward().save_png(SKILL_DIR.path_join("yuki_grand_ward.png"))
		measurements.append(_measure("yuki_grand_ward", Image.load_from_file(SKILL_DIR.path_join("yuki_grand_ward.png")), {"frames": 8, "cell": Vector2i(640, 640)}))
	for name: String in REALM_SPECS:
		if only != "all" and only != "realm":
			continue
		var strip := _build_strip(REALM_DIR.path_join(str(REALM_SPECS[name].source)), REALM_SPECS[name])
		var out := PORTAL_OUT if name == "portal_anim" else REALM_DIR.path_join("%s.png" % name)
		strip.save_png(out)
		measurements.append(_measure(name, strip, REALM_SPECS[name]))
	if only == "contact":
		_build_contacts()
	var report := ProjectSettings.globalize_path("res://../reports/codex-art-24/measurements_%s.txt" % only)
	FileAccess.open(report, FileAccess.WRITE).store_string("\n".join(measurements) + "\n")
	print("\n".join(measurements))
	quit(0)

func _build_strip(source_path: String, spec: Dictionary) -> Image:
	var source := Image.load_from_file(source_path)
	if source == null or source.is_empty():
		push_error("Missing source: %s" % source_path)
		return Image.new()
	var row_data: Array = spec.row
	var row := Rect2i(
		int(round(float(row_data[0]) * source.get_width())), int(round(float(row_data[1]) * source.get_height())),
		int(round((float(row_data[2]) - float(row_data[0])) * source.get_width())),
		int(round((float(row_data[3]) - float(row_data[1])) * source.get_height())))
	var row_image := source.get_region(row)
	var frames: int = spec.frames
	var source_frames: int = spec.source_frames
	var cell: Vector2i = spec.cell
	var result := Image.create(cell.x * frames, cell.y, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	var palette := _palette(spec.palette)
	for frame in frames:
		var source_frame := int(round(float(frame) * float(source_frames - 1) / float(maxi(frames - 1, 1))))
		var left := int(floor(float(source_frame) * row_image.get_width() / source_frames))
		var right := int(floor(float(source_frame + 1) * row_image.get_width() / source_frames))
		var part := row_image.get_region(Rect2i(left, 0, right - left, row_image.get_height()))
		var used := _opaque_rect(part, 0.12)
		if used.size == Vector2i.ZERO:
			continue
		part = part.get_region(used)
		var fit: Vector2i = spec.fit
		var scale := minf(1.0, minf(float(fit.x) / part.get_width(), float(fit.y) / part.get_height()))
		var size := Vector2i(maxi(1, int(round(part.get_width() * scale))), maxi(1, int(round(part.get_height() * scale))))
		if size != part.get_size():
			part.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
		_quantize(part, palette, 0.18)
		var pos := Vector2i(frame * cell.x + (cell.x - size.x) / 2, (cell.y - size.y) / 2)
		result.blit_rect(part, Rect2i(Vector2i.ZERO, size), pos)
	return result

func _build_yuki_grand_ward() -> Image:
	var frames := 8
	var cell := Vector2i(640, 640)
	var strip := Image.create(cell.x * frames, cell.y, false, Image.FORMAT_RGBA8)
	strip.fill(Color.TRANSPARENT)
	var cyan := Color("6AD7EE")
	var pale := Color("C9F7FF")
	var navy := Color("102039")
	var ivory := Color("F6E9C4")
	var red := Color("D94A38")
	for frame in frames:
		var origin := Vector2i(frame * cell.x + cell.x / 2, cell.y / 2)
		var radius := 297 + int(round(sin(TAU * frame / frames) * 3.0))
		_draw_ring(strip, origin, radius, 2, navy)
		_draw_ring(strip, origin, radius - 3, 2, cyan)
		for tick in 32:
			if (tick + frame) % 3 != 0:
				continue
			var angle := TAU * tick / 32.0
			var p := origin + Vector2i(roundi(cos(angle) * (radius - 7)), roundi(sin(angle) * (radius - 7)))
			_plot_cross(strip, p, pale)
		for direction: Vector2i in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
			var center: Vector2i = origin + direction * (radius - 18)
			_draw_talisman(strip, center, direction, ivory, red, navy, frame)
	return strip

func _draw_ring(image: Image, center: Vector2i, radius: int, width: int, color: Color) -> void:
	var outer_sq := radius * radius
	var inner_sq := (radius - width) * (radius - width)
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var dx := x - center.x
			var dy := y - center.y
			var distance_sq := dx * dx + dy * dy
			if distance_sq <= outer_sq and distance_sq >= inner_sq:
				image.set_pixel(x, y, color)

func _draw_talisman(image: Image, center: Vector2i, direction: Vector2i, paper: Color, ink: Color, outline: Color, frame: int) -> void:
	var horizontal := direction.x != 0
	var size := Vector2i(54, 24) if horizontal else Vector2i(24, 54)
	var rect := Rect2i(center - size / 2, size)
	image.fill_rect(rect.grow(2), outline)
	image.fill_rect(rect, paper)
	for mark in 3:
		var wobble := (frame + mark) % 2
		if horizontal:
			image.fill_rect(Rect2i(center.x - 13 + mark * 9, center.y - 2 + wobble, 5, 4), ink)
		else:
			image.fill_rect(Rect2i(center.x - 2 + wobble, center.y - 13 + mark * 9, 4, 5), ink)

func _plot_cross(image: Image, center: Vector2i, color: Color) -> void:
	for offset in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		image.set_pixelv(center + offset, color)

func _opaque_rect(image: Image, cutoff: float) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a >= cutoff:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func _palette(hexes: Array) -> Array[Color]:
	var colors: Array[Color] = []
	for value in hexes:
		colors.append(Color.from_string(str(value), Color.WHITE))
	return colors

func _quantize(image: Image, palette: Array[Color], cutoff: float) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var source := image.get_pixel(x, y)
			if source.a < cutoff:
				image.set_pixel(x, y, Color.TRANSPARENT)
				continue
			var best: Color = palette[0]
			var distance := INF
			for candidate in palette:
				var d := pow(source.r - candidate.r, 2) + pow(source.g - candidate.g, 2) + pow(source.b - candidate.b, 2)
				if d < distance:
					distance = d
					best = candidate
			image.set_pixel(x, y, Color(best.r, best.g, best.b, 1.0))

func _build_contacts() -> void:
	var part1_names: Array[String] = []
	for name: String in SPECS:
		part1_names.append(name)
	part1_names.append("yuki_grand_ward")
	_build_contact(part1_names, "res://tests/art_preview/skill_fx_24/part1_contact.png")
	_build_contact(["portal_anim", "seal_barrier", "collapse_cracks", "warning_edge"], "res://tests/art_preview/skill_fx_24/part2_contact.png")

func _build_contact(names: Array[String], out_path: String) -> void:
	var row_height := 410
	var width := 1536
	var contact := Image.create(width, row_height * names.size(), false, Image.FORMAT_RGBA8)
	var backgrounds: Array[Image] = []
	for path in ["res://assets/art/realm_asgard/bg_far.png", "res://assets/art/realm_midgard/bg_far.png", "res://assets/art/realm_muspelheim/bg_far.png"]:
		var background := Image.load_from_file(path)
		var crop_width := mini(background.get_width(), int(round(background.get_height() * 512.0 / 410.0)))
		background = background.get_region(Rect2i((background.get_width() - crop_width) / 2, 0, crop_width, background.get_height()))
		background.resize(512, row_height, Image.INTERPOLATE_NEAREST)
		background.adjust_bcs(0.55, 0.9, 0.75)
		backgrounds.append(background)
	var fighter_sheet := Image.load_from_file("res://assets/art/frey/frey_sheet.png")
	var fighter := fighter_sheet.get_region(Rect2i(0, 0, 128, 128))
	for index in names.size():
		var name := names[index]
		var source_path := PORTAL_OUT if name == "portal_anim" else (REALM_DIR.path_join("%s.png" % name) if REALM_SPECS.has(name) else SKILL_DIR.path_join("%s.png" % name))
		var strip := Image.load_from_file(source_path)
		var frames := int(REALM_SPECS[name].frames) if REALM_SPECS.has(name) else (8 if name == "yuki_grand_ward" else int(SPECS[name].frames))
		var cell := Vector2i(strip.get_width() / frames, strip.get_height())
		var frame_ids := [0, frames / 2, frames - 1]
		for panel in 3:
			var panel_rect := Rect2i(panel * 512, index * row_height, 512, row_height)
			contact.blit_rect(backgrounds[panel], Rect2i(0, 0, 512, row_height), panel_rect.position)
			# A 128 px fighter-cell silhouette for scale.
			contact.blend_rect(fighter, Rect2i(0, 0, 128, 128), panel_rect.position + Vector2i(8, 136))
			for sample in frame_ids.size():
				var frame_image := strip.get_region(Rect2i(frame_ids[sample] * cell.x, 0, cell.x, cell.y))
				var preview := frame_image.duplicate()
				var max_one := Vector2i(112, 112)
				var one_scale := minf(1.0, minf(float(max_one.x) / preview.get_width(), float(max_one.y) / preview.get_height()))
				if one_scale < 1.0:
					preview.resize(maxi(1, int(preview.get_width() * one_scale)), maxi(1, int(preview.get_height() * one_scale)), Image.INTERPOLATE_NEAREST)
				contact.blend_rect(preview, Rect2i(Vector2i.ZERO, preview.get_size()), panel_rect.position + Vector2i(96 + sample * 132, 38))
				var twice := preview.duplicate()
				twice.resize(preview.get_width() * 2, preview.get_height() * 2, Image.INTERPOLATE_NEAREST)
				var crop_size := Vector2i(mini(twice.get_width(), 120), mini(twice.get_height(), 120))
				contact.blend_rect(twice, Rect2i((twice.get_size() - crop_size) / 2, crop_size), panel_rect.position + Vector2i(96 + sample * 132, 222))
	contact.save_png(out_path)

func _measure(name: String, strip: Image, spec: Dictionary) -> String:
	var frames: int = spec.frames
	var cell: Vector2i = spec.cell
	var alpha_values := {}
	var colors := {}
	var occupied := 0
	for y in strip.get_height():
		for x in strip.get_width():
			var color := strip.get_pixel(x, y)
			alpha_values[int(round(color.a * 255.0))] = true
			if color.a > 0.0:
				colors[color.to_html(false)] = true
				occupied += 1
	return "%s size=%dx%d frames=%d cell=%dx%d format=RGBA8 alpha=%s colors=%d occupied=%d" % [name, strip.get_width(), strip.get_height(), frames, cell.x, cell.y, str(alpha_values.keys()), colors.size(), occupied]
