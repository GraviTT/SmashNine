extends Node2D
## Realm gimmicks (design/ROADMAP.md M2), driven by each realm's "hazard" entry in
## RealmCatalog. Only playable realms run their hazard.
## - ice: lower floor traction for everyone standing in the realm (slides, longer knockback)
## - eruption: fire pillars rise from platform spots after a warning; a hit launches upward
## - quake: after a rumble warning, everyone on the ground is stunned and popped up;
##   jumping during the warning avoids it
## Timing uses a seeded RNG, so a match seed replays the same hazards.

signal shake_requested(realm_index: int, strength: float, duration: float)

const REALM_LAYOUT := preload("res://scripts/realms/RealmLayout.gd")
const PILLAR_COLOR := Color(1.0, 0.36, 0.08, 0.72)
const PILLAR_WARNING_COLOR := Color(1.0, 0.55, 0.12, 0.16)
const VENT_COLOR := Color(1.0, 0.5, 0.1, 0.9)
const RUMBLE_COLOR := Color(0.95, 0.78, 0.45, 0.85)
const DAMAGE_FIXED := "fixed"

var enabled := true
var layout: REALM_LAYOUT
var state_of: Callable
var combatants: Array[Node] = []
var _rng := RandomNumberGenerator.new()
## realm_index -> {"hazard": Dictionary, "phase": String, "timer": float, "next_in": float,
##                 "columns": Array[Rect2], "hit": Array[Node], "visuals": Array[Node]}
var _realms: Dictionary = {}

func setup(new_layout: REALM_LAYOUT, new_state_of: Callable, match_seed: int) -> void:
	layout = new_layout
	state_of = new_state_of
	_rng.seed = hash([match_seed, "realm_hazards"])
	_realms.clear()
	for realm_index in layout.realm_count():
		var hazard: Dictionary = layout.get_realm(realm_index).get("hazard", {})
		if hazard.is_empty():
			continue
		_realms[realm_index] = {"hazard": hazard, "phase": "idle", "timer": 0.0, "next_in": _next_interval(hazard), "columns": [], "hit": [], "visuals": []}

func register_combatant(combatant: Node) -> void:
	if not combatants.has(combatant):
		combatants.append(combatant)

func get_hazard_text(realm_index: int) -> String:
	if not _realms.has(realm_index):
		return ""
	return str(_realms[realm_index].hazard.get("text", ""))

func get_phase(realm_index: int) -> String:
	return str(_realms[realm_index].phase) if _realms.has(realm_index) else ""

func get_columns(realm_index: int) -> Array:
	return _realms[realm_index].columns if _realms.has(realm_index) else []

## Starts the realm's warning right away (debugging and tests).
func trigger(realm_index: int) -> void:
	if _realms.has(realm_index):
		_start_warning(realm_index)

func advance(delta: float) -> void:
	_update_traction()
	if not enabled:
		return
	for realm_index in _realms:
		var entry: Dictionary = _realms[realm_index]
		if not _is_playable(realm_index):
			if entry.phase != "idle":
				_end(realm_index)
			continue
		match str(entry.hazard.type):
			"eruption", "quake":
				_advance_timed(realm_index, entry, delta)

func _update_traction() -> void:
	for combatant in combatants:
		if not is_instance_valid(combatant):
			continue
		var traction := 1.0
		if enabled and _realms.has(combatant.realm_index) and _is_playable(combatant.realm_index):
			var hazard: Dictionary = _realms[combatant.realm_index].hazard
			if str(hazard.type) == "ice":
				traction = float(hazard.get("traction", 1.0))
		combatant.ground_traction = traction

func _advance_timed(realm_index: int, entry: Dictionary, delta: float) -> void:
	match str(entry.phase):
		"idle":
			entry.next_in = float(entry.next_in) - delta
			if entry.next_in <= 0.0:
				_start_warning(realm_index)
		"warning":
			entry.timer = float(entry.timer) - delta
			_pulse_visuals(entry)
			if entry.timer <= 0.0:
				_start_active(realm_index)
		"active":
			entry.timer = float(entry.timer) - delta
			if str(entry.hazard.type) == "eruption":
				_burn(realm_index, entry)
			if entry.timer <= 0.0:
				_end(realm_index)

func _start_warning(realm_index: int) -> void:
	var entry: Dictionary = _realms[realm_index]
	_clear_visuals(entry)
	entry.phase = "warning"
	entry.timer = float(entry.hazard.get("warning", 1.0))
	entry.hit = []
	match str(entry.hazard.type):
		"eruption":
			entry.columns = _pick_columns(realm_index, entry.hazard)
			for column in entry.columns:
				var rect: Rect2 = column
				entry.visuals.append(_rect_node(rect, PILLAR_WARNING_COLOR))
				entry.visuals.append(_rect_node(Rect2(rect.position.x, rect.end.y - 8.0, rect.size.x, 8.0), VENT_COLOR))
		"quake":
			for platform in _platform_rects(realm_index):
				var top: Rect2 = platform
				entry.visuals.append(_rect_node(Rect2(top.position.x, top.position.y - 10.0, top.size.x, 10.0), RUMBLE_COLOR))
			shake_requested.emit(realm_index, 3.0, float(entry.timer))

func _start_active(realm_index: int) -> void:
	var entry: Dictionary = _realms[realm_index]
	_clear_visuals(entry)
	entry.phase = "active"
	match str(entry.hazard.type):
		"eruption":
			entry.timer = float(entry.hazard.get("active", 0.6))
			for column in entry.columns:
				entry.visuals.append(_rect_node(column, PILLAR_COLOR))
			shake_requested.emit(realm_index, 4.0, 0.25)
		"quake":
			entry.timer = 0.0
			_quake(realm_index, entry.hazard)
			shake_requested.emit(realm_index, 9.0, 0.45)

func _end(realm_index: int) -> void:
	var entry: Dictionary = _realms[realm_index]
	_clear_visuals(entry)
	entry.phase = "idle"
	entry.columns = []
	entry.hit = []
	entry.next_in = _next_interval(entry.hazard)

## Fire pillars: each fighter is hit at most once per eruption.
func _burn(realm_index: int, entry: Dictionary) -> void:
	for combatant in _fighters_in(realm_index):
		if entry.hit.has(combatant):
			continue
		var body: Vector2 = combatant.global_position + Vector2(0.0, -32.0)
		for column in entry.columns:
			var rect: Rect2 = column
			if rect.grow_individual(21.0, 0.0, 21.0, 0.0).has_point(body):
				entry.hit.append(combatant)
				combatant.apply_hit(null, float(entry.hazard.damage), float(entry.hazard.knockback), Vector2(0.0, -1.0), DAMAGE_FIXED)
				break

## Everyone standing on the ground is stunned and popped up; airborne fighters are safe.
func _quake(realm_index: int, hazard: Dictionary) -> void:
	for combatant in _fighters_in(realm_index):
		if combatant.is_on_floor():
			combatant.apply_stun_hit(null, float(hazard.damage), float(hazard.pop), Vector2(0.0, -1.0), float(hazard.stun), DAMAGE_FIXED)

func _fighters_in(realm_index: int) -> Array[Node]:
	var result: Array[Node] = []
	for combatant in combatants:
		if is_instance_valid(combatant) and not combatant.is_defeated and combatant.realm_index == realm_index:
			result.append(combatant)
	return result

## Pillar spots on platform tops, weighted by platform width, never closer than 140 px.
func _pick_columns(realm_index: int, hazard: Dictionary) -> Array[Rect2]:
	var platforms := _platform_rects(realm_index)
	var columns: Array[Rect2] = []
	var width := float(hazard.get("width", 80.0))
	var height := float(hazard.get("height", 420.0))
	var total := 0.0
	for platform in platforms:
		total += platform.size.x
	for attempt in 12:
		if columns.size() >= int(hazard.get("count", 1)):
			break
		var pick := _rng.randf() * total
		for platform in platforms:
			pick -= platform.size.x
			if pick > 0.0:
				continue
			var x := _rng.randf_range(platform.position.x + width * 0.5, platform.end.x - width * 0.5)
			var too_close := false
			for other in columns:
				too_close = too_close or absf(other.get_center().x - x) < 140.0
			if not too_close:
				columns.append(Rect2(x - width * 0.5, platform.position.y - height, width, height))
			break
	return columns

## Platform rectangles in world space (top edge = standing height).
func _platform_rects(realm_index: int) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var origin: Vector2 = layout.get_origin(realm_index)
	for offset in layout.tile_offsets(realm_index):
		for platform in layout.get_realm(realm_index).platforms:
			var size: Vector2 = platform.size
			rects.append(Rect2(origin + offset + platform.center - size * 0.5, size))
	return rects

func _next_interval(hazard: Dictionary) -> float:
	var interval: Array = hazard.get("interval", [10.0, 10.0])
	return _rng.randf_range(float(interval[0]), float(interval[1]))

func _is_playable(realm_index: int) -> bool:
	var state: String = state_of.call(realm_index)
	return state == "stable" or state == "warning"

func _rect_node(rect: Rect2, color: Color) -> ColorRect:
	var node := ColorRect.new()
	node.position = rect.position
	node.size = rect.size
	node.color = color
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	return node

func _pulse_visuals(entry: Dictionary) -> void:
	var alpha := 0.55 + 0.45 * sin(float(entry.timer) * 18.0)
	for node in entry.visuals:
		if is_instance_valid(node):
			node.modulate.a = alpha

func _clear_visuals(entry: Dictionary) -> void:
	for node in entry.visuals:
		if is_instance_valid(node):
			node.queue_free()
	entry.visuals = []

## Text for the HUD while a hazard winds up in this realm; empty otherwise.
func get_warning_text(realm_index: int) -> String:
	if not enabled or not _realms.has(realm_index) or str(_realms[realm_index].phase) != "warning":
		return ""
	return str(_realms[realm_index].hazard.get("warn_text", ""))

## What bots may know about a realm's hazard right now (the same cues a player sees):
## {"type", "phase", "time_left", "columns"}; empty when nothing is happening.
func get_threat(realm_index: int) -> Dictionary:
	if not enabled or not _realms.has(realm_index):
		return {}
	var entry: Dictionary = _realms[realm_index]
	if str(entry.phase) == "idle":
		return {}
	return {"type": str(entry.hazard.type), "phase": str(entry.phase), "time_left": float(entry.timer), "columns": entry.columns}
