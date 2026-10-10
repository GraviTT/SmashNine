extends SceneTree

func _init() -> void:
	var image := Image.load_from_file("res://tests/art_preview/frey_redo_32/idle_reference.png")
	image.resize(1024, 1024, Image.INTERPOLATE_NEAREST)
	var error := image.save_png("res://tests/art_preview/frey_redo_32/idle_reference_8x.png")
	quit(0 if error == OK else 1)
