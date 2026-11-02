extends Node2D
## A circle around Luna that stops other fighters' projectiles (2026-11-03 D45): her star barrier
## (L "별의 방어막") and Brave Luna's cyclone (L "별의 회오리"). The star barrier also takes the hits
## meant for her (Luna.character_hit_absorption) until it has taken `max_hp`, nudges away whoever
## touches it, and breaks after `duration`. Drawn in code until the barrier and cyclone art is in.

const GAME_SCALE := preload("res://scripts/GameScale.gd")
const VFX := preload("res://scripts/Vfx.gd")
const PROJECTILE_BARRIERS := preload("res://scripts/ProjectileBarriers.gd")
## A body this close to the rim (centre to body centre, past the radius) touches it.
const CONTACT_MARGIN := 18.0
const CONTACT_COOLDOWN := 0.6

signal broke

var fighter: Node2D
var style := "barrier"
var radius := 105.0
var max_hp := INF
var hp := INF
var duration := 5.0
var elapsed := 0.0
var contact_damage := 0.0
var contact_knockback := 0.0
var contact_cooldowns: Dictionary = {}
var broken := false
var spin := 0.0
var rim: Line2D
var fill: Polygon2D
var stars: Node2D

func configure(owner_fighter: Node2D, new_style: String, new_radius: float, new_duration: float, new_hp := INF, damage := 0.0, knockback := 0.0) -> void:
	fighter = owner_fighter
	style = new_style
	radius = new_radius
	duration = new_duration
	max_hp = new_hp
	hp = new_hp
	contact_damage = damage
	contact_knockback = knockback
	add_to_group(PROJECTILE_BARRIERS.GROUP)
	_build_visual()

func is_active() -> bool:
	return not broken and elapsed < duration

## A projectile of anyone but her that reaches the circle is stopped; the barrier takes its damage.
func stops_projectile(projectile: Node2D, source: Node) -> bool:
	if not is_active() or source == fighter or not is_instance_valid(fighter):
		return false
	if projectile.global_position.distance_to(global_position) > radius:
		return false
	var damage = projectile.get("damage")
	take_damage(float(damage) if damage != null else 0.0)
	_flash(projectile.global_position)
	return true

func take_damage(amount: float) -> void:
	if not is_active() or max_hp == INF:
		return
	hp -= amount
	_flash(global_position + Vector2(0, -radius).rotated(randf() * TAU))
	if hp <= 0.0:
		shatter()

func shatter() -> void:
	if broken:
		return
	broken = true
	remove_from_group(PROJECTILE_BARRIERS.GROUP)
	broke.emit()
	if is_instance_valid(get_parent()):
		VFX.spawn(get_parent(), "luna_moon_ring", global_position, Vector2.ONE * radius * 2.16 / 204.0, false, 5)
	_fade_out(0.14)

func _physics_process(delta: float) -> void:
	if broken:
		return
	if not is_instance_valid(fighter) or fighter.get("is_defeated") == true:
		shatter()
		return
	elapsed += delta
	if elapsed >= duration:
		broken = true
		remove_from_group(PROJECTILE_BARRIERS.GROUP)
		_fade_out(0.2)
		return
	spin += delta * (9.0 if style == "cyclone" else 1.6)
	if is_instance_valid(stars):
		stars.rotation = spin
	if style == "barrier" and is_instance_valid(rim):
		rim.modulate.a = 0.75 + 0.25 * sin(elapsed * 6.0) if elapsed < duration - 1.0 else (0.35 if int(elapsed * 10.0) % 2 == 0 else 0.9)
	for target_id in contact_cooldowns.keys():
		contact_cooldowns[target_id] = float(contact_cooldowns[target_id]) - delta
		if float(contact_cooldowns[target_id]) <= 0.0:
			contact_cooldowns.erase(target_id)
	if contact_damage > 0.0:
		_nudge_touching()

## Whoever touches the rim takes a small hit pushing them out (each body every CONTACT_COOLDOWN).
func _nudge_touching() -> void:
	var targets: Array[Node] = []
	targets.append_array(get_tree().get_nodes_in_group("players"))
	targets.append_array(get_tree().get_nodes_in_group("realm_monsters"))
	for target in targets:
		if target == fighter or not target is Node2D or not target.has_method("apply_hit"):
			continue
		if target.get("is_defeated") == true or contact_cooldowns.has(target.get_instance_id()):
			continue
		var realm = target.get("realm_index")
		if realm != null and int(realm) != int(fighter.get("realm_index")):
			continue
		var centre: Vector2 = (target as Node2D).global_position + GAME_SCALE.BODY_CENTRE
		var offset := centre - global_position
		if offset.length() > radius + CONTACT_MARGIN:
			continue
		contact_cooldowns[target.get_instance_id()] = CONTACT_COOLDOWN
		var push := Vector2(signf(offset.x) if absf(offset.x) > 2.0 else float(fighter.get("facing")), -0.25)
		target.apply_hit(fighter, contact_damage, contact_knockback, push)
		_flash(global_position + offset.normalized() * radius)

func _build_visual() -> void:
	var art := "luna_barrier" if style == "barrier" else "luna_cyclone"
	# Until the art is in Vfx.SPECS (CODEX-VFX-04), the code shapes below draw it.
	if VFX.SPECS.has(art) and VFX.available(art):
		var art_scale := radius * 2.0 / 210.0 if style == "barrier" else radius * 2.0 / 192.0
		VFX.spawn(self, art, Vector2.ZERO, Vector2.ONE * art_scale, true, 0, Color.WHITE, true)
		return
	if style == "barrier":
		fill = Polygon2D.new()
		fill.polygon = _circle(radius, 40)
		fill.color = Color(0.55, 0.92, 1.0, 0.08)
		add_child(fill)
		rim = Line2D.new()
		rim.points = _circle(radius, 40)
		rim.closed = true
		rim.width = 3.0
		rim.default_color = Color(0.62, 0.95, 1.0, 0.85)
		rim.antialiased = true
		add_child(rim)
		stars = Node2D.new()
		add_child(stars)
		for index in 5:
			var star := Polygon2D.new()
			star.polygon = _star(9.0, 4.0)
			star.color = Color(1.0, 0.86, 0.4, 0.95) if index % 2 == 0 else Color(1.0, 0.55, 0.88, 0.95)
			star.position = Vector2.RIGHT.rotated(TAU * float(index) / 5.0) * radius
			stars.add_child(star)
		return
	# The cyclone: three swirling arcs and a faint core.
	fill = Polygon2D.new()
	fill.polygon = _circle(radius * 0.92, 32)
	fill.color = Color(1.0, 0.6, 0.86, 0.06)
	add_child(fill)
	stars = Node2D.new()
	add_child(stars)
	for index in 3:
		var arc := Line2D.new()
		var points := PackedVector2Array()
		for step in 9:
			var angle := TAU * float(index) / 3.0 + float(step) * 0.22
			var reach := radius * (0.55 + 0.05 * float(step))
			points.append(Vector2(cos(angle) * reach, sin(angle) * reach * 1.25))
		arc.points = points
		arc.width = 5.0
		arc.default_color = Color(1.0, 0.72, 0.9, 0.8) if index != 1 else Color(1.0, 0.88, 0.45, 0.85)
		arc.antialiased = true
		stars.add_child(arc)

func _flash(at: Vector2) -> void:
	if not is_instance_valid(get_parent()):
		return
	VFX.spawn(get_parent(), "luna_star_bloom", at, Vector2.ONE * 0.28 * GAME_SCALE.COMBAT, false, 6)

func _fade_out(time: float) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, time)
	tween.tween_callback(queue_free)

func _circle(r: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in count:
		var angle := TAU * float(index) / float(count)
		points.append(Vector2(cos(angle), sin(angle)) * r)
	return points

func _star(outer: float, inner: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 10:
		var angle := -PI * 0.5 + PI * float(index) / 5.0
		points.append(Vector2(cos(angle), sin(angle)) * (outer if index % 2 == 0 else inner))
	return points
