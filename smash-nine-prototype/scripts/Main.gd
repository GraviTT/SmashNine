extends Node2D
## Match scene root: spawns combatants, follows the human player's realm with the
## camera and wires the realm layout, world, match director and HUD together.
## Bots call get_ai_* / move_ai_through_portal / _get_realm_state on their parent.

const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const REALM_LAYOUT_SCRIPT := preload("res://scripts/realms/RealmLayout.gd")
const REALM_WORLD_SCRIPT := preload("res://scripts/realms/RealmWorld.gd")
const MATCH_DIRECTOR_SCRIPT := preload("res://scripts/match/MatchDirector.gd")
const MATCH_HUD_SCRIPT := preload("res://scripts/ui/MatchHud.gd")
const REALM_MONSTER_SPAWNER_SCRIPT := preload("res://scripts/RealmMonsterSpawner.gd")
const CENTRAL_REALM_INDEX := REALM_LAYOUT_SCRIPT.CENTRAL_REALM_INDEX
const VIEWPORT_CENTER := REALM_LAYOUT_SCRIPT.VIEWPORT_CENTER
const REALM_SIZE := REALM_LAYOUT_SCRIPT.REALM_SIZE
const PORTAL_USE_ACTION := "use_portal"
const OFFSCREEN_AI_REALM_STEP_TIME := 0.25
const MAX_TEST_PLAYERS := 4

var layout: REALM_LAYOUT_SCRIPT
var director: MATCH_DIRECTOR_SCRIPT
var world: REALM_WORLD_SCRIPT
var hud: MATCH_HUD_SCRIPT
var camera: Camera2D
var realm_monster_spawner: Node
var characters := CHARACTER_REGISTRY.get_characters()

## When true every slot is a bot and the camera spectates (soak tests, attract mode).
@export var bots_only := false

var players: Array[Node] = []
var spectate_target: Node
var selected_character := "frey"
var target_player_count := 4
var dummy: Node
var current_map_index := 0
var spawn_points: Array[Vector2] = []
var active_portals: Array[Dictionary] = []
var offscreen_ai_realm_step_timer := 0.0

func _ready() -> void:
	randomize()
	layout = REALM_LAYOUT_SCRIPT.new()
	_create_director()
	_create_realm_monster_spawner()
	_create_camera()
	_create_hud()
	_create_world()
	_set_map(0, false)
	_spawn_players()

func _create_director() -> void:
	director = MATCH_DIRECTOR_SCRIPT.new()
	director.name = "MatchDirector"
	add_child(director)
	var names: Array[String] = []
	for i in layout.realm_count():
		names.append(str(layout.get_realm(i).name))
	director.setup(names, CENTRAL_REALM_INDEX)
	director.realm_state_changed.connect(_on_realm_state_changed)
	director.announcement.connect(_show_message)

func _create_realm_monster_spawner() -> void:
	realm_monster_spawner = Node.new()
	realm_monster_spawner.name = "RealmMonsterSpawner"
	realm_monster_spawner.set_script(REALM_MONSTER_SPAWNER_SCRIPT)
	add_child(realm_monster_spawner)
	realm_monster_spawner.configure(Callable(layout, "get_spawn_points"), Callable(director, "get_playable_indices"))

func _create_camera() -> void:
	camera = Camera2D.new()
	camera.name = "RealmCamera"
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_smoothed = true
	add_child(camera)

func _create_hud() -> void:
	hud = MATCH_HUD_SCRIPT.new()
	add_child(hud)

func _create_world() -> void:
	world = REALM_WORLD_SCRIPT.new()
	world.name = "World"
	add_child(world)
	move_child(world, 0)
	world.build(layout, Callable(director, "get_state"), director.warning_realm_index)
	realm_monster_spawner.sync_playable_realms(director.get_playable_indices())

func _process(delta: float) -> void:
	director.advance(delta)
	_update_ringout_pressure()
	_update_offscreen_ai_realm_movement(delta)
	_handle_character_switch()
	_handle_test_controls()
	_handle_portal_input()
	_update_camera_follow()
	_update_collapse_countdown_displays()
	_update_debug_ui()

func _on_realm_state_changed(realm_index: int, state: String) -> void:
	if state == MATCH_DIRECTOR_SCRIPT.STATE_COLLAPSED:
		var respawn_realm: int = director.find_safe_realm()
		_eliminate_combatants_in_collapsed_realm(realm_index, respawn_realm)
		if current_map_index == realm_index:
			_set_map(respawn_realm, false)
	world.refresh_dynamic(Callable(director, "get_state"), director.warning_realm_index)
	realm_monster_spawner.sync_playable_realms(director.get_playable_indices())
	active_portals = _get_portals_for_realm(current_map_index)
	hud.rebuild_minimap(layout, director, current_map_index)
	_sync_combatant_visibility()

func _eliminate_combatants_in_collapsed_realm(collapsed_index: int, respawn_realm: int) -> void:
	for combatant in _get_all_combatants():
		if not is_instance_valid(combatant) or combatant.realm_index != collapsed_index:
			continue
		_assign_realm(combatant, respawn_realm)
		combatant.eliminate_by_realm_collapse()

func _update_ringout_pressure() -> void:
	var pressure: float = director.get_ringout_pressure()
	for combatant in _get_all_combatants():
		if is_instance_valid(combatant):
			combatant.set_match_pressure(pressure)

# --- Camera and realm view ---

func _update_camera_for_current_realm() -> void:
	var origin: Vector2 = layout.get_origin(current_map_index)
	camera.limit_left = int(origin.x)
	camera.limit_top = int(origin.y)
	camera.limit_right = int(origin.x + REALM_SIZE.x)
	camera.limit_bottom = int(origin.y + REALM_SIZE.y)
	var camera_position := origin + VIEWPORT_CENTER
	var focus := _get_focus_player()
	if _is_in_view(focus):
		camera_position = _clamp_to_realm_view(focus.global_position, origin)
	camera.global_position = camera_position
	camera.reset_smoothing()
	active_portals = _get_portals_for_realm(current_map_index)
	hud.rebuild_minimap(layout, director, current_map_index)

func _update_camera_follow() -> void:
	var focus := _get_focus_player()
	if not is_instance_valid(focus):
		return
	if focus.realm_index != current_map_index and director.is_playable(focus.realm_index):
		_set_map(focus.realm_index, false)
	if _is_in_view(focus):
		camera.global_position = _clamp_to_realm_view(focus.global_position, layout.get_origin(current_map_index))

## The human while they are in the fight, otherwise a living combatant to spectate.
func _get_focus_player() -> Node:
	var human := _get_human_player()
	if is_instance_valid(human) and not human.is_defeated:
		return human
	if not _is_alive(spectate_target):
		spectate_target = null
		for player in players:
			if _is_alive(player):
				spectate_target = player
				break
	return spectate_target

func _is_alive(combatant: Node) -> bool:
	return is_instance_valid(combatant) and not combatant.is_defeated

func _is_in_view(combatant: Node) -> bool:
	return _is_alive(combatant) and combatant.realm_index == current_map_index

func _clamp_to_realm_view(point: Vector2, origin: Vector2) -> Vector2:
	var minimum := origin + VIEWPORT_CENTER
	var maximum := origin + REALM_SIZE - VIEWPORT_CENTER
	return Vector2(clampf(point.x, minimum.x, maximum.x), clampf(point.y, minimum.y, maximum.y))

func _set_map(index: int, show_message := true) -> void:
	if not director.is_playable(index):
		index = director.find_safe_realm()
	current_map_index = clampi(index, 0, layout.realm_count() - 1)
	spawn_points = layout.get_spawn_points(current_map_index)
	_update_camera_for_current_realm()
	if show_message:
		_show_message("Realm view changed to %s." % layout.get_realm(current_map_index).name)
	_sync_combatant_visibility()

func _update_collapse_countdown_displays() -> void:
	var seconds_left: int = director.get_warning_seconds_left()
	for display in world.countdown_displays:
		var label: Label = display.label
		if not is_instance_valid(label):
			continue
		if display.kind == "background":
			label.text = "COLLAPSE WARNING\n%d" % seconds_left
		else:
			label.text = "%ds" % seconds_left
	hud.update_minimap_labels(director)

# --- Combatants ---

func _spawn_players() -> void:
	var ids := CHARACTER_REGISTRY.get_character_ids()
	var starting_realms: Array[int] = director.get_playable_indices()
	starting_realms.erase(CENTRAL_REALM_INDEX)
	starting_realms.shuffle()
	for i in target_player_count:
		var realm_index := current_map_index if i == 0 else starting_realms[i % starting_realms.size()]
		_add_player(ids[i % ids.size()], i == 0 and not bots_only, layout.pick_spawn(realm_index), realm_index)
	_sync_combatant_visibility()

func _add_player(character_id: String, human: bool, position: Vector2, realm_index: int) -> Node:
	var player := PLAYER_FACTORY.create(character_id)
	add_child(player)
	player.global_position = position
	player.setup(characters[character_id], players.size() + 1, human)
	_assign_realm(player, realm_index)
	_connect_player_signals(player)
	players.append(player)
	return player

func _assign_realm(combatant: Node, realm_index: int) -> void:
	combatant.set_realm(realm_index, layout.get_spawn_points(realm_index), layout.get_origin(realm_index), layout.get_ringout_y(realm_index))

func _connect_player_signals(player: Node) -> void:
	player.defeated.connect(_on_player_defeated)
	player.respawned.connect(_on_combatant_respawned)
	player.leveled_up.connect(_on_player_leveled_up)

func _get_human_player() -> Node:
	if players.is_empty():
		return null
	var human: Node = players[0]
	if is_instance_valid(human) and human.is_human:
		return human
	return null

func _get_all_combatants() -> Array[Node]:
	var combatants: Array[Node] = []
	for player in players:
		combatants.append(player)
	if is_instance_valid(dummy):
		combatants.append(dummy)
	return combatants

func _sync_combatant_visibility() -> void:
	for combatant in _get_all_combatants():
		if is_instance_valid(combatant):
			combatant.set_realm_active(director.is_playable(combatant.realm_index))

func _get_combatant_count_in_realm(realm_index: int) -> int:
	var count := 0
	for combatant in _get_all_combatants():
		if is_instance_valid(combatant) and combatant.realm_index == realm_index:
			count += 1
	return count

# --- Portals ---

func _get_portals_for_realm(realm_index: int) -> Array[Dictionary]:
	return layout.get_portals(realm_index, Callable(director, "get_state"))

func _handle_portal_input() -> void:
	if not Input.is_action_just_pressed(PORTAL_USE_ACTION):
		return
	var human := _get_human_player()
	if not is_instance_valid(human) or human.is_defeated or not human.is_on_floor():
		return
	for portal in active_portals:
		var rect: Rect2 = portal.rect
		if rect.has_point(human.global_position):
			_move_through_portal(human, portal)
			_set_map(portal.destination, false)
			_show_message("%s entered %s through a portal." % [human.display_name, layout.get_realm(portal.destination).name])
			return

func _move_through_portal(combatant: Node, portal: Dictionary) -> void:
	var destination: int = portal.destination
	_assign_realm(combatant, destination)
	combatant.reset_for_map(portal.entry_position, layout.get_spawn_points(destination))
	_sync_combatant_visibility()

func get_ai_navigation_points_for_realm(realm_index: int) -> Array[Vector2]:
	return layout.get_navigation_points(realm_index)

func get_ai_portals_for_realm(realm_index: int) -> Array:
	if realm_index < 0 or realm_index >= layout.realm_count():
		return []
	return _get_portals_for_realm(realm_index)

func move_ai_through_portal(ai_player: Node, portal: Dictionary) -> void:
	if not is_instance_valid(ai_player) or ai_player.is_defeated or not director.is_playable(portal.destination):
		return
	_move_through_portal(ai_player, portal)
	_show_message("%s wandered into %s through a portal." % [ai_player.display_name, layout.get_realm(portal.destination).name])

func _get_realm_state(realm_index: int) -> String:
	return director.get_state(realm_index)

func _update_offscreen_ai_realm_movement(delta: float) -> void:
	offscreen_ai_realm_step_timer = maxf(offscreen_ai_realm_step_timer - delta, 0.0)
	if offscreen_ai_realm_step_timer > 0.0:
		return
	offscreen_ai_realm_step_timer = OFFSCREEN_AI_REALM_STEP_TIME
	var combatants := _get_all_combatants()
	for combatant in combatants:
		if not _can_update_offscreen_ai(combatant):
			continue
		var portals := _get_portals_for_realm(combatant.realm_index)
		var ai_controller = combatant.get("ai_controller")
		var portal: Dictionary = ai_controller.update_offscreen_realm(combatant, delta, combatants, portals, director.get_state(combatant.realm_index), Callable(director, "get_state"), Callable(layout, "grid_distance"))
		if not portal.is_empty():
			_move_through_portal(combatant, portal)

func _can_update_offscreen_ai(combatant: Node) -> bool:
	if not is_instance_valid(combatant) or combatant.is_human or combatant.is_dummy:
		return false
	if combatant.is_defeated or combatant.realm_index == current_map_index:
		return false
	return director.is_playable(combatant.realm_index) and combatant.get("ai_controller") != null

# --- Debug / test controls ---

func _handle_character_switch() -> void:
	if bots_only:
		return
	var mapping := {
		"select_frey": "frey",
		"select_yuki": "yuki",
		"select_luna": "luna",
		"select_nova": "nova"
	}
	for action in mapping:
		if Input.is_action_just_pressed(action):
			selected_character = mapping[action]
			_replace_human_character(selected_character)

func _replace_human_character(character_id: String) -> void:
	if players.is_empty() or not characters.has(character_id):
		return
	var previous: Node = players[0]
	if previous.character_id == character_id:
		return
	var replacement := PLAYER_FACTORY.create(character_id)
	add_child(replacement)
	replacement.global_position = previous.global_position
	replacement.setup(characters[character_id], previous.player_id, true)
	replacement.inherit_match_state(previous)
	replacement.set_realm(previous.realm_index, previous.spawn_points, previous.realm_origin, previous.ringout_y)
	replacement.set_realm_active(previous.is_realm_active)
	_connect_player_signals(replacement)
	players[0] = replacement
	previous.queue_free()

func _handle_test_controls() -> void:
	if Input.is_action_just_pressed("decrease_players"):
		_set_player_count(maxi(1, target_player_count - 1))
	if Input.is_action_just_pressed("increase_players"):
		_set_player_count(mini(MAX_TEST_PLAYERS, target_player_count + 1))
	if Input.is_action_just_pressed("toggle_dummy"):
		_toggle_dummy()

func _set_player_count(count: int) -> void:
	if count == target_player_count:
		return
	target_player_count = count
	while players.size() > target_player_count:
		var player: Node = players.pop_back()
		player.queue_free()
	var ids := CHARACTER_REGISTRY.get_character_ids()
	while players.size() < target_player_count:
		var realm_index: int = director.get_playable_indices().pick_random()
		_add_player(ids[players.size() % ids.size()], false, layout.pick_spawn(realm_index), realm_index)
	_sync_combatant_visibility()
	_show_message("Player count set to %d. 5/6 changes players, H toggles dummy." % target_player_count)

func _toggle_dummy() -> void:
	if is_instance_valid(dummy):
		dummy.queue_free()
		dummy = null
		_show_message("Training dummy removed.")
		return
	dummy = PLAYER_FACTORY.create()
	add_child(dummy)
	dummy.global_position = spawn_points.pick_random()
	dummy.setup_dummy(99)
	_assign_realm(dummy, current_map_index)
	dummy.defeated.connect(_on_player_defeated)
	dummy.respawned.connect(_on_combatant_respawned)
	_sync_combatant_visibility()
	_show_message("Training dummy spawned. Press H again to remove it.")

func _update_debug_ui() -> void:
	var map: Dictionary = layout.get_realm(current_map_index)
	var warning_text := "none"
	if director.warning_realm_index >= 0:
		warning_text = "%s %.0fs" % [layout.get_realm(director.warning_realm_index).name, director.warning_timer]
	var local_monsters: int = realm_monster_spawner.get_monster_count(current_map_index)
	var lines := [
		"Realm System",
		"Phase: %s  Time: %.0fs" % [director.get_phase_name(), director.match_elapsed],
		"Realm: %s  State: %s" % [map.name, director.get_state(current_map_index)],
		"Warning: %s" % warning_text,
		"Total combatants: %d   In realm: %d" % [_get_all_combatants().size(), _get_combatant_count_in_realm(current_map_index)],
		"Monsters in realm: %d (neutral until hit)" % local_monsters,
		"Stand on portal + Q: move to adjacent realm",
		""
	]
	for p in players:
		var exp_text := "MAX" if p.experience_to_next_level <= 0 else "%d/%d" % [p.experience, p.experience_to_next_level]
		lines.append("%s L%d X:%s R:%d H:%.0f A:%.0f D:%.0f S:%.0f" % [p.display_name, p.level, exp_text, p.realm_index + 1, p.hp, p.attack_power, p.defense, p.speed])
	if is_instance_valid(dummy):
		lines.append("%s  R:%d  HP:%3.0f" % [dummy.display_name, dummy.realm_index + 1, dummy.hp])
	hud.set_debug_text("\n".join(lines))

func _show_message(text: String) -> void:
	hud.show_message(text)

# --- Signal handlers ---

func _on_player_defeated(player: Node, attacker: Node) -> void:
	var attacker_name := "environment"
	if is_instance_valid(attacker):
		attacker_name = attacker.display_name
	_show_message("%s was defeated by %s. Respawning in 3 seconds." % [player.display_name, attacker_name])

func _on_player_leveled_up(player: Node, new_level: int) -> void:
	_show_message("%s reached Lv.%d. HP %.0f / ATK %.0f / DEF %.0f / SPD %.0f" % [player.display_name, new_level, player.max_hp, player.attack_power, player.defense, player.speed])

func _on_combatant_respawned(_combatant: Node) -> void:
	_sync_combatant_visibility()
