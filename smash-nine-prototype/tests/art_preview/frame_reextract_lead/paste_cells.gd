extends SceneTree
## Copies chosen 128 px cells from one sheet into another (merging a unit's frame fixes when the
## rest of its sheet is older than the lead's).
## Usage: godot --headless --path . -s tests/art_preview/frame_reextract_lead/paste_cells.gd --
##        <from.png> <into.png> r5c1 r5c2 ...

const CELL := 128

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var from := Image.load_from_file(args[0])
	var into := Image.load_from_file(args[1])
	from.convert(Image.FORMAT_RGBA8)
	into.convert(Image.FORMAT_RGBA8)
	for cell_name in args.slice(2):
		var row := int(cell_name.get_slice("c", 0).trim_prefix("r"))
		var column := int(cell_name.get_slice("c", 1))
		var rect := Rect2i(column * CELL, row * CELL, CELL, CELL)
		into.fill_rect(rect, Color(0, 0, 0, 0))
		into.blit_rect(from, rect, rect.position)
		print("pasted ", cell_name)
	into.save_png(args[1])
	quit(0)
