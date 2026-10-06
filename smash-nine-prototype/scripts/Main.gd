extends Node2D

const PLAYER_BASE_SCRIPT := preload("res://characters/common/PlayerBase.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const REALM_MONSTER_SPAWNER_SCRIPT := preload("res://scripts/RealmMonsterSpawner.gd")
const REALM_BACKDROP_SCRIPT := preload("res://scripts/RealmBackdrop.gd")
const WORLD_LAYER := 1
const PLAYER_LAYER := 2
const PLATFORM_MAIN := "main"
const PLATFORM_SUB := "sub"
const CENTRAL_REALM_INDEX := 8
const CENTRAL_OPEN_TIME := 210.0
const FIRST_COLLAPSE_WARNING_TIME := 35.0
const COLLAPSE_WARNING_DURATION := 18.0
const COLLAPSE_INTERVAL := 42.0
const MATCH_TARGET_TIME := 360.0
const PORTAL_SIZE := Vector2(92, 92)
const PORTAL_SUPPORT_SIZE := Vector2(170, 26)
const PORTAL_USE_ACTION := "use_portal"
const OFFSCREEN_AI_REALM_STEP_TIME := 0.25
const VIEWPORT_CENTER := Vector2(640, 360)
const BASE_REALM_SIZE := Vector2(1280, 720)
const REALM_TILE_COUNT := Vector2i(3, 3)
const REALM_SIZE := Vector2(3840, 2160)
const REALM_WORLD_SPACING := Vector2(4600, 2800)
const REALM_RINGOUT_MARGIN := 220.0

var world_root: Node2D
var camera: Camera2D
var ui_layer: CanvasLayer
var minimap_root: Control
var characters := CHARACTER_REGISTRY.get_characters()

var players: Array[Node] = []
var selected_character := "frey"
var info_label: Label
var debug_label: Label
var target_player_count := 4
var dummy: Node
var current_map_index := 0
var spawn_points: Array[Vector2] = []
var maps: Array = []
var realm_states: Array[String] = []
var collapse_order: Array[int] = []
var match_elapsed := 0.0
var next_warning_time := FIRST_COLLAPSE_WARNING_TIME
var warning_realm_index := -1
var warning_timer := 0.0
var active_portals: Array[Dictionary] = []
var offscreen_ai_realm_step_timer := 0.0
var collapse_countdown_displays: Array[Dictionary] = []
var minimap_labels: Dictionary = {}
var realm_monster_spawner: Node

func _build_maps() -> Array:
	return [
	{
		"name": "1. Valkyrie Gate",
		"subtitle": "Balanced starter arena",
		"grid": Vector2i(0, 0),
		"gimmick": "Clean neutral ground",
		"hazard": "Low edge pressure",
		"identity": "Baseline combat feel",
		"background": Color(0.02, 0.04, 0.08),
		"accent": Color(1.0, 0.72, 0.34),
		"platforms": [
			_main_platform(Vector2(640, 620), Vector2(1060, 52), Color(0.18, 0.21, 0.25)),
			_sub_platform(Vector2(230, 475), Vector2(270, 34), Color(0.22, 0.25, 0.3)),
			_sub_platform(Vector2(1050, 475), Vector2(270, 34), Color(0.22, 0.25, 0.3)),
			_sub_platform(Vector2(640, 345), Vector2(370, 34), Color(0.24, 0.27, 0.33)),
			_sub_platform(Vector2(420, 240), Vector2(210, 30), Color(0.2, 0.23, 0.29)),
			_sub_platform(Vector2(860, 240), Vector2(210, 30), Color(0.2, 0.23, 0.29))
		],
		"spawns": [Vector2(250, 540), Vector2(480, 540), Vector2(800, 540), Vector2(1030, 540), Vector2(230, 400), Vector2(520, 270), Vector2(760, 270), Vector2(1050, 400)]
	},
	{
		"name": "2. Moon Bridge",
		"subtitle": "Long bridge with high side shelves",
		"grid": Vector2i(1, 0),
		"gimmick": "Long sightline",
		"hazard": "Side ledge traps",
		"identity": "Horizontal control",
		"background": Color(0.035, 0.035, 0.09),
		"accent": Color(0.7, 0.82, 1.0),
		"platforms": [
			_main_platform(Vector2(640, 600), Vector2(900, 46), Color(0.18, 0.2, 0.32)),
			_sub_platform(Vector2(210, 420), Vector2(240, 32), Color(0.22, 0.24, 0.38)),
			_sub_platform(Vector2(1070, 420), Vector2(240, 32), Color(0.22, 0.24, 0.38)),
			_sub_platform(Vector2(640, 315), Vector2(310, 30), Color(0.24, 0.27, 0.42)),
			_sub_platform(Vector2(410, 215), Vector2(170, 28), Color(0.2, 0.22, 0.36)),
			_sub_platform(Vector2(870, 215), Vector2(170, 28), Color(0.2, 0.22, 0.36))
		],
		"spawns": [Vector2(270, 520), Vector2(500, 520), Vector2(780, 520), Vector2(1010, 520), Vector2(210, 350), Vector2(640, 245), Vector2(1070, 350), Vector2(870, 155)]
	},
	{
		"name": "3. Sunken Temple",
		"subtitle": "Low center with safer high corners",
		"grid": Vector2i(2, 0),
		"gimmick": "Low center basin",
		"hazard": "Center comeback tax",
		"identity": "High-ground decisions",
		"background": Color(0.0, 0.055, 0.065),
		"accent": Color(0.22, 0.95, 0.9),
		"platforms": [
			_main_platform(Vector2(640, 650), Vector2(520, 46), Color(0.13, 0.26, 0.27)),
			_main_platform(Vector2(250, 555), Vector2(350, 40), Color(0.12, 0.23, 0.25)),
			_main_platform(Vector2(1030, 555), Vector2(350, 40), Color(0.12, 0.23, 0.25)),
			_sub_platform(Vector2(640, 425), Vector2(280, 32), Color(0.15, 0.3, 0.3)),
			_sub_platform(Vector2(315, 300), Vector2(230, 30), Color(0.12, 0.24, 0.27)),
			_sub_platform(Vector2(965, 300), Vector2(230, 30), Color(0.12, 0.24, 0.27))
		],
		"spawns": [Vector2(280, 485), Vector2(500, 585), Vector2(780, 585), Vector2(1000, 485), Vector2(315, 230), Vector2(640, 355), Vector2(965, 230), Vector2(640, 570)]
	},
	{
		"name": "4. Skyline Spires",
		"subtitle": "Tall vertical routes and risky gaps",
		"grid": Vector2i(0, 1),
		"gimmick": "Vertical climbs",
		"hazard": "Open fall lanes",
		"identity": "Aerial chase and recovery",
		"background": Color(0.025, 0.055, 0.105),
		"accent": Color(0.38, 0.85, 1.0),
		"platforms": [
			_main_platform(Vector2(640, 640), Vector2(360, 44), Color(0.16, 0.21, 0.31)),
			_sub_platform(Vector2(260, 540), Vector2(250, 34), Color(0.18, 0.24, 0.34)),
			_sub_platform(Vector2(1020, 540), Vector2(250, 34), Color(0.18, 0.24, 0.34)),
			_sub_platform(Vector2(430, 405), Vector2(230, 30), Color(0.2, 0.27, 0.38)),
			_sub_platform(Vector2(850, 405), Vector2(230, 30), Color(0.2, 0.27, 0.38)),
			_sub_platform(Vector2(640, 270), Vector2(240, 30), Color(0.22, 0.29, 0.42)),
			_sub_platform(Vector2(640, 150), Vector2(160, 26), Color(0.18, 0.23, 0.36))
		],
		"spawns": [Vector2(260, 470), Vector2(430, 335), Vector2(640, 570), Vector2(850, 335), Vector2(1020, 470), Vector2(640, 200), Vector2(560, 570), Vector2(720, 570)]
	},
	{
		"name": "5. Ember Ring",
		"subtitle": "Compact brawl pit",
		"grid": Vector2i(2, 1),
		"gimmick": "Close-range pressure",
		"hazard": "Short escape routes",
		"identity": "Forced brawls",
		"background": Color(0.075, 0.025, 0.015),
		"accent": Color(1.0, 0.36, 0.16),
		"platforms": [
			_main_platform(Vector2(640, 610), Vector2(760, 52), Color(0.28, 0.15, 0.12)),
			_sub_platform(Vector2(370, 455), Vector2(220, 32), Color(0.34, 0.18, 0.13)),
			_sub_platform(Vector2(910, 455), Vector2(220, 32), Color(0.34, 0.18, 0.13)),
			_sub_platform(Vector2(640, 325), Vector2(280, 32), Color(0.38, 0.2, 0.14)),
			_sub_platform(Vector2(190, 315), Vector2(170, 28), Color(0.28, 0.14, 0.12)),
			_sub_platform(Vector2(1090, 315), Vector2(170, 28), Color(0.28, 0.14, 0.12))
		],
		"spawns": [Vector2(380, 540), Vector2(560, 540), Vector2(720, 540), Vector2(900, 540), Vector2(370, 385), Vector2(640, 255), Vector2(910, 385), Vector2(640, 540)]
	},
	{
		"name": "6. Frost Steps",
		"subtitle": "Staggered platforms for chase fights",
		"grid": Vector2i(0, 2),
		"gimmick": "Stair-step routes",
		"hazard": "Split recovery paths",
		"identity": "Pursuit and disengage",
		"background": Color(0.02, 0.065, 0.085),
		"accent": Color(0.66, 0.95, 1.0),
		"platforms": [
			_main_platform(Vector2(280, 620), Vector2(360, 44), Color(0.15, 0.25, 0.3)),
			_main_platform(Vector2(1000, 620), Vector2(360, 44), Color(0.15, 0.25, 0.3)),
			_sub_platform(Vector2(520, 505), Vector2(260, 34), Color(0.18, 0.29, 0.34)),
			_sub_platform(Vector2(760, 390), Vector2(260, 34), Color(0.19, 0.31, 0.36)),
			_sub_platform(Vector2(360, 275), Vector2(230, 30), Color(0.17, 0.27, 0.34)),
			_sub_platform(Vector2(920, 275), Vector2(230, 30), Color(0.17, 0.27, 0.34)),
			_sub_platform(Vector2(640, 170), Vector2(190, 28), Color(0.2, 0.32, 0.38))
		],
		"spawns": [Vector2(280, 550), Vector2(520, 435), Vector2(760, 320), Vector2(1000, 550), Vector2(360, 205), Vector2(920, 205), Vector2(640, 100), Vector2(640, 440)]
	},
	{
		"name": "7. Gravity Well",
		"subtitle": "Open center with orbiting ledges",
		"grid": Vector2i(1, 2),
		"gimmick": "Open center",
		"hazard": "Thin safe platforms",
		"identity": "Position resets",
		"background": Color(0.035, 0.025, 0.075),
		"accent": Color(0.48, 0.42, 1.0),
		"platforms": [
			_main_platform(Vector2(640, 620), Vector2(360, 46), Color(0.18, 0.16, 0.3)),
			_sub_platform(Vector2(260, 500), Vector2(230, 32), Color(0.2, 0.18, 0.34)),
			_sub_platform(Vector2(1020, 500), Vector2(230, 32), Color(0.2, 0.18, 0.34)),
			_sub_platform(Vector2(640, 440), Vector2(250, 32), Color(0.23, 0.2, 0.38)),
			_sub_platform(Vector2(430, 300), Vector2(210, 30), Color(0.19, 0.17, 0.34)),
			_sub_platform(Vector2(850, 300), Vector2(210, 30), Color(0.19, 0.17, 0.34)),
			_sub_platform(Vector2(640, 195), Vector2(170, 28), Color(0.21, 0.18, 0.38))
		],
		"spawns": [Vector2(260, 430), Vector2(520, 550), Vector2(760, 550), Vector2(1020, 430), Vector2(430, 230), Vector2(640, 370), Vector2(850, 230), Vector2(640, 125)]
	},
	{
		"name": "8. Market Rooftops",
		"subtitle": "Asymmetric streets and rooftops",
		"grid": Vector2i(2, 2),
		"gimmick": "Asymmetric routes",
		"hazard": "Uneven retreat angles",
		"identity": "Route reading",
		"background": Color(0.045, 0.04, 0.03),
		"accent": Color(0.95, 0.72, 0.42),
		"platforms": [
			_main_platform(Vector2(340, 615), Vector2(470, 46), Color(0.25, 0.2, 0.16)),
			_main_platform(Vector2(930, 590), Vector2(430, 46), Color(0.24, 0.18, 0.14)),
			_sub_platform(Vector2(185, 440), Vector2(220, 32), Color(0.29, 0.23, 0.18)),
			_sub_platform(Vector2(560, 450), Vector2(270, 32), Color(0.31, 0.24, 0.18)),
			_sub_platform(Vector2(1010, 375), Vector2(250, 32), Color(0.3, 0.22, 0.17)),
			_sub_platform(Vector2(405, 280), Vector2(190, 28), Color(0.26, 0.2, 0.16)),
			_sub_platform(Vector2(760, 240), Vector2(210, 28), Color(0.26, 0.2, 0.16))
		],
		"spawns": [Vector2(270, 545), Vector2(470, 545), Vector2(850, 520), Vector2(1040, 520), Vector2(185, 370), Vector2(560, 380), Vector2(1010, 305), Vector2(760, 170)]
	},
	{
		"name": "9. Starfall Shrine",
		"subtitle": "Final arena with layered center control",
		"grid": Vector2i(1, 1),
		"gimmick": "Locked central realm",
		"hazard": "Final convergence pressure",
		"identity": "Endgame brawl",
		"background": Color(0.055, 0.025, 0.065),
		"accent": Color(1.0, 0.55, 0.95),
		"platforms": [
			_main_platform(Vector2(640, 640), Vector2(980, 50), Color(0.22, 0.16, 0.27)),
			_sub_platform(Vector2(320, 505), Vector2(260, 34), Color(0.26, 0.18, 0.32)),
			_sub_platform(Vector2(960, 505), Vector2(260, 34), Color(0.26, 0.18, 0.32)),
			_sub_platform(Vector2(640, 390), Vector2(330, 34), Color(0.29, 0.2, 0.36)),
			_sub_platform(Vector2(250, 285), Vector2(190, 28), Color(0.24, 0.17, 0.31)),
			_sub_platform(Vector2(1030, 285), Vector2(190, 28), Color(0.24, 0.17, 0.31)),
			_sub_platform(Vector2(640, 205), Vector2(220, 28), Color(0.3, 0.2, 0.38))
		],
		"spawns": [Vector2(270, 570), Vector2(500, 570), Vector2(780, 570), Vector2(1010, 570), Vector2(320, 435), Vector2(640, 320), Vector2(960, 435), Vector2(640, 135)]
	}
	]

func _main_platform(center: Vector2, size: Vector2, color: Color, concept_tags: Array[String] = []) -> Dictionary:
	return _platform(center, size, color, PLATFORM_MAIN, concept_tags)

func _sub_platform(center: Vector2, size: Vector2, color: Color, concept_tags: Array[String] = []) -> Dictionary:
	return _platform(center, size, color, PLATFORM_SUB, concept_tags)

func _platform(center: Vector2, size: Vector2, color: Color, role: String, concept_tags: Array[String]) -> Dictionary:
	return {
		"center": center,
		"size": size,
		"color": color,
		"role": role,
		"concept_tags": concept_tags.duplicate()
	}

func _map_spawns(map: Dictionary) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for point in map.spawns:
		points.append(point)
	return points

func _get_realm_spawn_points(realm_index: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for tile_y in REALM_TILE_COUNT.y:
		for tile_x in REALM_TILE_COUNT.x:
			var tile_offset := Vector2(tile_x * BASE_REALM_SIZE.x, tile_y * BASE_REALM_SIZE.y)
			for point in _map_spawns(maps[realm_index]):
				points.append(_to_realm_world(realm_index, tile_offset + point))
	return points

func get_ai_navigation_points_for_realm(realm_index: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var origin := _get_realm_origin(realm_index)
	var map: Dictionary = maps[realm_index]
	for tile_y in REALM_TILE_COUNT.y:
		for tile_x in REALM_TILE_COUNT.x:
			var tile_offset := Vector2(tile_x * BASE_REALM_SIZE.x, tile_y * BASE_REALM_SIZE.y)
			for platform_data in map.platforms:
				var platform: Dictionary = platform_data
				var center: Vector2 = origin + tile_offset + platform.center
				var stand_y: float = center.y - float(platform.size.y) * 0.5
				points.append(Vector2(center.x, stand_y))
				var half_width: float = float(platform.size.x) * 0.5
				if half_width >= 80.0:
					var edge_offset: float = half_width - minf(34.0, half_width * 0.25)
					points.append(Vector2(center.x - edge_offset, stand_y))
					points.append(Vector2(center.x + edge_offset, stand_y))
				if float(platform.size.x) >= 500.0:
					var inset: float = minf(float(platform.size.x) * 0.32, 190.0)
					points.append(Vector2(center.x - inset, stand_y))
					points.append(Vector2(center.x + inset, stand_y))
	var horizontal_boundaries: Array[float] = [BASE_REALM_SIZE.x, BASE_REALM_SIZE.x * 2.0]
	for tile_y in REALM_TILE_COUNT.y:
		var stand_y: float = origin.y + tile_y * BASE_REALM_SIZE.y + 603.0
		for boundary_x in horizontal_boundaries:
			points.append(Vector2(origin.x + boundary_x, stand_y))
			points.append(Vector2(origin.x + boundary_x - 106.0, stand_y))
			points.append(Vector2(origin.x + boundary_x + 106.0, stand_y))
	var vertical_boundaries: Array[float] = [BASE_REALM_SIZE.y, BASE_REALM_SIZE.y * 2.0]
	for boundary_y in vertical_boundaries:
		for step in 4:
			var step_y: float = origin.y + boundary_y - 135.0 + step * 105.0
			var step_x: float = origin.x + REALM_SIZE.x * 0.5 + (-150.0 if step % 2 == 0 else 150.0)
			points.append(Vector2(step_x, step_y))
			points.append(Vector2(step_x - 116.0, step_y))
			points.append(Vector2(step_x + 116.0, step_y))
	return points

func _pick_spawn_in_realm(realm_index: int) -> Vector2:
	var points := _get_realm_spawn_points(realm_index)
	return points.pick_random()

func _get_realm_origin(realm_index: int) -> Vector2:
	var realm: Dictionary = maps[realm_index]
	var grid: Vector2i = realm.grid
	return Vector2(grid.x * REALM_WORLD_SPACING.x, grid.y * REALM_WORLD_SPACING.y)

func _to_realm_world(realm_index: int, local_position: Vector2) -> Vector2:
	return _get_realm_origin(realm_index) + local_position

func _get_realm_ringout_y(realm_index: int) -> float:
	return _get_realm_origin(realm_index).y + REALM_SIZE.y + REALM_RINGOUT_MARGIN

func _find_realm_by_grid(grid: Vector2i) -> int:
	for i in maps.size():
		var realm: Dictionary = maps[i]
		if realm.grid == grid:
			return i
	return -1

func _ready() -> void:
	randomize()
	maps = _build_maps()
	_initialize_match_flow()
	_create_realm_monster_spawner()
	_create_camera()
	_create_ui()
	_set_map(0, false)
	_spawn_players()

func _create_realm_monster_spawner() -> void:
	realm_monster_spawner = Node.new()
	realm_monster_spawner.name = "RealmMonsterSpawner"
	realm_monster_spawner.set_script(REALM_MONSTER_SPAWNER_SCRIPT)
	add_child(realm_monster_spawner)
	realm_monster_spawner.configure(Callable(self, "_get_realm_spawn_points"), Callable(self, "_get_playable_realm_indices"))

func _create_camera() -> void:
	camera = Camera2D.new()
	camera.name = "RealmCamera"
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_smoothed = true
	add_child(camera)

func _update_camera_for_current_realm() -> void:
	if not is_instance_valid(camera):
		return
	var origin := _get_realm_origin(current_map_index)
	camera.limit_left = int(origin.x)
	camera.limit_top = int(origin.y)
	camera.limit_right = int(origin.x + REALM_SIZE.x)
	camera.limit_bottom = int(origin.y + REALM_SIZE.y)
	var camera_position := origin + VIEWPORT_CENTER
	var human := _get_human_player()
	if is_instance_valid(human) and not human.is_defeated and human.realm_index == current_map_index:
		camera_position = Vector2(
			clampf(human.global_position.x, origin.x + VIEWPORT_CENTER.x, origin.x + REALM_SIZE.x - VIEWPORT_CENTER.x),
			clampf(human.global_position.y, origin.y + VIEWPORT_CENTER.y, origin.y + REALM_SIZE.y - VIEWPORT_CENTER.y)
		)
	camera.global_position = camera_position
	camera.reset_smoothing()
	active_portals = _get_portals_for_realm(current_map_index)
	_refresh_minimap()

func _process(delta: float) -> void:
	_update_match_flow(delta)
	_update_offscreen_ai_realm_movement(delta)
	_handle_character_switch()
	_handle_test_controls()
	_handle_portal_input()
	_update_camera_follow()
	_update_collapse_countdown_displays()
	_update_debug_ui()

func _update_camera_follow() -> void:
	if not is_instance_valid(camera):
		return
	var human := _get_human_player()
	if not is_instance_valid(human) or human.is_defeated or human.realm_index != current_map_index:
		return
	var origin := _get_realm_origin(current_map_index)
	var minimum := origin + VIEWPORT_CENTER
	var maximum := origin + REALM_SIZE - VIEWPORT_CENTER
	camera.global_position = Vector2(
		clampf(human.global_position.x, minimum.x, maximum.x),
		clampf(human.global_position.y, minimum.y, maximum.y)
	)

func _update_collapse_countdown_displays() -> void:
	var seconds_left := maxi(0, int(ceil(warning_timer)))
	for display in collapse_countdown_displays:
		var label: Label = display.label
		if not is_instance_valid(label):
			continue
		if display.kind == "background":
			label.text = "COLLAPSE WARNING\n%d" % seconds_left
		else:
			label.text = "%ds" % seconds_left
	for i in minimap_labels:
		var minimap_label: Label = minimap_labels[i]
		if not is_instance_valid(minimap_label):
			continue
		var state := _get_realm_state(i)
		if i == warning_realm_index:
			minimap_label.text = "%d\n! %ds" % [i + 1, seconds_left]
		else:
			minimap_label.text = "%d\n%s" % [i + 1, state.to_upper()]

func _initialize_match_flow() -> void:
	match_elapsed = 0.0
	next_warning_time = FIRST_COLLAPSE_WARNING_TIME
	warning_realm_index = -1
	warning_timer = 0.0
	realm_states.clear()
	collapse_order.clear()
	for i in maps.size():
		realm_states.append("locked" if i == CENTRAL_REALM_INDEX else "stable")
		if i != CENTRAL_REALM_INDEX:
			collapse_order.append(i)
	collapse_order.shuffle()

func _update_match_flow(delta: float) -> void:
	match_elapsed += delta
	if realm_states[CENTRAL_REALM_INDEX] == "locked" and match_elapsed >= CENTRAL_OPEN_TIME:
		realm_states[CENTRAL_REALM_INDEX] = "stable"
		if is_instance_valid(info_label):
			info_label.text = "Central realm opened: %s. Surviving realms now converge." % maps[CENTRAL_REALM_INDEX].name
		_create_world()
	if warning_realm_index >= 0:
		warning_timer = maxf(warning_timer - delta, 0.0)
		if warning_timer <= 0.0:
			_collapse_warned_realm()
	elif match_elapsed >= next_warning_time and not collapse_order.is_empty():
		_start_realm_warning()
	_update_ringout_pressure()

func _start_realm_warning() -> void:
	warning_realm_index = collapse_order.pop_front()
	realm_states[warning_realm_index] = "warning"
	warning_timer = COLLAPSE_WARNING_DURATION
	var realm: Dictionary = maps[warning_realm_index]
	if is_instance_valid(info_label):
		info_label.text = "Collapse warning: %s will fall soon. Move to a safer realm." % realm.name
	_create_world()

func _collapse_warned_realm() -> void:
	var collapsed_index := warning_realm_index
	warning_realm_index = -1
	realm_states[collapsed_index] = "collapsed"
	next_warning_time = match_elapsed + COLLAPSE_INTERVAL
	var respawn_realm := _find_safe_realm_index()
	_eliminate_combatants_in_collapsed_realm(collapsed_index, respawn_realm)
	if current_map_index == collapsed_index:
		_set_map(respawn_realm)
	else:
		_create_world()
	_sync_combatant_visibility()
	if is_instance_valid(info_label):
		info_label.text = "%s collapsed. Ring-out pressure is rising." % maps[collapsed_index].name

func _eliminate_combatants_in_collapsed_realm(collapsed_index: int, respawn_realm: int) -> void:
	for combatant in _get_all_combatants():
		if not is_instance_valid(combatant) or combatant.realm_index != collapsed_index:
			continue
		combatant.set_realm(respawn_realm, _get_realm_spawn_points(respawn_realm), _get_realm_origin(respawn_realm), _get_realm_ringout_y(respawn_realm))
		combatant.eliminate_by_realm_collapse()

func _update_ringout_pressure() -> void:
	var pressure := 1.0 + clampf(match_elapsed / MATCH_TARGET_TIME, 0.0, 1.0) * 1.4
	for player in players:
		if player.has_method("set_match_pressure"):
			player.set_match_pressure(pressure)
	if is_instance_valid(dummy) and dummy.has_method("set_match_pressure"):
		dummy.set_match_pressure(pressure)

func _create_world() -> void:
	if is_instance_valid(world_root):
		world_root.queue_free()
	collapse_countdown_displays.clear()
	world_root = Node2D.new()
	world_root.name = "World"
	add_child(world_root)
	move_child(world_root, 0)

	for i in maps.size():
		_create_realm_world(i)
	if is_instance_valid(realm_monster_spawner):
		realm_monster_spawner.sync_playable_realms(_get_playable_realm_indices())
	_update_camera_for_current_realm()

func _create_realm_world(realm_index: int) -> void:
	var map: Dictionary = maps[realm_index]
	var origin := _get_realm_origin(realm_index)
	var realm_root := Node2D.new()
	realm_root.name = "Realm_%d_%s" % [realm_index + 1, map.name]
	realm_root.position = origin
	world_root.add_child(realm_root)

	var backdrop := Node2D.new()
	backdrop.name = "Backdrop"
	backdrop.set_script(REALM_BACKDROP_SCRIPT)
	backdrop.z_index = -20
	realm_root.add_child(backdrop)
	backdrop.configure(REALM_SIZE, BASE_REALM_SIZE, realm_index, map.background, map.accent)
	_create_realm_state_overlay(map, realm_root, realm_index)

	for tile_y in REALM_TILE_COUNT.y:
		for tile_x in REALM_TILE_COUNT.x:
			var tile_offset := Vector2(tile_x * BASE_REALM_SIZE.x, tile_y * BASE_REALM_SIZE.y)
			for platform_data in map.platforms:
				var platform: Dictionary = platform_data
				var concept_tags: Array[String] = []
				for tag in platform.concept_tags:
					concept_tags.append(tag)
				_create_platform(origin + tile_offset + platform.center, platform.size, platform.color, platform.role, concept_tags, realm_index)
			for point in _map_spawns(map):
				_create_spawn_marker(origin + tile_offset + point, map.accent)
	_create_realm_connectors(origin, map.accent, realm_index)
	if _is_realm_playable(realm_index):
		_create_portals_for_realm_world(realm_index)

	var title := Label.new()
	title.text = "SMASH NINE REALMS - %s" % map.name
	title.position = Vector2(32, 22)
	title.add_theme_font_size_override("font_size", 28)
	realm_root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "%s | %s | Hazard: %s" % [map.subtitle, map.identity, map.hazard]
	subtitle.position = Vector2(34, 58)
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.modulate = Color(1.0, 1.0, 1.0, 0.75)
	realm_root.add_child(subtitle)

func _create_realm_connectors(origin: Vector2, accent: Color, realm_index: int) -> void:
	var connector_color := Color(
		lerpf(0.22, accent.r, 0.22),
		lerpf(0.25, accent.g, 0.22),
		lerpf(0.3, accent.b, 0.22)
	)
	var horizontal_boundaries: Array[float] = [BASE_REALM_SIZE.x, BASE_REALM_SIZE.x * 2.0]
	var vertical_boundaries: Array[float] = [BASE_REALM_SIZE.y, BASE_REALM_SIZE.y * 2.0]
	for tile_y in REALM_TILE_COUNT.y:
		var floor_y: float = origin.y + tile_y * BASE_REALM_SIZE.y + 620.0
		for boundary_x in horizontal_boundaries:
			_create_platform(Vector2(origin.x + boundary_x, floor_y), Vector2(280, 34), connector_color, PLATFORM_MAIN, ["realm_connector"], realm_index)
	for boundary_y in vertical_boundaries:
		for step in 4:
			var step_y: float = origin.y + boundary_y - 120.0 + step * 105.0
			var step_x: float = origin.x + REALM_SIZE.x * 0.5 + (-150.0 if step % 2 == 0 else 150.0)
			_create_platform(Vector2(step_x, step_y), Vector2(300, 30), connector_color, PLATFORM_SUB, ["realm_connector"], realm_index)

func _create_realm_state_overlay(map: Dictionary, parent: Node, realm_index: int) -> void:
	var state := _get_realm_state(realm_index)
	if state == "stable":
		return
	var overlay := ColorRect.new()
	overlay.size = REALM_SIZE
	overlay.color = Color(0.95, 0.2, 0.08, 0.18) if state == "warning" else Color(0.0, 0.0, 0.0, 0.55)
	parent.add_child(overlay)

	var label := Label.new()
	label.position = REALM_SIZE * 0.5 - Vector2(260, 70)
	label.size = Vector2(520, 140)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 38)
	label.text = "COLLAPSE WARNING" if state == "warning" else "REALM CLOSED"
	label.modulate = map.accent
	parent.add_child(label)
	if state == "warning":
		collapse_countdown_displays.append({"label": label, "kind": "background"})
		for tile_y in REALM_TILE_COUNT.y:
			for tile_x in REALM_TILE_COUNT.x:
				if tile_x == 1 and tile_y == 1:
					continue
				var tile_label := Label.new()
				tile_label.position = Vector2(tile_x * BASE_REALM_SIZE.x, tile_y * BASE_REALM_SIZE.y) + VIEWPORT_CENTER - Vector2(260, 70)
				tile_label.size = Vector2(520, 140)
				tile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				tile_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				tile_label.add_theme_font_size_override("font_size", 38)
				tile_label.modulate = map.accent
				parent.add_child(tile_label)
				collapse_countdown_displays.append({"label": tile_label, "kind": "background"})

func _create_realm_grid_ui(parent: Node) -> void:
	var origin := Vector2.ZERO
	var cell := Vector2(82, 42)
	for i in maps.size():
		var realm: Dictionary = maps[i]
		var grid: Vector2i = realm.grid
		var box := ColorRect.new()
		box.position = origin + Vector2(grid.x * (cell.x + 5), grid.y * (cell.y + 5))
		box.size = cell
		box.color = _get_realm_state_color(i)
		parent.add_child(box)

		var label := Label.new()
		label.position = box.position + Vector2(5, 4)
		label.size = cell - Vector2(10, 8)
		label.text = "%d\n%s" % [i + 1, _get_realm_state(i).to_upper()]
		label.add_theme_font_size_override("font_size", 10)
		parent.add_child(label)
		minimap_labels[i] = label

func _get_realm_state_color(index: int) -> Color:
	if index == current_map_index:
		return Color(0.35, 0.8, 1.0, 0.72)
	match _get_realm_state(index):
		"locked":
			return Color(0.25, 0.25, 0.3, 0.75)
		"warning":
			return Color(1.0, 0.28, 0.1, 0.78)
		"collapsed":
			return Color(0.03, 0.03, 0.035, 0.86)
		_:
			return Color(0.14, 0.18, 0.22, 0.72)

func _get_realm_state(index: int) -> String:
	if index < 0 or index >= realm_states.size():
		return "stable"
	return realm_states[index]

func get_platform_role(platform: Node) -> String:
	if not is_instance_valid(platform) or not platform.has_meta("platform_role"):
		return ""
	return str(platform.get_meta("platform_role"))

func platform_allows_drop_through(platform: Node) -> bool:
	return is_instance_valid(platform) and bool(platform.get_meta("allows_drop_through", false))

func get_platform_concept_tags(platform: Node) -> Array[String]:
	var tags: Array[String] = []
	if not is_instance_valid(platform):
		return tags
	for tag in platform.get_meta("concept_tags", []):
		tags.append(str(tag))
	return tags

func _create_platform(center: Vector2, size: Vector2, color: Color, role: String = PLATFORM_SUB, concept_tags: Array[String] = [], realm_index := -1) -> void:
	var body := StaticBody2D.new()
	body.name = "MainPlatform" if role == PLATFORM_MAIN else "SubPlatform"
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	body.add_to_group("platforms")
	body.add_to_group("main_platforms" if role == PLATFORM_MAIN else "sub_platforms")
	body.set_meta("platform_role", role)
	body.set_meta("allows_drop_through", role == PLATFORM_SUB)
	body.set_meta("concept_tags", concept_tags.duplicate())
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	var visual := ColorRect.new()
	rect.size = size
	shape.shape = rect
	shape.one_way_collision = role == PLATFORM_SUB
	shape.one_way_collision_margin = 12.0 if role == PLATFORM_SUB else 0.0
	visual.color = color
	visual.size = size
	visual.position = -size * 0.5
	body.position = center
	body.add_child(shape)
	var underside := ColorRect.new()
	underside.color = color.darkened(0.42)
	underside.size = Vector2(size.x, maxf(size.y * 0.38, 8.0))
	underside.position = Vector2(-size.x * 0.5, size.y * 0.5 - underside.size.y)
	body.add_child(visual)
	body.add_child(underside)
	var edge := ColorRect.new()
	var accent: Color = maps[realm_index].accent if realm_index >= 0 and realm_index < maps.size() else color.lightened(0.3)
	edge.color = Color(accent.r, accent.g, accent.b, 0.72 if role == PLATFORM_MAIN else 0.5)
	edge.size = Vector2(size.x, 5.0 if role == PLATFORM_MAIN else 3.0)
	edge.position = -size * 0.5
	body.add_child(edge)
	_add_platform_details(body, size, color, accent, realm_index)
	world_root.add_child(body)

func _add_platform_details(body: Node2D, size: Vector2, base_color: Color, accent: Color, realm_index: int) -> void:
	var segment_count := clampi(int(size.x / 78.0), 2, 12)
	for index in range(1, segment_count):
		var seam := ColorRect.new()
		seam.color = Color(base_color.r * 0.55, base_color.g * 0.55, base_color.b * 0.55, 0.42)
		seam.size = Vector2(2, maxf(size.y - 9.0, 4.0))
		seam.position = Vector2(-size.x * 0.5 + size.x * float(index) / float(segment_count), -size.y * 0.5 + 7)
		body.add_child(seam)
	match realm_index:
		2:
			for index in mini(segment_count, 8):
				var moss := ColorRect.new()
				moss.color = Color(0.2, 0.62, 0.49, 0.42)
				moss.size = Vector2(18 + index % 3 * 7, 3 + index % 2 * 4)
				moss.position = Vector2(-size.x * 0.5 + 18 + index * size.x / float(mini(segment_count, 8)), -size.y * 0.5 + 4)
				body.add_child(moss)
		4:
			for index in mini(segment_count, 7):
				var crack := Line2D.new()
				crack.width = 2.0
				crack.default_color = Color(accent.r, accent.g, accent.b, 0.55)
				var x := -size.x * 0.5 + 28 + index * size.x / float(mini(segment_count, 7))
				crack.points = PackedVector2Array([Vector2(x, -size.y * 0.5 + 8), Vector2(x + 8, -2), Vector2(x + 2, size.y * 0.5 - 5)])
				body.add_child(crack)
		5:
			for index in mini(segment_count, 9):
				var icicle := Polygon2D.new()
				var x := -size.x * 0.5 + 20 + index * size.x / float(mini(segment_count, 9))
				icicle.polygon = PackedVector2Array([Vector2(x, size.y * 0.5 - 4), Vector2(x + 13, size.y * 0.5 - 4), Vector2(x + 7, size.y * 0.5 + 10 + index % 3 * 5)])
				icicle.color = Color(accent.r, accent.g, accent.b, 0.48)
				body.add_child(icicle)
		6:
			for index in mini(segment_count, 8):
				var node := ColorRect.new()
				node.color = Color(accent.r, accent.g, accent.b, 0.7)
				node.size = Vector2(5, 5)
				node.position = Vector2(-size.x * 0.5 + 22 + index * size.x / float(mini(segment_count, 8)), -2)
				body.add_child(node)
		7:
			for index in mini(segment_count, 10):
				var tile := ColorRect.new()
				tile.color = Color(0.65, 0.28, 0.13, 0.42)
				tile.size = Vector2(24, 4)
				tile.position = Vector2(-size.x * 0.5 + 12 + index * size.x / float(mini(segment_count, 10)), -size.y * 0.5 + 5)
				body.add_child(tile)
		8:
			var center_rune := ColorRect.new()
			center_rune.color = Color(accent.r, accent.g, accent.b, 0.8)
			center_rune.size = Vector2(20, 4)
			center_rune.position = Vector2(-10, -2)
			body.add_child(center_rune)

func _create_spawn_marker(point: Vector2, color: Color) -> void:
	var marker := ColorRect.new()
	marker.size = Vector2(16, 4)
	marker.position = point + Vector2(-8, -4)
	marker.color = Color(color.r, color.g, color.b, 0.55)
	world_root.add_child(marker)

func _create_portals_for_current_realm() -> void:
	active_portals.clear()
	active_portals = _get_portals_for_realm(current_map_index)
	for portal in active_portals:
		var layout: Dictionary = portal.layout
		var support_center: Vector2 = layout.support
		_create_portal_support(support_center)
		_create_portal_visual(layout.position, layout.label, portal.destination, portal.source)

func _create_portals_for_realm_world(realm_index: int) -> void:
	for portal in _get_portals_for_realm(realm_index):
		var layout: Dictionary = portal.layout
		var support_center: Vector2 = layout.support
		_create_portal_support(support_center)
		_create_portal_visual(layout.position, layout.label, portal.destination, portal.source)

func _get_portals_for_realm(realm_index: int) -> Array[Dictionary]:
	var portals: Array[Dictionary] = []
	var current_realm: Dictionary = maps[realm_index]
	var current_grid: Vector2i = current_realm.grid
	var portal_layout := {
		Vector2i(0, -1): {"position": Vector2(1920, 140), "support": Vector2(1920, 220), "label": "UP"},
		Vector2i(1, 0): {"position": Vector2(3710, 1220), "support": Vector2(3710, 1310), "label": "RIGHT"},
		Vector2i(0, 1): {"position": Vector2(1920, 1940), "support": Vector2(1920, 2030), "label": "DOWN"},
		Vector2i(-1, 0): {"position": Vector2(130, 1220), "support": Vector2(130, 1310), "label": "LEFT"}
	}
	for direction in portal_layout:
		var destination_index := _find_realm_by_grid(current_grid + direction)
		if destination_index < 0 or not _is_realm_playable(destination_index):
			continue
		var layout: Dictionary = portal_layout[direction]
		var world_position := _to_realm_world(realm_index, layout.position)
		var support_center := _to_realm_world(realm_index, layout.support)
		var support_top := support_center.y - PORTAL_SUPPORT_SIZE.y * 0.5
		var rect := Rect2(Vector2(support_center.x - 84.0, support_top - 96.0), Vector2(168.0, 118.0))
		portals.append({
			"source": realm_index,
			"destination": destination_index,
			"destination_state": _get_realm_state(destination_index),
			"direction": direction,
			"rect": rect,
			"entry_position": _get_portal_entry_position(destination_index, direction),
			"layout": {
				"position": world_position,
				"support": support_center,
				"label": layout.label
			}
		})
	return portals

func _create_portal_support(center: Vector2) -> void:
	_create_platform(center, PORTAL_SUPPORT_SIZE, Color(0.24, 0.28, 0.32), PLATFORM_MAIN, ["portal_support"])

func _create_portal_visual(center: Vector2, label_text: String, destination_index: int, source_index: int) -> void:
	var realm: Dictionary = maps[destination_index]
	var frame := ColorRect.new()
	frame.size = PORTAL_SIZE
	frame.position = center - PORTAL_SIZE * 0.5
	frame.color = Color(realm.accent.r, realm.accent.g, realm.accent.b, 0.32)
	world_root.add_child(frame)

	var core := ColorRect.new()
	core.size = Vector2(52, 52)
	core.position = center - core.size * 0.5
	core.color = Color(realm.accent.r, realm.accent.g, realm.accent.b, 0.72)
	world_root.add_child(core)

	var label := Label.new()
	label.position = center + Vector2(-76, 48)
	label.size = Vector2(152, 34)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.text = "Q %s -> %s" % [label_text, realm.name]
	world_root.add_child(label)

	if warning_realm_index >= 0 and (source_index == warning_realm_index or destination_index == warning_realm_index):
		var countdown := Label.new()
		countdown.position = center + Vector2(-70, -92)
		countdown.size = Vector2(140, 42)
		countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		countdown.add_theme_font_size_override("font_size", 26)
		countdown.modulate = Color(1.0, 0.35, 0.16)
		world_root.add_child(countdown)
		collapse_countdown_displays.append({"label": countdown, "kind": "portal"})

func _get_portal_entry_position(destination_index: int, direction: Vector2i) -> Vector2:
	var local_position: Vector2
	if direction == Vector2i(1, 0):
		local_position = Vector2(130, 1297)
	elif direction == Vector2i(-1, 0):
		local_position = Vector2(3710, 1297)
	elif direction == Vector2i(0, 1):
		local_position = Vector2(1920, 207)
	else:
		local_position = Vector2(1920, 2017)
	return _to_realm_world(destination_index, local_position)

func _spawn_players() -> void:
	var ids := CHARACTER_REGISTRY.get_character_ids()
	var starting_realms := _get_playable_realm_indices()
	starting_realms.erase(CENTRAL_REALM_INDEX)
	starting_realms.shuffle()
	for i in target_player_count:
		var realm_index := current_map_index if i == 0 else starting_realms[i % starting_realms.size()]
		_add_player(ids[i], i == 0, _pick_spawn_in_realm(realm_index), realm_index)
	_sync_combatant_visibility()

func _add_player(character_id: String, human: bool, position: Vector2, realm_index: int) -> Node:
	var player := _create_player_node(character_id)
	add_child(player)
	player.global_position = position
	player.setup(characters[character_id], players.size() + 1, human)
	player.set_realm(realm_index, _get_realm_spawn_points(realm_index), _get_realm_origin(realm_index), _get_realm_ringout_y(realm_index))
	_connect_player_signals(player)
	players.append(player)
	return player

func _connect_player_signals(player: Node) -> void:
	player.defeated.connect(_on_player_defeated)
	player.respawned.connect(_on_combatant_respawned)
	player.leveled_up.connect(_on_player_leveled_up)

func _create_player_node(character_id := "") -> CharacterBody2D:
	var player: CharacterBody2D
	var character_scene := CHARACTER_REGISTRY.get_scene(character_id)
	if character_scene != null:
		player = character_scene.instantiate() as CharacterBody2D
	else:
		player = CharacterBody2D.new()
		player.set_script(PLAYER_BASE_SCRIPT)
	player.collision_layer = PLAYER_LAYER
	player.collision_mask = WORLD_LAYER

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(42, 64)
	shape.shape = rect
	shape.position = Vector2(0, -32)
	player.add_child(shape)

	var body := ColorRect.new()
	body.name = "Body"
	body.size = Vector2(42, 64)
	body.position = Vector2(-21, -64)
	player.add_child(body)

	var character_sprite := _create_character_prototype_sprite()
	player.add_child(character_sprite)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.position = Vector2(-46, -105)
	name_label.size = Vector2(92, 42)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	player.add_child(name_label)

	var hp_back := ColorRect.new()
	hp_back.name = "HpBar"
	hp_back.color = Color(0.1, 0.1, 0.1, 0.9)
	hp_back.size = Vector2(54, 7)
	hp_back.position = Vector2(-27, -78)
	player.add_child(hp_back)

	var hp_fill := ColorRect.new()
	hp_fill.name = "Fill"
	hp_fill.color = Color(0.25, 1.0, 0.35)
	hp_fill.size = Vector2(54, 7)
	hp_back.add_child(hp_fill)

	var exp_back := ColorRect.new()
	exp_back.name = "ExpBar"
	exp_back.color = Color(0.08, 0.08, 0.12, 0.92)
	exp_back.size = Vector2(54, 5)
	exp_back.position = Vector2(-27, -69)
	player.add_child(exp_back)

	var exp_fill := ColorRect.new()
	exp_fill.name = "Fill"
	exp_fill.color = Color(0.3, 0.72, 1.0)
	exp_fill.size = Vector2(54, 5)
	exp_back.add_child(exp_fill)
	return player

func _create_character_prototype_sprite() -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.name = "CharacterSprite"
	sprite.position = Vector2(0, -32)
	sprite.scale = Vector2(2.0, 2.0)
	sprite.z_index = 1
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.visible = false
	return sprite

func _create_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UI"
	add_child(ui_layer)

	info_label = Label.new()
	info_label.position = Vector2(32, 620)
	info_label.size = Vector2(850, 92)
	info_label.text = "A/D move, W/Space jump, J attack, K/L skills, I ultimate, Q portal, 1-4 character, 5/6 players, H dummy"
	info_label.add_theme_font_size_override("font_size", 15)
	ui_layer.add_child(info_label)

	debug_label = Label.new()
	debug_label.position = Vector2(900, 24)
	debug_label.size = Vector2(370, 250)
	debug_label.add_theme_font_size_override("font_size", 15)
	ui_layer.add_child(debug_label)

	minimap_root = Control.new()
	minimap_root.name = "RealmMinimap"
	minimap_root.position = Vector2(32, 94)
	minimap_root.size = Vector2(256, 136)
	ui_layer.add_child(minimap_root)
	_refresh_minimap()

func _refresh_minimap() -> void:
	if not is_instance_valid(minimap_root):
		return
	for child in minimap_root.get_children():
		child.queue_free()
	minimap_labels.clear()
	_create_realm_grid_ui(minimap_root)

func _handle_character_switch() -> void:
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
	var replacement := _create_player_node(character_id)
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
		_set_player_count(mini(4, target_player_count + 1))
	if Input.is_action_just_pressed("toggle_dummy"):
		_toggle_dummy()

func _handle_portal_input() -> void:
	if not Input.is_action_just_pressed(PORTAL_USE_ACTION) or players.is_empty():
		return
	var human: Node = players[0]
	if not is_instance_valid(human) or human.is_defeated or not human.is_on_floor():
		return
	for portal in active_portals:
		var rect: Rect2 = portal.rect
		if rect.has_point(human.global_position):
			_move_human_through_portal(portal)
			return

func _move_human_through_portal(portal: Dictionary) -> void:
	var human: Node = players[0]
	var destination: int = portal.destination
	human.set_realm(destination, _get_realm_spawn_points(destination), _get_realm_origin(destination), _get_realm_ringout_y(destination))
	human.reset_for_map(portal.entry_position, _get_realm_spawn_points(destination))
	_set_map(destination, false)
	_sync_combatant_visibility()
	if is_instance_valid(info_label):
		info_label.text = "%s entered %s through a portal." % [human.display_name, maps[destination].name]

func get_ai_portals_for_realm(realm_index: int) -> Array:
	if realm_index < 0 or realm_index >= maps.size():
		return []
	return _get_portals_for_realm(realm_index)

func move_ai_through_portal(ai_player: Node, portal: Dictionary) -> void:
	if not is_instance_valid(ai_player) or ai_player.is_defeated:
		return
	var destination: int = portal.destination
	if not _is_realm_playable(destination):
		return
	ai_player.set_realm(destination, _get_realm_spawn_points(destination), _get_realm_origin(destination), _get_realm_ringout_y(destination))
	ai_player.reset_for_map(portal.entry_position, _get_realm_spawn_points(destination))
	_sync_combatant_visibility()
	if is_instance_valid(info_label):
		info_label.text = "%s wandered into %s through a portal." % [ai_player.display_name, maps[destination].name]

func _update_offscreen_ai_realm_movement(delta: float) -> void:
	offscreen_ai_realm_step_timer = maxf(offscreen_ai_realm_step_timer - delta, 0.0)
	if offscreen_ai_realm_step_timer > 0.0:
		return
	offscreen_ai_realm_step_timer = OFFSCREEN_AI_REALM_STEP_TIME
	var combatants: Array[Node] = _get_all_combatants()
	for combatant in combatants:
		if not _can_update_offscreen_ai(combatant):
			continue
		var portals: Array[Dictionary] = _get_portals_for_realm(combatant.realm_index)
		var ai_controller = combatant.get("ai_controller")
		var portal: Dictionary = ai_controller.update_offscreen_realm(combatant, delta, combatants, portals, _get_realm_state(combatant.realm_index), Callable(self, "_get_realm_state"), Callable(self, "_get_grid_distance"))
		if not portal.is_empty():
			_move_offscreen_ai_through_portal(combatant, portal)

func _get_human_player() -> Node:
	if players.is_empty():
		return null
	var human: Node = players[0]
	if is_instance_valid(human) and human.is_human:
		return human
	return null

func _can_update_offscreen_ai(combatant: Node) -> bool:
	if not is_instance_valid(combatant) or combatant.is_human or combatant.is_dummy:
		return false
	if combatant.is_defeated or combatant.realm_index == current_map_index:
		return false
	return _is_realm_playable(combatant.realm_index) and combatant.get("ai_controller") != null

func _get_grid_distance(a_index: int, b_index: int) -> int:
	var a: Vector2i = maps[a_index].grid
	var b: Vector2i = maps[b_index].grid
	return absi(a.x - b.x) + absi(a.y - b.y)

func _move_offscreen_ai_through_portal(ai_player: Node, portal: Dictionary) -> void:
	var destination: int = portal.destination
	ai_player.set_realm(destination, _get_realm_spawn_points(destination), _get_realm_origin(destination), _get_realm_ringout_y(destination))
	ai_player.reset_for_map(portal.entry_position, _get_realm_spawn_points(destination))
	_sync_combatant_visibility()

func _set_map(index: int, reposition_players := true) -> void:
	if not _is_realm_playable(index):
		index = _find_safe_realm_index()
	current_map_index = clampi(index, 0, maps.size() - 1)
	spawn_points = _get_realm_spawn_points(current_map_index)
	if is_instance_valid(world_root):
		_update_camera_for_current_realm()
	else:
		_create_world()
	if reposition_players:
		var map: Dictionary = maps[current_map_index]
		info_label.text = "Realm view changed to %s." % map.name
	_sync_combatant_visibility()

func _clear_transient_combat_nodes() -> void:
	for child in get_children():
		if child is Area2D:
			child.queue_free()

func _is_realm_playable(index: int) -> bool:
	var state := _get_realm_state(index)
	return state == "stable" or state == "warning"

func _get_playable_realm_indices() -> Array[int]:
	var playable: Array[int] = []
	for i in maps.size():
		if _is_realm_playable(i):
			playable.append(i)
	return playable

func _find_safe_realm_index() -> int:
	var playable := _get_playable_realm_indices()
	if playable.is_empty():
		return CENTRAL_REALM_INDEX
	if playable.has(CENTRAL_REALM_INDEX):
		return CENTRAL_REALM_INDEX
	return playable.pick_random()

func _find_playable_realm(from_index: int, direction: int) -> int:
	var index := from_index
	for step in maps.size():
		index = posmod(index + direction, maps.size())
		if _is_realm_playable(index):
			return index
	return from_index

func _reposition_combatants_for_map() -> void:
	var positions := spawn_points.duplicate()
	positions.shuffle()
	for i in players.size():
		var player: Node = players[i]
		if player.has_method("reset_for_map"):
			player.reset_for_map(positions[i % positions.size()], spawn_points)
	if is_instance_valid(dummy) and dummy.has_method("reset_for_map"):
		dummy.reset_for_map(spawn_points.pick_random(), spawn_points)

func _get_all_combatants() -> Array[Node]:
	var combatants: Array[Node] = []
	for player in players:
		combatants.append(player)
	if is_instance_valid(dummy):
		combatants.append(dummy)
	return combatants

func _sync_combatant_visibility() -> void:
	for combatant in _get_all_combatants():
		if is_instance_valid(combatant) and combatant.has_method("set_realm_active"):
			combatant.set_realm_active(_is_realm_playable(combatant.realm_index))

func _set_player_count(count: int) -> void:
	if count == target_player_count:
		return
	target_player_count = count
	while players.size() > target_player_count:
		var player: Node = players.pop_back()
		player.queue_free()
	var ids := ["frey", "yuki", "luna", "nova"]
	while players.size() < target_player_count:
		var index: int = players.size()
		var realm_index: int = _get_playable_realm_indices().pick_random()
		_add_player(ids[index], false, _pick_spawn_in_realm(realm_index), realm_index)
	_sync_combatant_visibility()
	info_label.text = "Player count set to %d. 5/6 changes players, H toggles dummy." % target_player_count

func _toggle_dummy() -> void:
	if is_instance_valid(dummy):
		dummy.queue_free()
		dummy = null
		info_label.text = "Training dummy removed."
		return
	dummy = _create_player_node()
	add_child(dummy)
	dummy.global_position = spawn_points.pick_random()
	dummy.setup_dummy(99)
	dummy.set_realm(current_map_index, spawn_points, _get_realm_origin(current_map_index), _get_realm_ringout_y(current_map_index))
	dummy.defeated.connect(_on_player_defeated)
	dummy.respawned.connect(_on_combatant_respawned)
	_sync_combatant_visibility()
	info_label.text = "Training dummy spawned. Press H again to remove it."

func _update_debug_ui() -> void:
	var map: Dictionary = maps[current_map_index]
	var phase := _get_match_phase_name()
	var warning_text := "none"
	if warning_realm_index >= 0:
		warning_text = "%s %.0fs" % [maps[warning_realm_index].name, warning_timer]
	var total_count := _get_all_combatants().size()
	var local_count := _get_combatant_count_in_realm(current_map_index)
	var local_monsters: int = realm_monster_spawner.get_monster_count(current_map_index) if is_instance_valid(realm_monster_spawner) else 0
	var lines := ["Realm System", "Phase: %s  Time: %.0fs" % [phase, match_elapsed], "Realm: %s  State: %s" % [map.name, _get_realm_state(current_map_index)], "Warning: %s" % warning_text, "Total combatants: %d   In realm: %d" % [total_count, local_count], "Monsters in realm: %d (neutral until hit)" % local_monsters, "Stand on portal + Q: move to adjacent realm", ""]
	for p in players:
		var exp_text := "MAX" if p.experience_to_next_level <= 0 else "%d/%d" % [p.experience, p.experience_to_next_level]
		lines.append("%s L%d X:%s R:%d H:%.0f A:%.0f D:%.0f S:%.0f" % [p.display_name, p.level, exp_text, p.realm_index + 1, p.hp, p.attack_power, p.defense, p.speed])
	if is_instance_valid(dummy):
		lines.append("%s  R:%d  HP:%3.0f" % [dummy.display_name, dummy.realm_index + 1, dummy.hp])
	debug_label.text = "\n".join(lines)

func _get_combatant_count_in_realm(realm_index: int) -> int:
	var count := 0
	for combatant in _get_all_combatants():
		if is_instance_valid(combatant) and combatant.realm_index == realm_index:
			count += 1
	return count

func _get_match_phase_name() -> String:
	if match_elapsed < FIRST_COLLAPSE_WARNING_TIME:
		return "Early exploration"
	if realm_states[CENTRAL_REALM_INDEX] == "locked":
		return "Mid collapse"
	if _get_playable_realm_indices().size() <= 3:
		return "Final brawl"
	return "Late convergence"

func _on_player_defeated(player: Node, attacker: Node) -> void:
	var attacker_name := "environment"
	if is_instance_valid(attacker) and attacker.has_method("get"):
		attacker_name = attacker.display_name
	info_label.text = "%s was defeated by %s. Respawning in 3 seconds." % [player.display_name, attacker_name]

func _on_player_leveled_up(player: Node, new_level: int) -> void:
	if is_instance_valid(info_label):
		info_label.text = "%s reached Lv.%d. HP %.0f / ATK %.0f / DEF %.0f / SPD %.0f" % [player.display_name, new_level, player.max_hp, player.attack_power, player.defense, player.speed]

func _on_combatant_respawned(_combatant: Node) -> void:
	_sync_combatant_visibility()
