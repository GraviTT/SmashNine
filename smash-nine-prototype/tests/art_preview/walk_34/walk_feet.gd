extends SceneTree
# Walk row (row 1): silhouette change in the feet band (y 100..120) between consecutive frames,
# and the stance width (opaque x span at y 112..120) per frame.
func _init() -> void:
	for path in OS.get_cmdline_user_args():
		var img := Image.load_from_file(path)
		var change := 0.0
		var spans: Array[String] = []
		for f in 6:
			var g := (f + 1) % 6
			var diff := 0
			var area := 0
			var lo := 999
			var hi := -1
			for y in range(100, 121):
				for x in 128:
					var p := img.get_pixel(f * 128 + x, 128 + y).a > 0.5
					var q := img.get_pixel(g * 128 + x, 128 + y).a > 0.5
					if p or q:
						area += 1
						if p != q: diff += 1
					if y >= 112 and p:
						lo = mini(lo, x)
						hi = maxi(hi, x)
			change += float(diff) / maxf(area, 1.0)
			spans.append(str(hi - lo))
		print("%-24s feet silhouette change %4.1f%%  stance width %s" % [path.get_file(), change / 6.0 * 100.0, "/".join(spans)])
	quit()
