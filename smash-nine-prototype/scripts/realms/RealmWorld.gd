extends Node2D
## Scene nodes for the nine realms. Terrain (backdrops, platforms, connectors,
## portal supports) is built once per match; only the state overlays and portal
## visuals are rebuilt when a realm changes state.

const REALM_BACKDROP_SCRIPT := preload("res://scripts/RealmBackdrop.gd")
const REALM_LAYOUT := preload("res://scripts/realms/RealmLayout.gd")
const WORLD_LAYER := 1
const PLATFORM_MAIN := "main"
const PLATFORM_SUB := "sub"
const OVERLAY_Z := -10

var layout: REALM_LAYOUT
## Labels whose text Main refreshes every frame: [{"label": Label, "kind": "background"|"portal"}]
var countdown_displays: Array[Dictionary] = []
var _dynamic_roots: Array[Node2D] = []

func build(new_layout: REALM_LAYOUT, state_of: Callable, warning_index: int) -> void:
	layout = new_layout
	for child in get_children():
		child.queue_free()
	_dynamic_roots.clear()
	for i in layout.realm_count():
		var realm_root := Node2D.new()
		realm_root.name = "Realm_%d" % (i + 1)
		add_child(realm_root)
		var terrain := Node2D.new()
		terrain.name = "Terrain"
		realm_root.add_child(terrain)
		_build_terrain(terrain, i)
		var dynamic := Node2D.new()
		dynamic.name = "Dynamic"
		realm_root.add_child(dynamic)
		_dynamic_roots.append(dynamic)
	refresh_dynamic(state_of, warning_index)

func refresh_dynamic(state_of: Callable, warning_index: int) -> void:
	countdown_displays.clear()
	for i in _dynamic_roots.size():
		var dynamic := _dynamic_roots[i]
		for child in dynamic.get_children():
			child.queue_free()
		var state: String = state_of.call(i)
		_create_state_overlay(dynamic, i, state)
		if state == "stable" or state == "warning":
			for portal in layout.get_portals(i, state_of):
				_create_portal_visual(dynamic, portal.layout.position, portal.layout.label, portal.destination, portal.source, warning_index)

func _build_terrain(parent: Node2D, realm_index: int) -> void:
	var map: Dictionary = layout.get_realm(realm_index)
	var origin: Vector2 = layout.get_origin(realm_index)
	var backdrop := Node2D.new()
	backdrop.name = "Backdrop"
	backdrop.set_script(REALM_BACKDROP_SCRIPT)
	backdrop.z_index = -20
	backdrop.position = origin
	parent.add_child(backdrop)
	backdrop.configure(REALM_LAYOUT.REALM_SIZE, REALM_LAYOUT.BASE_REALM_SIZE, realm_index, map.background, map.accent)

	var header := Node2D.new()
	header.name = "Header"
	header.position = origin
	parent.add_child(header)
	var title := Label.new()
	title.text = "SMASH NINE REALMS - %s" % map.name
	title.position = Vector2(32, 22)
	title.add_theme_font_size_override("font_size", 28)
	header.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "%s | %s | Hazard: %s" % [map.subtitle, map.identity, map.hazard]
	subtitle.position = Vector2(34, 58)
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.modulate = Color(1.0, 1.0, 1.0, 0.75)
	header.add_child(subtitle)

	for tile_offset in layout.tile_offsets():
		for platform_data in map.platforms:
			var platform: Dictionary = platform_data
			var concept_tags: Array[String] = []
			for tag in platform.concept_tags:
				concept_tags.append(tag)
			_create_platform(parent, origin + tile_offset + platform.center, platform.size, platform.color, platform.role, concept_tags, realm_index)
		for point in map.spawns:
			_create_spawn_marker(parent, origin + tile_offset + point, map.accent)
	_create_realm_connectors(parent, origin, realm_index)
	# Supports stay even after a neighbour collapses so nobody loses the floor under them.
	for direction in layout.get_neighbor_directions(realm_index):
		_create_platform(parent, layout.get_portal_support_center(realm_index, direction), REALM_LAYOUT.PORTAL_SUPPORT_SIZE, Color(0.24, 0.28, 0.32), PLATFORM_MAIN, ["portal_support"])

func _create_realm_connectors(parent: Node2D, origin: Vector2, realm_index: int) -> void:
	var accent: Color = layout.get_realm(realm_index).accent
	var connector_color := Color(
		lerpf(0.22, accent.r, 0.22),
		lerpf(0.25, accent.g, 0.22),
		lerpf(0.3, accent.b, 0.22)
	)
	var base_size: Vector2 = REALM_LAYOUT.BASE_REALM_SIZE
	var horizontal_boundaries: Array[float] = [base_size.x, base_size.x * 2.0]
	var vertical_boundaries: Array[float] = [base_size.y, base_size.y * 2.0]
	for tile_y in REALM_LAYOUT.REALM_TILE_COUNT.y:
		var floor_y: float = origin.y + tile_y * base_size.y + 620.0
		for boundary_x in horizontal_boundaries:
			_create_platform(parent, Vector2(origin.x + boundary_x, floor_y), Vector2(280, 34), connector_color, PLATFORM_MAIN, ["realm_connector"], realm_index)
	for boundary_y in vertical_boundaries:
		for step in 4:
			var step_y: float = origin.y + boundary_y - 120.0 + step * 105.0
			var step_x: float = origin.x + REALM_LAYOUT.REALM_SIZE.x * 0.5 + (-150.0 if step % 2 == 0 else 150.0)
			_create_platform(parent, Vector2(step_x, step_y), Vector2(300, 30), connector_color, PLATFORM_SUB, ["realm_connector"], realm_index)

func _create_state_overlay(parent: Node2D, realm_index: int, state: String) -> void:
	if state == "stable":
		return
	var map: Dictionary = layout.get_realm(realm_index)
	var overlay_root := Node2D.new()
	overlay_root.name = "StateOverlay"
	overlay_root.position = layout.get_origin(realm_index)
	overlay_root.z_index = OVERLAY_Z
	parent.add_child(overlay_root)
	var realm_size: Vector2 = REALM_LAYOUT.REALM_SIZE
	var overlay := ColorRect.new()
	overlay.size = realm_size
	overlay.color = Color(0.95, 0.2, 0.08, 0.18) if state == "warning" else Color(0.0, 0.0, 0.0, 0.55)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_root.add_child(overlay)

	var label := _create_overlay_label(realm_size * 0.5 - Vector2(260, 70), map.accent)
	label.text = "COLLAPSE WARNING" if state == "warning" else "REALM CLOSED"
	overlay_root.add_child(label)
	if state != "warning":
		return
	countdown_displays.append({"label": label, "kind": "background"})
	var base_size: Vector2 = REALM_LAYOUT.BASE_REALM_SIZE
	for tile_y in REALM_LAYOUT.REALM_TILE_COUNT.y:
		for tile_x in REALM_LAYOUT.REALM_TILE_COUNT.x:
			if tile_x == 1 and tile_y == 1:
				continue
			var tile_label := _create_overlay_label(Vector2(tile_x * base_size.x, tile_y * base_size.y) + REALM_LAYOUT.VIEWPORT_CENTER - Vector2(260, 70), map.accent)
			overlay_root.add_child(tile_label)
			countdown_displays.append({"label": tile_label, "kind": "background"})

func _create_overlay_label(position: Vector2, accent: Color) -> Label:
	var label := Label.new()
	label.position = position
	label.size = Vector2(520, 140)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 38)
	label.modulate = accent
	return label

func _create_portal_visual(parent: Node2D, center: Vector2, label_text: String, destination_index: int, source_index: int, warning_index: int) -> void:
	var realm: Dictionary = layout.get_realm(destination_index)
	var frame := ColorRect.new()
	frame.size = REALM_LAYOUT.PORTAL_SIZE
	frame.position = center - REALM_LAYOUT.PORTAL_SIZE * 0.5
	frame.color = Color(realm.accent.r, realm.accent.g, realm.accent.b, 0.32)
	parent.add_child(frame)

	var core := ColorRect.new()
	core.size = Vector2(52, 52)
	core.position = center - core.size * 0.5
	core.color = Color(realm.accent.r, realm.accent.g, realm.accent.b, 0.72)
	parent.add_child(core)

	var label := Label.new()
	label.position = center + Vector2(-76, 48)
	label.size = Vector2(152, 34)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.text = "Q %s -> %s" % [label_text, realm.name]
	parent.add_child(label)

	if warning_index >= 0 and (source_index == warning_index or destination_index == warning_index):
		var countdown := Label.new()
		countdown.position = center + Vector2(-70, -92)
		countdown.size = Vector2(140, 42)
		countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		countdown.add_theme_font_size_override("font_size", 26)
		countdown.modulate = Color(1.0, 0.35, 0.16)
		parent.add_child(countdown)
		countdown_displays.append({"label": countdown, "kind": "portal"})

func _create_platform(parent: Node2D, center: Vector2, size: Vector2, color: Color, role: String = PLATFORM_SUB, concept_tags: Array[String] = [], realm_index := -1) -> void:
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
	var accent: Color = layout.get_realm(realm_index).accent if realm_index >= 0 and realm_index < layout.realm_count() else color.lightened(0.3)
	edge.color = Color(accent.r, accent.g, accent.b, 0.72 if role == PLATFORM_MAIN else 0.5)
	edge.size = Vector2(size.x, 5.0 if role == PLATFORM_MAIN else 3.0)
	edge.position = -size * 0.5
	body.add_child(edge)
	_add_platform_details(body, size, color, accent, realm_index)
	parent.add_child(body)

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

func _create_spawn_marker(parent: Node2D, point: Vector2, color: Color) -> void:
	var marker := ColorRect.new()
	marker.size = Vector2(16, 4)
	marker.position = point + Vector2(-8, -4)
	marker.color = Color(color.r, color.g, color.b, 0.55)
	parent.add_child(marker)
