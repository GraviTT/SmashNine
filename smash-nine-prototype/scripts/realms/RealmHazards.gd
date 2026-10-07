extends Node2D
## Realm gimmicks (design/ROADMAP.md M2), driven by each realm's "hazard" entry in
## RealmCatalog. Only playable realms run their hazard.
## - ice: lower floor traction for everyone standing in the realm (slides, longer knockback)
## - eruption: fire pillars rise from platform spots after a warning; a hit launches upward
## - quake: after a rumble warning, everyone on the ground is stunned and popped up;
##   jumping during the warning avoids it
## - beams: light columns fall on platform spots after a warning; a hit stuns in place
## - vines: after a sprouting warning a vine bridge grows across a gap for a while, then
##   withers (anyone standing on it drops)
## - bushes: a fighter inside a bush is concealed (faded, bots only notice within
##   notice_range); attacking or getting hit reveals them for a moment
## Timing uses a seeded RNG, so a match seed replays the same hazards.

signal shake_requested(realm_index: int, strength: float, duration: float)

const REALM_LAYOUT := preload("res://scripts/realms/RealmLayout.gd")
const PILLAR_COLOR := Color(1.0, 0.36, 0.08, 0.72)
const PILLAR_WARNING_COLOR := Color(1.0, 0.55, 0.12, 0.16)
const VENT_COLOR := Color(1.0, 0.5, 0.1, 0.9)
const RUMBLE_COLOR := Color(0.95, 0.78, 0.45, 0.85)
const DAMAGE_FIXED := "fixed"
const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
const BUSH_ART := "res://assets/art/realm_midgard/bush.png"
## Hazard effect art (CODEX-ART-07); coloured rects remain the fallback.
const FIRE_PILLAR_ART := "res://assets/art/hazards/fire_pillar.png"
const LIGHT_BEAM_ART := "res://assets/art/hazards/light_beam.png"
const VENT_GLYPH_ART := "res://assets/art/hazards/vent_glyph.png"
const VINE_BRIDGE_ART := "res://assets/art/hazards/vine_bridge.png"
const BEAM_GLYPH_TINT := Color(1.0, 0.92, 0.55)
const BEAM_COLOR := Color(1.0, 0.95, 0.62, 0.72)
const BEAM_WARNING_COLOR := Color(1.0, 0.9, 0.5, 0.14)
const BEAM_GLYPH_COLOR := Color(1.0, 0.86, 0.42, 0.9)
const VINE_COLOR := Color(0.3, 0.72, 0.32)
const VINE_DARK_COLOR := Color(0.14, 0.38, 0.17)
const WORLD_LAYER := 1
const BUSH_COLORS: Array[Color] = [Color(0.16, 0.42, 0.18), Color(0.22, 0.55, 0.22), Color(0.3, 0.66, 0.28)]

var enabled := true
var layout: REALM_LAYOUT
var state_of: Callable
var combatants: Array[Node] = []
var _rng := RandomNumberGenerator.new()
## realm_index -> {"hazard": Dictionary, "phase": String, "timer": float, "next_in": float,
##                 "columns": Array[Rect2], "hit": Array[Node], "visuals": Array[Node]}
var _realms: Dictionary = {}
## combatant -> seconds left before an attacker or a hit fighter can hide again
var _revealed: Dictionary = {}

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
		if str(hazard.type) == "bushes":
			_realms[realm_index]["bushes"] = _bush_rects(realm_index, hazard)
			_realms[realm_index]["visuals"] = _bush_visuals(_realms[realm_index].bushes)

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
	_update_concealment(delta)
	if not enabled:
		return
	for realm_index in _realms:
		var entry: Dictionary = _realms[realm_index]
		if not _is_playable(realm_index):
			if entry.phase != "idle":
				_end(realm_index)
			continue
		match str(entry.hazard.type):
			"eruption", "quake", "beams", "vines":
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

func get_bushes(realm_index: int) -> Array:
	return _realms[realm_index].get("bushes", []) if _realms.has(realm_index) else []

## Who is hidden right now. Off, unplayable or revealed means visible.
func _update_concealment(delta: float) -> void:
	for combatant in combatants:
		if not is_instance_valid(combatant):
			continue
		var left := maxf(float(_revealed.get(combatant, 0.0)) - delta, 0.0)
		if combatant.attack_lock_timer > 0.0 or combatant.hitstun_timer > 0.0:
			left = float(_bush_hazard(combatant.realm_index).get("reveal", 0.8))
		_revealed[combatant] = left
		var hidden := false
		if enabled and left <= 0.0 and not combatant.is_defeated and _is_playable(combatant.realm_index):
			var body_point: Vector2 = combatant.global_position + Vector2(0, -24)
			for bush in get_bushes(combatant.realm_index):
				hidden = hidden or (bush as Rect2).has_point(body_point)
		combatant.set_concealed(hidden)
	for realm_index in _realms:
		var entry: Dictionary = _realms[realm_index]
		if entry.has("bushes"):
			var show := enabled and _is_playable(realm_index)
			for node in entry.visuals:
				if is_instance_valid(node):
					node.visible = show

func _bush_hazard(realm_index: int) -> Dictionary:
	if _realms.has(realm_index) and str(_realms[realm_index].hazard.type) == "bushes":
		return _realms[realm_index].hazard
	return {}

func _bush_rects(realm_index: int, hazard: Dictionary) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var size: Vector2 = hazard.get("size", Vector2(150, 64))
	var origin: Vector2 = layout.get_origin(realm_index)
	for spot in hazard.get("spots", []):
		var bottom: Vector2 = origin + spot
		rects.append(Rect2(bottom.x - size.x * 0.5, bottom.y - size.y + 4.0, size.x, size.y))
	return rects

## Drawn in front of fighters (this node sits above them). Original art when present,
## otherwise a clump of leafy blobs.
func _bush_visuals(rects: Array[Rect2]) -> Array[Node]:
	var nodes: Array[Node] = []
	var texture := ART_SETTINGS.original_texture(BUSH_ART)
	for rect in rects:
		var bush := Node2D.new()
		bush.name = "Bush"
		bush.position = rect.position
		if texture != null:
			var sprite := Sprite2D.new()
			sprite.texture = texture
			sprite.centered = false
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.scale = rect.size / texture.get_size()
			bush.add_child(sprite)
		else:
			for blob in 7:
				var leaf := Polygon2D.new()
				var radius := rect.size.y * (0.34 + 0.06 * float(blob % 3))
				var center := Vector2(rect.size.x * (0.12 + 0.76 * blob / 6.0), rect.size.y - radius * 0.9 - float(blob % 2) * 8.0)
				var points := PackedVector2Array()
				for step in 10:
					var angle := TAU * step / 10.0
					points.append(center + Vector2(cos(angle) * radius * 1.15, sin(angle) * radius))
				leaf.polygon = points
				leaf.color = BUSH_COLORS[blob % BUSH_COLORS.size()]
				bush.add_child(leaf)
		add_child(bush)
		nodes.append(bush)
	return nodes

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
			if str(entry.hazard.type) == "eruption" or str(entry.hazard.type) == "beams":
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
				entry.visuals.append(_art_node(Rect2(rect.position.x, rect.end.y - 12.0, rect.size.x, 16.0), VENT_GLYPH_ART, VENT_COLOR))
				entry.visuals.append(_particles(Rect2(rect.position.x, rect.end.y - 10.0, rect.size.x, 6.0), Color(1.0, 0.6, 0.2, 0.9), 10, 0.5, 90.0, false))
		"quake":
			for platform in _platform_rects(realm_index):
				var top: Rect2 = platform
				entry.visuals.append(_rect_node(Rect2(top.position.x, top.position.y - 10.0, top.size.x, 10.0), RUMBLE_COLOR))
			shake_requested.emit(realm_index, 3.0, float(entry.timer))
		"beams":
			entry.columns = _pick_columns(realm_index, entry.hazard)
			for column in entry.columns:
				var rect: Rect2 = column
				entry.visuals.append(_rect_node(rect, BEAM_WARNING_COLOR))
				entry.visuals.append(_art_node(Rect2(rect.position.x, rect.end.y - 12.0, rect.size.x, 16.0), VENT_GLYPH_ART, BEAM_GLYPH_COLOR, BEAM_GLYPH_TINT))
		"vines":
			var bridges: Array = entry.hazard.get("bridges", [])
			var local: Rect2 = bridges[_rng.randi_range(0, bridges.size() - 1)]
			var rect := Rect2(layout.get_origin(realm_index) + local.position, local.size)
			entry.columns = [rect]
			for end_x in [rect.position.x, rect.end.x - 24.0]:
				entry.visuals.append(_particles(Rect2(end_x, rect.position.y, 24.0, rect.size.y), Color(0.45, 0.9, 0.4, 0.9), 12, 0.6, 60.0, false))

func _start_active(realm_index: int) -> void:
	var entry: Dictionary = _realms[realm_index]
	_clear_visuals(entry)
	entry.phase = "active"
	match str(entry.hazard.type):
		"eruption":
			entry.timer = float(entry.hazard.get("active", 0.6))
			for column in entry.columns:
				# The flame art is narrower than the hit zone: a faint band shows the full width.
				entry.visuals.append(_rect_node(column, Color(PILLAR_COLOR, 0.2)))
				entry.visuals.append(_art_node(column, FIRE_PILLAR_ART, PILLAR_COLOR))
				entry.visuals.append(_particles(column, Color(1.0, 0.82, 0.35, 0.95), 40, 0.6, 520.0, false))
			shake_requested.emit(realm_index, 4.0, 0.25)
		"beams":
			entry.timer = float(entry.hazard.get("active", 0.5))
			for column in entry.columns:
				entry.visuals.append(_rect_node(column, Color(BEAM_COLOR, 0.2)))
				entry.visuals.append(_art_node(column, LIGHT_BEAM_ART, BEAM_COLOR))
				entry.visuals.append(_particles(column, Color(1.0, 0.95, 0.7, 0.95), 30, 0.5, -420.0, false))
			shake_requested.emit(realm_index, 3.0, 0.2)
		"vines":
			entry.timer = float(entry.hazard.get("active", 9.0))
			for column in entry.columns:
				entry.visuals.append(_vine_bridge(column))
		"quake":
			entry.timer = 0.0
			_quake(realm_index, entry.hazard)
			for platform in _platform_rects(realm_index):
				var top: Rect2 = platform
				_particles(Rect2(top.position.x, top.position.y - 4.0, top.size.x, 4.0), Color(0.82, 0.72, 0.55, 0.85), clampi(int(top.size.x / 18.0), 6, 40), 0.7, 160.0, true).finished.connect(_free_finished)
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
				if entry.hazard.has("stun"):
					combatant.apply_stun_hit(null, float(entry.hazard.damage), float(entry.hazard.knockback), Vector2(0.0, 1.0), float(entry.hazard.stun), DAMAGE_FIXED)
				else:
					combatant.apply_hit(null, float(entry.hazard.damage), float(entry.hazard.knockback), Vector2(0.0, -1.0), DAMAGE_FIXED)
				break

## Everyone standing on the ground is stunned and popped up; airborne fighters are safe.
func _quake(realm_index: int, hazard: Dictionary) -> void:
	for combatant in _fighters_in(realm_index):
		if combatant.is_on_floor():
			combatant.apply_stun_hit(null, float(hazard.damage), float(hazard.pop), Vector2(0.0, -1.0), float(hazard.stun), DAMAGE_FIXED)

## A one-way vine platform (like a thin sub platform) that lives as one of the hazard's
## visuals, so ending the hazard removes it.
func _vine_bridge(rect: Rect2) -> Node:
	var bridge := StaticBody2D.new()
	bridge.name = "VineBridge"
	bridge.collision_layer = WORLD_LAYER
	bridge.collision_mask = 0
	bridge.add_to_group("platforms")
	bridge.add_to_group("vine_bridges")
	bridge.add_to_group("sub_platforms")
	bridge.set_meta("platform_role", "sub")
	bridge.set_meta("allows_drop_through", true)
	bridge.position = rect.get_center()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.one_way_collision = true
	shape.one_way_collision_margin = 12.0
	bridge.add_child(shape)
	var art := ART_SETTINGS.original_texture(VINE_BRIDGE_ART)
	if art != null:
		var strip := NinePatchRect.new()
		strip.texture = art
		strip.position = -rect.size * 0.5
		strip.size = rect.size
		strip.patch_margin_left = 24
		strip.patch_margin_right = 24
		strip.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
		strip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bridge.add_child(strip)
	var stem := ColorRect.new()
	stem.color = VINE_DARK_COLOR
	stem.visible = art == null
	stem.size = rect.size
	stem.position = -rect.size * 0.5
	bridge.add_child(stem)
	var top := ColorRect.new()
	top.color = VINE_COLOR
	top.visible = art == null
	top.size = Vector2(rect.size.x, 6.0)
	top.position = Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5)
	bridge.add_child(top)
	for leaf in int(rect.size.x / 28.0):
		var bud := Polygon2D.new()
		var x := -rect.size.x * 0.5 + 14.0 + leaf * 28.0
		bud.polygon = PackedVector2Array([Vector2(x - 6, -rect.size.y * 0.5), Vector2(x, -rect.size.y * 0.5 - 9), Vector2(x + 6, -rect.size.y * 0.5)])
		bud.color = VINE_COLOR.lightened(0.15)
		bud.visible = art == null
		bridge.add_child(bud)
	# Drawn with the platforms, behind fighters (this node sits above them).
	bridge.z_as_relative = false
	bridge.z_index = 0
	bridge.scale = Vector2(0.2, 1.0)
	add_child(bridge)
	bridge.create_tween().tween_property(bridge, "scale", Vector2.ONE, 0.35)
	return bridge

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

## Original effect art stretched over a rect (caps > 0: a 3-slice strip
## tiled across instead); the coloured rect when the art is missing or the prototype style is on.
func _art_node(rect: Rect2, path: String, fallback: Color, tint := Color.WHITE, caps := 0) -> Control:
	var texture := ART_SETTINGS.original_texture(path)
	if texture == null:
		return _rect_node(rect, fallback)
	var strip := NinePatchRect.new()
	strip.texture = texture
	strip.position = rect.position
	strip.size = rect.size
	strip.patch_margin_left = caps
	strip.patch_margin_right = caps
	strip.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT if caps > 0 else NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	# One stretched column: tiled, every 128 px repeat showed its own base.
	strip.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	strip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	strip.modulate = tint
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)
	return strip

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

## Particle burst or stream over a world rect (CPU particles: web/Compatibility safe).
func _particles(rect: Rect2, color: Color, amount: int, lifetime: float, rise: float, one_shot: bool) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.position = rect.get_center()
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = rect.size * 0.5
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = one_shot
	particles.explosiveness = 0.9 if one_shot else 0.0
	particles.direction = Vector2(0.0, -1.0)
	particles.spread = 25.0
	particles.gravity = Vector2(0.0, -rise * 0.5 if rise > 0.0 else 600.0)
	particles.initial_velocity_min = absf(rise) * 0.6
	particles.initial_velocity_max = absf(rise)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = color
	particles.emitting = true
	add_child(particles)
	return particles

func _free_finished() -> void:
	for child in get_children():
		if child is CPUParticles2D and child.one_shot and not child.emitting:
			child.queue_free()
