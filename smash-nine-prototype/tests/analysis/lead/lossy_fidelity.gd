extends SceneTree
## Saves what the game decodes from the lossy textures (web size, 2026-11-24), so the pixels the
## player sees can be compared with the source PNGs. Usage, from smash-nine-prototype/:
##   <godot> --headless --path . -s tests/analysis/lead/lossy_fidelity.gd -- --out=<dir>
## Writes <dir>/<folder>__<file>.png for every face and the title background.
## reports/web-size-2026-11-24/fidelity.py compares them with the sources.

func _initialize() -> void:
	var out := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	if out.is_empty():
		push_error("pass -- --out=<dir>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out)
	var paths: Array[String] = ["res://assets/art/ui/title_bg.png"]
	for folder in DirAccess.get_directories_at("res://assets/art"):
		for file in DirAccess.get_files_at("res://assets/art/%s" % folder):
			if file.ends_with(".png") and file.contains("_face"):
				paths.append("res://assets/art/%s/%s" % [folder, file])
	var saved := 0
	for path in paths:
		var texture: Texture2D = load(path)
		if texture == null:
			push_error("cannot load %s" % path)
			continue
		var image := texture.get_image()
		if image.is_compressed():
			image.decompress()
		image.convert(Image.FORMAT_RGBA8)
		var name := path.trim_prefix("res://assets/art/").replace("/", "__")
		if image.save_png(out.path_join(name)) == OK:
			saved += 1
	print("saved %d decoded textures to %s" % [saved, out])
	quit(0)
