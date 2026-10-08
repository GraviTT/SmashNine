extends SceneTree


func _init() -> void:
	var image := Image.load_from_file("../reports/codex-art-17/source/modular_hazards_source.png")
	print("MODULAR_SIZE ", image.get_size())
	print_runs(image, 250, 660)
	image = Image.load_from_file("../reports/codex-art-17/source/quake_source.png")
	print("QUAKE_SIZE ", image.get_size())
	print_runs(image, 360, 820)
	quit()


func print_runs(image: Image, y_start: int, y_end: int) -> void:
	var in_run := false
	var start := 0
	for x in image.get_width():
		var count := 0
		for y in range(y_start, mini(y_end, image.get_height())):
			if image.get_pixel(x, y).a > 0.15:
				count += 1
		var active := count > 8
		if active and not in_run:
			start = x
			in_run = true
		elif not active and in_run:
			print("RUN ", start, "..", x - 1)
			in_run = false
	if in_run:
		print("RUN ", start, "..", image.get_width() - 1)
