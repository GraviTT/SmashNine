extends SceneTree

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/art_preview/frey_heads_33"))
	var image := Image.load_from_file("res://assets/art/frey/frey_moves_body_sheet.png")
	if image.is_empty():
		push_error("capture fixture: source body sheet missing")
		quit(1)
		return
	var error := image.save_png("res://tests/art_preview/frey_heads_33/art32_pasted_body_sheet.png")
	if error != OK:
		push_error("capture fixture: %s" % error_string(error))
	quit(0 if error == OK else 1)
