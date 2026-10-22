extends SceneTree
## Instrument only the test subclass to retain the slot requested by production UI helpers.
const LANGUAGE := preload("res://scripts/Language.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const STORY := preload("res://scripts/story/StoryCatalog.gd")
const PROGRESS := preload("res://scripts/story/StoryProgress.gd")
var flags: Array = []
var checked := 0
var screens := 0

class AuditMenu extends "res://scripts/ui/StoryScreens.gd":
	func _label(text: String, rect: Rect2, font_size := 20, color := Color.WHITE) -> Label:
		var label: Label = super._label(text, rect, font_size, color)
		label.set_meta("qa_slot", rect)
		return label
	func _button(text: String, rect: Rect2, action: String, value := "") -> Button:
		var button: Button = super._button(text, rect, action, value)
		button.set_meta("qa_slot", rect)
		return button

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var menu := AuditMenu.new()
	root.add_child(menu)
	await process_frame
	for locale in ["en", "ko"]:
		LANGUAGE.set_locale(locale)
		for name in ["show_title", "show_options", "show_controls", "show_story_pause"]:
			menu.call(name)
			await _scan(menu, locale)
		for hero in REGISTRY.get_character_ids():
			menu.selected_id = hero
			menu.body = REGISTRY.get_bodies(hero)[0]
			menu.show_select()
			await _scan(menu, locale)
			menu.show_story_select()
			await _scan(menu, locale)
			PROGRESS.new_journey(hero, "normal")
			for stage in range(1, 10):
				PROGRESS.complete_stage(hero, stage, 0, [])
			for stage in range(1, 10):
				menu.show_story_map(stage)
				await _scan(menu, locale)
				menu.show_stage_card(STORY.stage(stage))
				menu.card_deadline = 9223372036854775807
				await _scan(menu, locale)
				menu.show_story_result({"clear": true, "stage": stage, "seconds": 126, "damage": 123, "cards": ["swiftness", "last_stand", "sky_step"]})
				await _scan(menu, locale)
			menu.show_story_ending()
			await _scan(menu, locale)
	var file := FileAccess.open("res://../reports/codex-qa-21/text-slots.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"screens": screens, "checked": checked, "flags": flags}, "\t") + "\n")
	print("QA21_TEXT_SUMMARY screens=", screens, " labels_buttons=", checked, " flags=", flags.size())
	menu.queue_free()
	await process_frame
	quit(0)

func _scan(menu: Control, locale: String) -> void:
	await process_frame
	await process_frame
	screens += 1
	for child in menu.content.get_children():
		if not child.has_meta("qa_slot") or not child.visible or child.text == "":
			continue
		checked += 1
		var rect: Rect2 = child.get_meta("qa_slot")
		var extent := 0.0
		if child is Label:
			# Story select explicitly enlarges/repositions the inherited captions.
			if menu.screen == "story_select" and (child.text.contains("★") or child.text.contains(tr("CLEAR"))):
				rect.size = child.size
			extent = child.get_line_count() * child.get_line_height()
		else:
			var font: Font = child.get_theme_font("font")
			var font_size: int = child.get_theme_font_size("font_size")
			extent = font.get_multiline_string_size(child.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).y
		var overflow := extent - rect.size.y
		if overflow > 4 or child.text.begins_with("story."):
			var row := {"locale": locale, "screen": menu.screen, "hero": menu.selected_id, "text": child.text, "slot": [rect.position.x, rect.position.y, rect.size.x, rect.size.y], "height": extent, "overflow": overflow, "actual_size": [child.size.x, child.size.y]}
			flags.append(row)
			print("QA21_TEXT_FLAG ", JSON.stringify(row))
