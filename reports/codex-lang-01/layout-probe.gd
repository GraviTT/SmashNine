extends SceneTree
## Extra review of real font measurements, all character panels and long HUD messages.
const LANGUAGE := preload("res://scripts/Language.gd")
const MENU := preload("res://scripts/ui/FrontendMenu.gd")
const DIRECTOR := preload("res://scripts/match/MatchDirector.gd")
var rows: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	change_scene_to_file("res://scenes/Main.tscn")
	for frame in 5:
		await process_frame
	var main: Node = current_scene
	var menu: Control = main.hud.frontend
	LANGUAGE.set_locale("ko")
	for id in ["frey", "yuki", "luna", "nova", "rio"]:
		menu.selected_id = id
		menu.show_select()
		for frame in 2:
			await process_frame
		for label: Label in [menu.fighter_name, menu.fighter_role, menu.description]:
			_record("select/" + id, label, label.size)
		for label: Label in menu.skill_labels:
			_record("select/" + id, label, Vector2(366, 44))
	for realm: Dictionary in main.layout.maps:
		var hazard: Dictionary = realm.get("hazard", {})
		if hazard.has("warn_text"):
			main.hud.set_warning_banner(-1, tr(str(hazard.warn_text)))
			_record("hazard/" + str(realm.name), main.hud.warning_label, Vector2(800, 90))
	main.hud.set_warning_banner(30)
	_record("collapse/banner", main.hud.warning_label, Vector2(800, 90))
	var names: String = main.director._realm_names([0, 2, 5, 7])
	main.hud.show_message(tr("Collapse warning: %s will fall in %ds. Reach a safe realm.") % [names, 30])
	_record("collapse/message", main.hud.info_label, Vector2(820, 48))
	for phase in [DIRECTOR.PHASE_EXPLORATION, DIRECTOR.PHASE_CORNER_WARNING, DIRECTOR.PHASE_CONVERGENCE, DIRECTOR.PHASE_CENTRAL, DIRECTOR.PHASE_SUDDEN_DEATH, DIRECTOR.PHASE_OVER]:
		main.hud.set_clock(tr(phase), 120.0, "Collapse warning", 30.0)
		_record("clock/" + phase, main.hud.clock_label, Vector2(500, 30))
	var out := FileAccess.open("res://../reports/codex-lang-01/layout-metrics.json", FileAccess.WRITE)
	out.store_string(JSON.stringify(rows, "\t"))
	for row: Dictionary in rows:
		if float(row.width) > float(row.box_width) and int(row.lines) == 1:
			print("REVIEW_WIDTH %s %.0f > %.0f: %s" % [row.context, row.width, row.box_width, row.text])
		if float(row.line_height) * int(row.lines) > float(row.box_height):
			print("REVIEW_HEIGHT %s: %s" % [row.context, row.text])
	print("Layout probe recorded %d text blocks" % rows.size())
	LANGUAGE.set_locale("en")
	quit()

func _record(context: String, label: Label, box: Vector2) -> void:
	var font: Font = label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var widest := 0.0
	for line in label.text.split("\n"):
		widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	rows.append({"context": context, "text": label.text, "width": widest, "lines": label.get_line_count(), "line_height": label.get_line_height(), "box_width": box.x, "box_height": box.y})
