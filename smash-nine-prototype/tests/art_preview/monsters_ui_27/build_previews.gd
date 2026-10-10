extends SceneTree
## Review-only contact sheets assembled from final runtime assets at 1x or nearest downscale.

const OUT_DIR := "res://tests/art_preview/monsters_ui_27"
const MONSTER_DIR := "res://assets/art/monsters"
const UI_DIR := "res://assets/art/ui"

func _initialize() -> void:
	_build_part1_contact()
	_build_hud_contact()
	print("ART27_PREVIEW_OK part1=1280x720 hud=1280x720")
	quit(0)

func _build_part1_contact() -> void:
	var output := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	output.fill(Color("080a18"))
	var title := Image.load_from_file("%s/title_bg.png" % UI_DIR)
	var title_preview := title.duplicate()
	title_preview.resize(960, 540, Image.INTERPOLATE_NEAREST)
	output.blit_rect(title_preview, Rect2i(Vector2i.ZERO, title_preview.get_size()), Vector2i.ZERO)
	var logo := Image.load_from_file("%s/title_logo.png" % UI_DIR)
	if logo != null and not logo.is_empty():
		var logo_preview := logo.duplicate()
		logo_preview.resize(320, 100, Image.INTERPOLATE_NEAREST)
		output.blend_rect(logo_preview, Rect2i(Vector2i.ZERO, logo_preview.get_size()), Vector2i(320, 20))
	# 1x runtime cells: four idle poses for direct mossling/golem weight comparison.
	for index in 4:
		_blit(output, "%s/mossling_sheet.png" % MONSTER_DIR, Rect2i(index * 96, 0, 96, 96), Vector2i(16 + index * 104, 590))
		_blit(output, "%s/jotunheim_rune_golem_sheet.png" % MONSTER_DIR, Rect2i(index * 96, 0, 96, 96), Vector2i(520 + index * 104, 590))
	var realm := Image.load_from_file("res://assets/art/realm_jotunheim/bg_mid.png")
	if realm != null and not realm.is_empty():
		var strip := _cover(realm, Vector2i(304, 720))
		output.blit_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), Vector2i(976, 0))
		output.blend_rect(_solid(Vector2i(304, 720), Color(0.01, 0.02, 0.06, 0.3)), Rect2i(0, 0, 304, 720), Vector2i(976, 0))
		for row in 4:
			_blit(output, "%s/jotunheim_rune_golem_sheet.png" % MONSTER_DIR, Rect2i(0, row * 96, 96, 96), Vector2i(1080, 44 + row * 150))
	var golem := Image.load_from_file("%s/jotunheim_rune_golem_sheet.png" % MONSTER_DIR)
	var mossling := Image.load_from_file("%s/mossling_sheet.png" % MONSTER_DIR)
	print("metric title=%s edge_fill_pixels=%d golem_alpha=%.3f mossling_alpha=%.3f" % [
		title.get_size(), _edge_fill_pixels(title, Color("06152f")), _alpha_ratio(golem), _alpha_ratio(mossling)
	])
	var error: Error = output.save_png("%s/contact_part1.png" % OUT_DIR)
	if error != OK:
		push_error("Could not save Part 1 contact (%s)" % error)

func _build_hud_contact() -> void:
	var output := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	output.fill(Color("080a18"))
	_blit(output, "%s/frames/result_panel.png" % UI_DIR, Rect2i(0, 0, 960, 520), Vector2i(160, 36))
	for index in 3:
		_blit(output, "%s/frames/card_panel.png" % UI_DIR, Rect2i(0, 0, 240, 112), Vector2i(236 + index * 268, 110))
	for index in 4:
		_blit(output, "%s/frames/skill_slot.png" % UI_DIR, Rect2i(0, 0, 72, 72), Vector2i(430 + index * 90, 258))
	_blit(output, "%s/frames/hp_bar.png" % UI_DIR, Rect2i(0, 0, 320, 32), Vector2i(480, 372))
	_blit(output, "%s/frames/menu_button.png" % UI_DIR, Rect2i(0, 0, 360, 56), Vector2i(460, 438))
	_blit(output, "%s/frames/menu_button.png" % UI_DIR, Rect2i(0, 0, 360, 56), Vector2i(460, 510))
	for index in 4:
		var icon_names := ["frey_j", "frey_k", "frey_l", "frey_i"]
		_blit(output, "res://assets/art/skill_icons/%s.png" % icon_names[index], Rect2i(0, 0, 40, 40), Vector2i(446 + index * 90, 274))
	var error: Error = output.save_png("%s/contact_hud.png" % OUT_DIR)
	if error != OK:
		push_error("Could not save HUD contact (%s)" % error)

func _blit(target: Image, path: String, region: Rect2i, at: Vector2i) -> void:
	var source := Image.load_from_file(path)
	if source == null or source.is_empty():
		push_error("Preview source missing: %s" % path)
		return
	target.blend_rect(source, region, at)

func _cover(source: Image, target_size: Vector2i) -> Image:
	var target_ratio := float(target_size.x) / float(target_size.y)
	var source_ratio := float(source.get_width()) / float(source.get_height())
	var crop_size := source.get_size()
	if source_ratio > target_ratio:
		crop_size.x = int(round(source.get_height() * target_ratio))
	else:
		crop_size.y = int(round(source.get_width() / target_ratio))
	var crop := source.get_region(Rect2i((source.get_size() - crop_size) / 2, crop_size))
	crop.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
	return crop

func _solid(size: Vector2i, color: Color) -> Image:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return image

func _alpha_ratio(image: Image) -> float:
	var visible := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a >= 0.16:
				visible += 1
	return float(visible) / float(image.get_width() * image.get_height())

func _edge_fill_pixels(image: Image, fill: Color) -> int:
	var count := 0
	for x in image.get_width():
		for y in [0, image.get_height() - 1]:
			if _rgb_distance(image.get_pixel(x, y), fill) < 0.01:
				count += 1
	for y in image.get_height():
		for x in [0, image.get_width() - 1]:
			if _rgb_distance(image.get_pixel(x, y), fill) < 0.01:
				count += 1
	return count

func _rgb_distance(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()
