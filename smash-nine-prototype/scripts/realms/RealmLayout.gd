extends RefCounted
## World-space geometry of the nine realms: origins, sizes, spawn and navigation
## points, blast lines and portal placement. Static per match, so results are cached.

const REALM_CATALOG := preload("res://scripts/realms/RealmCatalog.gd")
const GAME_SCALE := preload("res://scripts/GameScale.gd")

const CENTRAL_REALM_INDEX := 8
const VIEWPORT_CENTER := Vector2(640, 360)
const REALM_WORLD_SPACING := Vector2(4600, 2800)
## Recovery room below and beside a realm. One-screen realms put the bottom line only
## ~340 px under the main floor at 220, so a knock-off was a 0.6 s fall to death.
const BLAST_MARGIN_BOTTOM := 480.0 * GAME_SCALE.WORLD
const BLAST_MARGIN_SIDE := 300.0 * GAME_SCALE.WORLD
const PORTAL_SIZE := Vector2(92, 92)
const PORTAL_LABELS := {
	Vector2i(0, -1): "UP",
	Vector2i(1, 0): "RIGHT",
	Vector2i(0, 1): "DOWN",
	Vector2i(-1, 0): "LEFT"
}
## Corner realms collapse in the first wave, edge realms in the second (design D3).
const CORNER_GRIDS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(2, 0), Vector2i(0, 2), Vector2i(2, 2)]

var maps: Array = []
var _spawn_cache: Dictionary = {}
var _navigation_cache: Dictionary = {}

func _init() -> void:
	maps = REALM_CATALOG.scaled_maps(GAME_SCALE.WORLD)

func realm_count() -> int:
	return maps.size()

func get_realm(realm_index: int) -> Dictionary:
	return maps[realm_index]

func get_tile_size(realm_index: int) -> Vector2:
	return maps[realm_index].get("size", REALM_CATALOG.OUTER_SIZE)

func get_tiles(realm_index: int) -> Vector2i:
	return maps[realm_index].get("tiles", Vector2i(1, 1))

func get_size(realm_index: int) -> Vector2:
	var tiles := get_tiles(realm_index)
	return get_tile_size(realm_index) * Vector2(tiles.x, tiles.y)

func get_origin(realm_index: int) -> Vector2:
	var grid: Vector2i = maps[realm_index].grid
	return Vector2(grid.x * REALM_WORLD_SPACING.x, grid.y * REALM_WORLD_SPACING.y)

func get_bounds(realm_index: int) -> Rect2:
	return Rect2(get_origin(realm_index), get_size(realm_index))

func to_world(realm_index: int, local_position: Vector2) -> Vector2:
	return get_origin(realm_index) + local_position

func get_ringout_y(realm_index: int) -> float:
	return get_origin(realm_index).y + get_size(realm_index).y + BLAST_MARGIN_BOTTOM

## Left and right x beyond which a combatant is rung out.
func get_side_blast_lines(realm_index: int) -> Vector2:
	var origin := get_origin(realm_index)
	return Vector2(origin.x - BLAST_MARGIN_SIDE, origin.x + get_size(realm_index).x + BLAST_MARGIN_SIDE)

func find_by_grid(grid: Vector2i) -> int:
	for i in maps.size():
		if maps[i].grid == grid:
			return i
	return -1

func grid_distance(a_index: int, b_index: int) -> int:
	var a: Vector2i = maps[a_index].grid
	var b: Vector2i = maps[b_index].grid
	return absi(a.x - b.x) + absi(a.y - b.y)

func is_corner(realm_index: int) -> bool:
	return CORNER_GRIDS.has(maps[realm_index].grid)

func get_corner_indices() -> Array[int]:
	var result: Array[int] = []
	for i in maps.size():
		if i != CENTRAL_REALM_INDEX and is_corner(i):
			result.append(i)
	return result

func get_edge_indices() -> Array[int]:
	var result: Array[int] = []
	for i in maps.size():
		if i != CENTRAL_REALM_INDEX and not is_corner(i):
			result.append(i)
	return result

func tile_offsets(realm_index: int) -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	var tile_size := get_tile_size(realm_index)
	var tiles := get_tiles(realm_index)
	for tile_y in tiles.y:
		for tile_x in tiles.x:
			offsets.append(Vector2(tile_x * tile_size.x, tile_y * tile_size.y))
	return offsets

## Shared cached array: callers must not modify it (PlayerBase.set_spawn_points copies).
func get_spawn_points(realm_index: int) -> Array[Vector2]:
	if _spawn_cache.has(realm_index):
		return _spawn_cache[realm_index]
	var points: Array[Vector2] = []
	for tile_offset in tile_offsets(realm_index):
		for point in maps[realm_index].spawns:
			points.append(to_world(realm_index, tile_offset + point))
	_spawn_cache[realm_index] = points
	return points

func pick_spawn(realm_index: int) -> Vector2:
	return get_spawn_points(realm_index).pick_random()

## Standing points on every platform, used by the bot path planner.
## Shared cached array: callers must not modify it.
func get_navigation_points(realm_index: int) -> Array[Vector2]:
	if _navigation_cache.has(realm_index):
		return _navigation_cache[realm_index]
	var points: Array[Vector2] = []
	var origin := get_origin(realm_index)
	for tile_offset in tile_offsets(realm_index):
		for platform_data in maps[realm_index].platforms:
			var platform: Dictionary = platform_data
			var center: Vector2 = origin + tile_offset + platform.center
			var stand_y: float = center.y - float(platform.size.y) * 0.5
			points.append(Vector2(center.x, stand_y))
			var half_width: float = float(platform.size.x) * 0.5
			if half_width >= 80.0 * GAME_SCALE.WORLD:
				var edge_offset: float = half_width - minf(34.0 * GAME_SCALE.WORLD, half_width * 0.25)
				points.append(Vector2(center.x - edge_offset, stand_y))
				points.append(Vector2(center.x + edge_offset, stand_y))
			if float(platform.size.x) >= 500.0 * GAME_SCALE.WORLD:
				var inset: float = minf(float(platform.size.x) * 0.32, 190.0 * GAME_SCALE.WORLD)
				points.append(Vector2(center.x - inset, stand_y))
				points.append(Vector2(center.x + inset, stand_y))
	_navigation_cache[realm_index] = points
	return points

## Grid neighbours that physically exist, regardless of their current state.
func get_neighbor_directions(realm_index: int) -> Array[Vector2i]:
	var directions: Array[Vector2i] = []
	var grid: Vector2i = maps[realm_index].grid
	for direction in PORTAL_LABELS:
		if find_by_grid(grid + direction) >= 0:
			directions.append(direction)
	return directions

## Where a combatant stands to use the portal toward `direction` (top of a platform).
func get_portal_stand_point(realm_index: int, direction: Vector2i) -> Vector2:
	return to_world(realm_index, maps[realm_index].portals[direction])

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
		var stand := get_portal_stand_point(realm_index, direction)
		portals.append({
			"source": realm_index,
			"destination": destination_index,
			"destination_state": destination_state,
			"direction": direction,
			"rect": Rect2(stand + Vector2(-70.0, -100.0), Vector2(140.0, 112.0)),
			"entry_position": get_portal_entry_position(destination_index, direction),
			"layout": {
				"position": stand + Vector2(0.0, -50.0),
				"support": stand,
				"label": PORTAL_LABELS[direction]
			}
		})
	return portals

## Travelling RIGHT arrives at the destination's LEFT portal, and so on.
func get_portal_entry_position(destination_index: int, direction: Vector2i) -> Vector2:
	return get_portal_stand_point(destination_index, -direction) + Vector2(0.0, -24.0)

## Gives a combatant everything it needs about its realm: spawns, bounds and blast lines.
func assign_combatant(combatant: Node, realm_index: int) -> void:
	combatant.set_realm(realm_index, get_spawn_points(realm_index), get_bounds(realm_index), get_ringout_y(realm_index), get_side_blast_lines(realm_index))
