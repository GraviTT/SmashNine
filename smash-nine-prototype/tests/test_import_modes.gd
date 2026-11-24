extends SceneTree
## How each picture is stored in the build (D52, web size 2026-11-24, user "추천대로 해").
## Painted illustrations are lossy WebP: the faces, the title background, the story CGs and the
## stage cards. Everything else (body and move sheets, motion rows, monsters, effects, realm
## backgrounds, icons, UI frames) is pixel art and stays lossless, because lossy WebP keeps the
## colour at half resolution and smears pixel edges (reports/web-size-2026-11-24/).
## Files the web export leaves out (illustrations, generation sources, contact sheets) are skipped.

const ART := "res://assets/art"
const EXPORT_SKIPS := ["_illustration.png", "_source.png", "contact_sheet.png"]

var failed := false
var checked := 0
var lossy := 0

func _initialize() -> void:
	_walk(ART)
	if checked == 0:
		_fail("found no pictures under %s" % ART)
	if failed:
		quit(1)
		return
	print("Import mode tests passed (%d pictures, %d lossy illustrations)" % [checked, lossy])
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
	elif mode != 0:
		_fail("%s is pixel art: import it as Lossless (compress/mode=0), not mode %d. If it is a painted illustration, add it to _is_illustration and D52" % [path, mode])

func _is_illustration(path: String) -> bool:
	var file := path.get_file()
	if path.begins_with(ART + "/story/"):
		return file.begins_with("cg_") or file.begins_with("stage_card_")
	if path == ART + "/ui/title_bg.png":
		return true
	return file.contains("_face")

func _fail(message: String) -> void:
	push_error(message)
	failed = true
