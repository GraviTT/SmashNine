extends SceneTree
# Cells whose opaque pixels come closer than 4 px to a cell edge (test_sprite_frames contract).
func _init() -> void:
	for path in OS.get_cmdline_user_args():
		var img := Image.load_from_file(path)
		var out: Array[String] = []
		for r in img.get_height() / 128:
			for c in 6:
				var m := 99
				for y in 128:
					for x in 128:
						if img.get_pixel(c * 128 + x, r * 128 + y).a > 0.0:
							m = mini(m, mini(mini(x, 127 - x), mini(y, 127 - y)))
				if m < 4: out.append("r%dc%d:%d" % [r, c, m])
		print(path.get_file(), " margin<4: ", out.size(), "  ", " ".join(out))
	quit()
