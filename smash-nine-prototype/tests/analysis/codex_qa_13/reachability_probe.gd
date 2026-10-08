extends SceneTree

## QA-13: static geometry/physics audit for the 2026-10-08 scale change.
## This intentionally reads product constants and data without changing product code.

const GAME_SCALE := preload("res://scripts/GameScale.gd")
const REALM_CATALOG := preload("res://scripts/realms/RealmCatalog.gd")
const REALM_LAYOUT := preload("res://scripts/realms/RealmLayout.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

const GRAVITY := 1850.0 * GAME_SCALE.GRAVITY
const FALL_GRAVITY_MULTIPLIER := 1.18
const AIR_JUMP_SPEED_RATIO := 0.86
const NAV_SAME_LEVEL := 92.0 * GAME_SCALE.WORLD
const NAV_HORIZONTAL_REACH := 470.0 * GAME_SCALE.WORLD
const NAV_JUMP_RISE := 185.0 * GAME_SCALE.JUMP_HEIGHT
const NAV_JUMP_REACH := 470.0 * GAME_SCALE.WORLD
const NAV_DROP_DEPTH := 360.0 * GAME_SCALE.WORLD
const NAV_DROP_REACH := 470.0 * GAME_SCALE.WORLD
const NAV_DROP_MIN_HORIZONTAL := 86.0 * GAME_SCALE.WORLD


func _init() -> void:
	var layout := REALM_LAYOUT.new()
	var characters: Dictionary = CHARACTER_REGISTRY.get_characters()
	var authored: Array = REALM_CATALOG.build_maps()
	var result := {
		"scales": {
			"combat": GAME_SCALE.COMBAT,
			"world": GAME_SCALE.WORLD,
			"move": GAME_SCALE.MOVE,
			"gravity": GAME_SCALE.GRAVITY,
			"jump_speed": GAME_SCALE.JUMP_SPEED,
			"nav_jump_rise": NAV_JUMP_RISE
		},
		"characters": [],
		"realms": [],
		"anchor_audit": [],
		"spawn_separation": []
	}
	for character_id in characters:
		var data: Dictionary = characters[character_id]
		var jump_speed: float = absf(float(data.jump)) * GAME_SCALE.JUMP_SPEED
		var air_jumps: int = int(data.get("air_jumps", 1))
		var ground_height := jump_speed * jump_speed / (2.0 * GRAVITY)
		var air_height := pow(jump_speed * AIR_JUMP_SPEED_RATIO, 2.0) / (2.0 * GRAVITY)
		result.characters.append({
			"id": character_id,
			"speed": float(data.speed) * GAME_SCALE.MOVE,
			"jump_speed": jump_speed,
			"air_jumps": air_jumps,
			"ground_jump_height": ground_height,
			"all_jumps_height": ground_height + air_height * air_jumps
		})
	for realm_index in layout.realm_count():
		var platforms := _platforms(layout, realm_index)
		var realm_result := {
			"index": realm_index,
			"name": str(layout.get_realm(realm_index).name),
			"platforms": platforms.size(),
			"max_required_rise": _max_required_rise(platforms),
			"nav_jump_rise": NAV_JUMP_RISE,
			"nav_all_platforms_strongly_connected": _all_platforms_connected(platforms, Callable(self, "_ai_link"), {}),
			"characters": [],
			"frey_nav_links_exceed_ground_jump": []
		}
		for character_row: Dictionary in result.characters:
			var options := {
				"speed": float(character_row.speed),
				"jump_speed": float(character_row.jump_speed),
				"air_jumps": int(character_row.air_jumps)
			}
			var connected := _all_platforms_connected(platforms, Callable(self, "_fighter_link"), options)
			var ground_only := options.duplicate()
			ground_only.air_jumps = 0
			realm_result.characters.append({
				"id": character_row.id,
				"all_platforms_strongly_connected": connected,
				"ground_jump_only_strongly_connected": _all_platforms_connected(platforms, Callable(self, "_fighter_link"), ground_only),
				"ground_only_unreachable_from_lowest": _unreachable_from_lowest(platforms, Callable(self, "_fighter_link"), ground_only)
			})
			if str(character_row.id) == "frey":
				realm_result.frey_nav_links_exceed_ground_jump = _nav_ground_mismatches(platforms, ground_only)
		result.realms.append(realm_result)
		result.anchor_audit.append(_anchor_row(authored[realm_index], layout.get_realm(realm_index), realm_index))
		result.spawn_separation.append(_spawn_separation_row(authored[realm_index], layout.get_realm(realm_index), realm_index))
	print("QA13_REACHABILITY %s" % JSON.stringify(result))
	quit(0)


func _platforms(layout, realm_index: int) -> Array:
	var result: Array = []
	var map: Dictionary = layout.get_realm(realm_index)
	for tile_offset: Vector2 in layout.tile_offsets(realm_index):
		for platform_index in map.platforms.size():
			var platform: Dictionary = map.platforms[platform_index]
			var center: Vector2 = tile_offset + platform.center
			var size: Vector2 = platform.size
			result.append({
				"id": platform_index,
				"center": center,
				"top": center.y - size.y * 0.5,
				"left": center.x - size.x * 0.5,
				"right": center.x + size.x * 0.5,
				"size": size,
				"points": _navigation_points(center, size)
			})
	return result


func _navigation_points(center: Vector2, size: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var stand_y := center.y - size.y * 0.5
	result.append(Vector2(center.x, stand_y))
	var half_width := size.x * 0.5
	if half_width >= 80.0 * GAME_SCALE.WORLD:
		var edge_offset := half_width - minf(34.0 * GAME_SCALE.WORLD, half_width * 0.25)
		result.append(Vector2(center.x - edge_offset, stand_y))
		result.append(Vector2(center.x + edge_offset, stand_y))
	if size.x >= 500.0 * GAME_SCALE.WORLD:
		var inset := minf(size.x * 0.32, 190.0 * GAME_SCALE.WORLD)
		result.append(Vector2(center.x - inset, stand_y))
		result.append(Vector2(center.x + inset, stand_y))
	return result


func _all_platforms_connected(platforms: Array, link: Callable, options: Dictionary) -> bool:
	for start in platforms.size():
		var visited := {start: true}
		var queue: Array[int] = [start]
		while not queue.is_empty():
			var current: int = queue.pop_front()
			for candidate in platforms.size():
				if visited.has(candidate) or candidate == current:
					continue
				if link.call(platforms[current], platforms[candidate], options):
					visited[candidate] = true
					queue.append(candidate)
		if visited.size() != platforms.size():
			return false
	return true


func _unreachable_from_lowest(platforms: Array, link: Callable, options: Dictionary) -> Array[int]:
	var start := 0
	for index in platforms.size():
		if float(platforms[index].top) > float(platforms[start].top):
			start = index
	var visited := {start: true}
	var queue: Array[int] = [start]
	while not queue.is_empty():
		var current: int = queue.pop_front()
		for candidate in platforms.size():
			if visited.has(candidate) or candidate == current:
				continue
			if link.call(platforms[current], platforms[candidate], options):
				visited[candidate] = true
				queue.append(candidate)
	var result: Array[int] = []
	for index in platforms.size():
		if not visited.has(index):
			result.append(index)
	return result


func _nav_ground_mismatches(platforms: Array, fighter_options: Dictionary) -> Array:
	var result: Array = []
	for from_index in platforms.size():
		for to_index in platforms.size():
			if from_index == to_index:
				continue
			if _ai_link(platforms[from_index], platforms[to_index], {}) and not _fighter_link(platforms[from_index], platforms[to_index], fighter_options):
				var rise: float = float(platforms[from_index].top) - float(platforms[to_index].top)
				if rise > 0.0:
					result.append({"from": from_index, "to": to_index, "rise": rise, "horizontal_gap": _horizontal_gap(platforms[from_index], platforms[to_index])})
	return result


func _fighter_link(from: Dictionary, to: Dictionary, options: Dictionary) -> bool:
	var rise: float = float(from.top) - float(to.top)
	var jump_speed: float = float(options.jump_speed)
	var air_jumps: int = int(options.air_jumps)
	var ground_height := jump_speed * jump_speed / (2.0 * GRAVITY)
	var air_speed := jump_speed * AIR_JUMP_SPEED_RATIO
	var air_height := air_speed * air_speed / (2.0 * GRAVITY)
	var peak_height := ground_height + air_height * air_jumps
	if rise > peak_height:
		return false
	var ascent_time := jump_speed / GRAVITY + float(air_jumps) * air_speed / GRAVITY
	var descent_distance := maxf(peak_height - rise, 0.0)
	var descent_time := sqrt(2.0 * descent_distance / (GRAVITY * FALL_GRAVITY_MULTIPLIER))
	var horizontal_range := float(options.speed) * (ascent_time + descent_time)
	return _horizontal_gap(from, to) <= horizontal_range


func _ai_link(from: Dictionary, to: Dictionary, _options: Dictionary) -> bool:
	for from_point: Vector2 in from.points:
		for to_point: Vector2 in to.points:
			var delta := to_point - from_point
			var horizontal := absf(delta.x)
			if absf(delta.y) <= NAV_SAME_LEVEL and horizontal <= NAV_HORIZONTAL_REACH:
				return true
			if delta.y < 0.0 and -delta.y <= NAV_JUMP_RISE and horizontal <= NAV_JUMP_REACH:
				return true
			if delta.y > 0.0 and delta.y <= NAV_DROP_DEPTH and horizontal >= NAV_DROP_MIN_HORIZONTAL and horizontal <= NAV_DROP_REACH:
				return true
	return false


func _horizontal_gap(a: Dictionary, b: Dictionary) -> float:
	return maxf(0.0, maxf(float(a.left), float(b.left)) - minf(float(a.right), float(b.right)))


## Largest of the smallest upward steps available to each elevated platform. This is the
## authored "stair" rise, rather than the meaningless bottom-to-top direct rise.
func _max_required_rise(platforms: Array) -> float:
	var result := 0.0
	for target: Dictionary in platforms:
		var best := INF
		for source: Dictionary in platforms:
			var rise: float = float(source.top) - float(target.top)
			if rise <= 0.0 or _horizontal_gap(source, target) > NAV_JUMP_REACH:
				continue
			best = minf(best, rise)
		if best < INF:
			result = maxf(result, best)
	return result


func _anchor_row(authored: Dictionary, scaled: Dictionary, realm_index: int) -> Dictionary:
	var row := {"index": realm_index, "name": str(scaled.name), "portals": [], "spawns": [], "hazards": []}
	for side in authored.portals:
		var before: Vector2 = authored.portals[side]
		var after: Vector2 = scaled.portals[side]
		row.portals.append({
			"side": str(side),
			"before_ground_gap": _ground_gap(before, authored.platforms),
			"after_ground_gap": _ground_gap(after, scaled.platforms)
		})
	for index in authored.spawns.size():
		row.spawns.append({
			"index": index,
			"before_ground_gap": _ground_gap(authored.spawns[index], authored.platforms),
			"after_ground_gap": _ground_gap(scaled.spawns[index], scaled.platforms)
		})
	if authored.has("hazard") and str(authored.hazard.get("type", "")) == "bushes":
		for index in authored.hazard.spots.size():
			row.hazards.append({
				"kind": "bush_bottom",
				"index": index,
				"before_ground_gap": _ground_gap(authored.hazard.spots[index], authored.platforms),
				"after_ground_gap": _ground_gap(scaled.hazard.spots[index], scaled.platforms)
			})
	if authored.has("hazard") and str(authored.hazard.get("type", "")) == "vines":
		for index in authored.hazard.bridges.size():
			var before_rect: Rect2 = authored.hazard.bridges[index]
			var after_rect: Rect2 = scaled.hazard.bridges[index]
			row.hazards.append({
				"kind": "vine_top",
				"index": index,
				"before_ground_gap": _ground_gap(before_rect.position, authored.platforms),
				"after_ground_gap": _ground_gap(after_rect.position, scaled.platforms)
			})
	return row


## Positive means the point is above the nearest platform top; zero is exactly supported.
func _ground_gap(point: Vector2, platforms: Array) -> float:
	var best := INF
	for platform: Dictionary in platforms:
		var center: Vector2 = platform.center
		var size: Vector2 = platform.size
		if point.x < center.x - size.x * 0.5 or point.x > center.x + size.x * 0.5:
			continue
		var top := center.y - size.y * 0.5
		if top + 1.0 < point.y:
			continue
		best = minf(best, top - point.y)
	return best if best < INF else -INF


func _spawn_separation_row(authored: Dictionary, scaled: Dictionary, realm_index: int) -> Dictionary:
	var authored_valid := 0
	var current_valid := 0
	var intended_valid := 0
	for a in authored.spawns.size():
		for b in range(a + 1, authored.spawns.size()):
			if (authored.spawns[a] as Vector2).distance_to(authored.spawns[b]) >= 320.0:
				authored_valid += 1
			var distance: float = (scaled.spawns[a] as Vector2).distance_to(scaled.spawns[b])
			if distance >= 320.0:
				current_valid += 1
			if distance >= 320.0 * GAME_SCALE.WORLD:
				intended_valid += 1
	return {
		"index": realm_index,
		"name": str(scaled.name),
		"pairs_before_320": authored_valid,
		"pairs_after_current_320": current_valid,
		"pairs_after_world_480": intended_valid
	}
