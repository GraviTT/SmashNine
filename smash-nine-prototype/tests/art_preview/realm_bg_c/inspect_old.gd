extends SceneTree

const REALMS := [
	"center", "asgard", "midgard",
	"niflheim", "alfheim", "muspelheim",
	"svartalfheim", "vanaheim", "jotunheim",
]

func _init() -> void:
	var cell := Vector2i(640, 360)
	var sheet := Image.create(cell.x * 3, cell.y * 3, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#11131b"))
	for i in REALMS.size():
		var dir := "res://assets/art/realm_%s" % REALMS[i]
		var far := Image.load_from_file(dir + "/bg_far.png")
		var mid := Image.load_from_file(dir + "/bg_mid.png")
		far.resize(cell.x, cell.y, Image.INTERPOLATE_NEAREST)
		mid.resize(cell.x, cell.y, Image.INTERPOLATE_NEAREST)
		var composite := far.duplicate()
		composite.blend_rect(mid, Rect2i(Vector2i.ZERO, cell), Vector2i.ZERO)
		sheet.blit_rect(composite, Rect2i(Vector2i.ZERO, cell), Vector2i((i % 3) * cell.x, (i / 3) * cell.y))
	var out_dir := "res://../reports/codex-art-15"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var err := sheet.save_png(out_dir + "/old_contact.png")
	print("OLD_CONTACT save=", err, " size=", sheet.get_size())
	quit(0 if err == OK else 1)
