extends SceneTree
## SYS-05: real event hooks with no assets, then in-memory tones (never written to assets/).
const AUDIO := preload("res://scripts/audio/AudioManager.gd")
const SETTINGS := preload("res://scripts/audio/AudioSettings.gd")
const CATALOG := preload("res://scripts/audio/AudioCatalog.gd")
const FACTORY := preload("res://scripts/PlayerFactory.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const MONSTER := preload("res://scripts/RealmMonster.gd")
const ARCHETYPES := preload("res://scripts/monsters/MonsterArchetypes.gd")
const CARDS := preload("res://scripts/match/SoulCards.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
var manager: Node
var failed := false
var checks := 0
var probe_counts: Dictionary = {}
var probe_resolution_attempts: Dictionary = {}
var probe_world: Dictionary = {}
var world_filter_checks := 0
var unreachable := {
	"swing": "폴백 전용(직접 이벤트 없음)",
	"skill_cast": "폴백 전용(직접 이벤트 없음)",
	"ult_start": "폴백 전용(직접 이벤트 없음)",
	"monster_attack": "폴백 전용(직접 이벤트 없음)",
}

func _initialize() -> void:
	# Regression: test_hud_frames constructs a standalone HUD while the root is
	# still setting up children. A nested Frontend must not try to add a manager.
	var isolated_hud: Node = preload("res://scripts/ui/MatchHud.gd").new()
	root.add_child(isolated_hud)
	_check(root.get_node_or_null("AudioManager") == null, "Standalone HUD initialization must not create a root manager")
	isolated_hud.queue_free()
	call_deferred("_run")
	create_timer(100.0).timeout.connect(func() -> void:
		push_error("Audio test timed out")
		quit(1))

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error(message)

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _run() -> void:
	root.size = Vector2i(1280, 720)
	manager = AUDIO.install(root)
	manager.probe_enabled = true
	if OS.get_cmdline_user_args().has("--sys08-audio-only"):
		await _test_id_gaps()
		await _test_landing_audio()
		print("SYS08 focused audio %s (%d checks)" % ["FAILED" if failed else "passed", checks])
		quit(1 if failed else 0)
		return
	await _probe_hooks()
	await _probe_story_dialogue()
	probe_counts = manager.requests.duplicate()
	probe_resolution_attempts = manager.resolution_attempts.duplicate()
	probe_world = manager.world_probe.duplicate()
	_check(int(probe_world.no_realm) == 0, "Every world hook must identify its realm")
	for id: String in CATALOG.SOUNDS:
		_check(probe_counts.has(id) or unreachable.has(id), "Scripted hook did not request " + id)
		if CATALOG.SOUNDS[id].group == "Fallback":
			_check(probe_resolution_attempts.has(id), "Fallback must be visited by the silent hook probe: " + id)
	_check(manager.cache.values().all(func(stream: Variant) -> bool: return stream == null), "Asset-free probe must not load a sound")
	_check(manager.voices.all(func(voice: AudioStreamPlayer) -> bool: return not voice.playing), "Missing files must stay silent")
	await _test_world_filtering()
	await _test_navigation_audio()
	await _test_voices()
	await _test_id_gaps()
	await _test_landing_audio()
	await _test_music()
	await _test_settings_and_options()
	_test_contract()
	print("AUDIO_PROBE " + JSON.stringify({"requests": probe_counts, "resolution_attempts": probe_resolution_attempts, "world": probe_world, "world_filter_checks": world_filter_checks, "unrequested": unreachable, "checks": checks}))
	if OS.get_cmdline_user_args().has("--report"):
		var file := FileAccess.open("res://../reports/codex-sys-08/probe.json", FileAccess.WRITE)
		file.store_string(JSON.stringify({"requests": probe_counts, "resolution_attempts": probe_resolution_attempts, "world": probe_world, "world_filter_checks": world_filter_checks, "unrequested": unreachable, "checks": checks, "passed": not failed}, "\t") + "\n")
	manager.queue_free()
	await process_frame
	print("Audio tests %s (%d checks; %d/%d event ids requested, 4 fallback-only)" % ["FAILED" if failed else "passed", checks, probe_counts.size(), CATALOG.SOUNDS.size() - unreachable.size()])
	quit(1 if failed else 0)

func _probe_hooks() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await _frames(5)
	var main: Node = current_scene
	_check(AUDIO.install(main) == manager and root.get_node("AudioManager") == manager, "Main must reuse the root manager")
	main.hud.frontend._move_focus(1)
	main.hud.frontend._activate("select", "")
	var cancel := InputEventKey.new()
	cancel.keycode = KEY_ESCAPE
	cancel.pressed = true
	main.hud.frontend._input(cancel)
	main.player_count = 4
	main._start_match("frey")
	await _frames(3)
	main.set_process(false)
	for player in main.players:
		player.set_physics_process(false)
	main.realm_monster_spawner.set_physics_process(false)
	main.soul_crystal_spawner.set_physics_process(false)
	var fighter: Node = main.players[0]
	var victim: Node = main.players[1]
	main.current_map_index = fighter.realm_index
	main.layout.assign_combatant(victim, fighter.realm_index)
	# A real physics step grounds the fighter. No helper is called just to increment counts.
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(800, 40)
	shape.shape = box
	floor_body.add_child(shape)
	main.add_child(floor_body)
	floor_body.global_position = Vector2(0, 320)
	fighter.global_position = Vector2(0, 150)
	fighter.collision_mask = 1
	fighter.is_human = false
	fighter.velocity = Vector2(0, 300)
	fighter.knockback_velocity = Vector2.ZERO
	for step in 40:
		await physics_frame
		fighter.velocity = Vector2(0, 300)
		fighter.move_and_slide()
		fighter._handle_landing_state()
	fighter.was_on_floor_last_frame = false
	fighter._handle_landing_state()
	_check(fighter.is_on_floor(), "Landing/guard fixture must be grounded")
	fighter.jump_buffer_timer = 0.1
	fighter.coyote_timer = 0.1
	fighter._apply_movement(1.0 / 60.0)
	_check(float(fighter.velocity.y) < 0.0, "Jump hook must follow a real jump")
	fighter.set_concealed(true)
	fighter.set_concealed(false)
	for attack_type in ["neutral", "up"]:
		_reset_action(fighter)
		fighter.ai_controller.aim_direction = Vector2.ZERO if attack_type == "neutral" else Vector2.UP
		fighter.basic_attack()
		fighter.cancel_pending_actions()
	# Every actual roster variant, including Brave Luna's follow-up ultimate.
	for id: String in REGISTRY.get_character_ids():
		var actor: Node = FACTORY.create(id)
		main.add_child(actor)
		actor.setup(REGISTRY.get_characters()[id], 40, false)
		actor.realm_index = main.current_map_index
		actor.set_physics_process(false)
		actor.global_position = Vector2(0, -300)
		for slot in ["1", "2", "ult"]:
			_reset_action(actor)
			if slot == "1": actor.skill_one()
			elif slot == "2": actor.skill_two()
			else: actor.ultimate()
			actor.cancel_pending_actions()
		if id == "luna":
			actor._enter_transformation()
			for slot in ["1", "2", "ult"]:
				_reset_action(actor)
				if slot == "1": actor.skill_one()
				elif slot == "2": actor.skill_two()
				else: actor.ultimate()
				actor.cancel_pending_actions()
		if id in ["rio", "nova"]:
			_reset_action(actor)
			if id == "rio":
				actor.air_blink_available = false
			else:
				actor.air_vector_shift_available = false
			var before: int = manager.requests.get("skill_%s_1" % id, 0)
			actor.skill_one()
			_check(int(manager.requests.get("skill_%s_1" % id, 0)) == before, "Rejected airborne skill must not sound: " + id)
		actor.queue_free()
	# Accepted, blocked, parried, absorbed, forced-launch and rejected hit paths.
	victim.invulnerable_timer = 0.0
	victim.hp = victim.max_hp
	victim.apply_hit(fighter, 5.0, 100.0, Vector2.RIGHT)
	victim.apply_hit(fighter, 50.0, 150.0, Vector2.RIGHT)
	victim.apply_forced_launch_hit(fighter, 2.0, Vector2(0, -700), 0.4, 700.0, Vector2.UP)
	victim.invulnerable_timer = 1.0
	var hits_before: int = manager.requests.get("hurt", 0)
	_check(not victim.apply_hit(fighter, 5.0, 100.0, Vector2.RIGHT), "Invulnerable hit must be rejected")
	_check(int(manager.requests.get("hurt", 0)) == hits_before, "Rejected hit must not request hurt")
	# Use the resolved knockback, including low-HP amplification. Armor receives
	# an impact without being launched, even for the forced-launch attack API.
	victim.invulnerable_timer = 0.0
	victim.ultimate_armor_timer = 0.0
	victim.hp = victim.max_hp * 0.3
	var launches_before: int = manager.requests.get("hit_launch", 0)
	victim.apply_hit(fighter, 1.0, 470.0, Vector2.UP)
	_check(int(manager.requests.get("hit_launch", 0)) == launches_before + 1, "Resolved strong knockback must request launch")
	victim.ultimate_armor_timer = 1.0
	launches_before = int(manager.requests.get("hit_launch", 0))
	victim.apply_forced_launch_hit(fighter, 1.0, Vector2(0, -700), 0.4, 700.0, Vector2.UP)
	_check(int(manager.requests.get("hit_launch", 0)) == launches_before, "Armor-absorbed hit must not request launch")
	fighter.invulnerable_timer = 0.0
	fighter.hitstun_timer = 0.0
	fighter.global_position = Vector2(0, 299)
	for step in 5:
		await physics_frame
		fighter.velocity = Vector2(0, 300)
		fighter.move_and_slide()
	fighter.is_guarding = true
	fighter.guard_direction = Vector2.RIGHT
	fighter.guard_parry_timer = 0.0
	victim.global_position = Vector2(50, 300)
	fighter.apply_hit(victim, 4.0, 100.0, Vector2.LEFT)
	fighter.guard_parry_timer = 0.1
	fighter.apply_hit(victim, 4.0, 100.0, Vector2.LEFT)
	fighter.is_guarding = false
	fighter.is_human = true
	fighter.add_souls(25)
	main.hud.show_card_offer(CARDS.CARDS.slice(0, 3), 5.0)
	var offers: int = manager.requests.get("card_offer", 0)
	main.hud.show_card_offer(CARDS.CARDS.slice(0, 3), 4.0)
	_check(int(manager.requests.get("card_offer", 0)) == offers, "Card countdown must not repeat the offer sound")
	fighter.apply_upgrade(CARDS.CARDS[0])
	main.hud.set_warning_banner(30)
	main.hud.set_warning_banner(29)
	var warnings: int = manager.requests.get("collapse_warning", 0)
	main.hud.set_warning_banner(28)
	_check(int(manager.requests.get("collapse_warning", 0)) == warnings, "Collapse countdown must not repeat the warning")
	main.hud.set_warning_banner(-1)
	fighter._ringout()
	for realm in main.layout.realm_count():
		var kind := str(main.layout.get_realm(realm).get("hazard", {}).get("type", ""))
		if kind in ["eruption", "quake", "beams", "vines", "belts", "gates"]:
			main.current_map_index = realm
			main.hazards.trigger(realm)
			main.hazards._start_active(realm)
			if kind == "gates":
				main.layout.assign_combatant(fighter, realm)
				fighter.global_position = main.hazards.get_gates(realm)[0]
				main.hazards._carry_through_gates(realm, main.hazards._realms[realm])
	# All ten action owners execute their real action, not AudioManager.play directly.
	main.current_map_index = fighter.realm_index
	for kind: String in ARCHETYPES.PROFILES:
		var monster := CharacterBody2D.new()
		monster.set_script(MONSTER)
		monster.setup("mossling", fighter.realm_index, Vector2(0, 300))
		main.add_child(monster)
		monster.set_physics_process(false)
		monster.archetype = kind
		monster.target = fighter
		monster._begin_windup()
		monster._execute_action()
		monster.apply_hit(fighter, 1.0, 100.0, Vector2.RIGHT)
		monster.apply_hit(fighter, 10000.0, 100.0, Vector2.RIGHT)
		monster.queue_free()
	main.current_map_index = main.layout.get_corner_indices()[0]
	main.realm_monster_spawner._try_spawn_elite(main.layout.get_corner_indices()[0])
	var origin: int = main.layout.get_corner_indices()[0]
	main.layout.assign_combatant(fighter, origin)
	main.current_map_index = origin
	var portals: Array = main._get_portals_for_realm(origin)
	_check(not portals.is_empty(), "Probe requires an actual playable portal")
	if not portals.is_empty():
		main._move_through_portal(fighter, portals[0])
	victim.invulnerable_timer = 0.0
	victim.apply_environment_damage(10000.0)
	main.director._finish(fighter, "audio probe")
	await _frames(2)
	_check(main.match_over and main.hud.frontend.screen == "results", "Silent scripted match must reach results")
	# A real story session also initializes without audio assets.
	main.next_screen = "story_stage"
	main.story_stage = 1
	reload_current_scene()
	await _frames(6)
	main = current_scene
	_check(main.match_started and is_instance_valid(main.story_session), "Story stage must also initialize silently")
	_check(manager.watched_realm.is_valid() and int(manager.watched_realm.call()) == int(main.current_map_index), "Reloaded story Main must supply the current camera realm")
	main.next_screen = "title"
	main.session_mode = "battle_royale"
	main.queue_free()
	await _frames(3)

func _test_world_filtering() -> void:
	var checks_before := checks
	change_scene_to_file("res://scenes/Main.tscn")
	await _frames(4)
	var main: Node = current_scene
	main.player_count = 4
	main._start_match("frey")
	await _frames(2)
	main.process_mode = Node.PROCESS_MODE_DISABLED
	var fighters: Array = [main.players[0], main.players[1]]
	var realms: Array[int] = []
	for realm in main.layout.realm_count():
		if str(main.layout.get_realm(realm).get("hazard", {}).get("type", "")) in ["eruption", "quake", "beams", "vines", "belts", "gates"]:
			realms.append(realm)
	_check(realms.size() >= 2, "Filtering fixture needs two real hazard realms")
	for index in 2:
		main.layout.assign_combatant(fighters[index], realms[index])
	var monster := CharacterBody2D.new()
	monster.set_script(MONSTER)
	monster.setup("mossling", realms[0], Vector2.ZERO)
	main.add_child(monster)
	monster.archetype = "bite"
	monster.target = fighters[0]
	for id in ["hit_light", "monster_bite", "hazard_warning", "card_pick", "soul_pickup"]:
		manager.register_stream(id, _tone(2.0))
	var no_realm_before: int = manager.world_probe.no_realm
	for watched: int in realms.slice(0, 2):
		main.current_map_index = watched
		for index in 2:
			var actor: Node = fighters[index]
			var audible: bool = int(actor.realm_index) == watched
			_stop_voices()
			var before: int = manager.requests.get("hit_light", 0)
			actor.invulnerable_timer = 0.0
			actor.ultimate_armor_timer = 0.0
			actor.is_guarding = false
			actor.hp = actor.max_hp
			_check(actor.apply_hit(fighters[1 - index], 1.0, 10.0, Vector2.RIGHT), "Fixture hit must be accepted")
			_check(int(manager.requests.get("hit_light", 0)) == before + 1, "Both realm hits must be requested")
			_check(manager.active_count("hit_light") == (1 if audible else 0), "Only the watched fighter hit must play")
			_stop_voices()
			monster.realm_index = actor.realm_index
			before = int(manager.requests.get("monster_bite", 0))
			monster._execute_action()
			_check(int(manager.requests.get("monster_bite", 0)) == before + 1, "Both realm monster attacks must be requested")
			_check(manager.active_count("monster_bite") == (1 if audible else 0), "Only the watched monster attack must play")
			_stop_voices()
			before = int(manager.requests.get("hazard_warning", 0))
			main.hazards._start_warning(actor.realm_index)
			_check(int(manager.requests.get("hazard_warning", 0)) == before + 1, "Both realm hazard warnings must be requested")
			_check(manager.active_count("hazard_warning") == (1 if audible else 0), "Only the explicitly identified watched hazard must play")
	# Progress is human-only even when spectating a bot in a different realm.
	main.current_map_index = realms[1]
	for human in [false, true]:
		var actor: Node = fighters[0]
		actor.is_human = human
		_stop_voices()
		var souls_before: int = actor.souls
		actor.add_souls(1)
		_check(actor.souls == souls_before + 1, "Audio must preserve human and bot soul gains")
		_check(manager.active_count("soul_pickup") == (1 if human else 0), "Soul pickup must play only for is_human, regardless of watched realm")
		_stop_voices()
		var picks_before: int = actor.soul_picks
		actor.apply_upgrade(CARDS.CARDS[0])
		_check(actor.soul_picks == picks_before + 1, "Audio must preserve human and bot card application")
		_check(manager.active_count("card_pick") == (1 if human else 0), "Card pick must play only for is_human, regardless of watched realm")
	_stop_voices()
	_check(int(manager.world_probe.no_realm) == no_realm_before, "World filtering fixtures must all identify a realm")
	# Global collapse warning must remain global even through its world fallback.
	AUDIO.sound(main.hud, "collapse_warning")
	_check(manager.active_count("collapse_warning") == 1, "Global warning must play via a world fallback without a source realm")
	_check(int(manager.world_probe.no_realm) == no_realm_before, "Global warning must not be counted as a world request")
	_stop_voices()
	# A missing realm is deliberately fail-open, counted separately from real hooks.
	var voice: AudioStreamPlayer = manager.play("hit_light")
	_check(voice != null and int(manager.world_probe.no_realm) == no_realm_before + 1, "Unknown realm must play and increment no_realm")
	_stop_voices()
	main.next_screen = "story_stage"
	main.story_stage = 3
	reload_current_scene()
	await _frames(6)
	main = current_scene
	main.process_mode = Node.PROCESS_MODE_DISABLED
	var hero: Node = main._get_human_player()
	_check(main.match_started and hero != null and int(main.current_map_index) == int(hero.realm_index) and int(main.current_map_index) != 0, "Story camera must watch its nonzero stage realm")
	manager.register_stream("jump", _tone())
	_stop_voices()
	hero._restart_jump_motion()
	_check(manager.active_count("jump") == 1, "World sound must play in the watched story realm after scene reload")
	_stop_voices()
	main.next_screen = "title"
	main.session_mode = "battle_royale"
	main.queue_free()
	await _frames(2)
	for id in ["monster_bite", "hazard_warning", "card_pick", "soul_pickup"]:
		manager.cache[id] = null
	world_filter_checks = checks - checks_before

func _test_navigation_audio() -> void:
	var menu: Control = preload("res://scripts/ui/FrontendMenu.gd").new()
	root.add_child(menu)
	var before: int = manager.requests.get("ui_move", 0)
	menu.show_title()
	menu.show_options()
	menu.show_select()
	_check(int(manager.requests.get("ui_move", 0)) == before, "Screen initial focus must never request ui_move")
	menu.show_title()
	menu.buttons[2].mouse_entered.emit()
	_check(int(manager.requests.get("ui_move", 0)) == before, "A button appearing under a stationary mouse must stay silent")
	menu._finish("")
	var down := InputEventKey.new()
	down.keycode = KEY_DOWN
	down.pressed = true
	menu._input(down)
	_check(int(manager.requests.get("ui_move", 0)) == before + 1, "Keyboard navigation must request one ui_move")
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(3, 2)
	menu._input(motion)
	menu.buttons[2].mouse_entered.emit()
	await process_frame
	_check(int(manager.requests.get("ui_move", 0)) == before + 2, "Mouse focus navigation must request one ui_move")
	menu.buttons[2].mouse_entered.emit()
	await process_frame
	_check(int(manager.requests.get("ui_move", 0)) == before + 2, "Hovering the already focused button must stay silent")
	menu._activate("options", "")
	_check(int(manager.requests.get("ui_move", 0)) == before + 2, "Menu activation and its initial focus must not add ui_move")
	menu.show_select()
	menu._input(down)
	_check(int(manager.requests.get("ui_move", 0)) == before + 3, "Character grid keyboard navigation must still sound")
	menu.show_title()
	await process_frame
	before = int(manager.requests.get("ui_move", 0))
	motion = InputEventMouseMotion.new()
	motion.position = menu.buttons[1].get_global_rect().get_center()
	motion.global_position = motion.position
	motion.relative = Vector2(20, 30)
	root.push_input(motion, true)
	await process_frame
	_check(int(manager.requests.get("ui_move", 0)) == before + 1, "A real viewport mouse event must sound exactly once on focus change")
	menu.queue_free()
	await process_frame

func _probe_story_dialogue() -> void:
	var dialogue: Control = preload("res://scripts/ui/StoryDialogue.gd").new()
	root.add_child(dialogue)
	var text_before: int = manager.requests.get("story_text", 0)
	var advance_before: int = manager.requests.get("story_advance", 0)
	dialogue.play([["narrator", "First line"], ["hero", "Second line"]], "frey", "", "female")
	_check(int(manager.requests.get("story_text", 0)) == text_before + 1, "Showing one dialogue line must request story_text once")
	dialogue._activate("dialogue_next", "")
	_check(int(manager.requests.get("story_advance", 0)) == advance_before + 1 and int(manager.requests.get("story_text", 0)) == text_before + 1, "Revealing typed text must request advance without a new line sound")
	dialogue._activate("dialogue_next", "")
	_check(int(manager.requests.get("story_advance", 0)) == advance_before + 2 and int(manager.requests.get("story_text", 0)) == text_before + 2, "Advancing to the next line must request both hooks once")
	dialogue._activate("dialogue_skip", "")
	_check(int(manager.requests.get("story_advance", 0)) == advance_before + 3 and int(manager.requests.get("story_text", 0)) == text_before + 2, "Skip must request advance, without sounding a nonexistent line")
	dialogue.queue_free()
	await process_frame
	var menu: Control = preload("res://scripts/ui/StoryScreens.gd").new()
	root.add_child(menu)
	var results_before: int = manager.requests.get("results", 0)
	var victory_before: int = manager.requests.get("victory", 0)
	var music_before: int = manager.requests.get("music_results", 0)
	menu.show_story_result({"clear": false, "stage": 1, "seconds": 10, "damage": 25, "cards": []})
	_check(int(manager.requests.get("results", 0)) == results_before + 1 and int(manager.requests.get("victory", 0)) == victory_before, "Failed stage must request results without victory")
	_check(int(manager.requests.get("music_results", 0)) == music_before + 1 and manager.current_music == "music_results", "Failed stage must switch to result music")
	menu.show_story_result({"clear": true, "stage": 1, "seconds": 10, "damage": 25, "cards": []})
	_check(int(manager.requests.get("results", 0)) == results_before + 2 and int(manager.requests.get("victory", 0)) == victory_before + 1, "Cleared stage must request results and victory once")
	menu.queue_free()
	await process_frame

func _test_id_gaps() -> void:
	var expected := {"land": 150, "hurt": 70, "hit_light": 50, "hit_heavy": 60, "swing_light": 60, "swing_heavy": 60, "tumble": 120, "monster_hurt": 70, "jump": 40}
	for id: String in expected:
		_stop_voices()
		manager.register_stream(id, _tone())
		var gap: int = expected[id] * 1000
		_check(manager.gap_usec(id) == gap, "Catalog gap differs for " + id)
		_check(manager.play(id) != null, "First request must play: " + id)
		# Anchor to the real monotonic clock just before each production play call.
		manager.last_started[id] = Time.get_ticks_usec() - gap + 20000
		_check(manager.play(id) == null, "Request before its per-id gap must be rejected: " + id)
		manager.last_started[id] = Time.get_ticks_usec() - gap
		_check(manager.play(id) != null, "Request at its per-id gap must play: " + id)
		var now := 1000000
		manager.last_started[id] = now
		_check(not manager.gap_allows(id, id, now + gap - 1) and manager.gap_allows(id, id, now + gap), "Gap boundary must hold to one microsecond: " + id)
	_stop_voices()
	# Separate ids must not throttle one another when neither uses a fallback.
	_check(manager.play("land") != null and manager.play("hurt") != null, "Distinct sound ids must retain independent gaps")
	_stop_voices()
	manager.cache.hit_heavy = null
	_check(manager.play("hit_heavy") != null, "Missing heavy sound must resolve to light")
	var now := 1000000
	manager.last_started = {"hit_light": now}
	_check(not manager.gap_allows("hit_heavy", "hit_light", now + 49999), "Fallback's own gap must still hold")
	manager.last_started = {"hit_heavy": now}
	_check(not manager.gap_allows("hit_heavy", "hit_light", now + 59999), "Requested id's longer gap must still hold through fallback")
	_stop_voices()

func _test_landing_audio() -> void:
	var arena := Node2D.new()
	root.add_child(arena)
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(1600, 40)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector2(0, 320)
	arena.add_child(floor_body)
	var actors: Array[Node] = []
	for index in 2:
		var actor: Node = FACTORY.create("frey")
		arena.add_child(actor)
		actor.setup(REGISTRY.get_characters().frey, 80 + index, false)
		actor.set_physics_process(false)
		actor.collision_mask = 1
		actor.global_position = Vector2(index * 300, 298)
		actors.append(actor)
		for frame in 4:
			await physics_frame
			actor.velocity = Vector2(0, 100)
			actor.move_and_slide()
			actor._handle_landing_state()
	manager.watched_realm = Callable()
	manager.register_stream("land", _tone())
	_stop_voices()
	var before: int = manager.requests.get("land", 0)
	# A tiny physical hop and landing, below the 0.12 s audible threshold.
	actors[0].velocity.y = -40.0
	var short_frames := 0
	for frame in 20:
		await physics_frame
		actors[0]._apply_movement(1.0 / 60.0)
		actors[0]._handle_landing_state()
		if not actors[0].is_on_floor(): short_frames += 1
	_check(short_frames > 0 and short_frames < 7, "Short-hop fixture must actually leave the floor for less than 0.12 s")
	_check(int(manager.requests.get("land", 0)) == before and manager.active_count("land") == 0, "A short hop must not request or play land")
	# A real jump uses the fighter's existing jump/gravity/movement implementation.
	actors[0].jump_buffer_timer = 0.1
	var air_frames := 0
	for frame in 90:
		await physics_frame
		actors[0]._apply_movement(1.0 / 60.0)
		actors[0]._handle_landing_state()
		# Grounded fighter B is updated every tick while A is in the air.
		actors[1]._apply_movement(1.0 / 60.0)
		actors[1]._handle_landing_state()
		if not actors[0].is_on_floor(): air_frames += 1
	_check(actors[0].is_on_floor() and air_frames >= 8, "Real jump fixture must land after at least 0.12 s in the air")
	_check(int(manager.requests.get("land", 0)) == before + 1 and manager.active_count("land") == 1, "A real jump must request and play one land, independently of grounded fighter B")
	var key: int = actors[0].get_instance_id()
	arena.queue_free()
	await process_frame
	_check(not manager._landing_states.has(key), "Freed fighters must not retain landing audio state")
	_stop_voices()

func _reset_action(actor: Node) -> void:
	actor.cancel_pending_actions()
	actor.attack_lock_timer = 0.0
	actor.hitstun_timer = 0.0
	actor.guard_recovery_timer = 0.0
	actor.is_guarding = false
	actor.action_locked_until_land = false
	actor.movement_freeze_timer = 0.0
	actor.ultimate_cooldown_timer = 0.0
	actor.ultimate_armor_timer = 0.0
	if actor.character_id == "rio":
		actor.air_blink_available = true
		actor.rune_cooldown_timer = 0.0
	elif actor.character_id == "nova":
		actor.air_vector_shift_available = true
		actor.ultimate_phase = actor.ULTIMATE_NONE

func _tone(seconds := 1.0) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var pcm := PackedByteArray()
	pcm.resize(int(seconds * stream.mix_rate) * 2)
	for sample in pcm.size() / 2:
		pcm.encode_s16(sample * 2, int(sin(TAU * 440.0 * sample / stream.mix_rate) * 2000.0))
	stream.data = pcm
	return stream

func _stop_voices() -> void:
	for voice: AudioStreamPlayer in manager.voices:
		voice.stop()
	manager.last_started.clear()

func _real_wait(milliseconds: int) -> void:
	var deadline := Time.get_ticks_msec() + milliseconds
	while Time.get_ticks_msec() < deadline:
		await process_frame

func _test_voices() -> void:
	manager.register_stream("hit_light", _tone())
	var voice: AudioStreamPlayer = manager.play("hit_light")
	_check(voice != null and voice.playing and voice.bus == "SFX", "Registered tone must play on SFX")
	_check(voice.pitch_scale >= 0.96 and voice.pitch_scale <= 1.04, "Hit pitch variation must stay within 4%")
	_check(manager.play("hit_light") == null, "Immediate repeat must be suppressed")
	await _real_wait(70)
	_check(manager.play("hit_light") != null, "Repeat after the 50ms gap must play")
	await _real_wait(70)
	_check(manager.play("hit_light") != null, "Third hit fits the cap")
	await _real_wait(70)
	_check(manager.play("hit_light") == null and manager.active_count("hit_light") == 3, "Fourth hit must respect the per-id voice cap")
	_stop_voices()
	_check(manager.play("hit_launch") != null and manager.resolutions.get("hit_launch") == "hit_light", "hit_launch -> hit_heavy -> hit_light must resolve")
	_stop_voices()
	manager.register_stream("swing", _tone())
	_check(manager.play("swing_heavy") != null and manager.resolutions.get("swing_heavy") == "swing", "Trial swing name must remain the fallback")
	_check(manager.play("swing_light") == null, "Shared fallback must share its minimum gap")
	for id in ["swing_light", "swing_heavy"]:
		await _real_wait(70)
		_check(manager.play(id) != null, "Shared fallback must accept up to three voices")
	await _real_wait(70)
	_check(manager.play("swing_light") == null and manager.active_count("swing", true) == 3, "Aliases must also share the resolved voice cap")
	_stop_voices()
	manager.unlocked = false
	_check(manager.play("hit_light") == null, "No sound before input unlock")
	var input := InputEventKey.new()
	input.pressed = true
	input.keycode = KEY_ENTER
	manager._input(input)
	_check(manager.unlocked and manager.play("hit_light") != null, "First pressed input must unlock audio")
	var pitch: float = manager.voices[0].pitch_scale
	Engine.time_scale = 0.7
	await process_frame
	_check(is_equal_approx(manager.voices[0].pitch_scale, pitch), "Game speed must not alter pitch")
	Engine.time_scale = 1.0
	_stop_voices()
	manager.register_stream("jump", _tone())
	seed(731)
	var expected := randf()
	seed(731)
	manager.play("jump")
	_check(is_equal_approx(randf(), expected), "Sound must not consume gameplay RNG")
	_stop_voices()
	# Pool exhaustion cannot allocate more players or steal an existing event's voice.
	for index in manager.voices.size():
		manager.voices[index].stream = _tone()
		manager.voices[index].play()
	_check(manager.play("jump") == null and manager.voices.size() == AUDIO.POOL_SIZE, "Global voice pool must stay bounded")
	_stop_voices()

func _test_music() -> void:
	manager.register_stream("music_battle", _tone(0.15))
	manager.register_stream("music_title", _tone(0.15))
	manager.unlocked = false
	manager.play_music("music_title")
	manager.play_music("music_battle")
	_check(manager.music_players.all(func(item: AudioStreamPlayer) -> bool: return not item.playing), "Locked music must remain silent")
	manager.unlock()
	_check(manager.current_music == "music_battle", "Unlock must start only the newest pending track")
	await create_timer(0.55, true, false, true).timeout
	var player: AudioStreamPlayer = manager.music_players[manager.music_index]
	_check(player.playing and player.bus == "Music" and is_zero_approx(player.volume_db), "Music must reach full level and loop past tone duration")
	_check(not (manager.cache["music_battle"] as AudioStreamWAV).loop_mode, "Looping must not mutate a cached or caller-owned test stream")
	manager.play_music("music_title")
	_check(manager.music_players[0].playing and manager.music_players[1].playing, "Music change must overlap during the crossfade")
	await create_timer(0.55, true, false, true).timeout
	_check(manager.music_players.filter(func(item: AudioStreamPlayer) -> bool: return item.playing).size() == 1, "Only one music player remains after crossfade")
	for track in ["music_battle", "music_title", "music_story", "music_title"]:
		manager.play_music(track)
	await create_timer(0.55, true, false, true).timeout
	_check(manager.music_players.filter(func(item: AudioStreamPlayer) -> bool: return item.playing).size() == 1, "Rapid retargeting must leave one player")
	manager.play_music("music_story")
	_check(manager.resolved_music == "music_battle", "Missing story music must fall back to battle")
	manager.cache["music_battle"] = null
	manager.cache["music_results"] = null
	manager.play_music("music_results")
	await create_timer(0.55, true, false, true).timeout
	_check(manager.music_players.all(func(item: AudioStreamPlayer) -> bool: return not item.playing), "Missing music must fade the old track to silence")

func _test_settings_and_options() -> void:
	var saved_before := FileAccess.get_file_as_bytes(SETTINGS.SAVE_PATH) if FileAccess.file_exists(SETTINGS.SAVE_PATH) else PackedByteArray()
	var existed := FileAccess.file_exists(SETTINGS.SAVE_PATH)
	var temporary := "res://../reports/codex-sys-08/audio-test.cfg"
	SETTINGS.values = {"master": 30, "music": 40, "effects": 50, "mute": true}
	_check(SETTINGS.save_to(temporary) == OK, "Explicit temporary config must save")
	SETTINGS.values = SETTINGS.DEFAULTS.duplicate()
	_check(SETTINGS.load_from(temporary) == OK and SETTINGS.values.master == 30 and SETTINGS.values.mute, "Settings must round-trip")
	_check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "Mute must set the Master bus")
	for pair in [["Master", 0.3], ["Music", 0.4], ["SFX", 0.5]]:
		_check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(pair[0]))), pair[1]), "Bus volume differs from saved percent: " + pair[0])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
	SETTINGS.values = SETTINGS.DEFAULTS.duplicate()
	SETTINGS.apply()
	var menu: Control = preload("res://scripts/ui/FrontendMenu.gd").new()
	root.add_child(menu)
	for locale in ["en", "ko"]:
		LANGUAGE.set_locale(locale)
		menu.show_options()
		await process_frame
		_check(menu.buttons.size() == 10 and menu.audio_buttons.size() == 4, "Options must retain five old choices plus four audio choices and Back")
		for button: Button in menu.buttons:
			var font: Font = button.get_theme_font("font")
			var width := font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
			_check(width <= button.size.x - 24.0, "Option text overflows in %s: %s (%.0f / %.0f)" % [locale, button.text, width, button.size.x - 24.0])
			_check(Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(Rect2(button.position, button.size)), "Option button must remain within the screen")
	menu.audio_buttons.master.pressed.emit()
	_check(SETTINGS.values.master == 90, "Master button must cycle by ten")
	menu.audio_buttons.music.pressed.emit()
	_check(SETTINGS.values.music == 70, "Music button must cycle by ten")
	menu.audio_buttons.effects.pressed.emit()
	_check(SETTINGS.values.effects == 90, "Effects button must cycle by ten")
	menu.audio_buttons.mute.pressed.emit()
	_check(SETTINGS.values.mute, "Mute button must toggle")
	for pair in [["master", 80], ["music", 60], ["effects", 80]]:
		SETTINGS.values[pair[0]] = pair[1]
		for step in 11:
			SETTINGS.cycle(pair[0])
		_check(SETTINGS.values[pair[0]] == pair[1], "Every volume option must cycle through eleven steps")
	SETTINGS.values.master = 100
	SETTINGS.cycle("master")
	_check(SETTINGS.values.master == 0 and AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "100 must cycle to a silent zero")
	_check(FileAccess.file_exists(SETTINGS.SAVE_PATH) == existed, "Headless options must not create the user's config")
	if existed:
		_check(FileAccess.get_file_as_bytes(SETTINGS.SAVE_PATH) == saved_before, "Headless tests must preserve the user's audio config")
	SETTINGS.values = SETTINGS.DEFAULTS.duplicate()
	SETTINGS.apply()
	LANGUAGE.set_locale("en")
	menu.queue_free()
	await process_frame

func _test_contract() -> void:
	var doc := FileAccess.get_file_as_string("res://../design/AUDIO.md")
	for path in ["scripts/Main.gd", "scripts/realms/RealmHazards.gd", "scripts/ui/MatchHud.gd", "scripts/RealmMonsterSpawner.gd", "scripts/ui/FrontendMenu.gd"]:
		var source := FileAccess.get_file_as_string("res://" + path)
		_check(source.find("##") < source.find("const AUDIO :="), "Class documentation must precede the AUDIO preload: " + path)
	for id: String in CATALOG.SOUNDS:
		_check(doc.contains("| `" + id + "` |"), "AUDIO.md must document runtime id " + id)
		if CATALOG.SOUNDS[id].group in ["Fighters", "Skills", "Monsters", "Realms"]:
			_check(bool(CATALOG.SOUNDS[id].world) == (id != "collapse_warning"), "World groups must be filtered except global collapse warning: " + id)
		elif CATALOG.SOUNDS[id].group != "Fallback":
			_check(not bool(CATALOG.SOUNDS[id].world), "Menus, music and progress must remain global: " + id)
		var seen: Dictionary = {}
		var next := id
		while next != "":
			_check(CATALOG.SOUNDS.has(next) and not seen.has(next), "Fallback chain must terminate: " + id)
			if not CATALOG.SOUNDS.has(next) or seen.has(next): break
			seen[next] = true
			next = CATALOG.SOUNDS[next].fallback
