extends SceneTree
## Lead fix (2026-10-08): fire_pillar_mid.png frames 2-5 had row 110 transparent across the
## column body (left over from CODEX-ART-17 round 2, which filled rows 111-123 below it), so a
## dark line crossed every repeat in game. Fills each transparent pixel inside a frame's body
## with the average of the pixels above and below. Run from smash-nine-prototype/:
## godot --headless --path . -s tests/art_preview/fire_row_fix_lead/fill_holes.gd

const PATH := "res://assets/art/hazards/fire_pillar_mid.png"
const FRAMES := 6

func _initialize() -> void:
	var file := ProjectSettings.globalize_path(PATH)
	var img := Image.load_from_file(file)
	img.convert(Image.FORMAT_RGBA8)
	var fw := img.get_width() / FRAMES
	var filled := 0
	for f in FRAMES:
		# Body columns: opaque in the middle row of the frame.
		var body: Array[int] = []
		for x in fw:
			if img.get_pixel(f * fw + x, img.get_height() / 2).a > 0.5:
				body.append(f * fw + x)
		for y in range(1, img.get_height() - 1):
			var holes := 0
			for x in body:
				if img.get_pixel(x, y).a < 0.5:
					holes += 1
			# Only whole-row holes (a seam), not the flame's own edge.
			if holes <= body.size() / 4:
				continue
			for x in body:
				var c := img.get_pixel(x, y)
				if c.a >= 0.5:
					continue
				var up := img.get_pixel(x, y - 1)
				var down := img.get_pixel(x, y + 1)
				img.set_pixel(x, y, up.lerp(down, 0.5) if up.a >= 0.5 and down.a >= 0.5 else (up if up.a >= 0.5 else down))
				filled += 1
	img.save_png(file)
	print("FIRE_ROW_FIX filled %d pixels" % filled)
	quit()
