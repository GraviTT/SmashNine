extends SceneTree
const MAIN := preload("res://scripts/Main.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const SPEED := preload("res://scripts/GameSpeed.gd")
var rows: Array = []
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	MAIN.next_screen = "title"
	MAIN.session_mode = "battle_royale"
	change_scene_to_file("res://scenes/Main.tscn")
	await _frames(6)
	var baseline := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphan_base := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var cycle := 0
	for locale in ["en", "ko"]:
		var main: Node = current_scene
		main.hud.frontend.show_options()
		if LANGUAGE.locale != locale:
			main.hud.frontend.language_button.pressed.emit()
			await _frames(6)
		main = current_scene
		var speeds: Array = []
		for pick in 4:
			speeds.append(SPEED.factor)
			main.hud.frontend.speed_button.pressed.emit()
		main.hud.frontend.show_title()
		for id in REGISTRY.get_character_ids():
			for body in REGISTRY.get_bodies(id):
				main = current_scene
				await _tap(KEY_ENTER)
				main.hud.frontend.portrait_buttons[REGISTRY.get_character_ids().find(id)].pressed.emit()
				if MAIN.human_body != body:
					main.hud.frontend.body_button.pressed.emit()
				main.hud.frontend.buttons[8].pressed.emit()
				await _frames(6)
				var human: Node = main._get_human_player()
				var correct: bool = is_instance_valid(human) and human.character_id == id and human.body_type == body
				main.director._finish(human, "qa21")
				await _frames(3)
				await _tap(KEY_R)
				await _frames(6)
				main = current_scene
				correct = correct and main.match_started and main._get_human_player().character_id == id and main._get_human_player().body_type == body
				main.director._finish(main._get_human_player(), "qa21")
				await _frames(3)
				main.hud.frontend.buttons[cycle % 2 + 1].pressed.emit()
				await _frames(6)
				main = current_scene
				if main.hud.frontend.screen == "select":
					await _tap(KEY_ESCAPE)
				await _frames(3)
				var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
				var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
				var ok: bool = correct and main.hud.frontend.screen == "title" and absi(nodes - baseline) <= 5 and orphans == orphan_base
				if not ok:
					failures += 1
				var row := {"cycle": cycle, "locale": locale, "hero": id, "body": body, "selection_rematch_ok": correct, "title_nodes": nodes, "baseline": baseline, "orphans": orphans, "ok": ok, "speeds": speeds}
				rows.append(row)
				print("QA21_MENU ", JSON.stringify(row))
				cycle += 1
	var output := FileAccess.open("res://../reports/codex-qa-21/menu-cycles.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"failures": failures, "cycles": rows}, "\t") + "\n")
	quit(1 if failures else 0)

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _tap(code: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await _frames(2)
