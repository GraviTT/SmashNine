extends SceneTree
## Measures rendered deltas against each scenario's final clean frame. Values are from PNG pixels,
## then divided by the 2x window/content scale to report game-screen pixels.

const REPORT_RELATIVE := "../reports/codex-art-20/before"
const GROUPS := ["parry", "landing", "hit_light", "hit_heavy", "streak_light", "streak_heavy", "guard_block", "seal_break"]

func _initialize() -> void:
	var base := ProjectSettings.globalize_path("res://").path_join(REPORT_RELATIVE)
	var lines: Array[String] = ["Captured-frame delta measurements (raw PNG px; game px = raw / 2)"]
	for group in GROUPS:
		var files := _pngs(base.path_join(group))
		var baseline := Image.load_from_file(files[-1])
		var visible := 0
		lines.append("[%s]" % group)
		for index in files.size() - 1:
			var frame := Image.load_from_file(files[index])
			var rect := _difference_rect(frame, baseline, 0.055)
			if rect.size.x * rect.size.y >= 16:
				visible += 1
				lines.append("f%02d raw=(%d,%d %dx%d) game=(%.1f,%.1f %.1fx%.1f)" % [index, rect.position.x, rect.position.y, rect.size.x, rect.size.y, rect.position.x / 2.0, rect.position.y / 2.0, rect.size.x / 2.0, rect.size.y / 2.0])
		lines.append("visible_frames=%d duration_at_60fps=%.3fs" % [visible, visible / 60.0])
	var text := "\n".join(lines) + "\n"
	FileAccess.open(base.path_join("measurements.txt"), FileAccess.WRITE).store_string(text)
	print(text)
	quit(0)

func _pngs(path: String) -> Array[String]:
	var result: Array[String] = []
	for file in DirAccess.get_files_at(path):
		if file.ends_with(".png"):
			result.append(path.path_join(file))
	result.sort()
	return result

func _difference_rect(image: Image, baseline: Image, threshold: float) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in image.get_height():
		for x in image.get_width():
			var a := image.get_pixel(x, y)
			var b := baseline.get_pixel(x, y)
			if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) + absf(a.a - b.a) > threshold:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
