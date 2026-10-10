extends SceneTree
func _init() -> void:
	for path in OS.get_cmdline_user_args():
		var img := Image.load_from_file(path)
		var out: Array[String] = []
		for r in img.get_height() / 128:
			for c in 6:
				var x0 := c * 128
				var y0 := r * 128
				var e := {"L": 0, "R": 0, "T": 0, "B": 0}
				var any := false
				for i in 128:
					if img.get_pixel(x0, y0 + i).a > 0.0: e.L += 1
					if img.get_pixel(x0 + 127, y0 + i).a > 0.0: e.R += 1
					if img.get_pixel(x0 + i, y0).a > 0.0: e.T += 1
					if img.get_pixel(x0 + i, y0 + 127).a > 0.0: e.B += 1
				var bad := ""
				for k in e:
					if e[k] >= 3: bad += "%s%d " % [k, e[k]]
				if bad != "": out.append("r%dc%d(%s)" % [r, c, bad.strip_edges()])
		print(path.get_file(), " edge-touching: ", out.size(), "  ", " ".join(out))
	quit()
