extends SceneTree

const SOURCE_DIR := "res://assets/art/vfx"

func _init() -> void:
	for file_name in DirAccess.get_files_at(SOURCE_DIR):
		if not file_name.ends_with("_source.png"):
			continue
		var image := Image.load_from_file(SOURCE_DIR.path_join(file_name))
		var corners := [
			image.get_pixel(0, 0),
			image.get_pixel(image.get_width() - 1, 0),
			image.get_pixel(0, image.get_height() - 1),
			image.get_pixel(image.get_width() - 1, image.get_height() - 1),
		]
		print("[source] %s %dx%d alpha=%s" % [file_name, image.get_width(), image.get_height(), corners.map(func(color: Color) -> float: return color.a)])
	quit()
