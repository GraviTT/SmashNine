extends SceneTree
## Real shaped text bounds for the complete bilingual script and each hero's ending.
const DIALOGUE := preload("res://scripts/ui/StoryDialogue.gd")
const SCREENS := preload("res://scripts/ui/StoryScreens.gd")
const STORY := preload("res://scripts/story/StoryCatalog.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
var failed := false
var checked_lines := 0
var maximum_dialogue_height := 0.0
var maximum_ending_height := 0.0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	LANGUAGE.load_saved()
	var dialogue := DIALOGUE.new()
	var menu := SCREENS.new()
	root.add_child(dialogue)
	root.add_child(menu)
	await process_frame
	for locale in ["en", "ko"]:
		LANGUAGE.set_locale(locale)
		for hero in REGISTRY.get_character_ids():
			for data: Dictionary in STORY.stages():
				for scene in (["pre", "mid", "post"] if int(data.id) == 9 else ["pre", "post"]):
					var lines := STORY.dialogue_for(data, hero, scene)
					dialogue.play(lines, hero, "" if STORY.is_home(data, hero) else str(data.rival), REGISTRY.get_bodies(hero)[0])
					for index in lines.size():
						dialogue.line_index = index
						dialogue._show_line()
						dialogue.line_label.visible_characters = -1
						dialogue._characters = dialogue.line_label.get_total_character_count()
						await process_frame
						checked_lines += 1
						var height := float(dialogue.line_label.get_line_count() * dialogue.line_label.get_line_height())
						maximum_dialogue_height = maxf(maximum_dialogue_height, height)
						_check(height <= 120.0, "Dialogue text overflows the preserved box: %s %s %s" % [locale, hero, str(lines[index][1])])
			menu.selected_id = hero
			menu.body = REGISTRY.get_bodies(hero)[0]
			menu.show_story_ending()
			await process_frame
			var ending: Array[String] = []
			for id in STORY.ending_ids(hero):
				ending.append(tr(id))
			var found := 0
			for child in menu.content.get_children():
				if child is Label and ending.has(child.text):
					found += 1
					checked_lines += 1
					var height := float(child.get_line_count() * child.get_line_height())
					maximum_ending_height = maxf(maximum_ending_height, height)
					_check(height <= 80.0, "Ending text overflows its block: %s %s %s" % [locale, hero, child.text])
			_check(found == 3, "Ending must render all three existing script lines")
	dialogue.queue_free()
	menu.queue_free()
	await process_frame
	LANGUAGE.set_locale("en")
	if not failed:
		print("Story text fit tests passed (%d bilingual dialogue/ending lines; maximum dialogue %.0f/120 px, ending %.0f/80 px)" % [checked_lines, maximum_dialogue_height, maximum_ending_height])
	quit(1 if failed else 0)
