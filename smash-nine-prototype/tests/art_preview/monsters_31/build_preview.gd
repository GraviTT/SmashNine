extends SceneTree
## One-pixel-scale review sheet: both realm skins beside one 128 px fighter cell.

const OUT := "res://tests/art_preview/monsters_31/contact_pairs.png"
const DIR := "res://assets/art/monsters"
const REALMS := [
	["asgard", "asgard_aegis_ram", "asgard_runic_raven"],
	["midgard", "mossling", "midgard_rooftop_slinger"],
	["niflheim", "niflheim_glacier_wolf", "niflheim_frost_owl"],
	["alfheim", "alfheim_moon_stag", "alfheim_moon_moth"],
	["muspelheim", "muspelheim_magma_boar", "ember_imp"],
	["svartalfheim", "svartalfheim_gear_beetle", "svartalfheim_cog_drone"],
	["vanaheim", "vanaheim_vine_hound", "vanaheim_seed_sprite"],
	["jotunheim", "jotunheim_rune_golem", "jotunheim_storm_wisp"],
	["center", "yggdrasil_root_guardian", "yggdrasil_root_oracle"],
]

func _initialize() -> void:
	var output := Image.create(1280, 1152, false, Image.FORMAT_RGBA8)
	output.fill(Color("071426"))
	for index in REALMS.size():
		var entry: Array = REALMS[index]
		var y := index * 128
		var background := Image.load_from_file("res://assets/art/realm_%s/bg_mid.png" % entry[0])
		if background != null and not background.is_empty():
			var strip := _cover(background, Vector2i(1280, 128))
			output.blit_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), Vector2i(0, y))
			var veil := Image.create(1280, 128, false, Image.FORMAT_RGBA8)
			veil.fill(Color(0.01, 0.02, 0.05, 0.38))
			output.blend_rect(veil, Rect2i(0, 0, 1280, 128), Vector2i(0, y))
		_blit(output, "%s/%s_sheet.png" % [DIR, entry[1]], Rect2i(0, 0, 96, 96), Vector2i(96, y + 16))
		_blit(output, "%s/%s_sheet.png" % [DIR, entry[2]], Rect2i(0, 0, 96, 96), Vector2i(256, y + 16))
		_blit(output, "res://assets/art/frey/frey_sheet.png", Rect2i(0, 0, 128, 128), Vector2i(432, y))
		var projectile_path := "%s/%s_projectile.png" % [DIR, entry[2]]
		if FileAccess.file_exists(projectile_path):
			_blit(output, projectile_path, Rect2i(0, 0, 24, 24), Vector2i(376, y + 52))
	if output.save_png(OUT) != OK:
		push_error("Could not save %s" % OUT)
		quit(1)
		return
	print("ART31_PREVIEW_OK contact=1280x1152")
	quit(0)

func _blit(target: Image, path: String, region: Rect2i, at: Vector2i) -> void:
	var source := Image.load_from_file(path)
	if source == null or source.is_empty():
		push_error("Missing preview source: %s" % path)
		return
	target.blend_rect(source, region, at)

func _cover(source: Image, target_size: Vector2i) -> Image:
	var target_ratio := float(target_size.x) / target_size.y
	var source_ratio := float(source.get_width()) / source.get_height()
	var crop_size := source.get_size()
	if source_ratio > target_ratio:
		crop_size.x = int(round(source.get_height() * target_ratio))
	else:
		crop_size.y = int(round(source.get_width() / target_ratio))
	var result := source.get_region(Rect2i((source.get_size() - crop_size) / 2, crop_size))
	result.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
	return result
