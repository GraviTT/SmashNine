extends SceneTree
## How each picture is stored in the build (D52, web size 2026-11-24, user "추천대로 해").
## Painted illustrations are lossy WebP: the faces, the title background, the story CGs, the
## stage cards and the fighters' main illustrations. Everything else (body and move sheets,
## motion rows, monsters, effects, realm backgrounds, icons, UI frames) is pixel art and stays
## lossless, because lossy WebP keeps the colour at half resolution and smears pixel edges
## (reports/web-size-2026-11-24/).
## The main illustrations (1024x1536) are also cut to 768 px on their long side at import, and
## the web export carries them: the select screen, the story screens and the results draw them,
## and the web build, which had left them out since before the game used them, showed an
## enlarged face in their place (UI audit 2026-11-25, reports/ui-audit-2026-11-25/). The export
## may still leave out an illustration no screen draws (Brave Luna's: the build sits at its budget).
## Files the web export leaves out (generation sources, contact sheets) are skipped.

const ART := "res://assets/art"
const EXPORT_PRESETS := "res://export_presets.cfg"
const EXPORT_SKIPS := ["_source.png", "contact_sheet.png"]
const MAIN_ILLUSTRATION := "_illustration.png"
const MAIN_ILLUSTRATION_LIMIT := 768
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const MENU := preload("res://scripts/ui/FrontendMenu.gd")

var failed := false
var checked := 0
var lossy := 0
var mains := 0

func _initialize() -> void:
	_walk(ART)
	if checked == 0:
		_fail("found no pictures under %s" % ART)
	_check_export()
	if failed:
		quit(1)
		return
	print("Import mode tests passed (%d pictures, %d lossy illustrations, %d of them main illustrations at %d px, in the web export)" % [checked, lossy, mains, MAIN_ILLUSTRATION_LIMIT])
	quit(0)

func _walk(dir: String) -> void:
	for sub in DirAccess.get_directories_at(dir):
		_walk(dir.path_join(sub))
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".png.import"):
			_check(dir.path_join(file.trim_suffix(".import")))

func _check(path: String) -> void:
	for skip in EXPORT_SKIPS:
		if path.ends_with(skip):
			return
	var config := ConfigFile.new()
	if config.load(path + ".import") != OK:
		_fail("cannot read %s.import" % path)
		return
	checked += 1
	var mode: int = config.get_value("params", "compress/mode", 0)
	var quality: float = config.get_value("params", "compress/lossy_quality", 0.7)
	if _is_illustration(path):
		lossy += 1
		if mode != 1 or quality < 0.85:
			_fail("%s is an illustration: import it as Lossy with quality 0.85-0.9 (compress/mode=1), not mode %d quality %.2f" % [path, mode, quality])
		if path.ends_with(MAIN_ILLUSTRATION):
			mains += 1
			var limit: int = config.get_value("params", "process/size_limit", 0)
			if limit != MAIN_ILLUSTRATION_LIMIT:
				_fail("%s is a main illustration: import it at half size (process/size_limit=%d), not %d. At full size nine of them take the web build past its 45 MiB budget" % [path, MAIN_ILLUSTRATION_LIMIT, limit])
	elif mode != 0:
		_fail("%s is pixel art: import it as Lossless (compress/mode=0), not mode %d. If it is a painted illustration, add it to _is_illustration and D52" % [path, mode])

func _is_illustration(path: String) -> bool:
	var file := path.get_file()
	if path.begins_with(ART + "/story/"):
		return file.begins_with("cg_") or file.begins_with("stage_card_")
	if path == ART + "/ui/title_bg.png":
		return true
	return file.contains("_face") or file.ends_with(MAIN_ILLUSTRATION)

## The export must carry every illustration the menus ask for: FrontendMenu.illustration() falls
## back to the face without an error, so a build without them still runs and nobody is told.
func _check_export() -> void:
	var presets := ConfigFile.new()
	if presets.load(EXPORT_PRESETS) != OK:
		_fail("cannot read %s" % EXPORT_PRESETS)
		return
	var seen := 0
	for section in presets.get_sections():
		if not section.begins_with("preset.") or section.ends_with(".options"):
			continue
		seen += 1
		var filters := str(presets.get_value(section, "exclude_filter", "")).split(",", false)
		for id in REGISTRY.get_character_ids():
			for body in REGISTRY.get_bodies(id):
				var texture := MENU.illustration(id, body)
				if texture == null or not texture.resource_path.ends_with(MAIN_ILLUSTRATION):
					_fail("%s %s has no main illustration (the menus would show %s)" % [id, body, "nothing" if texture == null else texture.resource_path])
					continue
				# The export matches a filter against the path with and without res://.
				var path := texture.resource_path
				for filter in filters:
					var pattern := filter.strip_edges()
					if path.matchn(pattern) or path.trim_prefix("res://").matchn(pattern):
						_fail("export preset '%s' leaves out %s (exclude_filter: %s): the select and story screens then show an enlarged face" % [presets.get_value(section, "name", section), path, pattern])
	if seen == 0:
		_fail("%s has no export preset" % EXPORT_PRESETS)

func _fail(message: String) -> void:
	push_error(message)
	failed = true
