extends SceneTree
## Practice mode (quality track, 2026-11-26) through the real menu and real keys: the entry from
## the title, the target's three kinds (H) and the bot's fighter (N), putting everything back (R,
## with what each kit leaves on the field), refill (E), the card list (C: paused, pages, a card
## that then really works, growth for three cards only), giving cards back (X), the skill list
## (Tab), a monster (M), standing up after a fall, no end after any time, Esc, and no save file
## touched. -- --only=<part> runs one part.

const MAIN := preload("res://scripts/Main.gd")
const SESSION := preload("res://scripts/practice/PracticeSession.gd")
const DIRECTOR := preload("res://scripts/practice/PracticeDirector.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const SPEED := preload("res://scripts/GameSpeed.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const CARDS := preload("res://scripts/match/SoulCards.gd")
const MENU := preload("res://scripts/ui/FrontendMenu.gd")
const CATCHER := preload("res://tests/support/error_catcher.gd")
const SAVES: Array[String] = ["user://story.cfg", "user://language.cfg", "user://game_speed.cfg", "user://audio.cfg"]

var failed := false
var checks := 0
var only := ""
## Script errors and engine errors logged while the test runs: any of them fails it.
var catcher := CATCHER.new()

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			only = argument.trim_prefix("--only=")
	create_timer(540.0, true, false, true).timeout.connect(func() -> void:
		push_error("Practice mode test timed out")
		quit(1))
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error(message)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	LANGUAGE.load_saved()
	LANGUAGE.set_locale("en")
	SPEED.factor = 1.0
	var saves_before := _save_stamps()
	OS.add_logger(catcher)
	var parts := {
		"menu": _test_menu_entry,
		"target": _test_target_kinds,
		"reset": _test_reset,
		"steps": _test_reset_between_steps,
		"refill": _test_refill,
		"cards": _test_cards,
		"skills": _test_skill_list,
		"damage": _test_damage_lines,
		"monster": _test_monster,
		"falls": _test_falls_and_time,
	}
	for part: String in parts:
		if only == "" or only == part:
			# A part cut short by a script error returns nothing: that is a failure too.
			var done = await parts[part].call()
			_check(done == true, "The part '%s' did not run to its end" % part)
			for line in catcher.take():
				_check(false, "The engine logged an error in the part '%s': %s" % [part, line])
	OS.remove_logger(catcher)
	_check(_save_stamps() == saves_before, "Practice must not touch a save file (%s -> %s)" % [saves_before, _save_stamps()])
	if failed:
		quit(1)
		return
	print("Practice mode tests passed (%d checks; menu entry, H/N, R with each kit's leftovers, E, C/X, Tab, M, falls, no end, Esc, no save writes)" % checks)
	quit(0)

## Size and time of every save file: nothing of them is read.
func _save_stamps() -> String:
	var stamps: Array[String] = []
	for path in SAVES:
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			stamps.append("%s:%d:%d" % [path.get_file(), FileAccess.get_modified_time(path), file.get_length() if file != null else -1])
		else:
			stamps.append("%s:none" % path.get_file())
	return ", ".join(stamps)

func _frames(count: int) -> void:
	for frame in count:
		# Input polls, grounding and collisions live on physics frames (as in test_story_flow).
		await physics_frame
		await process_frame

func _key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _tap(code: int, held := 2) -> void:
	_key(code, true)
	await _frames(held)
	_key(code, false)
	await _frames(2)

func _click(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	await _frames(2)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await _frames(2)

## A fresh title screen.
func _title() -> Node:
	MAIN.next_screen = "title"
	MAIN.session_mode = "battle_royale"
	MAIN.last_character_id = "frey"
	MAIN.human_body = "male"
	SESSION.bot_id = "frey"
	change_scene_to_file("res://scenes/Main.tscn")
	await _frames(6)
	return current_scene

## Practice with `character_id`, as the select screen starts it (a reload into "practice").
func _practice(character_id: String) -> Node:
	MAIN.next_screen = "practice"
	MAIN.last_character_id = character_id
	MAIN.human_body = "male"
	SESSION.bot_id = "frey"
	change_scene_to_file("res://scenes/Main.tscn")
	await _frames(8)
	var main: Node = current_scene
	if not is_instance_valid(main.practice_session):
		_check(false, "Test setup: practice should start for %s" % character_id)
		return main
	# The fighters drop to the floor from their spawn points.
	await _frames(30)
	return main

func _has_text(node: Node, expected: String) -> bool:
	if (node is Label or node is Button) and node.visible and str(node.text).contains(expected):
		return true
	for child in node.get_children():
		if _has_text(child, expected):
			return true
	return false

## Title -> Practice -> the select screen -> a fighter -> practice, by mouse and keys; and the
## select screen opened from Battle Royale still starts a match.
func _test_menu_entry() -> bool:
	var main: Node = await _title()
	var menu: Control = main.hud.frontend
	var names: Array[String] = []
	for button: Button in menu.buttons:
		names.append(button.text)
	_check(names == ["Battle Royale", "Story", "Practice", "Watch bots", "Options", "Controls"], "The title should list Practice under Story (%s)" % [names])
	for index in menu.buttons.size():
		var button: Button = menu.buttons[index]
		_check(button.position.y + button.size.y <= 600.0, "Title row %d should end above the status line (ends at %.0f)" % [index, button.position.y + button.size.y])
		if index > 0:
			var above: Button = menu.buttons[index - 1]
			_check(button.position.y >= above.position.y + above.size.y - 0.5, "Title rows %d and %d should not overlap (%.0f + %.0f, %.0f)" % [index - 1, index, above.position.y, above.size.y, button.position.y])
	await _click(menu.buttons[2])
	_check(menu.screen == "select" and menu.select_mode == "practice" and not main.match_started, "Practice should open the select screen")
	_check(_has_text(menu, "Start practice"), "The select screen opened from Practice should say Start practice")
	for button: Button in menu.buttons:
		if button.text == "Start practice":
			var font: Font = button.get_theme_font("font")
			var width := font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
			_check(width <= button.size.x - 24.0, "Start practice should fit its button (%.0f px in %.0f)" % [width, button.size.x - 24.0])
	# F2 (the art style) reloads the screen: it is still the one that starts practice.
	await _tap(KEY_F2)
	await _frames(8)
	main = current_scene
	menu = main.hud.frontend
	_check(menu.screen == "select" and menu.select_mode == "practice" and _has_text(menu, "Start practice"), "F2 on the practice select screen should keep it one")
	await _tap(KEY_F2)
	await _frames(8)
	main = current_scene
	menu = main.hud.frontend
	# Esc returns to the title; Battle Royale then opens the same screen for a match.
	await _tap(KEY_ESCAPE)
	_check(menu.screen == "title", "Esc should return from the select screen to the title")
	await _click(menu.buttons[0])
	_check(menu.screen == "select" and menu.select_mode == "match" and _has_text(menu, "Start match"), "Battle Royale should open the select screen for a match")
	await _tap(KEY_ESCAPE)
	# Practice, the third fighter by the arrow keys, Enter.
	await _click(menu.buttons[2])
	await _tap(KEY_3)
	await _frames(8)
	main = current_scene
	_check(is_instance_valid(main.practice_session) and main.match_started, "A number key on the practice select screen should start practice")
	if not is_instance_valid(main.practice_session):
		return false
	var session: Node = main.practice_session
	var third: String = REGISTRY.get_character_ids()[2]
	_check(session.hero.character_id == third and session.hero.is_human, "Practice should start with the fighter picked (%s, got %s)" % [third, session.hero.character_id])
	_check(main.director is DIRECTOR and main.director.get_phase_name() == "Practice", "Practice should run under its own director")
	_check(main.director.get_playable_indices() == [main.CENTRAL_REALM_INDEX] and main.active_portals.is_empty(), "Only the central realm should be open, with no portal out")
	_check(session.hero.realm_index == main.CENTRAL_REALM_INDEX and session.target.realm_index == main.CENTRAL_REALM_INDEX, "Both should stand in the central realm")
	_check(session.mode == "stand" and session.target.is_dummy and main.players.size() == 1, "Practice should begin against the standing dummy")
	_check(not main.realm_monster_spawner.is_physics_processing() and not main.soul_crystal_spawner.is_physics_processing() and not main.hazards.enabled, "Monsters, crystals and realm hazards should be off")
	_check(session.hero.soul_threshold_reached.get_connections().is_empty(), "Practice should open no soul offers")
	_check(MAIN.session_mode == "practice", "The session mode should read practice")
	await _frames(20)
	_check(main.hud.clock_label.text.begins_with("Practice"), "The clock should name the mode (%s)" % main.hud.clock_label.text)
	_check(session.info.visible and session.info.text.contains("Standing dummy") and session.info.text.contains("H target"), "The practice lines should name the target and the keys (%s)" % session.info.text)
	_check(main.hud.status_label.text.contains("Cards held 0") and not main.hud.status_label.text.contains("next card") and not main.hud.status_label.text.contains("Alive"), "The status line should be practice's own: no survivors, no next card (%s)" % main.hud.status_label.text)
	# Esc leaves to a clean title.
	await _tap(KEY_ESCAPE)
	await _frames(8)
	main = current_scene
	_check(not main.match_started and main.hud.frontend.screen == "title" and MAIN.session_mode == "battle_royale", "Esc should leave practice for the title")
	_check(not is_instance_valid(main.practice_session) and not paused and is_equal_approx(Engine.time_scale, 1.0), "The title after practice should be a clean one")
	return true

## H: standing dummy -> walking dummy -> fighting bot -> standing dummy. N: the bot's fighter.
func _test_target_kinds() -> bool:
	var main: Node = await _practice("frey")
	var session: Node = main.practice_session
	var home: Vector2 = session.target.global_position
	await _frames(40)
	_check(session.target.global_position.distance_to(home) < 4.0, "The standing dummy should stand (moved %.1f px)" % session.target.global_position.distance_to(home))
	_check(is_equal_approx(session.target.incoming_damage_scale, main.director.get_combat_damage_scale()), "The dummy should take hits at the match's damage scale")
	await _tap(KEY_H)
	await _frames(2)
	if not is_instance_valid(session.target):
		_check(false, "H should change the practice target, not remove it")
		return false
	_check(session.mode == "walk" and session.target.is_dummy, "H should make the dummy walk")
	var least := INF
	var most := -INF
	for frame in 420:
		await physics_frame
		least = minf(least, session.target.global_position.x)
		most = maxf(most, session.target.global_position.x)
	_check(most - least > session.WALK_REACH and most - least < session.WALK_REACH * 2.0 + 60.0, "The walking dummy should go to and fro about its start place (%.0f px covered)" % (most - least))
	_check(not main.match_over, "Walking should end nothing")
	await _tap(KEY_H)
	var bot: Node = session.target
	_check(session.mode == "fight" and not bot.is_dummy and not bot.is_human and bot.character_id == "frey", "H should bring the fighting bot, Frey first (%s)" % bot.character_id)
	_check(main.players.size() == 2 and main.players[1] == bot and main.director.get_alive_combatants().size() == 2, "The bot should be a fighter of the match")
	_check(not is_instance_valid(main.dummy), "The dummy should be gone while the bot fights")
	# The bot really attacks: the fighter, left alone, is hit.
	var hits := [0]
	session.hero.damaged.connect(func(_fighter: Node, _amount: float, attacker: Node, _source: String) -> void:
		if attacker == session.target:
			hits[0] += 1)
	for frame in 900:
		await physics_frame
		if hits[0] > 0:
			break
	_check(hits[0] > 0, "The fighting bot should come and hit a fighter that stands still (15 s)")
	# N: the next fighter of the roster takes the bot's place.
	await _tap(KEY_N)
	var ids := REGISTRY.get_character_ids()
	_check(session.target != bot and session.target.character_id == ids[1] and SESSION.bot_id == ids[1], "N should change the bot's fighter (%s)" % session.target.character_id)
	await _frames(3)
	_check(not is_instance_valid(bot), "The bot that left should be freed")
	# Nothing keeps it: each list holds the fighter and the new bot, both alive nodes.
	for list: Array in [main.players, main.director.combatants, main.hazards.combatants]:
		var live := 0
		for entry in list:
			if is_instance_valid(entry):
				live += 1
		_check(list.size() == 2 and live == 2, "No list should keep the bot that left (%d entries, %d live)" % [list.size(), live])
	await _tap(KEY_H)
	_check(session.mode == "stand" and session.target.is_dummy and main.players.size() == 1 and main.dummy == session.target, "H should bring the standing dummy back")
	# In another mode N only names the next bot.
	await _tap(KEY_N)
	_check(SESSION.bot_id == ids[2] and session.target.is_dummy, "N with a dummy out should only choose the bot's fighter")
	_check(not main.match_over and main.match_started, "Changing targets should end nothing")
	return true

## What sits on the field beside the two fighters: every body and hitbox, by its script.
func _left_on_field(main: Node, session: Node) -> Array[String]:
	var left: Array[String] = []
	for child in main.get_children():
		if child is CollisionObject2D and child != session.hero and child != session.target and not child.is_queued_for_deletion():
			var script: Script = child.get_script()
			left.append(script.resource_path.get_file() if script != null else child.get_class())
	return left

func _at_start(session: Node, fighter: Node, spawn: int) -> bool:
	var start: Vector2 = session._start_point(spawn)
	# A fighter is put at its spawn point and drops to the floor under it.
	return absf(fighter.global_position.x - start.x) < 2.0 and absf(fighter.global_position.y - start.y) < 90.0

## R: both back at their start places with full HP and nothing left on the field, whatever the
## fighter had out: Rio's decoy, Nova's field and orb, Yuki's seals and talismans, Xion's double
## and shots, Luna's barrier and stars, a monster. Twice for each fighter: with everything out, and
## in the middle of the moves' start-ups.
func _test_reset() -> bool:
	var kits := {
		"rio": [KEY_U, KEY_K], "nova": [KEY_L, KEY_K], "yuki": [KEY_K, KEY_J],
		"xion": [KEY_U, KEY_J], "luna": [KEY_L, KEY_J], "frey": [KEY_K, KEY_J],
	}
	# The ultimates too, each cut short by R at three moments of it.
	for id: String in kits:
		var main: Node = await _practice(id)
		var session: Node = main.practice_session
		for wait: int in [4, 30, 75]:
			session.hero.facing = 1
			session.hero.global_position = session.target.global_position + Vector2(-120, 0)
			await _frames(8)
			await _tap(KEY_E)
			await _tap(KEY_I)
			await _frames(wait)
			await _tap(KEY_I)
			await _frames(6)
			await _tap(KEY_R)
			await _frames(3)
			_check(_left_on_field(main, session).is_empty(), "R should clear an ultimate's field (%s, %d frames in): %s" % [id, wait, _left_on_field(main, session)])
			_check(_at_start(session, session.hero, session.HERO_SPAWN) and is_equal_approx(session.target.hp, session.target.max_hp), "R should put everything back in the middle of an ultimate (%s, %d frames in)" % [id, wait])
			await _frames(30)
			await _tap(KEY_J)
			await _frames(20)
			_check(not session.hero.is_defeated and session.hero.attack_lock_timer < 2.0 and not session.hero.is_queued_for_deletion(), "The fighter should be free to act after R (%s)" % id)
	# A bot in action, every fighter in turn: R three times while it fights, N to the next.
	var arena: Node = await _practice("frey")
	var bout: Node = arena.practice_session
	bout.set_mode("fight")
	for index in REGISTRY.get_character_ids().size():
		for wait: int in [70, 25, 110]:
			await _frames(wait)
			await _tap(KEY_E)
			# The bot moves on at once: its place is read in the frame after the key.
			_key(KEY_R, true)
			await _frames(1)
			_key(KEY_R, false)
			var start: Vector2 = bout._start_point(bout.TARGET_SPAWN)
			_check(absf(bout.target.global_position.x - start.x) < 30.0 and is_equal_approx(bout.target.hp, bout.target.max_hp) and is_equal_approx(bout.hero.hp, bout.hero.max_hp), "R should put a fighting bot back too (%s, after %d frames; at %s, start %s)" % [bout.target.character_id, wait, bout.target.global_position, start])
			await _frames(3)
			_check(_left_on_field(arena, bout).is_empty() or bout.target.attack_lock_timer > 0.0, "R should clear the field under a fighting bot (%s): %s" % [bout.target.character_id, _left_on_field(arena, bout)])
		await _tap(KEY_N)
		await _frames(4)
	_check(not arena.match_over and is_instance_valid(bout.target) and not bout.target.is_dummy, "The bots should still be fighting after every reset")
	for id: String in kits:
		var main: Node = await _practice(id)
		var session: Node = main.practice_session
		var hero: Node = session.hero
		for wait: int in [26, 3]:
			hero.facing = 1
			for code: int in kits[id]:
				await _tap(code)
				await _frames(wait)
			await _tap(KEY_M)
			hero.apply_environment_damage(12.0)
			session.target.apply_hit(hero, 8.0, 500.0, Vector2.RIGHT)
			await _frames(wait)
			var held: Array[Node] = []
			for name in ["decoy", "field", "double", "barrier"]:
				var thing = hero.get(name)
				if thing is Node and is_instance_valid(thing):
					held.append(thing)
			if id == "yuki":
				for seal: Node in hero.seals:
					held.append(seal)
			if wait > 10:
				_check(not _left_on_field(main, session).is_empty(), "Test setup: %s should have something on the field before R" % id)
				if id in ["rio", "nova", "xion", "luna", "yuki"]:
					_check(not held.is_empty(), "Test setup: %s should hold its own object before R" % id)
				_check(session.total_damage > 0.0 and hero.hp < hero.max_hp, "Test setup: damage should be on the books before R")
			await _tap(KEY_R)
			await _frames(3)
			_check(_left_on_field(main, session).is_empty(), "R should clear the field (%s, wait %d): %s" % [id, wait, _left_on_field(main, session)])
			for thing in held:
				_check(not is_instance_valid(thing), "R should remove %s's own object (wait %d)" % [id, wait])
			if id == "yuki":
				_check(hero.seals.is_empty(), "R should clear Yuki's seals")
			_check(_at_start(session, hero, session.HERO_SPAWN) and _at_start(session, session.target, session.TARGET_SPAWN), "R should put both at their start places (%s: %s, %s)" % [id, hero.global_position, session.target.global_position])
			_check(is_equal_approx(hero.hp, hero.max_hp) and is_equal_approx(session.target.hp, session.target.max_hp), "R should fill both HP bars (%s)" % id)
			_check(session.total_damage == 0.0 and session.last_damage == 0.0, "R should start the damage count over")
			_check(session.monsters.is_empty(), "R should send the monsters away")
			# The fight goes on after it: another swing, nothing broken.
			await _frames(20)
			await _tap(KEY_J)
			await _frames(30)
			_check(not main.match_over and not hero.is_defeated, "Play should go on after R (%s)" % id)
	return true

## R just after a hitbox touched the target. The engine finds a touch in one physics step and
## delivers it at the start of the next; what R removes is only gone after that start. So a hitbox
## that had just touched the target when R came still hit it, on the place R had put it back to.
## Under load a frame runs several physics steps and R lands in that gap more often: the UI session
## saw "R ... in the middle of an ultimate" fail twice that way (2026-11-26), and Rio's cuts 30
## frames into his ultimate did it once in six with frames slowed to 50 ms. Here the gap is made
## every time; it fails without the fix (R takes what it removes out of the physics at once).
func _test_reset_between_steps() -> bool:
	var main: Node = await _practice("frey")
	var session: Node = main.practice_session
	var hero: Node = session.hero
	var target: Node = session.target
	var home: Vector2 = session._start_point(session.TARGET_SPAWN)
	for attempt in 5:
		session.reset_positions(true)
		await _frames(20)
		var hp: float = target.hp
		# A hitbox on the target, made in this frame's process: its touch is found in the next
		# physics step, and delivered at the start of the one after.
		await process_frame
		var before: Array[Node] = main.get_children()
		hero._spawn_attack(Vector2(140, 140), Vector2.ZERO, 12.0, 300.0, Vector2.RIGHT, Color(1, 1, 1, 0.3), 5.0)
		var attack: Node = null
		for child in main.get_children():
			if not before.has(child) and child.get_script() != null and str(child.get_script().resource_path).ends_with("Attack.gd"):
				attack = child
		if attack == null:
			_check(false, "Test setup: the fighter's hitbox should be on the field")
			return false
		attack.global_position = target.global_position + Vector2(0, -34)
		await physics_frame
		await process_frame
		if not is_equal_approx(target.hp, hp):
			# A slow frame ran two steps: the touch was delivered before R. Again.
			continue
		# R now: it is read at the start of the next frame, before its first physics step. The
		# frame is held a little so that the next one runs at least one step.
		_key(KEY_R, true)
		OS.delay_msec(40)
		await _frames(3)
		_key(KEY_R, false)
		await _frames(2)
		_check(is_equal_approx(target.hp, target.max_hp) and _at_start(session, target, session.TARGET_SPAWN), "A hitbox that had just touched the target should not hit it after R puts it back (HP %.1f of %.0f, at %s, start %s)" % [target.hp, target.max_hp, target.global_position, home])
		_check(not is_instance_valid(attack), "R should remove the hitbox")
		return true
	_check(false, "Test setup: five tries and R never came between the touch and its delivery")
	return false

## E: the ultimate and every skill ready at once, for each fighter after it used them; the bot's too.
func _test_refill() -> bool:
	for id: String in REGISTRY.get_character_ids():
		var main: Node = await _practice(id)
		var session: Node = main.practice_session
		var hero: Node = session.hero
		hero.facing = 1
		var longest := 0.0
		for code: int in [KEY_K, KEY_L, KEY_U]:
			await _tap(code)
			await _frames(50)
			for slot in ["j", "k", "l", "u"]:
				longest = maxf(longest, hero.skill_cooldown(slot).x)
		if id in ["luna", "nova", "rio", "xion"]:
			_check(longest > 0.5, "Test setup: %s should have a skill on cooldown (%.1f s)" % [id, longest])
		await _tap(KEY_E)
		for slot in ["j", "k", "l", "u"]:
			_check(hero.skill_cooldown(slot).x <= 0.0, "E should ready %s's %s (%.1f s left)" % [id, slot.to_upper(), hero.skill_cooldown(slot).x])
		await _tap(KEY_R)
		await _frames(20)
		await _tap(KEY_I)
		await _frames(6)
		_check(not hero.is_ultimate_ready(), "Test setup: %s's ultimate should be on cooldown after I" % id)
		await _tap(KEY_E)
		_check(hero.is_ultimate_ready(), "E should ready %s's ultimate" % id)
		await _tap(KEY_R)
	var main: Node = await _practice("xion")
	var session: Node = main.practice_session
	# Xion's rounds are her J's cooldown: an empty magazine is full again.
	session.hero._use_rounds(session.hero.ammo)
	_check(session.hero.ammo == 0 and session.hero.reload_timer > 0.0, "Test setup: Xion should be reloading")
	await _tap(KEY_E)
	_check(session.hero.ammo == session.hero.magazine_size() and session.hero.reload_timer <= 0.0, "E should fill Xion's magazine (%d)" % session.hero.ammo)
	session.set_mode("fight")
	await _frames(4)
	session.target.ultimate_cooldown_timer = 20.0
	await _tap(KEY_E)
	_check(session.target.is_ultimate_ready(), "E should ready the bot's ultimate too")
	return true

## C: the card list. The game is paused while it is open (A/D turn the page and move nobody), a
## card is held at once and really works, a card held as often as it may be is refused, growth
## counts for three cards, Esc closes the list without leaving. X gives everything back.
func _test_cards() -> bool:
	var main: Node = await _practice("frey")
	var session: Node = main.practice_session
	var hero: Node = session.hero
	var hud: Node = main.hud
	var plain := {"attack": hero.attack_power, "hp": hero.max_hp, "speed": hero.speed}
	var list: Array[Dictionary] = session.card_list()
	_check(list.size() == 15 and session.card_pages() == 5, "Frey may hold fifteen cards, five pages (%d)" % list.size())
	await _tap(KEY_C)
	_check(session.panel == "cards" and paused and hud.card_panel.visible, "C should open the card list and pause the game")
	_check(hud.card_title.text.contains("1 / 5") and hud.card_row_text(0).contains(str(list[0].title)), "The list should open on its first page (%s)" % hud.card_title.text)
	_check(not session.info.visible, "The practice lines should make room for the cards")
	_check(hud.info_label.visible and hud.info_label.text.contains("three cards"), "The list should say that growth counts for three cards (%s)" % hud.info_label.text)
	# D held: one page on, and the fighter does not move.
	var place: Vector2 = hero.global_position
	_key(KEY_D, true)
	await _frames(30)
	_key(KEY_D, false)
	await _frames(2)
	_check(session.card_page == 1 and hud.card_title.text.contains("2 / 5"), "D should turn one page (%d)" % session.card_page)
	_check(hero.global_position == place, "A/D on the card list should not move the fighter (%s -> %s)" % [place, hero.global_position])
	await _tap(KEY_A)
	_check(session.card_page == 0, "A should turn the page back")
	await _tap(KEY_A)
	_check(session.card_page == 4 and hud.card_title.text.contains("5 / 5"), "The pages should go round")
	await _tap(KEY_D)
	# The first card of the list, by its key.
	await _tap(KEY_1)
	_check(hero.upgrades == [str(list[0].id)], "1 should take the first card (%s)" % [hero.upgrades])
	_check(hero.attack_power > float(plain.attack), "The card taken should act at once (attack %.1f -> %.1f)" % [plain.attack, hero.attack_power])
	_check(hud.card_row_text(0).contains("held x1"), "A held card should say so (%s)" % hud.card_row_text(0))
	_check(hud.status_label.text.contains("Cards held 1"), "The status line should count the card while the list is still open (%s)" % hud.status_label.text)
	for label: Label in hud.card_labels:
		_check(label.get_line_count() * label.get_line_height() <= label.size.y, "A card with its held mark should still fit its box: %s" % label.text)
	# Air Dash: found on its page, taken, and refused the second time.
	var at := -1
	for index in list.size():
		if str(list[index].id) == "air_dash":
			at = index
	for page in at / 3:
		await _tap(KEY_D)
	await _tap(KEY_1 + at % 3)
	_check(hero.has_card("air_dash"), "The Air Dash card should be taken from page %d" % (at / 3 + 1))
	await _tap(KEY_1 + at % 3)
	_check(hero.upgrades.count("air_dash") == 1 and hud.info_label.text.contains("held already"), "A card held as often as it may be should be refused (%s)" % hud.info_label.text)
	# Esc closes the list and nothing else.
	await _tap(KEY_ESCAPE)
	await _frames(4)
	if current_scene != main or not is_instance_valid(session):
		_check(false, "Esc on the card list should close the list, not leave practice")
		return false
	_check(session.panel == "" and not paused and not hud.card_panel.visible, "Esc should close the card list")
	_check(not hud.info_label.visible, "The note about growth should go with the card list")
	_check(current_scene == main and main.match_started and is_instance_valid(main.practice_session), "Esc on the card list should not leave practice")
	_check(is_equal_approx(Engine.time_scale, SPEED.factor), "Time should run again after the list")
	# The card really works: a jump, the guard key in the air, a dash.
	await _frames(10)
	_key(KEY_W, true)
	await _frames(3)
	_key(KEY_W, false)
	for frame in 40:
		await physics_frame
		if not hero.is_on_floor() and hero.velocity.y > -200.0:
			break
	var x_before: float = hero.global_position.x
	await _tap(KEY_SPACE)
	await _frames(8)
	_check(int(hero.move_counts.get("air_dash", 0)) == 1 and absf(hero.global_position.x - x_before) > 40.0, "The Air Dash taken in practice should dash at the guard key (%d, %.0f px)" % [int(hero.move_counts.get("air_dash", 0)), absf(hero.global_position.x - x_before)])
	# Growth for three cards only: five more cards, three picks' growth.
	await _frames(40)
	await _tap(KEY_C)
	var taken := 0
	for page in session.card_pages():
		for slot in 3:
			if taken < 5 and await _take_if_free(session, slot):
				taken += 1
		await _tap(KEY_D)
	# Every page with its held marks fits its boxes, in Korean too (the longer of the two).
	for locale in ["ko", "en"]:
		LANGUAGE.set_locale(locale)
		for page in session.card_pages():
			await _tap(KEY_D)
			for label: Label in hud.card_labels:
				_check(label.get_line_count() * label.get_line_height() <= label.size.y, "A card with its held mark should fit its box (%s, page %d): %s" % [locale, session.card_page + 1, label.text])
			var title_font: Font = hud.card_title.get_theme_font("font")
			var title_width := title_font.get_string_size(hud.card_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, hud.card_title.get_theme_font_size("font_size")).x
			_check(title_width <= hud.card_title.size.x, "The card list's title line should fit (%s, %.0f px of %.0f)" % [locale, title_width, hud.card_title.size.x])
	await _tap(KEY_C)
	_check(session.panel == "" and not paused, "C should close the list it opened")
	_check(hero.upgrades.size() == 7 and hero.soul_picks == 3, "Seven cards should count as three picks of growth (%d cards, %d picks)" % [hero.upgrades.size(), hero.soul_picks])
	# X: everything given back, and both put back.
	await _tap(KEY_X)
	await _frames(3)
	_check(hero.upgrades.is_empty() and hero.soul_picks == 0, "X should give every card back (%s)" % [hero.upgrades])
	_check(is_equal_approx(hero.attack_power, float(plain.attack)) and is_equal_approx(hero.max_hp, float(plain.hp)) and is_equal_approx(hero.speed, float(plain.speed)), "X should take the cards' numbers away (attack %.1f, HP %.1f, speed %.1f)" % [hero.attack_power, hero.max_hp, hero.speed])
	_check(is_equal_approx(hero.hp, hero.max_hp) and not hero.has_card("air_dash") and hero.max_air_jumps == hero.base_air_jumps, "X should leave a plain fighter at full HP")
	_check(_at_start(session, hero, session.HERO_SPAWN), "X should put the fighter back at its start place")
	# Yuki has no card of her own: fourteen.
	main = await _practice("yuki")
	_check(main.practice_session.card_list().size() == 14, "Yuki may hold fourteen cards")
	return true

func _take_if_free(session: Node, slot: int) -> bool:
	var list: Array[Dictionary] = session.card_list()
	var at: int = session.card_page * 3 + slot
	if at >= list.size() or session.hero.upgrades.has(str(list[at].id)):
		return false
	await _tap(KEY_1 + slot)
	return session.hero.upgrades.has(str(list[at].id))

## Tab: the fighter's kit, the select screen's text, over a paused game; every row inside the
## panel and clear of the next, in both languages, for every fighter. And the practice lines fit.
func _test_skill_list() -> bool:
	for id: String in REGISTRY.get_character_ids():
		var main: Node = await _practice(id)
		var session: Node = main.practice_session
		for locale in ["en", "ko"]:
			LANGUAGE.set_locale(locale)
			await _tap(KEY_TAB)
			_check(session.panel == "skills" and paused and session.skills_panel.visible, "Tab should open the skill list and pause the game (%s)" % id)
			var kit: Array = MENU.KITS[id]
			var rows: Array[Label] = []
			for child in session.skills_panel.get_children():
				if child is Label:
					rows.append(child)
					_check(child.position.y + child.size.y <= session.skills_panel.size.y + 0.5 and child.get_line_count() * child.get_line_height() <= child.size.y + 0.5, "A skill row should fit the panel (%s %s): %s" % [id, locale, child.text])
			for index in range(1, kit.size()):
				_check(_has_text(session.skills_panel, tr(str(kit[index]))), "The skill list should hold the select screen's row %d (%s %s)" % [index, id, locale])
			# Rows in the text column do not run into each other.
			var column: Array[Label] = []
			for row in rows:
				if is_equal_approx(row.position.x, 128.0):
					column.append(row)
			for index in range(1, column.size()):
				_check(column[index].position.y >= column[index - 1].position.y + column[index - 1].size.y, "Skill rows should not overlap (%s %s, row %d)" % [id, locale, index])
			await _tap(KEY_TAB)
			_check(session.panel == "" and not paused and not session.skills_panel.visible, "Tab should close the skill list")
			await _frames(3)
			var font: Font = session.info.get_theme_font("font")
			for line: String in session.info.text.split("\n"):
				var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, session.info.get_theme_font_size("font_size")).x
				_check(width <= session.info.size.x, "A practice line should fit its width (%s %s, %.0f px of %.0f): %s" % [id, locale, width, session.info.size.x, line])
			# The longest target name too.
			session.set_mode("fight")
			await _frames(3)
			for line: String in session.info.text.split("\n"):
				var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, session.info.get_theme_font_size("font_size")).x
				_check(width <= session.info.size.x, "A practice line should fit with the bot out (%s %s, %.0f px)" % [id, locale, width])
			session.set_mode("stand")
			await _frames(3)
		LANGUAGE.set_locale("en")
	# Esc closes this list too, without leaving.
	var main: Node = current_scene
	await _tap(KEY_TAB)
	await _tap(KEY_ESCAPE)
	await _frames(4)
	_check(current_scene == main and main.practice_session.panel == "" and not paused, "Esc should close the skill list and stay in practice")
	return true

## The damage the target takes is counted in the HP it loses, at the match's scale.
func _test_damage_lines() -> bool:
	var main: Node = await _practice("frey")
	var session: Node = main.practice_session
	var hero: Node = session.hero
	var dummy: Node = session.target
	hero.global_position = dummy.global_position + Vector2(-70, 0)
	hero.facing = 1
	await _frames(12)
	var hp: float = dummy.hp
	await _tap(KEY_J)
	for frame in 60:
		await physics_frame
		if session.last_damage > 0.0:
			break
	await _frames(2)
	var lost: float = hp - dummy.hp
	_check(session.last_damage > 0.0 and is_equal_approx(session.last_damage, lost) and is_equal_approx(session.total_damage, lost), "A real J should be counted in the HP the dummy lost (%.2f counted, %.2f lost)" % [session.last_damage, lost])
	_check(session.info.text.contains("Last hit %.1f HP" % session.last_damage), "The practice lines should show the hit (%s)" % session.info.text.split("\n")[0])
	# In a match Frey's first swing costs a fighter the same: the scale is the director's.
	_check(lost < 4.0, "The count should be in match HP, not the move's own number (%.2f)" % lost)
	# The realm's damage is not a hit.
	var total: float = session.total_damage
	dummy.apply_environment_damage(30.0)
	_check(is_equal_approx(session.total_damage, total), "Ring-out damage should stay out of the hit count")
	return true

## M calls a monster of the realm, three at most; its souls reach the fighter and open no offer.
func _test_monster() -> bool:
	var main: Node = await _practice("frey")
	var session: Node = main.practice_session
	for press in 4:
		await _tap(KEY_M)
		await _frames(2)
	_check(session.monsters.size() == 3 and _left_on_field(main, session).count("RealmMonster.gd") == 3, "M should call a monster, three at most (%d)" % session.monsters.size())
	var monster: Node = session.monsters[0]
	_check(monster.realm_index == main.CENTRAL_REALM_INDEX and monster.is_physics_processing(), "The monster should live in the central realm")
	for called: Node in session.monsters:
		var gap: float = called.global_position.x - session.hero.global_position.x
		_check(gap > 150.0 and gap < 600.0, "A called monster should come out in front of the fighter, on screen (%.0f px ahead)" % gap)
	var souls: int = session.hero.souls
	monster.apply_hit(session.hero, 9999.0, 100.0, Vector2.RIGHT, "fixed")
	await _frames(4)
	_check(session.hero.souls > souls, "A monster's souls should reach the fighter (%d -> %d)" % [souls, session.hero.souls])
	session.hero.add_souls(200)
	await _frames(4)
	_check(main.soul_growth.active_offers.is_empty() and not main.hud.card_panel.visible, "Souls should open no card offer in practice")
	return true

## A fall is not the end: the fighter, the bot and the dummy stand up again where they began, and
## a ring-out costs the central brawl's 30 HP. Any amount of time ends nothing.
func _test_falls_and_time() -> bool:
	var main: Node = await _practice("frey")
	var session: Node = main.practice_session
	var hero: Node = session.hero
	_check(is_equal_approx(main.director.get_ringout_damage(), 30.0) and is_equal_approx(main.director.get_recovery_rate(), 0.0) and is_equal_approx(main.director.get_combat_damage_scale(), 0.26) and is_equal_approx(main.director.get_bot_aggression(), 1.0), "Practice should use the central brawl's numbers")
	hero.global_position.y = hero.ringout_y + 50.0
	await _frames(4)
	_check(is_equal_approx(hero.hp, hero.max_hp - 30.0) and _at_start(session, hero, session.HERO_SPAWN), "A ring-out should cost 30 HP and return the fighter to its start place (HP %.0f, %s)" % [hero.hp, hero.global_position])
	hero.apply_environment_damage(hero.hp)
	await _frames(3)
	_check(hero.is_defeated and not main.match_over and main.director.winner == null, "A fall should end nothing")
	for frame in 150:
		await physics_frame
	_check(not hero.is_defeated and is_equal_approx(hero.hp, hero.max_hp) and _at_start(session, hero, session.HERO_SPAWN), "The fighter should stand up again at full HP (%s, HP %.0f)" % [hero.is_defeated, hero.hp])
	# The dummy stands up by its own 3 s; R before that leaves it standing where R put it.
	var dummy: Node = session.target
	dummy.apply_environment_damage(dummy.hp)
	await _frames(3)
	_check(dummy.is_defeated, "Test setup: the dummy should fall")
	await _tap(KEY_R)
	await _frames(3)
	_check(not dummy.is_defeated and is_equal_approx(dummy.hp, dummy.max_hp), "R should stand a fallen dummy up")
	dummy.global_position.x += 120.0
	var moved: Vector2 = dummy.global_position
	for frame in 220:
		await physics_frame
	_check(absf(dummy.global_position.x - moved.x) < 2.0, "The dummy's own timer should not move it again after R (%s -> %s)" % [moved, dummy.global_position])
	# The bot.
	session.set_mode("fight")
	await _frames(4)
	var bot: Node = session.target
	bot.apply_environment_damage(bot.hp)
	await _frames(3)
	_check(bot.is_defeated and not main.match_over, "A fallen bot should end nothing")
	for frame in 150:
		await physics_frame
	_check(not bot.is_defeated and is_equal_approx(bot.hp, bot.max_hp), "The bot should stand up again")
	session.set_mode("stand")
	await _frames(4)
	# Ten minutes of the director's clock: nothing warns, falls or ends.
	var states: Array[String] = main.director.realm_states.duplicate()
	main.director.advance(600.0)
	await _frames(30)
	_check(not main.match_over and main.director.realm_states == states and main.director.get_phase_name() == "Practice" and main.director.get_warning_seconds_left() == 0, "Time should end nothing in practice")
	_check(main.director.get_next_event_label() == "" and not main.hud.warning_label.visible, "No event should be on the clock")
	_check(main.director.match_elapsed > 600.0, "The clock should count up")
	return true
