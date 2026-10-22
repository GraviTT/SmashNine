extends SceneTree
const DIALOGUE := preload("res://scripts/ui/StoryDialogue.gd")
const STORY := preload("res://scripts/story/StoryCatalog.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
var finished := 0
var scenes := 0
var presses := 0
var failed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var dialogue := DIALOGUE.new()
	root.add_child(dialogue)
	dialogue.finished.connect(func() -> void: finished += 1)
	for locale in ["en", "ko"]:
		LANGUAGE.set_locale(locale)
		for hero in REGISTRY.get_character_ids():
			for data: Dictionary in STORY.stages():
				for scene in (["pre", "mid", "post"] if data.id == 9 else ["pre", "post"]):
					var lines := STORY.dialogue_for(data, hero, scene)
					dialogue.play(lines, hero, "" if STORY.is_home(data, hero) else data.rival, REGISTRY.get_bodies(hero)[0])
					scenes += 1
					for attempt in lines.size() * 2 + 2:
						if not dialogue.visible:
							break
						await _tap(KEY_J)
					if dialogue.visible or finished != scenes:
						failed += 1
						print("QA21_DIALOGUE_FAIL ", locale, " ", hero, " ", data.id, " ", scene)
	var file := FileAccess.open("res://../reports/codex-qa-21/dialogue-keys.json", FileAccess.WRITE)
	var row := {"scenes": scenes, "finished_signals": finished, "J_presses": presses, "failed": failed}
	file.store_string(JSON.stringify(row, "\t") + "\n")
	print("QA21_DIALOGUE ", JSON.stringify(row))
	dialogue.queue_free()
	await process_frame
	quit(1 if failed else 0)

func _tap(code: int) -> void:
	presses += 1
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await physics_frame
		await process_frame
