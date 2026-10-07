extends Node2D
## Scene nodes for the nine realms. Terrain (backdrop, platforms, header) is built
## once per match; state overlays and portal visuals are rebuilt when a realm
## changes state; the sudden-death band is resized every frame while active.

const REALM_BACKDROP_SCRIPT := preload("res://scripts/RealmBackdrop.gd")
const REALM_LAYOUT := preload("res://scripts/realms/RealmLayout.gd")
const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
const WORLD_LAYER := 1
const PLATFORM_MAIN := "main"
const PLATFORM_SUB := "sub"
const OVERLAY_Z := -10
const HAZARD_Z := 4
const HAZARD_COLOR := Color(0.85, 0.08, 0.12, 0.34)
const BACKDROP_MARGIN := 320.0

var layout: REALM_LAYOUT
## Portal countdown labels whose text Main refreshes every frame: [{"label": Label, "kind": "portal"}]
var countdown_displays: Array[Dictionary] = []
var _dynamic_roots: Array[Node2D] = []
var _hazard_rects: Dictionary = {}

func build(new_layout: REALM_LAYOUT, state_of: Callable, is_warning: Callable) -> void:
	layout = new_layout
	for child in get_children():
		child.queue_free()
	_dynamic_roots.clear()
	_hazard_rects.clear()
	for i in layout.realm_count():
		var realm_root := Node2D.new()
		realm_root.name = "Realm_%d_%s" % [i + 1, layout.get_realm(i).name]
		add_child(realm_root)
		var terrain := Node2D.new()
		terrain.name = "Terrain"
		realm_root.add_child(terrain)
		_build_terrain(terrain, i)
		var dynamic := Node2D.new()
		dynamic.name = "Dynamic"
		realm_root.add_child(dynamic)
		_dynamic_roots.append(dynamic)
		_create_hazard_band(realm_root, i)
	refresh_dynamic(state_of, is_warning)

func refresh_dynamic(state_of: Callable, is_warning: Callable) -> void:
	countdown_displays.clear()
	for i in _dynamic_roots.size():
		var dynamic := _dynamic_roots[i]
		for child in dynamic.get_children():
			child.queue_free()
		var state: String = state_of.call(i)
		_create_state_overlay(dynamic, i, state)
		if state == "stable" or state == "warning":
			for portal in layout.get_portals(i, state_of):
				var warned: bool = is_warning.call(portal.source) or is_warning.call(portal.destination)
				_create_portal_visual(dynamic, portal.layout.position, portal.layout.label, portal.destination, portal.source, warned)

## Shows the deadly zones outside [safe_left, safe_right] (world x) in a realm; pass an empty band to hide.
func set_hazard_band(realm_index: int, safe_left: float, safe_right: float) -> void:
	var rects: Array = _hazard_rects.get(realm_index, [])
	if rects.is_empty():
		return
	var bounds: Rect2 = layout.get_bounds(realm_index)
	var visible_band := safe_right > safe_left
	var left_rect: ColorRect = rects[0]
	var right_rect: ColorRect = rects[1]
	left_rect.visible = visible_band
	right_rect.visible = visible_band
	if not visible_band:
		return
	var top := bounds.position.y - BACKDROP_MARGIN
	var height := bounds.size.y + BACKDROP_MARGIN * 2.0
	var outer_left := bounds.position.x - BACKDROP_MARGIN
	var outer_right := bounds.end.x + BACKDROP_MARGIN
	left_rect.position = Vector2(outer_left, top)
	left_rect.size = Vector2(maxf(safe_left - outer_left, 0.0), height)
	right_rect.position = Vector2(safe_right, top)
	right_rect.size = Vector2(maxf(outer_right - safe_right, 0.0), height)

func _create_hazard_band(parent: Node2D, realm_index: int) -> void:
	var rects: Array = []
	for side in 2:
		var rect := ColorRect.new()
		rect.name = "HazardLeft" if side == 0 else "HazardRight"
		rect.color = HAZARD_COLOR
		rect.z_index = HAZARD_Z
		rect.visible = false
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(rect)
		rects.append(rect)
	_hazard_rects[realm_index] = rects

func _build_terrain(parent: Node2D, realm_index: int) -> void:
	var map: Dictionary = layout.get_realm(realm_index)
	var origin: Vector2 = layout.get_origin(realm_index)
	var backdrop := Node2D.new()
	backdrop.name = "Backdrop"
	backdrop.set_script(REALM_BACKDROP_SCRIPT)
	backdrop.z_index = -20
	backdrop.position = origin
	parent.add_child(backdrop)
	backdrop.configure(layout.get_size(realm_index), layout.get_tile_size(realm_index), str(map.theme), map.background, map.accent, BACKDROP_MARGIN)
	_add_painted_backdrop(parent, realm_index, backdrop)

	var decor := _get_decor(str(map.theme))
	for tile_offset in layout.tile_offsets(realm_index):
		for platform_data in map.platforms:
			var platform: Dictionary = platform_data
			var concept_tags: Array[String] = []
			for tag in platform.concept_tags:
				concept_tags.append(tag)
			var body := _create_platform(parent, origin + tile_offset + platform.center, platform.size, platform.color, platform.role, concept_tags, map.accent, decor)
			_paint_platform(body, realm_index, platform.role, platform.size)

## Original art (ArtSettings): bg_far + bg_mid stretched over the realm in front of the
## procedural backdrop, which stays as the fallback and fills the margin around it.
func _add_painted_backdrop(parent: Node2D, realm_index: int, backdrop: Node2D) -> void:
	var realm_size: Vector2 = layout.get_size(realm_index)
	var layers := 0
	for layer in ["bg_far", "bg_mid"]:
		var texture := _realm_art(realm_index, layer)
		if texture == null:
			continue
		var rect := TextureRect.new()
		rect.name = "Painted_%s" % layer
		rect.texture = texture
		rect.position = layout.get_origin(realm_index)
		rect.size = realm_size
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rect.z_index = -19 + layers
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(rect)
		layers += 1
	if layers > 0:
		backdrop.set_meta("painted_over", true)

## Original art for a platform: a 3-slice strip (caps + tiled middle) replaces the coloured
## rectangles but keeps the same collision body.
func _paint_platform(body: Node2D, realm_index: int, role: String, size: Vector2) -> void:
	var texture := _realm_art(realm_index, "platform_main" if role == PLATFORM_MAIN else "platform_sub")
	if texture == null:
		return
	for child in body.get_children():
		if child is CanvasItem and child.name != "Edge":
			child.visible = false
	var art: Dictionary = layout.get_realm(realm_index).art
	var cap := int(art.get("cap_main", 16) if role == PLATFORM_MAIN else art.get("cap_sub", 16))
	var strip := NinePatchRect.new()
	strip.name = "PaintedPlatform"
	strip.texture = texture
	strip.patch_margin_left = cap
	strip.patch_margin_right = cap
	strip.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	strip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	strip.position = -size * 0.5
	strip.size = size
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(strip)
	# The accent edge stays on top: walkable surfaces must read against busy painted backgrounds.
	var edge := body.get_node_or_null("Edge")
	if edge != null:
		body.move_child(edge, -1)

func _realm_art(realm_index: int, art_name: String) -> Texture2D:
	var art: Dictionary = layout.get_realm(realm_index).get("art", {})
	if art.is_empty():
		return null
	return ART_SETTINGS.original_texture("%s/%s.png" % [art.dir, art_name])

func _get_decor(theme: String) -> String:
	match theme:
		"sunken_temple":
			return "moss"
		"ember_ring":
			return "cracks"
		"frost_steps":
			return "icicles"
		"gravity_well":
			return "nodes"
		"market_rooftops":
			return "tiles"
		"starfall_shrine":
			return "rune"
		"skyline_spires":
			return "rivets"
	return ""

func _create_state_overlay(parent: Node2D, realm_index: int, state: String) -> void:
	if state == "stable":
		return
	var map: Dictionary = layout.get_realm(realm_index)
	var realm_size: Vector2 = layout.get_size(realm_index)
	var overlay_root := Node2D.new()
	overlay_root.name = "StateOverlay"
	overlay_root.position = layout.get_origin(realm_index)
	overlay_root.z_index = OVERLAY_Z
	parent.add_child(overlay_root)
	var overlay := ColorRect.new()
	overlay.position = Vector2(-BACKDROP_MARGIN, -BACKDROP_MARGIN)
	overlay.size = realm_size + Vector2.ONE * BACKDROP_MARGIN * 2.0
	overlay.color = Color(0.95, 0.2, 0.08, 0.18) if state == "warning" else Color(0.0, 0.0, 0.0, 0.55)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_root.add_child(overlay)

	# The warning countdown is a HUD banner; only closed realms get an in-world label.
	if state == "warning":
		return
	var label := Label.new()
	label.position = realm_size * 0.5 - Vector2(260, 110)
	label.size = Vector2(520, 140)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 38)
	label.modulate = map.accent
	label.text = "SEALED" if state == "locked" else "REALM COLLAPSED"
	overlay_root.add_child(label)

func _create_portal_visual(parent: Node2D, center: Vector2, label_text: String, destination_index: int, source_index: int, warned: bool) -> void:
	var realm: Dictionary = layout.get_realm(destination_index)
	var painted := _realm_art(source_index, "portal")
	if painted != null:
		# Original art: the portal sprite tinted toward the destination realm's colour.
		var sprite := TextureRect.new()
		sprite.texture = painted
		sprite.size = REALM_LAYOUT.PORTAL_SIZE
		sprite.position = center - REALM_LAYOUT.PORTAL_SIZE * 0.5
		sprite.stretch_mode = TextureRect.STRETCH_SCALE
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.modulate = Color.WHITE.lerp(realm.accent, 0.35)
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(sprite)
	else:
		var frame := ColorRect.new()
		frame.size = REALM_LAYOUT.PORTAL_SIZE
		frame.position = center - REALM_LAYOUT.PORTAL_SIZE * 0.5
		frame.color = Color(realm.accent.r, realm.accent.g, realm.accent.b, 0.26)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(frame)

		var core := ColorRect.new()
		core.size = Vector2(46, 46)
		core.position = center - core.size * 0.5
		core.color = Color(realm.accent.r, realm.accent.g, realm.accent.b, 0.62)
		core.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(core)

	var label := Label.new()
	label.position = center + Vector2(-80, -78)
	label.size = Vector2(160, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.text = "Q %s: %s" % [label_text, realm.name]
	parent.add_child(label)

	if warned:
		var countdown := Label.new()
		countdown.position = center + Vector2(-70, -112)
		countdown.size = Vector2(140, 36)
		countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		countdown.add_theme_font_size_override("font_size", 24)
		countdown.modulate = Color(1.0, 0.35, 0.16)
		parent.add_child(countdown)
		countdown_displays.append({"label": countdown, "kind": "portal"})

func _create_platform(parent: Node2D, center: Vector2, size: Vector2, color: Color, role: String, concept_tags: Array[String], accent: Color, decor: String) -> StaticBody2D:
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
	rect.size = size
	shape.shape = rect
	shape.one_way_collision = role == PLATFORM_SUB
	shape.one_way_collision_margin = 12.0 if role == PLATFORM_SUB else 0.0
	body.position = center
	body.add_child(shape)
	var visual := ColorRect.new()
	visual.color = color
	visual.size = size
	visual.position = -size * 0.5
	body.add_child(visual)
	var underside := ColorRect.new()
	underside.color = color.darkened(0.42)
	underside.size = Vector2(size.x, maxf(size.y * 0.38, 8.0))
	underside.position = Vector2(-size.x * 0.5, size.y * 0.5 - underside.size.y)
	body.add_child(underside)
	var edge := ColorRect.new()
	edge.name = "Edge"
	edge.color = Color(accent.r, accent.g, accent.b, 0.72 if role == PLATFORM_MAIN else 0.5)
	edge.size = Vector2(size.x, 5.0 if role == PLATFORM_MAIN else 3.0)
	edge.position = -size * 0.5
	body.add_child(edge)
	_add_platform_details(body, size, color, accent, decor)
	parent.add_child(body)
	return body

func _add_platform_details(body: Node2D, size: Vector2, base_color: Color, accent: Color, decor: String) -> void:
	var segment_count := clampi(int(size.x / 78.0), 2, 12)
	for index in range(1, segment_count):
		var seam := ColorRect.new()
		seam.color = Color(base_color.r * 0.55, base_color.g * 0.55, base_color.b * 0.55, 0.42)
		seam.size = Vector2(2, maxf(size.y - 9.0, 4.0))
		seam.position = Vector2(-size.x * 0.5 + size.x * float(index) / float(segment_count), -size.y * 0.5 + 7)
		body.add_child(seam)
	match decor:
		"moss":
			for index in mini(segment_count, 8):
				var moss := ColorRect.new()
				moss.color = Color(0.2, 0.62, 0.36, 0.48)
				moss.size = Vector2(18 + index % 3 * 7, 3 + index % 2 * 4)
				moss.position = Vector2(-size.x * 0.5 + 18 + index * size.x / float(mini(segment_count, 8)), -size.y * 0.5 + 4)
				body.add_child(moss)
		"cracks":
			for index in mini(segment_count, 7):
				var crack := Line2D.new()
				crack.width = 2.0
				crack.default_color = Color(accent.r, accent.g, accent.b, 0.55)
				var x := -size.x * 0.5 + 28 + index * size.x / float(mini(segment_count, 7))
				crack.points = PackedVector2Array([Vector2(x, -size.y * 0.5 + 8), Vector2(x + 8, -2), Vector2(x + 2, size.y * 0.5 - 5)])
				body.add_child(crack)
		"icicles":
			for index in mini(segment_count, 9):
				var icicle := Polygon2D.new()
				var x := -size.x * 0.5 + 20 + index * size.x / float(mini(segment_count, 9))
				icicle.polygon = PackedVector2Array([Vector2(x, size.y * 0.5 - 4), Vector2(x + 13, size.y * 0.5 - 4), Vector2(x + 7, size.y * 0.5 + 10 + index % 3 * 5)])
				icicle.color = Color(accent.r, accent.g, accent.b, 0.48)
				body.add_child(icicle)
		"nodes", "rivets":
			for index in mini(segment_count, 8):
				var node := ColorRect.new()
				node.color = Color(accent.r, accent.g, accent.b, 0.7)
				node.size = Vector2(5, 5)
				node.position = Vector2(-size.x * 0.5 + 22 + index * size.x / float(mini(segment_count, 8)), -2)
				body.add_child(node)
		"tiles":
			for index in mini(segment_count, 10):
				var tile := ColorRect.new()
				tile.color = Color(0.65, 0.28, 0.13, 0.42)
				tile.size = Vector2(24, 4)
				tile.position = Vector2(-size.x * 0.5 + 12 + index * size.x / float(mini(segment_count, 10)), -size.y * 0.5 + 5)
				body.add_child(tile)
		"rune":
			var center_rune := ColorRect.new()
			center_rune.color = Color(accent.r, accent.g, accent.b, 0.8)
			center_rune.size = Vector2(20, 4)
			center_rune.position = Vector2(-10, -2)
			body.add_child(center_rune)
