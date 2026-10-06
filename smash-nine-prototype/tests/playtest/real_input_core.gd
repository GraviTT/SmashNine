extends SceneTree
## Real-input playtest for start flow, controls, portal travel, and soul cards.
## Every gameplay action is sent through Input.parse_input_event with physical keys.

const MAIN_SCENE := "res://scenes/Main.tscn"
const OUT_RELATIVE := "../reports/codex-tester-01"

const KEY_A := 65
const KEY_B := 66
const KEY_D := 68
const KEY_I := 73
const KEY_J := 74
const KEY_K := 75
const KEY_L := 76
const KEY_Q := 81
const KEY_S := 83
const KEY_SPACE := 32
const KEY_W := 87
const KEY_1 := 49
const KEY_2 := 50
const KEY_3 := 51
const KEY_4 := 52

var out_dir := ""
var main: Node
var held: Dictionary = {}
var results: Dictionary = {
	"driver": "real_input_core",
	"start_flow": [],
	"controls": {},
	"portal": {},
	"soul_cards": {},
	"screenshots": []
}

func _initialize() -> void:
	out_dir = ProjectSettings.globalize_path("res://").path_join(OUT_RELATIVE)
	DirAccess.make_dir_recursive_absolute(out_dir)
	call_deferred("_run")

func _run() -> void:
	await _test_start_flow()
	await _test_controls_portal_and_cards()
	_release_all()
	Engine.time_scale = 1.0
	_write_json("real_input_core.json", results)
	print("PLAYTEST_RESULT ", JSON.stringify(results))
	quit(0)

func _test_start_flow() -> void:
	var cases: Array[Dictionary] = [
		{"key": KEY_1, "expected": "frey", "label": "1_frey"},
		{"key": KEY_2, "expected": "yuki", "label": "2_yuki"},
		{"key": KEY_3, "expected": "luna", "label": "3_luna"},
		{"key": KEY_4, "expected": "nova", "label": "4_nova"},
		{"key": KEY_B, "expected": "bots", "label": "b_bots"}
	]
	for index in cases.size():
		var test_case: Dictionary = cases[index]
		await _new_main(4100 + index)
		if index == 0:
			await _shot("01_start_overlay")
		var start_nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		await _tap(int(test_case.key))
		await _physics_frames(12)
		var entry: Dictionary = {
			"key": test_case.label,
			"match_started": main.match_started,
			"overlay_hidden": not main.hud.overlay.visible,
			"player_count": main.players.size(),
			"start_nodes": start_nodes,
			"realm_view": main.current_map_index,
			"hud_status": main.hud.status_label.text
		}
		if test_case.expected == "bots":
			var focus: Node = main._get_focus_player()
			entry["bots_only"] = main.bots_only
			entry["human_count"] = _human_count()
			entry["spectate_valid"] = is_instance_valid(focus) and not focus.is_human
			entry["spectate_realm"] = focus.realm_index if is_instance_valid(focus) else -1
			entry["pass"] = main.match_started and main.bots_only and int(entry.human_count) == 0 and bool(entry.spectate_valid) and main.current_map_index == int(entry.spectate_realm)
		else:
			var player: Node = main.players[0] if not main.players.is_empty() else null
			entry["actual_character"] = player.character_id if is_instance_valid(player) else ""
			entry["p1_human"] = is_instance_valid(player) and player.is_human
			entry["camera_realm_matches"] = is_instance_valid(player) and main.current_map_index == player.realm_index
			entry["pass"] = main.match_started and bool(entry.overlay_hidden) and entry.actual_character == test_case.expected and bool(entry.p1_human) and bool(entry.camera_realm_matches)
		results.start_flow.append(entry)
		await _shot("%02d_start_%s" % [index + 2, test_case.label])
		await _free_main()

func _test_controls_portal_and_cards() -> void:
	await _new_main(4242)
	await _tap(KEY_1)
	await _physics_frames(18)
	var player: Node = main.players[0]
	var control: Dictionary = {}
	var start_position: Vector2 = player.global_position
	await _hold(KEY_D, 30)
	control["move_dx"] = snappedf(player.global_position.x - start_position.x, 0.1)
	control["move_pass"] = absf(float(control.move_dx)) >= 40.0
	await _shot("07_move")

	await _wait_for_floor(player, 180)
	var jump_start_y: float = player.global_position.y
	await _tap(KEY_W)
	var jump_min_y := jump_start_y
	for _frame in 48:
		await physics_frame
		jump_min_y = minf(jump_min_y, player.global_position.y)
	control["jump_rise"] = snappedf(jump_start_y - jump_min_y, 0.1)
	control["jump_pass"] = float(control.jump_rise) >= 40.0
	await _shot("08_jump")

	await _wait_for_floor(player, 240)
	_set_key(KEY_SPACE, true)
	await _physics_frames(10)
	control["guard_active"] = player.is_guarding
	control["guard_visual"] = is_instance_valid(player.guard_visual) and player.guard_visual.visible
	await _shot("09_guard")
	_set_key(KEY_SPACE, false)
	await _physics_frames(3)
	control["guard_released"] = not player.is_guarding and player.guard_recovery_timer > 0.0

	var attack_checks: Dictionary = {}
	for attack in [
		{"name": "J", "key": KEY_J},
		{"name": "K", "key": KEY_K},
		{"name": "L", "key": KEY_L}
	]:
		await _wait_attack_ready(player, 180)
		await _tap(int(attack.key))
		attack_checks[attack.name] = {
			"lock": snappedf(player.attack_lock_timer, 0.001),
			"accepted": player.attack_lock_timer > 0.0
		}
	control["attacks"] = attack_checks

	await _wait_action_ready(player, 240)
	await _tap(KEY_I)
	var first_cooldown: float = player.ultimate_cooldown_timer
	await _physics_frames(18)
	var before_refusal: float = player.ultimate_cooldown_timer
	await _tap(KEY_I)
	var after_refusal: float = player.ultimate_cooldown_timer
	control["ultimate_first_cooldown"] = snappedf(first_cooldown, 0.01)
	control["ultimate_before_refusal"] = snappedf(before_refusal, 0.01)
	control["ultimate_after_refusal"] = snappedf(after_refusal, 0.01)
	control["ultimate_refused"] = after_refusal <= before_refusal + 0.08 and after_refusal < first_cooldown
	await _shot("10_attacks_ultimate_cooldown")
	Engine.time_scale = 8.0
	var cooldown_frames := 0
	while player.ultimate_cooldown_timer > 0.01 and cooldown_frames < 360 and not player.is_defeated:
		await physics_frame
		cooldown_frames += 1
	Engine.time_scale = 1.0
	await _wait_action_ready(player, 180)
	await _tap(KEY_I)
	control["ultimate_after_wait"] = snappedf(player.ultimate_cooldown_timer, 0.01)
	control["ultimate_reused"] = player.ultimate_cooldown_timer >= 29.0

	var drop_result: Dictionary = await _test_drop_through(player)
	control["drop_through"] = drop_result
	results.controls = control

	await _new_main(4242)
	await _tap(KEY_1)
	await _physics_frames(18)
	player = main.players[0]
	results.portal = await _test_portal(player)
	results.soul_cards = await _test_soul_cards()
	await _free_main()

func _test_drop_through(player: Node) -> Dictionary:
	await _wait_for_floor(player, 240)
	var reached_sub := _on_sub_platform(player)
	var target: Node2D
	if not reached_sub:
		target = _nearest_reachable_sub_platform(player)
		if is_instance_valid(target):
			for frame in 600:
				if player.is_defeated or _on_sub_platform(player):
					break
				var dx: float = target.global_position.x - player.global_position.x
				_set_horizontal(dx, 22.0)
				if player.is_on_floor() and target.global_position.y < player.global_position.y - 35.0 and frame % 22 == 0:
					await _tap(KEY_W)
				else:
					await physics_frame
			_set_horizontal(0.0, INF)
		reached_sub = _on_sub_platform(player)
	var before_y: float = player.global_position.y
	var timer_after_taps := 0.0
	if reached_sub:
		await _wait_action_ready(player, 180)
		await _physics_frames(5)
		for _attempt in 3:
			if not _on_sub_platform(player):
				break
			await _tap(KEY_S)
			await _physics_frames(3)
			await _tap(KEY_S)
			timer_after_taps = player.drop_through_timer
			if timer_after_taps > 0.0:
				break
			await _physics_frames(4)
		await _physics_frames(18)
	await _shot("11_drop_through")
	return {
		"reached_sub_platform": reached_sub,
		"timer_after_double_s": snappedf(timer_after_taps, 0.001),
		"y_delta": snappedf(player.global_position.y - before_y, 0.1),
		"pass": reached_sub and timer_after_taps > 0.0 and player.global_position.y > before_y + 8.0
	}

func _test_portal(player: Node) -> Dictionary:
	var portals: Array = main._get_portals_for_realm(player.realm_index)
	if portals.is_empty():
		return {"pass": false, "reason": "no open portal"}
	var portal: Dictionary = portals[0]
	var best_distance := INF
	for candidate in portals:
		var distance: float = player.global_position.distance_to(candidate.rect.get_center())
		if distance < best_distance:
			best_distance = distance
			portal = candidate
	var reached := false
	var drop_cooldown := 0
	var jump_cooldown := 0
	for frame in 900:
		if player.is_defeated:
			break
		if portal.rect.has_point(player.global_position) and player.is_on_floor():
			reached = true
			break
		var target: Vector2 = portal.rect.get_center() + Vector2(0.0, 40.0)
		var dx: float = target.x - player.global_position.x
		_set_horizontal(dx, 28.0)
		drop_cooldown = maxi(drop_cooldown - 1, 0)
		jump_cooldown = maxi(jump_cooldown - 1, 0)
		if player.is_on_floor() and _on_sub_platform(player) and target.y > player.global_position.y + 65.0 and drop_cooldown == 0:
			await _tap(KEY_S)
			await _physics_frames(3)
			await _tap(KEY_S)
			drop_cooldown = 24
		elif player.is_on_floor() and (target.y < player.global_position.y - 50.0 or absf(dx) > 150.0) and jump_cooldown == 0:
			await _tap(KEY_W)
			jump_cooldown = 24
		else:
			await physics_frame
	_set_horizontal(0.0, INF)
	await _shot("12_portal_before_q")
	var source_realm: int = player.realm_index
	var destination: int = int(portal.destination)
	var expected_entry: Vector2 = portal.entry_position
	var before: Vector2 = player.global_position
	if reached:
		await _tap(KEY_Q)
		await _physics_frames(2)
	var arrival: Vector2 = player.global_position
	var arrival_error: float = arrival.distance_to(expected_entry)
	await _physics_frames(10)
	await _shot("13_portal_after_q")
	return {
		"reached_with_adw": reached,
		"source_realm": source_realm,
		"destination_realm": destination,
		"before": _vec(before),
		"expected_entry": _vec(expected_entry),
		"arrival": _vec(arrival),
		"arrival_error_px": snappedf(arrival_error, 0.1),
		"player_realm": player.realm_index,
		"camera_realm": main.current_map_index,
		"q_presses": 1 if reached else 0,
		"pass": reached and player.realm_index == destination and main.current_map_index == destination and arrival_error <= 8.0
	}

func _test_soul_cards() -> Dictionary:
	var data: Dictionary = {"policy": "nearest same-realm monster; A/D/W/S+S navigation; J attacks"}
	await _new_main(4242, 1)
	await _tap(KEY_1)
	await _physics_frames(18)
	var player: Node = main.players[0]
	data["manual_match_character"] = player.character_id
	data["manual_match_seed"] = main.match_seed
	Engine.time_scale = 3.0
	var first_frames: int = await _fight_until_offer(player, 7200)
	Engine.time_scale = 1.0
	var first_offer: Dictionary = main.soul_growth.get_offer(player)
	data["first_offer_frames"] = first_frames
	data["souls_at_first_offer"] = player.souls
	if first_offer.is_empty():
		data["manual_pass"] = false
		data["manual_reason"] = "offer not reached"
		_release_all()
		return data
	var first_cards: Array = first_offer.cards
	var chosen_id: String = str(first_cards[1].id)
	data["first_offer_ids"] = _card_ids(first_cards)
	await _shot("14_soul_offer_manual")
	await _tap(KEY_2)
	await _physics_frames(6)
	data["manual_chosen_id"] = chosen_id
	data["upgrades_after_manual"] = player.upgrades.duplicate()
	data["manual_pass"] = player.upgrades.has(chosen_id) and main.soul_growth.get_offer(player).is_empty()

	# Use another full 8-player match so the timeout is measured independently of
	# damage accumulated during the manual-choice run.
	await _new_main(4242, 1)
	await _tap(KEY_1)
	await _physics_frames(18)
	player = main.players[0]
	data["auto_match_character"] = player.character_id
	data["auto_match_seed"] = main.match_seed
	Engine.time_scale = 3.0
	var second_frames: int = await _fight_until_offer(player, 7200)
	Engine.time_scale = 1.0
	var second_offer: Dictionary = main.soul_growth.get_offer(player)
	data["second_offer_frames"] = second_frames
	data["souls_at_second_offer"] = player.souls
	if second_offer.is_empty():
		data["auto_pass"] = false
		data["auto_reason"] = "second offer not reached"
		_release_all()
		return data
	var second_cards: Array = second_offer.cards
	var auto_id: String = str(second_cards[0].id)
	data["second_offer_ids"] = _card_ids(second_cards)
	await _shot("15_soul_offer_timeout_start")
	var offer_started: float = main.director.match_elapsed
	_set_key(KEY_SPACE, true)
	var wait_frames := 0
	while not main.soul_growth.get_offer(player).is_empty() and wait_frames < 480 and not player.is_defeated:
		await physics_frame
		wait_frames += 1
	_set_key(KEY_SPACE, false)
	var elapsed: float = main.director.match_elapsed - offer_started
	data["auto_elapsed_s"] = snappedf(elapsed, 0.01)
	data["auto_expected_id"] = auto_id
	data["upgrades_after_auto"] = player.upgrades.duplicate()
	data["auto_message"] = main.hud.info_label.text
	data["auto_pass"] = player.upgrades.has(auto_id) and elapsed >= 4.9 and elapsed <= 5.3 and "auto-picked" in main.hud.info_label.text
	await _shot("16_soul_offer_auto_picked")
	_release_all()
	return data

func _fight_until_offer(player: Node, max_frames: int) -> int:
	var attack_cooldown := 0
	var jump_cooldown := 0
	var drop_cooldown := 0
	for frame in max_frames:
		if player.is_defeated or main.match_over or not main.soul_growth.get_offer(player).is_empty():
			_release_all()
			return frame
		var target: Node = _nearest_monster(player)
		if not is_instance_valid(target):
			_set_horizontal(0.0, INF)
			await physics_frame
			continue
		var offset: Vector2 = target.global_position - player.global_position
		_set_horizontal(offset.x, 58.0)
		attack_cooldown = maxi(attack_cooldown - 1, 0)
		jump_cooldown = maxi(jump_cooldown - 1, 0)
		drop_cooldown = maxi(drop_cooldown - 1, 0)
		if player.is_on_floor() and _on_sub_platform(player) and offset.y > 105.0 and drop_cooldown == 0:
			await _tap(KEY_S)
			await _physics_frames(2)
			await _tap(KEY_S)
			drop_cooldown = 24
		elif player.is_on_floor() and (offset.y < -55.0 or absf(offset.x) > 150.0) and jump_cooldown == 0:
			await _tap(KEY_W)
			jump_cooldown = 28
		elif absf(offset.x) < 125.0 and absf(offset.y) < 145.0 and attack_cooldown == 0:
			await _tap(KEY_J)
			attack_cooldown = 16
		else:
			await physics_frame
	_release_all()
	return max_frames

func _nearest_monster(player: Node) -> Node:
	var nearest: Node
	var best := INF
	for monster in get_nodes_in_group("realm_monsters"):
		if not is_instance_valid(monster) or monster.is_queued_for_deletion() or monster.realm_index != player.realm_index:
			continue
		var distance: float = player.global_position.distance_squared_to(monster.global_position)
		if distance < best:
			best = distance
			nearest = monster
	return nearest

func _nearest_reachable_sub_platform(player: Node) -> Node2D:
	var bounds: Rect2 = main.layout.get_bounds(player.realm_index)
	var nearest: Node2D
	var best := INF
	for candidate in get_nodes_in_group("sub_platforms"):
		if not candidate is Node2D or not bounds.has_point(candidate.global_position):
			continue
		var vertical: float = player.global_position.y - candidate.global_position.y
		if vertical < 25.0 or vertical > 230.0:
			continue
		var score: float = absf(player.global_position.x - candidate.global_position.x) + vertical * 1.5
		if score < best:
			best = score
			nearest = candidate
	return nearest

func _on_sub_platform(player: Node) -> bool:
	return player.is_on_floor() and is_instance_valid(player.current_floor_platform) and player.current_floor_platform.is_in_group("sub_platforms")

func _new_main(seed_value: int, player_count: int = 8) -> void:
	await _free_main()
	main = load(MAIN_SCENE).instantiate()
	main.match_seed = seed_value
	main.player_count = player_count
	root.add_child(main)
	await _process_frames(10)

func _free_main() -> void:
	_release_all()
	if is_instance_valid(main):
		main.queue_free()
		await _process_frames(5)
	main = null

func _human_count() -> int:
	var count := 0
	for player in main.players:
		if is_instance_valid(player) and player.is_human:
			count += 1
	return count

func _wait_for_floor(player: Node, max_frames: int) -> void:
	for _frame in max_frames:
		if player.is_on_floor() or player.is_defeated:
			return
		await physics_frame

func _wait_attack_ready(player: Node, max_frames: int) -> void:
	for _frame in max_frames:
		if (player.attack_lock_timer <= 0.0 and player.guard_recovery_timer <= 0.0 and player.hitstun_timer <= 0.0 and not player.is_guarding) or player.is_defeated:
			return
		await physics_frame

func _wait_action_ready(player: Node, max_frames: int) -> void:
	await _wait_attack_ready(player, max_frames)

func _set_horizontal(dx: float, deadzone: float) -> void:
	if absf(dx) <= deadzone:
		_set_key(KEY_A, false)
		_set_key(KEY_D, false)
	elif dx < 0.0:
		_set_key(KEY_D, false)
		_set_key(KEY_A, true)
	else:
		_set_key(KEY_A, false)
		_set_key(KEY_D, true)

func _tap(keycode: int) -> void:
	_set_key(keycode, true)
	await process_frame
	_set_key(keycode, false)
	await process_frame
	await physics_frame

func _hold(keycode: int, frames: int) -> void:
	_set_key(keycode, true)
	await _physics_frames(frames)
	_set_key(keycode, false)
	await physics_frame

func _set_key(keycode: int, pressed: bool) -> void:
	if bool(held.get(keycode, false)) == pressed:
		return
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	event.echo = false
	Input.parse_input_event(event)
	held[keycode] = pressed

func _release_all() -> void:
	for keycode in held.keys():
		if bool(held[keycode]):
			var event := InputEventKey.new()
			event.physical_keycode = int(keycode)
			event.pressed = false
			event.echo = false
			Input.parse_input_event(event)
	held.clear()

func _physics_frames(count: int) -> void:
	for _frame in count:
		await physics_frame

func _process_frames(count: int) -> void:
	for _frame in count:
		await process_frame

func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := out_dir.path_join("%s.png" % shot_name)
	var error := root.get_texture().get_image().save_png(path)
	results.screenshots.append({"name": shot_name, "path": path, "error": error})
	print("saved ", path)

func _write_json(file_name: String, data: Dictionary) -> void:
	var file := FileAccess.open(out_dir.path_join(file_name), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))

func _vec(value: Vector2) -> Array:
	return [snappedf(value.x, 0.1), snappedf(value.y, 0.1)]

func _card_ids(cards: Array) -> Array[String]:
	var ids: Array[String] = []
	for card in cards:
		ids.append(str(card.id))
	return ids
