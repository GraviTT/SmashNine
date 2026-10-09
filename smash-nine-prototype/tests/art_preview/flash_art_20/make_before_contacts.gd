extends SceneTree
## Builds compact review sheets from the running-game captures without external image tools.

func _initialize() -> void:
	var base := ProjectSettings.globalize_path("res://").path_join("../reports/codex-art-20/before")
	_make(base.path_join("attacks"), base.path_join("attacks_contact.png"), 5)
	_make(base.path_join("ultimates"), base.path_join("ultimates_contact.png"), 5)
	_make(base.path_join("support"), base.path_join("support_contact.png"), 4)
	quit(0)

func _make(folder: String, output: String, columns: int) -> void:
	var files: Array[String] = []
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(".png"):
			files.append(file)
	files.sort()
	if files.is_empty():
		return
	var first := Image.load_from_file(folder.path_join(files[0]))
	var thumb := Vector2i(first.get_width() / 4, first.get_height() / 4)
	var rows := ceili(float(files.size()) / columns)
	var sheet := Image.create(thumb.x * columns, thumb.y * rows, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("101522"))
	for index in files.size():
		var image := Image.load_from_file(folder.path_join(files[index]))
		image.resize(thumb.x, thumb.y, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(image, Rect2i(Vector2i.ZERO, thumb), Vector2i(index % columns * thumb.x, index / columns * thumb.y))
	sheet.save_png(output)
	print("saved ", output)
