extends Node2D
## Match scene root: start screen, spawning, camera, input routing and wiring of
## the realm layout, world, match director, soul growth and HUD.
## Bots call get_ai_* / move_ai_through_portal / get_realm_state on their parent.

const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const REALM_LAYOUT_SCRIPT := preload("res://scripts/realms/RealmLayout.gd")
const REALM_WORLD_SCRIPT := preload("res://scripts/realms/RealmWorld.gd")
const REALM_HAZARDS_SCRIPT := preload("res://scripts/realms/RealmHazards.gd")
const MATCH_DIRECTOR_SCRIPT := preload("res://scripts/match/MatchDirector.gd")
const SOUL_GROWTH_SCRIPT := preload("res://scripts/match/SoulGrowth.gd")
const MATCH_HUD_SCRIPT := preload("res://scripts/ui/MatchHud.gd")
const REALM_MONSTER_SPAWNER_SCRIPT := preload("res://scripts/RealmMonsterSpawner.gd")
const CENTRAL_REALM_INDEX := REALM_LAYOUT_SCRIPT.CENTRAL_REALM_INDEX
const PORTAL_USE_ACTION := "use_portal"
const OFFSCREEN_AI_REALM_STEP_TIME := 0.25
const CAMERA_ZOOM := 0.85
const CAMERA_EDGE_PADDING := 80.0
const CHOOSE_ACTIONS: Array[String] = ["choose_1", "choose_2", "choose_3", "choose_4", "choose_5"]
const BODY_TYPES: Array[String] = ["male", "female"]

## The body P1 plays characters that come in two (Nova, Rio); V on the start screen.
## Static so it survives the scene reload of F2 and R.
static var human_body := "male"

## Every slot is a bot and the camera spectates (soak tests, attract mode). Skips the start screen.
@export var bots_only := false
## design D7: 8 = two per corner realm, 16 = two per outer realm.
@export var player_count := 8
## -1 picks a random seed; soak tests pass a fixed one.
@export var match_seed := -1
## Realm gimmicks (ice, eruptions, quakes). Off restores the plain M1 arenas.
@export var realm_hazards := true

var layout: REALM_LAYOUT_SCRIPT
var director: MATCH_DIRECTOR_SCRIPT
var soul_growth: SOUL_GROWTH_SCRIPT
var world: REALM_WORLD_SCRIPT
var hazards: REALM_HAZARDS_SCRIPT
var hud: MATCH_HUD_SCRIPT
var camera: Camera2D
var realm_monster_spawner: Node
var characters := CHARACTER_REGISTRY.get_characters()

var players: Array[Node] = []
var spectate_target: Node
var dummy: Node
var match_started := false
var match_over := false
var current_map_index := CENTRAL_REALM_INDEX
var spawn_points: Array[Vector2] = []
var active_portals: Array[Dictionary] = []
var offscreen_ai_realm_step_timer := 0.0
var shake_time := 0.0
var shake_strength := 0.0
var _shake_rng := RandomNumberGenerator.new()
## Bots' body types, separate from the global RNG so it does not shift seeded matches.
var _body_rng := RandomNumberGenerator.new()

func _ready() -> void:
	if match_seed < 0:
		randomize()
		match_seed = randi()
	seed(match_seed)
	_body_rng.seed = match_seed
	layout = REALM_LAYOUT_SCRIPT.new()
	_create_director()
	_create_soul_growth()
	_create_realm_monster_spawner()
	_create_camera()
	_create_hud()
	_create_world()
	_set_map(CENTRAL_REALM_INDEX)
	if bots_only:
		_start_match("")
	else:
		hud.show_start_screen(_get_character_list(), human_body)

func _create_director() -> void:
	director = MATCH_DIRECTOR_SCRIPT.new()
	director.name = "MatchDirector"
	add_child(director)
	director.setup(layout)
	director.realm_state_changed.connect(_on_realm_state_changed)
	director.announcement.connect(_show_message)
	director.combatant_relocated.connect(_on_combatant_relocated)
	director.match_finished.connect(_on_match_finished)

func _create_soul_growth() -> void:
	soul_growth = SOUL_GROWTH_SCRIPT.new()
	soul_growth.name = "SoulGrowth"
	soul_growth.match_seed = match_seed
	add_child(soul_growth)
	soul_growth.offer_closed.connect(_on_soul_offer_closed)

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
	camera.zoom = Vector2(CAMERA_ZOOM, CAMERA_ZOOM)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	add_child(camera)

func _create_hud() -> void:
	hud = MATCH_HUD_SCRIPT.new()
	add_child(hud)

func _create_world() -> void:
	world = REALM_WORLD_SCRIPT.new()
	world.name = "World"
	add_child(world)
	move_child(world, 0)
	world.build(layout, Callable(director, "get_state"), Callable(director, "is_warning"))
	hazards = REALM_HAZARDS_SCRIPT.new()
	hazards.name = "RealmHazards"
	hazards.z_index = 2
	world.add_child(hazards)
	hazards.setup(layout, Callable(director, "get_state"), match_seed)
	hazards.enabled = realm_hazards
	hazards.shake_requested.connect(_on_shake_requested)

func _on_shake_requested(realm_index: int, strength: float, duration: float) -> void:
	if realm_index == current_map_index:
		shake_strength = maxf(shake_strength if shake_time > 0.0 else 0.0, strength)
		shake_time = maxf(shake_time, duration)

func _get_character_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for character_id in CHARACTER_REGISTRY.get_character_ids():
		list.append(characters[character_id])
	return list

# --- Match flow ---

func _start_match(human_character_id: String) -> void:
	match_started = true
	hud.hide_overlay()
	hud.show_message(MATCH_HUD_SCRIPT.CONTROLS_HINT)
	realm_monster_spawner.sync_playable_realms(director.get_playable_indices())
	_spawn_players(human_character_id)
	_set_map(players[0].realm_index)

func _process(delta: float) -> void:
	# A restart frees this scene right away: stop before touching the viewport (CODEX-TESTER-01).
	if _handle_global_input() or not is_inside_tree():
		return
	if not match_started:
		return
	if not match_over:
		director.advance(delta)
		hazards.advance(delta)
		_apply_phase_rules()
		_update_offscreen_ai_realm_movement()
		_handle_portal_input()
		_handle_card_input()
		_handle_test_controls()
	_update_camera_follow()
	_update_hud()

func _apply_phase_rules() -> void:
	var ringout_damage: float = director.get_ringout_damage()
	var damage_scale: float = director.get_combat_damage_scale()
	var recovery_rate: float = director.get_recovery_rate()
	var aggression: float = director.get_bot_aggression()
	for combatant in players:
		if is_instance_valid(combatant):
			combatant.ringout_damage = ringout_damage
			combatant.incoming_damage_scale = damage_scale
			combatant.recovery_rate = recovery_rate
			combatant.ai_aggression = aggression
	var band: Vector2 = director.get_sudden_death_band()
	if director.phase == MATCH_DIRECTOR_SCRIPT.PHASE_SUDDEN_DEATH:
		world.set_hazard_band(CENTRAL_REALM_INDEX, band.x, band.y)

## Returns true when the scene is being reloaded and this frame must stop.
func _handle_global_input() -> bool:
	if Input.is_action_just_pressed("toggle_debug"):
		hud.toggle_debug()
	if not match_started:
		var ids := CHARACTER_REGISTRY.get_character_ids()
		for index in mini(CHOOSE_ACTIONS.size(), ids.size()):
			if Input.is_action_just_pressed(CHOOSE_ACTIONS[index]):
				_start_match(ids[index])
				return false
		if Input.is_action_just_pressed("toggle_body"):
			human_body = BODY_TYPES[(BODY_TYPES.find(human_body) + 1) % BODY_TYPES.size()]
			hud.show_start_screen(_get_character_list(), human_body)
		if Input.is_action_just_pressed("toggle_art"):
			ART_SETTINGS.toggle()
			get_tree().reload_current_scene()
			return true
		if Input.is_action_just_pressed("watch_bots"):
			bots_only = true
			_start_match("")
		return false
	if match_over and Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return true
	return false

func _on_match_finished(winner: Node, reason: String) -> void:
	match_over = true
	soul_growth.set_process(false)
	hud.hide_card_offer()
	_freeze_combat()
	if is_instance_valid(winner):
		spectate_target = winner
	hud.show_results(winner, reason, director.get_standings(), _get_human_player())

## The result screen is a snapshot: fighters, monsters, hitboxes and projectiles stop,
## and fighters are protected from attacks whose start-up timers were already running.
func _freeze_combat() -> void:
	for child in get_children():
		if child is CharacterBody2D or child is Area2D:
			child.process_mode = Node.PROCESS_MODE_DISABLED
	for player in players:
		if is_instance_valid(player):
			player.cancel_pending_actions()
			player.grant_protection(INF)
			player.modulate.a = 1.0

func get_winner() -> Node:
	return director.winner

func _on_realm_state_changed(_realm_index: int, _state: String) -> void:
	world.refresh_dynamic(Callable(director, "get_state"), Callable(director, "is_warning"))
	realm_monster_spawner.sync_playable_realms(director.get_playable_indices())
	active_portals = _get_portals_for_realm(current_map_index)
	hud.rebuild_minimap(layout, director, current_map_index)
	_sync_combatant_visibility()

func _on_combatant_relocated(combatant: Node, realm_index: int) -> void:
	if combatant == _get_human_player():
		_show_message("Caught in the collapse! Thrown into %s." % layout.get_realm(realm_index).name)

# --- Camera and realm view ---

func _set_map(index: int) -> void:
	current_map_index = clampi(index, 0, layout.realm_count() - 1)
	spawn_points = layout.get_spawn_points(current_map_index)
	camera.global_position = _get_camera_target()
	camera.reset_smoothing()
	active_portals = _get_portals_for_realm(current_map_index)
	hud.rebuild_minimap(layout, director, current_map_index)

func _update_camera_follow() -> void:
	var focus := _get_focus_player()
	if is_instance_valid(focus) and focus.realm_index != current_map_index and director.is_playable(focus.realm_index):
		_set_map(focus.realm_index)
	camera.global_position = _get_camera_target()
	if shake_time > 0.0:
		shake_time = maxf(shake_time - get_process_delta_time(), 0.0)
		camera.offset = Vector2(_shake_rng.randf_range(-1.0, 1.0), _shake_rng.randf_range(-1.0, 1.0)) * shake_strength
	else:
		camera.offset = Vector2.ZERO

## Follows the focus inside the realm; an axis smaller than the view stays centred.
func _get_camera_target() -> Vector2:
	if not is_inside_tree():
		return camera.global_position
	var bounds: Rect2 = layout.get_bounds(current_map_index).grow(CAMERA_EDGE_PADDING)
	var view := get_viewport().get_visible_rect().size / camera.zoom
	var focus := _get_focus_player()
	var point := bounds.get_center()
	if _is_in_view(focus):
		point = focus.global_position + Vector2(0, -60)
	var target := bounds.get_center()
	if view.x < bounds.size.x:
		target.x = clampf(point.x, bounds.position.x + view.x * 0.5, bounds.end.x - view.x * 0.5)
	if view.y < bounds.size.y:
		target.y = clampf(point.y, bounds.position.y + view.y * 0.5, bounds.end.y - view.y * 0.5)
	return target

## The human while they are in the fight, otherwise a living combatant to spectate.
func _get_focus_player() -> Node:
	var human := _get_human_player()
	if _is_alive(human):
		return human
	if not _is_alive(spectate_target) and not match_over:
		spectate_target = null
		var alive: Array[Node] = director.get_alive_combatants()
		if not alive.is_empty():
			spectate_target = alive[0]
	return spectate_target

func _is_alive(combatant: Node) -> bool:
	return is_instance_valid(combatant) and not combatant.is_defeated

func _is_in_view(combatant: Node) -> bool:
	return _is_alive(combatant) and combatant.realm_index == current_map_index

# --- Combatants ---

## Two fighters per realm: corner realms for up to 8, all outer realms beyond (D7).
## Realm slot k seats characters k and k+1 of the roster (rotated so P1 keeps their
## pick), so every opening pair is a different match-up and no pair is a mirror.
func _spawn_players(human_character_id: String) -> void:
	var ids := CHARACTER_REGISTRY.get_character_ids()
	var start_realms: Array[int] = layout.get_corner_indices()
	if player_count > start_realms.size() * 2:
		start_realms.append_array(layout.get_edge_indices())
	start_realms.shuffle()
	var used_points: Dictionary = {}
	var first_id := maxi(ids.find(human_character_id), 0)
	for i in player_count:
		var slot := (i / 2) % start_realms.size()
		var seat := i % 2
		var realm_index := start_realms[slot]
		var character_id: String = ids[(first_id + slot + seat) % ids.size()]
		var human := i == 0 and not bots_only
		_add_player(character_id, human, _take_spawn_point(realm_index, used_points), realm_index, _pick_body(character_id, human))
	_sync_combatant_visibility()

func _take_spawn_point(realm_index: int, used_points: Dictionary) -> Vector2:
	var points := layout.get_spawn_points(realm_index).duplicate()
	points.shuffle()
	var taken: Array = used_points.get(realm_index, [])
	for point in points:
		var far_enough := true
		for other in taken:
			if point.distance_to(other) < 320.0:
				far_enough = false
				break
		if far_enough:
			taken.append(point)
			used_points[realm_index] = taken
			return point
	return points[0]

## P1 keeps the start-screen choice when the character has it; bots roll (seeded).
func _pick_body(character_id: String, human: bool) -> String:
	var bodies := CHARACTER_REGISTRY.get_bodies(character_id)
	if human and bodies.has(human_body):
		return human_body
	return bodies[_body_rng.randi_range(0, bodies.size() - 1)]

func _add_player(character_id: String, human: bool, position: Vector2, realm_index: int, body_type := "") -> Node:
	var player := PLAYER_FACTORY.create(character_id, body_type)
	add_child(player)
	player.global_position = position
	player.setup(characters[character_id], players.size() + 1, human)
	layout.assign_combatant(player, realm_index)
	player.respawned.connect(_on_combatant_respawned)
	player.defeated.connect(_on_player_defeated)
	director.register_combatant(player)
	hazards.register_combatant(player)
	soul_growth.register_player(player)
	players.append(player)
	return player

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

func _count_alive_by_realm() -> Dictionary:
	var counts: Dictionary = {}
	for combatant in director.get_alive_combatants():
		counts[combatant.realm_index] = int(counts.get(combatant.realm_index, 0)) + 1
	return counts

# --- Soul cards ---

func _handle_card_input() -> void:
	var human := _get_human_player()
	if not _is_alive(human):
		return
	for index in 3:
		if Input.is_action_just_pressed(CHOOSE_ACTIONS[index]):
			soul_growth.choose(human, index)

func _on_soul_offer_closed(player: Node, card: Dictionary, auto_picked: bool) -> void:
	if player == _get_human_player():
		hud.hide_card_offer()
		_show_message("Soul card: %s%s." % [card.title, " (auto-picked)" if auto_picked else ""])

# --- Portals ---

func _get_portals_for_realm(realm_index: int) -> Array[Dictionary]:
	return layout.get_portals(realm_index, Callable(director, "get_state"))

func _handle_portal_input() -> void:
	if not Input.is_action_just_pressed(PORTAL_USE_ACTION):
		return
	var human := _get_human_player()
	if not _is_alive(human) or not human.is_on_floor():
		return
	for portal in _get_portals_for_realm(human.realm_index):
		var rect: Rect2 = portal.rect
		if rect.has_point(human.global_position):
			_move_through_portal(human, portal)
			_set_map(portal.destination)
			_show_message("%s entered %s." % [human.display_name, layout.get_realm(portal.destination).name])
			return

func _move_through_portal(combatant: Node, portal: Dictionary) -> void:
	var destination: int = portal.destination
	layout.assign_combatant(combatant, destination)
	combatant.reset_for_map(portal.entry_position, layout.get_spawn_points(destination))
	_sync_combatant_visibility()

func get_ai_navigation_points_for_realm(realm_index: int) -> Array[Vector2]:
	return layout.get_navigation_points(realm_index)

func get_ai_portals_for_realm(realm_index: int) -> Array:
	if realm_index < 0 or realm_index >= layout.realm_count():
		return []
	return _get_portals_for_realm(realm_index)

func move_ai_through_portal(ai_player: Node, portal: Dictionary) -> void:
	if not _is_alive(ai_player) or not director.is_playable(portal.destination):
		return
	_move_through_portal(ai_player, portal)

func get_ai_hazard(realm_index: int) -> Dictionary:
	return hazards.get_threat(realm_index) if is_instance_valid(hazards) else {}

func get_realm_state(realm_index: int) -> String:
	return director.get_state(realm_index)

## Bots outside the camera's realm also decide whether to hop realms, every 0.25 s.
func _update_offscreen_ai_realm_movement() -> void:
	offscreen_ai_realm_step_timer = maxf(offscreen_ai_realm_step_timer - get_process_delta_time(), 0.0)
	if offscreen_ai_realm_step_timer > 0.0:
		return
	offscreen_ai_realm_step_timer = OFFSCREEN_AI_REALM_STEP_TIME
	var combatants := _get_all_combatants()
	for combatant in combatants:
		if not _can_update_offscreen_ai(combatant):
			continue
		var portals := _get_portals_for_realm(combatant.realm_index)
		var ai_controller = combatant.get("ai_controller")
		# The step interval, not the frame delta: the AI's think timers count real seconds.
		var portal: Dictionary = ai_controller.update_offscreen_realm(combatant, OFFSCREEN_AI_REALM_STEP_TIME, combatants, portals, director.get_state(combatant.realm_index), Callable(director, "get_state"), Callable(layout, "grid_distance"))
		if not portal.is_empty():
			_move_through_portal(combatant, portal)

func _can_update_offscreen_ai(combatant: Node) -> bool:
	if not _is_alive(combatant) or combatant.is_human or combatant.is_dummy:
		return false
	if combatant.realm_index == current_map_index:
		return false
	return director.is_playable(combatant.realm_index) and combatant.get("ai_controller") != null

# --- HUD, debug and practice ---

func _update_hud() -> void:
	hud.set_clock(director.get_phase_name(), director.match_elapsed, director.get_next_event_label(), director.get_next_event_in())
	hud.set_status(director.get_alive_combatants().size(), players.size(), _get_focus_player())
	hud.update_minimap_labels(director, _count_alive_by_realm())
	var seconds_left: int = director.get_warning_seconds_left()
	for display in world.countdown_displays:
		var label: Label = display.label
		if is_instance_valid(label):
			label.text = "%ds" % seconds_left
	var realm: Dictionary = layout.get_realm(current_map_index)
	var hazard_text: String = hazards.get_hazard_text(current_map_index) if hazards.enabled else ""
	hud.set_realm_title("%s  -  %s%s" % [realm.name, realm.subtitle, "   |   " + hazard_text if hazard_text != "" else ""], realm.accent)
	hud.set_warning_banner(seconds_left if director.is_warning(current_map_index) and not match_over else -1, hazards.get_warning_text(current_map_index) if not match_over else "")
	var human := _get_human_player()
	var offer: Dictionary = soul_growth.get_offer(human) if is_instance_valid(human) else {}
	if not offer.is_empty() and not match_over:
		hud.show_card_offer(offer.cards, offer.time_left)
	if hud.debug_label.visible:
		_update_debug_text()

func _update_debug_text() -> void:
	var lines: Array[String] = [
		"seed %d  t=%.1f  phase %s" % [match_seed, director.match_elapsed, director.phase],
		"view: %s  monsters here: %d" % [layout.get_realm(current_map_index).name, realm_monster_spawner.get_monster_count(current_map_index)],
		""
	]
	for p in players:
		var status := "OUT" if p.is_defeated else "R%d" % (p.realm_index + 1)
		lines.append("%-6s %-4s HP %3.0f/%3.0f  S%2d  KO%d  ult %2.0f  %s" % [p.display_name, status, p.hp, p.max_hp, p.souls, p.score, p.ultimate_cooldown_timer, ",".join(p.upgrades)])
	hud.set_debug_text("\n".join(lines))

func _handle_test_controls() -> void:
	if Input.is_action_just_pressed("toggle_dummy"):
		_toggle_dummy()

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
	layout.assign_combatant(dummy, current_map_index)
	dummy.respawned.connect(_on_combatant_respawned)
	_sync_combatant_visibility()
	_show_message("Training dummy spawned. Press H again to remove it.")

func _show_message(text: String) -> void:
	hud.show_message(text)

func _on_player_defeated(player: Node, attacker: Node) -> void:
	var cause := "the realm"
	if is_instance_valid(attacker):
		cause = attacker.display_name
	_show_message("%s was eliminated by %s. %d left." % [player.display_name, cause, director.get_alive_combatants().size()])

func _on_combatant_respawned(_combatant: Node) -> void:
	_sync_combatant_visibility()
