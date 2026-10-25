extends SceneTree
const MAIN = preload("res://scripts/Main.gd")
const PROGRESS = preload("res://scripts/story/StoryProgress.gd")
const SPEED = preload("res://scripts/GameSpeed.gd")
const FACTORY = preload("res://scripts/PlayerFactory.gd")
const REGISTRY = preload("res://characters/CharacterRegistry.gd")
var events: Array = []
var recording := false
var rows: Array = []
var main: Node
var mode := "a"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="): mode = arg.trim_prefix("--mode=")
	node_added.connect(_added)
	call_deferred("_run")

func _added(node: Node) -> void:
	if recording and node is Area2D:
		events.append({"tick": Engine.get_physics_frames(), "paused": paused, "script": str(node.get_script().resource_path) if node.get_script() else "", "id": node.get_instance_id()})

func key(code: int, down := true) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = down
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func ticks(n: int) -> void:
	for i in n: await physics_frame

func dispose() -> void:
	paused = false
	Engine.time_scale = 1.0
	if is_instance_valid(main):
		main.queue_free()
		current_scene = null
		await process_frame
		await process_frame

func start(stage: int, id := "frey", begin := true) -> Node:
	await dispose()
	MAIN.story_hero = id
	MAIN.human_body = "female"
	MAIN.story_stage = stage
	MAIN.story_difficulty = "normal"
	MAIN.story_art_state = {}
	MAIN.next_screen = "story_stage"
	PROGRESS.runs.clear()
	PROGRESS.new_journey(id, "normal")
	main = load("res://scenes/Main.tscn").instantiate()
	main.match_seed = 1001
	root.add_child(main)
	current_scene = main
	await ticks(6)
	if begin:
		main.story_session.begin_dialogue()
		main.story_session.dialogue._activate("dialogue_skip", "")
		for enemy in main.story_session.enemies:
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
		main.hazards.enabled = false
		main.story_session.hero.grant_protection(1000.0)
		await ticks(60)
	return main.story_session.hero

func state(h: Node) -> Dictionary:
	return {"invulnerable": h.invulnerable_timer, "hitstun": h.hitstun_timer, "hitstop": h.hitstop_timer, "alpha": h.modulate.a, "action": str(h.sprite_action), "action_timer": h.sprite_action_timer, "attack_lock": h.attack_lock_timer, "laser": is_instance_valid(h.get("heart_laser")), "transformed": h.get("transformed"), "rune": h.get("rune_timer")}

func pause_wall(h: Node) -> Dictionary:
	key(KEY_ESCAPE)
	key(KEY_ESCAPE, false)
	var before := state(h)
	var start_tick := Engine.get_physics_frames()
	var start_us := Time.get_ticks_usec()
	var frames := 0
	var was_paused := paused
	while Time.get_ticks_usec() - start_us < 2100000:
		await process_frame
		frames += 1
	var after := state(h)
	var end_tick := Engine.get_physics_frames()
	var wall := (Time.get_ticks_usec() - start_us) / 1000000.0
	key(KEY_ESCAPE)
	key(KEY_ESCAPE, false)
	return {"before": before, "after": after, "wall_seconds": wall, "process_frames": frames, "paused_ticks": end_tick-start_tick, "start_tick": start_tick, "resume_tick": end_tick, "entered": was_paused, "resumed": not paused, "resume_scale": Engine.time_scale}

func case_a(kind: String, with_pause: bool, speed: float) -> void:
	var id := "rio" if kind == "rio_l" else ("luna" if kind.begins_with("laser") else "frey")
	var h: Node = await start(1, id)
	SPEED.factor = speed
	SPEED.apply_to_match()
	if kind.begins_with("laser"):
		key(KEY_I)
		key(KEY_I, false)
		await ticks(120)
		# Transformation reached through I; shorten only remaining form lifetime for the fixture.
		h.transformation_timer = 0.6
		await ticks(1)
	if kind == "protection":
		h.invulnerable_timer = 0.0
		h._ringout()
	if kind == "hitstun":
		h.invulnerable_timer = 0.0
		h.apply_hit(null, 1.0, 600.0, Vector2.RIGHT)
	var press := Engine.get_physics_frames()
	events = []
	recording = true
	if kind == "frey_j": key(KEY_J)
	elif kind in ["frey_i", "frey_aftershock"] or kind.begins_with("laser"): key(KEY_I)
	elif kind == "rio_l": key(KEY_L)
	key(KEY_J, false)
	key(KEY_I, false)
	key(KEY_L, false)
	# A real absorbed hit gives Rio an observable release attack.
	if kind == "rio_l":
		h.invulnerable_timer = 0.0
		h.apply_hit(null, 1.0, 100.0, Vector2.RIGHT)
	var pause_at := 2
	if kind == "frey_aftershock": pause_at = 18 if speed == 1.0 else 25
	if kind == "laser_end": pause_at = 14
	if kind == "protection" or kind == "hitstun": pause_at = 7
	await ticks(pause_at)
	var p: Dictionary = {}
	if with_pause: p = await pause_wall(h)
	var samples: Array = []
	for i in 110:
		samples.append({"tick": Engine.get_physics_frames(), "state": state(h)})
		await ticks(1)
	recording = false
	var row := {"kind": kind, "pause": with_pause, "speed": speed, "press_tick": press, "pause_info": p, "events": events.duplicate(true), "samples": samples}
	rows.append(row)
	print("QA24_A ", kind, " pause=", with_pause, " events=", events.size(), " resumed=", p.get("resumed", true))

func run_b() -> void:
	await dispose()
	for id in ["frey", "luna", "luna_brave", "yuki", "nova", "rio"]:
		var actual: String = "luna" if id == "luna_brave" else id
		for body in (["male", "female"] if id in ["nova", "rio"] else ["female"]):
			for strength in [100.0, 800.0]:
				main = Node2D.new()
				root.add_child(main)
				var h: Node = FACTORY.create(actual, body)
				main.add_child(h)
				h.body_type = body
				h.setup(REGISTRY.get_characters()[actual], 1, true)
				h.global_position = Vector2(0, -600)
				h.spawn_points = [Vector2(0, -600)] as Array[Vector2]
				h.ringout_y = 1000.0
				if id == "luna_brave":
					h.transformed = true
					h.transformation_timer = 30.0
				await ticks(2)
				var hurt_name: StringName = h._get_sprite_animation_name(&"hurt")
				var hurt_frames: int = h.character_sprite.sprite_frames.get_frame_count(hurt_name)
				h.apply_hit(null, 1.0, strength, Vector2.RIGHT)
				var hit_tick := Engine.get_physics_frames()
				var hit_action := str(h.sprite_action)
				await ticks(1)
				h.global_position.y = h.ringout_y + 100.0
				key(KEY_D)
				var count := 0
				while h.global_position.y > h.ringout_y and count < 30:
					await ticks(1)
					count += 1
				var respawn_tick := Engine.get_physics_frames()
				var samples: Array = []
				var last: Vector2 = h.global_position
				for i in 61:
					var pos: Vector2 = h.global_position
					samples.append({"tick": Engine.get_physics_frames(), "animation": str(h.character_sprite.animation), "frame": h.character_sprite.frame, "sprite_action": str(h.sprite_action), "sprite_action_timer": h.sprite_action_timer, "hurt_motion_duration": h.hurt_motion_duration, "landing_motion_timer": h.landing_motion_timer, "hitstun_timer": h.hitstun_timer, "attack_lock_timer": h.attack_lock_timer, "x": pos.x, "y": pos.y, "dx": pos.x-last.x, "dy": pos.y-last.y, "can_attack": h._can_start_attack()})
					last = pos
					await ticks(1)
				key(KEY_D, false)
				rows.append({"id": id, "body": body, "strength": strength, "hurt_frames": hurt_frames, "hit_tick": hit_tick, "hit_action": hit_action, "respawn_tick": respawn_tick, "respawn_observed": count < 30, "samples": samples})
				print("QA24_B ", id, " ", body, " ", strength, " ", hit_action, " respawn_wait=", count)
				await dispose()

func hud_sample(label: String, index: int) -> void:
	var s: Node = main.story_session
	rows.append({"transition": label, "offset": index, "process_frame": Engine.get_process_frames(), "physics_frame": Engine.get_physics_frames(), "hp": main.hud.hp_bar.visible, "clock": main.hud.clock_label.visible, "phase": s.phase, "dialogue": s.dialogue.visible, "overlay": main.hud.overlay.visible, "paused": paused})

func sample_frames(label: String, first: int, count: int) -> void:
	for i in count:
		await process_frame
		# Deferred resumes after node _process, before the next rendered frame.
		await create_timer(0.0, true, false, true).timeout
		hud_sample(label, first+i)

func transition(label: String, action: Callable) -> void:
	await sample_frames(label, -10, 10)
	action.call()
	hud_sample(label, 0)
	await sample_frames(label, 1, 30)

func run_c() -> void:
	for stage in [1, 8, 9]:
		await start(stage, "frey", false)
		await transition("s%d_start_pre" % stage, func(): main.story_session.begin_dialogue())
		await transition("s%d_pre_combat" % stage, func(): main.story_session.dialogue._activate("dialogue_skip", ""))
		for enemy in main.story_session.enemies: enemy.process_mode = Node.PROCESS_MODE_DISABLED
		main.story_session.hero.grant_protection(1000.0)
		await transition("s%d_pause" % stage, func(): key(KEY_ESCAPE); key(KEY_ESCAPE, false))
		await transition("s%d_resume" % stage, func(): key(KEY_ESCAPE); key(KEY_ESCAPE, false))
		if stage == 9:
			await transition("s9_mid", func(): kill_wave())
			await transition("s9_mid_combat", func(): main.story_session.dialogue._activate("dialogue_skip", ""))
		await transition("s%d_post" % stage, func(): kill_all())
		await transition("s%d_post_exit_result" % stage, func(): main.story_session.dialogue._activate("dialogue_skip", ""))
		await transition("s%d_result" % stage, func(): main.director._finish(main.story_session.hero, "qa24"))

func kill_wave() -> void:
	for enemy: Node in main.story_session.enemies.duplicate():
		if enemy.has_method("apply_environment_damage"): enemy.apply_environment_damage(enemy.hp + 100.0)
		else: enemy.apply_hit(null, 100000.0, 0.0, Vector2.RIGHT, "fixed")

func kill_all() -> void:
	# Objective completion is a controlled transition fixture; actual wave completion is tested for mid.
	main.story_session._objective_done()

func _run() -> void:
	root.size = Vector2i(1280, 720)
	Engine.max_fps = 60
	if mode in ["a", "a_protection"]:
		for speed in [1.0, 0.7]:
			for kind in (["protection"] if mode == "a_protection" else ["frey_j", "frey_i", "frey_aftershock", "rio_l", "laser_start", "laser_end", "protection", "hitstun"]):
				for with_pause in [false, true]: await case_a(kind, with_pause, speed)
	elif mode == "b": await run_b()
	elif mode == "c": await run_c()
	var file := FileAccess.open("res://../reports/codex-qa-24/" + mode + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"mode": mode, "seed": 1001, "rows": rows}, "\t"))
	await dispose()
	print("QA24_DONE ", mode, " rows=", rows.size())
	quit()
