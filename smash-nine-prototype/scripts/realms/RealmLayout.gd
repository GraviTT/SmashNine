extends RefCounted
## World-space geometry of the nine realms: origins, spawn and navigation points,
## ring-out lines and portal placement. Static per match, so results are cached.

const REALM_CATALOG := preload("res://scripts/realms/RealmCatalog.gd")

const CENTRAL_REALM_INDEX := 8
const VIEWPORT_CENTER := Vector2(640, 360)
const BASE_REALM_SIZE := Vector2(1280, 720)
const REALM_TILE_COUNT := Vector2i(3, 3)
const REALM_SIZE := Vector2(3840, 2160)
const REALM_WORLD_SPACING := Vector2(4600, 2800)
const REALM_RINGOUT_MARGIN := 220.0
const PORTAL_SIZE := Vector2(92, 92)
const PORTAL_SUPPORT_SIZE := Vector2(170, 26)
const PORTAL_LAYOUT := {
	Vector2i(0, -1): {"position": Vector2(1920, 140), "support": Vector2(1920, 220), "label": "UP"},
	Vector2i(1, 0): {"position": Vector2(3710, 1220), "support": Vector2(3710, 1310), "label": "RIGHT"},
	Vector2i(0, 1): {"position": Vector2(1920, 1940), "support": Vector2(1920, 2030), "label": "DOWN"},
	Vector2i(-1, 0): {"position": Vector2(130, 1220), "support": Vector2(130, 1310), "label": "LEFT"}
}

var maps: Array = []
var _spawn_cache: Dictionary = {}
var _navigation_cache: Dictionary = {}

func _init() -> void:
	maps = REALM_CATALOG.build_maps()

func realm_count() -> int:
	return maps.size()

func get_realm(realm_index: int) -> Dictionary:
	return maps[realm_index]

func get_origin(realm_index: int) -> Vector2:
	var grid: Vector2i = maps[realm_index].grid
	return Vector2(grid.x * REALM_WORLD_SPACING.x, grid.y * REALM_WORLD_SPACING.y)

func to_world(realm_index: int, local_position: Vector2) -> Vector2:
	return get_origin(realm_index) + local_position

func get_ringout_y(realm_index: int) -> float:
	return get_origin(realm_index).y + REALM_SIZE.y + REALM_RINGOUT_MARGIN

func find_by_grid(grid: Vector2i) -> int:
	for i in maps.size():
		if maps[i].grid == grid:
			return i
	return -1

func grid_distance(a_index: int, b_index: int) -> int:
	var a: Vector2i = maps[a_index].grid
	var b: Vector2i = maps[b_index].grid
	return absi(a.x - b.x) + absi(a.y - b.y)

func tile_offsets() -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	for tile_y in REALM_TILE_COUNT.y:
		for tile_x in REALM_TILE_COUNT.x:
			offsets.append(Vector2(tile_x * BASE_REALM_SIZE.x, tile_y * BASE_REALM_SIZE.y))
	return offsets

## Shared cached array: callers must not modify it (PlayerBase.set_spawn_points copies).
func get_spawn_points(realm_index: int) -> Array[Vector2]:
	if _spawn_cache.has(realm_index):
		return _spawn_cache[realm_index]
	var points: Array[Vector2] = []
	for tile_offset in tile_offsets():
		for point in maps[realm_index].spawns:
			points.append(to_world(realm_index, tile_offset + point))
	_spawn_cache[realm_index] = points
	return points

func pick_spawn(realm_index: int) -> Vector2:
	return get_spawn_points(realm_index).pick_random()

## Standing points on every platform and connector, used by the bot path planner.
## Shared cached array: callers must not modify it.
func get_navigation_points(realm_index: int) -> Array[Vector2]:
	if _navigation_cache.has(realm_index):
		return _navigation_cache[realm_index]
	var points: Array[Vector2] = []
	var origin := get_origin(realm_index)
	var map: Dictionary = maps[realm_index]
	for tile_offset in tile_offsets():
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
	_navigation_cache[realm_index] = points
	return points

## Grid neighbours that physically exist, regardless of their current state.
func get_neighbor_directions(realm_index: int) -> Array[Vector2i]:
	var directions: Array[Vector2i] = []
	var grid: Vector2i = maps[realm_index].grid
	for direction in PORTAL_LAYOUT:
		if find_by_grid(grid + direction) >= 0:
			directions.append(direction)
	return directions

func get_portal_support_center(realm_index: int, direction: Vector2i) -> Vector2:
	return to_world(realm_index, PORTAL_LAYOUT[direction].support)

## Open portals out of a realm. state_of(realm_index) -> String decides which
## destinations are still playable.
func get_portals(realm_index: int, state_of: Callable) -> Array[Dictionary]:
	var portals: Array[Dictionary] = []
	var current_grid: Vector2i = maps[realm_index].grid
	for direction in get_neighbor_directions(realm_index):
		var destination_index := find_by_grid(current_grid + direction)
		var destination_state: String = state_of.call(destination_index)
		if destination_state != "stable" and destination_state != "warning":
			continue
		var layout: Dictionary = PORTAL_LAYOUT[direction]
		var support_center := get_portal_support_center(realm_index, direction)
		var support_top := support_center.y - PORTAL_SUPPORT_SIZE.y * 0.5
		portals.append({
			"source": realm_index,
			"destination": destination_index,
			"destination_state": destination_state,
			"direction": direction,
			"rect": Rect2(Vector2(support_center.x - 84.0, support_top - 96.0), Vector2(168.0, 118.0)),
			"entry_position": get_portal_entry_position(destination_index, direction),
			"layout": {
				"position": to_world(realm_index, layout.position),
				"support": support_center,
				"label": layout.label
			}
		})
	return portals

func get_portal_entry_position(destination_index: int, direction: Vector2i) -> Vector2:
	var local_position: Vector2
	if direction == Vector2i(1, 0):
		local_position = Vector2(130, 1297)
	elif direction == Vector2i(-1, 0):
		local_position = Vector2(3710, 1297)
	elif direction == Vector2i(0, 1):
		local_position = Vector2(1920, 207)
	else:
		local_position = Vector2(1920, 2017)
	return to_world(destination_index, local_position)
