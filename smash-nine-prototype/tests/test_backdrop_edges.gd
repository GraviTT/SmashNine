extends SceneTree
## The painted realm backgrounds reach as far as the camera can look (UI audit 2026-11-25, B8).
## The camera shows up to Main.CAMERA_EDGE_PADDING beyond a realm's edge, more during a shake,
## and the paintings ended at the edge: beside Asgard a dark strip showed, beside Niflheim a flat
## triangle of the procedural backdrop. Each painted layer now has a mirrored continuation under
## it; the painting itself keeps its place and size.

const MAIN := preload("res://scripts/Main.gd")
const REALM_WORLD := preload("res://scripts/realms/RealmWorld.gd")
const REALM_LAYOUT := preload("res://scripts/realms/RealmLayout.gd")
## The strongest camera shake (the Jotunheim quake) is 9 px.
const SHAKE_ROOM := 16.0

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _run() -> void:
	var layout := REALM_LAYOUT.new()
	var world: Node2D = REALM_WORLD.new()
	root.add_child(world)
	world.build(layout, func(_index: int) -> String: return "stable", func(_index: int) -> bool: return false)
	await process_frame
	var reach := MAIN.CAMERA_EDGE_PADDING + SHAKE_ROOM
	var layers := 0
	for index in layout.realm_count():
		var realm_root := world.get_child(index)
		var realm_name := str(layout.get_realm(index).name)
		var seen := layout.get_bounds(index).grow(reach)
		for painted: TextureRect in realm_root.find_children("Painted_bg_*", "TextureRect", true, false):
			layers += 1
			_check(Rect2(painted.global_position, painted.size).is_equal_approx(layout.get_bounds(index)), "%s %s: the painting itself should still cover exactly the realm" % [realm_name, painted.name])
			var skirt := realm_root.find_child(str(painted.name).replace("Painted_", "PaintedSkirt_"), true, false) as Sprite2D
			_check(skirt != null, "%s %s: no continuation past the realm's edge" % [realm_name, painted.name])
			if skirt == null:
				continue
			var covered := Rect2(skirt.global_position, skirt.region_rect.size * skirt.scale)
			_check(covered.encloses(seen), "%s %s: the continuation covers %s, the camera sees %s" % [realm_name, painted.name, covered, seen])
			_check(skirt.texture == painted.texture and skirt.region_enabled and skirt.texture_repeat == CanvasItem.TEXTURE_REPEAT_MIRROR, "%s %s: the continuation should mirror the same painting" % [realm_name, painted.name])
			# Texel (0, 0) of the continuation lies on the painting's corner at the painting's scale.
			var corner := skirt.global_position - skirt.region_rect.position * skirt.scale
			_check(corner.is_equal_approx(painted.global_position) and (skirt.scale * skirt.texture.get_size()).is_equal_approx(painted.size), "%s %s: the continuation does not line up with the painting" % [realm_name, painted.name])
			_check(skirt.z_index == painted.z_index and skirt.get_index() < painted.get_index(), "%s %s: the continuation should draw under its painting" % [realm_name, painted.name])
		var dim := realm_root.find_child("Painted_dim", true, false) as ColorRect
		if dim != null:
			_check(Rect2(dim.global_position, dim.size).encloses(seen), "%s: the dimming shade should cover what the camera sees" % realm_name)
	_check(layers == layout.realm_count() * 2, "Expected a far and a mid painting per realm, found %d layers" % layers)
	world.queue_free()
	await process_frame
	if not failed:
		print("Backdrop edge tests passed (%d painted layers continue %.0f px or more past their realm)" % [layers, reach])
	quit(1 if failed else 0)
