extends SceneTree
## Images are made here and registered in ResourceLoader's memory cache with
## take_over_path(): production loading/spawning is tested without writing PNGs.
const MONSTER := preload("res://scripts/RealmMonster.gd")
const PROJECTILE := preload("res://scripts/Projectile.gd")
const ART := preload("res://scripts/ArtSettings.gd")
const SCALE := preload("res://scripts/GameScale.gd")
const DIR := "res://assets/art/monsters/"
var arena: Node2D
var failed := false
var checks := 0
var originals: Dictionary = {}
var injected: Array[Texture2D] = []

class FixtureMonster:
	extends "res://scripts/RealmMonster.gd"
	var hide_wave := false
	func _shockwave_texture() -> Texture2D:
		return null if hide_wave else super._shockwave_texture()

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error(message)

func _inject(path: String, width: int, height: int, count := 1) -> Texture2D:
	if not originals.has(path):
		originals[path] = load(path) if ResourceLoader.exists(path) else null
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	for index in count:
		image.fill_rect(Rect2i(index * (width / count), 0, width / count, height), Color.from_hsv(float(index) / count, 1.0, 1.0))
	var texture := ImageTexture.create_from_image(image)
	texture.take_over_path(path)
	injected.append(texture)
	return texture

func _monster() -> Node:
	var monster := FixtureMonster.new()
	monster.setup("ember_imp", 0, Vector2(200, 300))
	arena.add_child(monster)
	monster.set_physics_process(false)
	return monster

func _shot(monster: Node, kind: String, direction := Vector2(1, -1)) -> Node:
	var shot: Node = monster._spawn_ecology_projectile(direction, kind)
	shot.set_physics_process(false)
	return shot

func _crest(shot: Node) -> Line2D:
	for child in shot.get_children():
		if child is Line2D:
			return child
	return null

func _combat(shot: Node, kind: String) -> void:
	_check(shot.shape.shape.size == Vector2(30, 22) * SCALE.WORLD, kind + " hitbox unchanged")
	_check(shot.damage == 6.0 and shot.knockback == 110.0, kind + " damage/knockback unchanged")
	var speed := 180.0 if kind == "homing" else (340.0 if kind == "shockwave" else 390.0)
	var duration := 2.2 if kind in ["homing", "lob", "bomb"] else (0.42 if kind == "shockwave" else 1.35)
	_check(shot.speed == speed * SCALE.WORLD and shot.lifetime == duration, kind + " speed/lifetime unchanged")

func _run() -> void:
	ART.style = ART.STYLE_ORIGINAL
	arena = Node2D.new()
	root.add_child(arena)
	var monster := _monster()
	var path := DIR + "ember_imp_projectile.png"
	_inject(path, 192, 48, 4)
	var bolt := _shot(monster, "bolt")
	var sprite := bolt.get_node("ArtSprite") as AnimatedSprite2D
	_check(sprite != null, "whole-multiple monster texture selects strip")
	if sprite != null:
		_check(sprite.sprite_frames.get_frame_count(&"default") == 4, "four atlas frames")
		_check(sprite.sprite_frames.get_animation_speed(&"default") == 12.0 and sprite.sprite_frames.get_animation_loop(&"default"), "12 fps loop")
		_check(sprite.sprite_frames.get_frame_texture(&"default", 0).get_size() * sprite.scale == Vector2.ONE * 36.0 * SCALE.WORLD, "strip retains old 54px cell size")
		_check(is_equal_approx(sprite.rotation, -PI / 4.0), "bolt aims along flight")
		var first := sprite.frame
		await create_timer(0.12).timeout
		_check(sprite.frame != first, "strip frame advances over real elapsed time")
		bolt.direction = Vector2(-1, -1).normalized()
		bolt._process(0.0)
		_check(sprite.flip_h and is_equal_approx(sprite.rotation, PI / 4.0), "left bolt mirrors without upside-down art")
	_combat(bolt, "bolt")
	bolt.free()
	for kind in ["lob", "bomb", "homing"]:
		var shot := _shot(monster, kind)
		var round_art := shot.get_node("ArtSprite") as AnimatedSprite2D
		_check(round_art.rotation == 0.0 and not round_art.flip_h, kind + " starts upright")
		shot.direction = Vector2(-1, 2).normalized()
		shot._process(0.0)
		_check(round_art.rotation == 0.0 and round_art.flip_h, kind + " stays upright and mirrors as direction changes")
		_combat(shot, kind)
		shot.free()
	# Square keeps the existing Sprite2D path; non-integral wide images are not strips.
	for size in [Vector2i(24, 24), Vector2i(50, 24)]:
		_inject(path, size.x, size.y)
		var still := _shot(monster, "bolt")
		var still_art := still.get_node("ArtSprite") as Sprite2D
		_check(still_art != null and still_art.hframes == 1, "square/non-integral image stays a Sprite2D")
		_check(is_equal_approx(still_art.texture.get_width() * still_art.scale.x, 36.0 * SCALE.WORLD), "still retains old width")
		still.free()
	_inject(path, 24, 24)
	var round_still := _shot(monster, "lob", Vector2(-1, -1))
	_check(round_still.get_node("ArtSprite").rotation == 0.0 and round_still.get_node("ArtSprite").flip_h, "round legacy still is upright and mirrored")
	round_still.free()
	await _shockwaves(monster)
	_fighter_unchanged(monster)
	# Missing skin still uses the common fireball (which can itself become a strip).
	monster.skin_id = "sys07_missing_skin"
	_inject(DIR + "ember_fireball.png", 192, 48, 4)
	var fallback := _shot(monster, "bolt")
	_check(fallback.get_node("ArtSprite") is AnimatedSprite2D and monster.projectile_art_path == DIR + "ember_fireball.png", "common fireball fallback supports strips")
	fallback.free()
	ART.style = ART.STYLE_PROTOTYPE
	var prototype := _shot(monster, "bolt")
	_check(prototype.get_node_or_null("ArtSprite") == null and prototype.visual.visible, "prototype keeps coloured projectile")
	prototype.free()
	var prototype_wave := _shot(monster, "shockwave")
	_check(_crest(prototype_wave) != null and prototype_wave.get_node_or_null("ArtSprite") == null, "prototype keeps crest")
	prototype_wave.free()
	ART.style = ART.STYLE_ORIGINAL
	for texture in injected:
		texture.resource_path = ""
	for original_path in originals:
		if originals[original_path] != null:
			originals[original_path].take_over_path(original_path)
	arena.free()
	print("Projectile art tests: %d checks, %s" % [checks, "FAILED" if failed else "PASSED"])
	quit(1 if failed else 0)

func _shockwaves(monster: Node) -> void:
	monster.hide_wave = true
	var missing := _shot(monster, "shockwave", Vector2.LEFT)
	_check(_crest(missing) != null and missing.get_node_or_null("ArtSprite") == null, "absent shockwave file keeps crest")
	var crest := _crest(missing)
	_check(crest.points == PackedVector2Array([Vector2(-16, 12), Vector2(-8, -10), Vector2(0, -22), Vector2(8, -10), Vector2(16, 12)]) and crest.width == 5.0, "legacy crest geometry unchanged")
	missing.free()
	monster.hide_wave = false
	var shock_path := DIR + "slam_shockwave.png"
	var texture := _inject(shock_path, 256, 48, 4)
	# Exercise the real slam caller, including both origins and the shared victim set.
	monster.archetype = "slam"
	monster._execute_action()
	var waves: Array[Node] = []
	for child in arena.get_children():
		if child is Area2D and child.get("source") == monster:
			child.set_physics_process(false)
			waves.append(child)
	_check(waves.size() == 2, "slam still emits two waves")
	for wave in waves:
		var sprite := wave.get_node("ArtSprite") as AnimatedSprite2D
		_check(sprite != null and _crest(wave) == null and not wave.visual.visible, "sprite replaces crest")
		_check(sprite.flip_h == (wave.direction.x < 0.0) and sprite.rotation == 0.0, "wave mirrors for left")
		var floor_y: float = sprite.global_position.y + (44.0 - 24.0) * sprite.global_scale.y
		_check(is_equal_approx(floor_y, monster.global_position.y), "sprite y=44 floor matches monster ground")
		_check(sprite.sprite_frames.get_frame_texture(&"default", 0).get_size() == Vector2(64, 48), "rectangular wave frames")
		_combat(wave, "shockwave")
		var first := sprite.frame
		await create_timer(0.12).timeout
		_check(sprite.frame != first, "wave animates")
	waves[0].hit_targets.append(monster)
	_check(waves[1].hit_targets.has(monster), "slam still shares victims between waves")
	for wave in waves:
		wave.free()
	texture.resource_path = ""
	monster.hide_wave = true
	var absent := _shot(monster, "shockwave")
	_check(_crest(absent) != null, "missing optional resource restores crest")
	absent.free()
	monster.hide_wave = false
	_inject(shock_path, 200, 48, 4)
	var malformed := _shot(monster, "shockwave")
	_check(_crest(malformed) != null, "malformed optional wave uses safe crest fallback")
	malformed.free()

func _fighter_unchanged(source: Node) -> void:
	var shot := Area2D.new()
	shot.set_script(PROJECTILE)
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	shot.add_child(shape)
	var visual := ColorRect.new()
	visual.name = "Visual"
	shot.add_child(visual)
	arena.add_child(shot)
	shot.set_physics_process(false)
	shot.configure(source, Vector2(20, 10), 8.0, 380.0, Vector2(-1, -1), Color.RED)
	var path := "res://assets/art/effects/rio_mana_wave.png"
	_inject(path, 192, 48, 4)
	shot.art_scale_multiplier = 1.5
	_check(shot.set_art(path, Color.CYAN, 2.0), "fighter set_art succeeds")
	var sprite := shot.get_node("ArtSprite") as Sprite2D
	_check(sprite != null and sprite.hframes == 1 and sprite.texture.get_width() == 192, "fighter wide art is still one whole image")
	_check(is_equal_approx(sprite.scale.x, 2.0 * 1.5 / (192.0 / 24.0)) and sprite.modulate == Color.CYAN, "fighter authored width correction and tint unchanged")
	var initial_rotation := sprite.rotation
	shot.direction = Vector2.RIGHT
	shot._process(0.0)
	_check(sprite.rotation == initial_rotation and sprite.flip_h, "fighter set_art does not opt into tracking")
	shot.free()
