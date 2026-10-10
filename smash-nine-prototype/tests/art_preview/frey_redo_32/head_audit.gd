extends SceneTree
## Independent D32 head audit. This script never reads frey_moves_heads.json. It locates rare
## exact-palette anchor candidates, matches the idle head template at scales 0.70..1.40, checks
## mirrored variants, and rotates the template by the expected quarter-turn for tumble.

const CELL := 128
const HEAD_BOX := Rect2i(62, 27, 28, 32) # same reference crop, metadata is not read
const BASE_SHEET := "res://assets/art/frey/frey_sheet.png"
const BEFORE_SHEET := "res://tests/art_preview/frey_redo_32/before_sheet.png"
const AFTER_SHEET := "res://assets/art/frey/frey_moves_body_sheet.png"
const OUTPUT_DIR := "res://tests/art_preview/frey_redo_32"
const ROWS := [
	["attack_up", 4], ["attack_down", 4], ["attack_air_side", 4], ["dash_strike", 4],
	["rising_cleave", 5], ["spike_followup", 4], ["descent", 6], ["tumble", 4],
]
const DIGITS := {
	"0": ["111", "101", "101", "101", "111"], "1": ["010", "110", "010", "010", "111"],
	"2": ["111", "001", "111", "100", "111"], "3": ["111", "001", "111", "001", "111"],
	"4": ["101", "101", "111", "001", "001"], "5": ["111", "100", "111", "001", "111"],
	"6": ["111", "100", "111", "101", "111"], "7": ["111", "001", "010", "010", "010"],
	"8": ["111", "101", "111", "101", "111"], "9": ["111", "101", "111", "001", "111"],
	".": ["000", "000", "000", "000", "010"], "-": ["000", "000", "111", "000", "000"],
}

var failures: Array[String] = []


func _init() -> void:
	var base := Image.load_from_file(BASE_SHEET)
	var before := Image.load_from_file(BEFORE_SHEET)
	var after := Image.load_from_file(AFTER_SHEET)
	if base.is_empty() or before.is_empty() or after.is_empty():
		push_error("head_audit: missing input image")
		quit(1)
		return
	var template := base.get_region(HEAD_BOX)
	var before_rows := {}
	var after_rows := {}
	var text := PackedStringArray([
		"method=idle head template exact-palette match; candidates=rarest shared opaque color anchors; scales=0.70..1.40 step 0.025; mirrored=yes; tumble=quarter-rotated",
		"reference_box=%s (white helmet wings excluded)" % HEAD_BOX,
	])
	for row_index in ROWS.size():
		var row := String(ROWS[row_index][0])
		var count := int(ROWS[row_index][1])
		var before_scales: Array[float] = []
		var after_scales: Array[float] = []
		var before_line := PackedStringArray()
		var after_line := PackedStringArray()
		for frame_index in count:
			var before_frame := before.get_region(Rect2i(frame_index * CELL, row_index * CELL, CELL, CELL))
			var after_frame := after.get_region(Rect2i(frame_index * CELL, row_index * CELL, CELL, CELL))
			var turns := frame_index if row == "tumble" else 0
			var before_match := _match_head(before_frame, template, turns)
			var after_match := _match_head(after_frame, template, turns)
			before_scales.append(float(before_match.scale))
			after_scales.append(float(after_match.scale))
			before_line.append("%d:%.3f" % [frame_index + 1, float(before_match.scale)])
			after_line.append("%d:%.3f" % [frame_index + 1, float(after_match.scale)])
			if absf(float(after_match.scale) - 1.0) > 0.0501:
				failures.append("%s frame %d matched head scale %.3f (outside ±5%%)" % [row, frame_index + 1, float(after_match.scale)])
		before_rows[row] = before_scales
		after_rows[row] = after_scales
		text.append("%s before %s" % [row, " ".join(before_line)])
		text.append("%s after  %s" % [row, " ".join(after_line)])
		_write_csv(row, before_scales, after_scales)
	_update_contacts(before_rows, after_rows)
	text.append("verdict=%s; after frames within +/-5%%=%d/35" % ["PASS" if failures.is_empty() else "FAIL", 35 - failures.size()])
	var output := "\n".join(text) + "\n"
	print(output)
	var file := FileAccess.open("%s/head_audit.txt" % OUTPUT_DIR, FileAccess.WRITE)
	file.store_string(output)
	file.close()
	if failures.is_empty():
		print("head_audit: all 35 after frames within +/-5%")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _match_head(frame: Image, reference: Image, quarter_turns: int) -> Dictionary:
	var frame_colors := {}
	for y in frame.get_height():
		for x in frame.get_width():
			var color := frame.get_pixel(x, y)
			if color.a < 0.5:
				continue
			var key := _color_key(color)
			if not frame_colors.has(key):
				frame_colors[key] = []
			(frame_colors[key] as Array).append(Vector2i(x, y))
	var best_scale := 0.0
	var best_score := -INF
	for step in 29:
		var scale := 0.70 + step * 0.025
		for mirrored in [false, true]:
			var variant := reference.duplicate()
			if mirrored:
				variant.flip_x()
			variant = _rotate_quarter(variant, quarter_turns)
			if quarter_turns % 2 == 1:
				# The production body keeps the metadata box 28x32 for rotated tumble heads.
				variant.resize(HEAD_BOX.size.x, HEAD_BOX.size.y, Image.INTERPOLATE_NEAREST)
			variant.resize(maxi(1, roundi(variant.get_width() * scale)), maxi(1, roundi(variant.get_height() * scale)), Image.INTERPOLATE_NEAREST)
			var template_colors := {}
			for y in variant.get_height():
				for x in variant.get_width():
					var color: Color = variant.get_pixel(x, y)
					if color.a < 0.5:
						continue
					var key: int = _color_key(color)
					if not template_colors.has(key):
						template_colors[key] = []
					(template_colors[key] as Array).append(Vector2i(x, y))
			var anchor_key := -1
			var anchor_cost := 1000000000
			for key in template_colors:
				if not frame_colors.has(key):
					continue
				var cost := (template_colors[key] as Array).size() * (frame_colors[key] as Array).size()
				if cost < anchor_cost:
					anchor_cost = cost
					anchor_key = int(key)
			if anchor_key < 0:
				continue
			for frame_point in frame_colors[anchor_key]:
				for template_point in template_colors[anchor_key]:
					var position: Vector2i = frame_point - template_point
					if position.x < 0 or position.y < 0 or position.x + variant.get_width() > frame.get_width() or position.y + variant.get_height() > frame.get_height():
						continue
					var score := _exact_score(frame, variant, position)
					# Resolve essentially equal exact matches toward the canonical 1.0 scale.
					score -= absf(scale - 1.0) * 0.0001
					if score > best_score:
						best_score = score
						best_scale = scale
	return {"scale": best_scale, "score": best_score}


func _exact_score(frame: Image, template: Image, position: Vector2i) -> float:
	var exact := 0
	var visible := 0
	for y in template.get_height():
		for x in template.get_width():
			var template_color := template.get_pixel(x, y)
			if template_color.a < 0.5:
				continue
			visible += 1
			if _color_key(template_color) == _color_key(frame.get_pixel(position.x + x, position.y + y)):
				exact += 1
	return float(exact) / maxf(1.0, float(visible))


func _color_key(color: Color) -> int:
	return (roundi(color.r * 255.0) << 16) | (roundi(color.g * 255.0) << 8) | roundi(color.b * 255.0)


func _rotate_quarter(source: Image, turns: int) -> Image:
	var normalized := posmod(turns, 4)
	if normalized == 0:
		return source.duplicate()
	var output_size := Vector2i(source.get_height(), source.get_width()) if normalized % 2 == 1 else source.get_size()
	var output := Image.create(output_size.x, output_size.y, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	for y in source.get_height():
		for x in source.get_width():
			var target := Vector2i.ZERO
			if normalized == 1:
				target = Vector2i(source.get_height() - 1 - y, x)
			elif normalized == 2:
				target = Vector2i(source.get_width() - 1 - x, source.get_height() - 1 - y)
			else:
				target = Vector2i(y, source.get_width() - 1 - x)
			output.set_pixelv(target, source.get_pixel(x, y))
	return output


func _skin_components(image: Image, area: Rect2i) -> Array[Dictionary]:
	var width := area.size.x
	var height := area.size.y
	var mask := PackedByteArray()
	mask.resize(width * height)
	for local_y in height:
		for local_x in width:
			var color := image.get_pixel(area.position.x + local_x, area.position.y + local_y)
			# Broad warm-color candidate mask. Matching against the full reference crop does the
			# discrimination; this mask only supplies possible face/hair anchor components.
			var skin := color.a >= 0.5 and color.r > 0.45 and color.g > 0.18 and color.b < 0.76 \
				and color.r > color.g * 1.04 and color.g > color.b * 0.72
			mask[local_y * width + local_x] = 1 if skin else 0
	var visited := PackedByteArray()
	visited.resize(mask.size())
	var components: Array[Dictionary] = []
	for start_y in height:
		for start_x in width:
			var start := start_y * width + start_x
			if mask[start] == 0 or visited[start] != 0:
				continue
			var stack: Array[Vector2i] = [Vector2i(start_x, start_y)]
			visited[start] = 1
			var cursor := 0
			var component_area := 0
			var bounds := Rect2i()
			while cursor < stack.size():
				var point := stack[cursor]
				cursor += 1
				component_area += 1
				bounds = Rect2i(point, Vector2i.ONE) if bounds.size == Vector2i.ZERO else bounds.expand(point).expand(point + Vector2i.ONE)
				for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next: Vector2i = point + offset
					if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
						continue
					var next_index: int = next.y * width + next.x
					if mask[next_index] != 0 and visited[next_index] == 0:
						visited[next_index] = 1
						stack.append(next)
			if component_area >= 1:
				components.append({"rect": Rect2i(bounds.position + area.position, bounds.size), "area": component_area})
	return components


func _write_csv(row: String, before: Array[float], after: Array[float]) -> void:
	var lines := PackedStringArray(["frame,before,after"])
	for frame in before.size():
		lines.append("%d,%.3f,%.3f" % [frame + 1, before[frame], after[frame]])
	var file := FileAccess.open("%s/%s_head_audit.csv" % [OUTPUT_DIR, row], FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()


func _update_contacts(before_rows: Dictionary, after_rows: Dictionary) -> void:
	for spec in ROWS:
		var row := String(spec[0])
		var count := int(spec[1])
		var path := "%s/%s_before_after_1x.png" % [OUTPUT_DIR, row]
		var contact := Image.load_from_file(path)
		if contact.is_empty():
			continue
		for frame in count:
			var x := (frame + 1) * CELL + 44
			contact.fill_rect(Rect2i(x, CELL, 40, 10), Color("101729"))
			contact.fill_rect(Rect2i(x, 2 * CELL + 10, 40, 10), Color("101729"))
			_draw_text(contact, Vector2i(x + 4, CELL + 2), "%.2f" % float(before_rows[row][frame]), Color("ffcf6b"))
			_draw_text(contact, Vector2i(x + 4, 2 * CELL + 12), "%.2f" % float(after_rows[row][frame]), Color("8ef2d0"))
		contact.save_png(path)
		var contact_3x := contact.duplicate()
		contact_3x.resize(contact.get_width() * 3, contact.get_height() * 3, Image.INTERPOLATE_NEAREST)
		contact_3x.save_png("%s/%s_before_after_3x.png" % [OUTPUT_DIR, row])


func _draw_text(image: Image, position: Vector2i, value: String, color: Color) -> void:
	var cursor := position.x
	for glyph_name in value:
		if not DIGITS.has(glyph_name):
			cursor += 4
			continue
		var glyph: Array = DIGITS[glyph_name]
		for y in glyph.size():
			for x in 3:
				if glyph[y][x] == "1":
					image.set_pixel(cursor + x, position.y + y, color)
		cursor += 4
