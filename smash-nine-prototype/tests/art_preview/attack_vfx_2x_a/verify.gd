extends SceneTree

const CELL := 128
const FRAME_COUNT := 6
const REPORT := "res://../reports/codex-art-16"
const VFX := {
	"frey_slash": Vector2i(384, 256), "frey_k": Vector2i(448, 192), "frey_l": Vector2i(256, 384),
	"yuki_slash": Vector2i(384, 256), "yuki_k": Vector2i(256, 256), "yuki_l": Vector2i(384, 384),
	"luna_slash": Vector2i(384, 256), "luna_k": Vector2i(320, 192), "luna_l": Vector2i(384, 384),
	"luna_brave_slash": Vector2i(448, 256),
	"nova_slash": Vector2i(320, 256), "nova_k": Vector2i(448, 192), "nova_l": Vector2i(384, 384),
	"rio_slash": Vector2i(384, 256), "rio_k": Vector2i(512, 192), "rio_l": Vector2i(256, 320),
}
const SHEETS := {
	"rio_male": "res://assets/art/rio/rio_male_sheet.png",
	"rio_female": "res://assets/art/rio/rio_female_sheet.png",
	"frey": "res://assets/art/frey/frey_sheet.png",
}

var failures: Array[String] = []
var lines := PackedStringArray(["kind,id,frame,width,height,changed_pixels,left,top,right,bottom,margin,feet_y,palette,alpha_levels,cut_run"])

func _initialize() -> void:
	for name: String in VFX:
		_verify_vfx(name, VFX[name])
	for id: String in SHEETS:
		_verify_sheet(id, SHEETS[id])
	var file := FileAccess.open(ProjectSettings.globalize_path(REPORT + "/measurements.csv"), FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	if failures.is_empty():
		print("ART16_VERIFY_OK vfx_files=16 vfx_frames=96 untouched_cells=105 rio_target_cells=20 frey_target_cells=1")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _verify_vfx(name: String, frame_size: Vector2i) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://assets/art/attack_vfx/%s.png" % name))
	if image == null or image.is_empty():
		failures.append("missing VFX %s" % name)
		return
	image.convert(Image.FORMAT_RGBA8)
	var expected := Vector2i(frame_size.x * FRAME_COUNT, frame_size.y)
	if image.get_size() != expected:
		failures.append("%s size=%s expected=%s" % [name, image.get_size(), expected])
	var colors := {}
	var alphas := {}
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a8 == 0:
				continue
			colors[(c.r8 << 16) | (c.g8 << 8) | c.b8] = true
			alphas[c.a8] = true
	if colors.size() > 6:
		failures.append("%s palette=%d" % [name, colors.size()])
	if alphas.size() > 2:
		failures.append("%s alpha_levels=%d" % [name, alphas.size()])
	for index in FRAME_COUNT:
		var frame := image.get_region(Rect2i(index * frame_size.x, 0, frame_size.x, frame_size.y))
		var rect := frame.get_used_rect()
		if rect.size == Vector2i.ZERO:
			failures.append("%s f%d empty" % [name, index])
			continue
		var margin := mini(mini(rect.position.x, rect.position.y), mini(frame_size.x - rect.end.x, frame_size.y - rect.end.y))
		if margin < 6:
			failures.append("%s f%d margin=%d" % [name, index, margin])
		lines.append("vfx,%s,%d,%d,%d,0,%d,%d,%d,%d,%d,-1,%d,%d,%d" % [name, index, frame_size.x, frame_size.y, rect.position.x, rect.position.y, rect.end.x - 1, rect.end.y - 1, margin, colors.size(), alphas.size(), _cut_run(frame, rect)])

func _verify_sheet(id: String, path: String) -> void:
	var current := Image.load_from_file(ProjectSettings.globalize_path(path))
	var baseline := Image.load_from_file(ProjectSettings.globalize_path("res://tests/art_preview/attack_vfx_2x_a/baseline/%s_sheet.png" % id))
	current.convert(Image.FORMAT_RGBA8)
	baseline.convert(Image.FORMAT_RGBA8)
	if current.get_size() != Vector2i(768, 896):
		failures.append("%s sheet size=%s" % [id, current.get_size()])
	var changed_targets := 0
	var untouched := 0
	for row in 7:
		for column in 6:
			var before := baseline.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
			var after := current.get_region(Rect2i(column * CELL, row * CELL, CELL, CELL))
			var target := (id.begins_with("rio") and (row == 4 or row == 5) and column < (4 if row == 4 else 6)) or (id == "frey" and row == 4 and column == 3)
			var changed := _pixel_diff(before, after)
			if target:
				if changed == 0:
					failures.append("%s r%dc%d unchanged target" % [id, row, column])
				else:
					changed_targets += 1
				var rect := after.get_used_rect()
				var margin := mini(mini(rect.position.x, rect.position.y), mini(CELL - rect.end.x, CELL - rect.end.y))
				var feet := rect.end.y - 1
				if margin < 4:
					failures.append("%s r%dc%d margin=%d" % [id, row, column, margin])
				if feet != 120:
					failures.append("%s r%dc%d feet=%d" % [id, row, column, feet])
				lines.append("sheet,%s,r%dc%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,-1,-1,%d" % [id, row, column, CELL, CELL, changed, rect.position.x, rect.position.y, rect.end.x - 1, rect.end.y - 1, margin, feet, _cut_run(after, rect)])
			elif changed != 0:
				failures.append("%s r%dc%d changed outside whitelist=%d" % [id, row, column, changed])
			else:
				untouched += 1
	var expected_targets := 10 if id.begins_with("rio") else 1
	var expected_untouched := 32 if id.begins_with("rio") else 41
	if changed_targets != expected_targets or untouched != expected_untouched:
		failures.append("%s counts target=%d/%d untouched=%d/%d" % [id, changed_targets, expected_targets, untouched, expected_untouched])
	print("SHEET_VERIFY %s changed_targets=%d untouched=%d" % [id, changed_targets, untouched])

func _pixel_diff(a: Image, b: Image) -> int:
	var count := 0
	for y in CELL:
		for x in CELL:
			if a.get_pixel(x, y) != b.get_pixel(x, y):
				count += 1
	return count

func _cut_run(frame: Image, rect: Rect2i) -> int:
	var best := 0
	for x in [rect.position.x, rect.end.x - 1]:
		var run := 0
		for y in range(rect.position.y, rect.end.y):
			if frame.get_pixel(x, y).a >= 0.5:
				run += 1
				best = maxi(best, run)
			else:
				run = 0
	for y in [rect.position.y, rect.end.y - 1]:
		var run := 0
		for x in range(rect.position.x, rect.end.x):
			if frame.get_pixel(x, y).a >= 0.5:
				run += 1
				best = maxi(best, run)
			else:
				run = 0
	return best
