extends SceneTree

const CELL := 128
const BASE_SHEET := "res://assets/art/frey/frey_sheet.png"
const MOVE_SHEET := "res://assets/art/frey/frey_moves_sheet.png"
const ROWS := [
	["attack_up", 4],
	["attack_down", 4],
	["attack_air_side", 4],
	["dash_strike", 4],
	["rising_cleave", 5],
	["spike_followup", 4],
	["descent", 6],
	["tumble", 4],
]


func _init() -> void:
	var base := Image.load_from_file(BASE_SHEET)
	var moves := Image.load_from_file(MOVE_SHEET)
	if base.is_empty() or moves.is_empty():
		printerr("scale_audit: failed to load Frey sheets")
		quit(1)
		return
	var idle := base.get_region(Rect2i(0, 0, CELL, CELL))
	var idle_core := _core_area(idle)
	if idle_core <= 0:
		printerr("scale_audit: idle core is empty")
		quit(1)
		return
	var lines := PackedStringArray()
	lines.append("method=one-pixel 8-neighbour erosion; scale=sqrt(eroded_opaque_area/idle_eroded_opaque_area)")
	lines.append("idle_core_pixels=%d" % idle_core)
	lines.append("row,frames,min,max,spread,per_frame")
	for row_index in ROWS.size():
		var row: Array = ROWS[row_index]
		var scales := PackedFloat32Array()
		var frame_text := PackedStringArray()
		for frame_index in int(row[1]):
			var frame := moves.get_region(Rect2i(frame_index * CELL, row_index * CELL, CELL, CELL))
			var core := _core_area(frame)
			var scale := sqrt(float(core) / float(idle_core)) if core > 0 else 0.0
			scales.append(scale)
			frame_text.append("%d:%.3f" % [frame_index + 1, scale])
		var minimum := scales[0]
		var maximum := scales[0]
		for scale in scales:
			minimum = minf(minimum, scale)
			maximum = maxf(maximum, scale)
		var spread := maximum - minimum
		lines.append("%s,%d,%.3f,%.3f,%.3f,%s" % [row[0], row[1], minimum, maximum, spread, " ".join(frame_text)])
	var output := "\n".join(lines) + "\n"
	print(output)
	var output_path := "res://tests/art_preview/frey_redo_32/current_scale_audit.txt"
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		printerr("scale_audit: cannot write %s" % output_path)
		quit(1)
		return
	file.store_string(output)
	quit(0)


func _core_area(image: Image) -> int:
	# Erosion ignores the one-pixel sword trails, loose sparks and anti-aliased crumbs that
	# would inflate a simple bounding box. The remaining dense armor/hair/cape mass is
	# orientation-independent, so rotated tumble frames are measured on the same basis.
	var width := image.get_width()
	var height := image.get_height()
	var mask := PackedByteArray()
	mask.resize(width * height)
	for y in height:
		for x in width:
			mask[y * width + x] = 1 if image.get_pixel(x, y).a >= 0.5 else 0
	var count := 0
	for y in range(1, height - 1):
		for x in range(1, width - 1):
			var solid := true
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					if mask[(y + oy) * width + x + ox] == 0:
						solid = false
						break
				if not solid:
					break
			if solid:
				count += 1
	return count
