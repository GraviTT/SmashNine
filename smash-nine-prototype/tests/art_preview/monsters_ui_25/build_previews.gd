extends SceneTree
## Builds review-only contact sheets from final 1x assets. All resizing is nearest-neighbour
## downsampling; runtime files are not changed here.

const OUT_DIR := "res://tests/art_preview/monsters_ui_25"
const MONSTER_DIR := "res://assets/art/monsters"
const UI_DIR := "res://assets/art/ui"
const REALMS := [
	{"key": "asgard", "skin": "asgard_aegis_ram", "accent": Color(1.0, 0.72, 0.34)},
	{"key": "niflheim", "skin": "niflheim_frost_owl", "accent": Color(0.66, 0.95, 1.0)},
	{"key": "alfheim", "skin": "alfheim_moon_moth", "accent": Color(0.7, 0.82, 1.0)},
	{"key": "svartalfheim", "skin": "svartalfheim_gear_beetle", "accent": Color(0.95, 0.62, 0.25)},
	{"key": "vanaheim", "skin": "vanaheim_vine_hound", "accent": Color(0.42, 0.95, 0.55)},
	{"key": "jotunheim", "skin": "jotunheim_rune_golem", "accent": Color(0.62, 0.72, 0.95)},
	{"key": "yggdrasil_heart", "skin": "yggdrasil_root_oracle", "accent": Color(1.0, 0.55, 0.95)},
]
const ALL_EMBLEMS := [
	"asgard", "midgard", "niflheim", "alfheim", "muspelheim",
	"svartalfheim", "vanaheim", "jotunheim", "yggdrasil_heart",
]

func _initialize() -> void:
	_build_monster_contact()
	_build_ui_contact()
	print("ART25_PREVIEW_OK monster_contact=1280x896 ui_contact=1280x720")
	quit(0)

func _build_monster_contact() -> void:
	var output := Image.create(1280, 896, false, Image.FORMAT_RGBA8)
	output.fill(Color("071426"))
	for index in REALMS.size():
		var entry: Dictionary = REALMS[index]
		var y := index * 128
		var bg_key := "center" if entry.key == "yggdrasil_heart" else str(entry.key)
		var background := Image.load_from_file("res://assets/art/realm_%s/bg_mid.png" % bg_key)
		if background != null and not background.is_empty():
			var strip := _cover(background, Vector2i(1280, 128))
			output.blit_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), Vector2i(0, y))
			output.blend_rect(_solid(Vector2i(1280, 128), Color(0.015, 0.025, 0.06, 0.42)), Rect2i(0, 0, 1280, 128), Vector2i(0, y))
		_blit(output, "%s/realm_emblems/%s.png" % [UI_DIR, entry.key], Rect2i(0, 0, 32, 32), Vector2i(24, y + 48))
		_blit(output, "%s/%s_sheet.png" % [MONSTER_DIR, entry.skin], Rect2i(0, 0, 96, 96), Vector2i(104, y + 16))
		_blit(output, "%s/mossling_sheet.png" % MONSTER_DIR, Rect2i(0, 0, 96, 96), Vector2i(252, y + 16))
		_blit(output, "%s/ember_imp_sheet.png" % MONSTER_DIR, Rect2i(0, 0, 96, 96), Vector2i(400, y + 16))
		_blit(output, "res://assets/art/frey/frey_sheet.png", Rect2i(0, 0, 128, 128), Vector2i(548, y))
		var sheet := Image.load_from_file("%s/%s_sheet.png" % [MONSTER_DIR, entry.skin])
		print("metric %s size=%s alpha=%.3f palette_rms=%.3f" % [
			entry.skin, sheet.get_size(), _alpha_ratio(sheet), _palette_rms(sheet, entry.accent)
		])
	var error := output.save_png("%s/contact_monsters.png" % OUT_DIR)
	if error != OK:
		push_error("Could not save monster contact (%s)" % error)

func _build_ui_contact() -> void:
	var output := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	output.fill(Color("080a18"))
	var title := Image.load_from_file("%s/title_bg.png" % UI_DIR)
	title.resize(600, 338, Image.INTERPOLATE_NEAREST)
	output.blit_rect(title, Rect2i(Vector2i.ZERO, title.get_size()), Vector2i(16, 16))
	var result := Image.load_from_file("%s/frames/result_panel.png" % UI_DIR)
	result.resize(620, 336, Image.INTERPOLATE_NEAREST)
	output.blend_rect(result, Rect2i(Vector2i.ZERO, result.get_size()), Vector2i(644, 16))
	for index in ALL_EMBLEMS.size():
		_blit(output, "%s/realm_emblems/%s.png" % [UI_DIR, ALL_EMBLEMS[index]], Rect2i(0, 0, 32, 32), Vector2i(28 + index * 48, 382))
	var statuses := ["super_armor", "stun", "luna_star_charge", "frey_pursuit_mark", "shield_break", "low_hp"]
	for index in statuses.size():
		_blit(output, "%s/status/%s.png" % [UI_DIR, statuses[index]], Rect2i(0, 0, 24, 24), Vector2i(32 + index * 42, 438))
	_blit(output, "%s/frames/skill_slot.png" % UI_DIR, Rect2i(0, 0, 72, 72), Vector2i(24, 492))
	_blit(output, "%s/frames/hp_bar.png" % UI_DIR, Rect2i(0, 0, 320, 32), Vector2i(120, 512))
	_blit(output, "%s/frames/card_panel.png" % UI_DIR, Rect2i(0, 0, 240, 112), Vector2i(464, 486))
	_blit(output, "%s/frames/menu_button.png" % UI_DIR, Rect2i(0, 0, 360, 56), Vector2i(24, 620))
	var cutin := Image.load_from_file("res://assets/art/vfx/ult_cutin_band.png")
	if cutin != null and not cutin.is_empty():
		cutin.resize(560, 112, Image.INTERPOLATE_NEAREST)
		output.blend_rect(cutin, Rect2i(Vector2i.ZERO, cutin.get_size()), Vector2i(712, 450))
	var error := output.save_png("%s/contact_ui.png" % OUT_DIR)
	if error != OK:
		push_error("Could not save UI contact (%s)" % error)

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

## RMS RGB distance includes the dark outline, so it is a comparative palette fact rather
## than a quality score. Lower means the sheet as a whole sits closer to its realm accent.
func _palette_rms(image: Image, accent: Color) -> float:
	var sum_squared := 0.0
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 0.16:
				continue
			var delta := Vector3(color.r - accent.r, color.g - accent.g, color.b - accent.b)
			sum_squared += delta.length_squared()
			count += 1
	return sqrt(sum_squared / maxf(1.0, float(count)))
