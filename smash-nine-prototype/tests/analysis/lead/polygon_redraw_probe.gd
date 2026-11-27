extends SceneTree
## Quality track 4 (2026-11-27): which Polygon2D changes make it draw again. In the Godot 4.7
## web build every redraw of an unchanged shape updates its mesh in place, which WebGL refuses
## ("bindBuffer: element array buffers can not be bound to a different target"). Counts the
## node's draw signal after each change and prints POLYGON_REDRAW_RESULT {json}.
##   <godot> --headless --path . -s tests/analysis/lead/polygon_redraw_probe.gd

var draws := 0

func _initialize() -> void:
	call_deferred("_run")

func _count() -> int:
	await process_frame
	await process_frame
	var seen := draws
	draws = 0
	return seen

func _run() -> void:
	var polygon := Polygon2D.new()
	polygon.polygon = PackedVector2Array([Vector2(-6, -6), Vector2(0, 0), Vector2(-6, 6), Vector2(-2.7, 0)])
	polygon.color = Color(0.9, 0.8, 0.3)
	polygon.draw.connect(func() -> void: draws += 1)
	root.add_child(polygon)
	var result := {}
	result["first_draw"] = await _count()
	result["nothing_changed"] = await _count()
	polygon.color = polygon.color
	result["same_color"] = await _count()
	polygon.color = Color(0.2, 0.4, 0.9)
	result["new_color"] = await _count()
	polygon.polygon = polygon.polygon
	result["same_polygon"] = await _count()
	polygon.position += Vector2(5, 0)
	polygon.rotation = 0.5
	polygon.scale = Vector2(-1, 1)
	result["position_rotation_scale"] = await _count()
	polygon.self_modulate.a = 0.0
	result["self_modulate_clear"] = await _count()
	polygon.self_modulate.a = 1.0
	result["self_modulate_back"] = await _count()
	polygon.visible = false
	result["hidden"] = await _count()
	polygon.visible = true
	result["shown_again"] = await _count()
	print("POLYGON_REDRAW_RESULT ", JSON.stringify(result))
	quit()
