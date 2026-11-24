extends SceneTree
## Match HUD layout (UI audit 2026-11-25, reports/ui-audit-2026-11-25): the focus fighter's status
## text stays clear of the HP bar (B7), the skill bar keeps to the right edge of a window wider
## than 16:9 as the controls line under it does (B1), and a minimap cell shows its fighter count
## whole in both languages (B2).

const MAIN_SCENE := "res://scenes/Main.tscn"
const MATCH_HUD := preload("res://scripts/ui/MatchHud.gd")
const REALM_LAYOUT := preload("res://scripts/realms/RealmLayout.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const WINDOWS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1470, 720)]

var failed := false

## Realm states and a countdown for the minimap, without a match.
class FakeDirector extends Node:
	var states: Array[String] = []
	func get_state(index: int) -> String:
		return states[index]
	func get_warning_seconds_left() -> int:
		return 29

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _run() -> void:
	LANGUAGE.load_saved()
	await _status_and_skill_bar()
	await _minimap_counts()
	LANGUAGE.set_locale("en")
	root.size = WINDOWS[0]
	if not failed:
		print("HUD layout tests passed (status text above the HP bar; skill bar on the right edge at 1280 and 1470 px, four and five slots; minimap counts whole in en/ko)")
	quit(1 if failed else 0)

func _status_and_skill_bar() -> void:
	for window in WINDOWS:
		for character in ["frey", "rio"]:
			root.size = window
			var main: Node = load(MAIN_SCENE).instantiate()
			root.add_child(main)
			for frame in 5:
				await process_frame
			main._start_match(character)
			for frame in 10:
				await process_frame
			var hud: Node = main.hud
			var view: Vector2 = root.get_visible_rect().size
			var where := "%s at %d px" % [character, window.x]
			_check(is_equal_approx(view.x, float(window.x)), "The test window should be %d px wide (%.0f)" % [window.x, view.x])
			# B7: two status lines, then the bar.
			var status: Label = hud.status_label
			var text_bottom := status.global_position.y + status.get_line_count() * status.get_line_height()
			_check(status.get_line_count() == 2, "The status block should be two lines (%s: %d)" % [where, status.get_line_count()])
			_check(hud.hp_bar.visible and text_bottom <= hud.hp_bar.global_position.y + 0.5,
				"The status text (down to y %.0f) runs over the HP bar (from y %.0f) for %s" % [text_bottom, hud.hp_bar.global_position.y, where])
			# B1: the bar and the line under it share the right edge.
			var bar: Rect2 = hud.skill_bar.get_global_rect()
			_check(absf(bar.end.x - (view.x - hud.SKILL_BAR_MARGIN)) <= 0.5,
				"The skill bar should end %d px from the right edge (%.0f of %.0f) for %s" % [hud.SKILL_BAR_MARGIN, bar.end.x, view.x, where])
			_check(absf(hud.controls_label.get_global_rect().end.x - bar.end.x) <= 0.5, "The controls line and the skill bar should share a right edge for " + where)
			var slots := 0
			for slot: String in hud.SKILL_SLOTS:
				var panel := hud.skill_bar.get_node("SkillSlot%s" % slot.to_upper()) as Control
				if panel.visible:
					slots += 1
					_check(panel.get_global_rect().end.x <= view.x - hud.SKILL_BAR_MARGIN + 0.5, "Skill slot %s hangs past the bar for %s" % [slot, where])
			_check(slots == (5 if character == "rio" else 4), "%s should show %d skill slots, got %d" % [character, 5 if character == "rio" else 4, slots])
			main.queue_free()
			await process_frame

func _minimap_counts() -> void:
	root.size = WINDOWS[0]
	var hud: CanvasLayer = MATCH_HUD.new()
	root.add_child(hud)
	var director := FakeDirector.new()
	root.add_child(director)
	await process_frame
	var layout := REALM_LAYOUT.new()
	var counts := {}
	for index in layout.realm_count():
		director.states.append(["stable", "warning", "collapsed", "locked"][index % 4])
		counts[index] = 16
	for locale in ["en", "ko"]:
		LANGUAGE.set_locale(locale)
		hud.rebuild_minimap(layout, director, 0)
		hud.update_minimap_labels(director, counts)
		await process_frame
		var counted := 0
		for index: int in hud.minimap_labels:
			var state := director.states[index]
			if state != "stable" and state != "warning":
				continue
			var label: Label = hud.minimap_labels[index].label
			var font := label.get_theme_font("font")
			var font_size := label.get_theme_font_size("font_size")
			var count_line := ""
			for line in label.text.split("\n"):
				if line.contains("x16"):
					count_line = line
			_check(count_line != "", "A %s cell should show its fighter count (%s: %s)" % [state, locale, label.text.c_escape()])
			# Cells are 68 px wide on a 72 px pitch. A label grows with its text, so a line too long
			# for the space beside the emblem pushes the label, and the count at its end, out of the
			# cell and under the next one.
			var cell_right := floorf(label.position.x / 72.0) * 72.0 + 68.0
			var width := font.get_string_size(count_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			_check(label.position.x + maxf(label.size.x, width) <= cell_right + 0.5, "The minimap line with the count ('%s', %.0f px) runs %.0f px past its cell in %s" % [count_line, width, label.position.x + maxf(label.size.x, width) - cell_right, locale])
			_check(label.get_line_count() * label.get_line_height() <= 36.0, "The minimap text is taller than its 36 px cell in %s: %s" % [locale, label.text.c_escape()])
			counted += 1
		_check(counted >= 4, "Expected stable and warning cells on the minimap, checked %d" % counted)
	hud.queue_free()
	director.queue_free()
	await process_frame
