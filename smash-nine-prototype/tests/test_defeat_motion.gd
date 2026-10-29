extends SceneTree
## Defeat motion (user 2026-10-17: "캐릭터들 패배 모션 추가"). A fighter knocked out on the ground
## plays its `defeat` row, holds the last drawing, fades out and hides. Without the row, in the air
## or off the map it vanishes at once, as before. The rows come as art candidates (CODEX-ART-69),
## so the test lends Frey a stand-in row made of its hurt frame.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var arena: Node2D
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error(message)
	failed = true

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	await _test_no_row_vanishes()
	await _test_row_plays_then_fades()
	await _test_in_air_vanishes()
	arena.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Defeat motion tests passed")
	quit(0)

func _fighter(at: Vector2) -> Node:
	var fighter: Node = PLAYER_FACTORY.create("frey")
	arena.add_child(fighter)
	fighter.global_position = at
	fighter.setup(CHARACTER_REGISTRY.get_characters()["frey"], 1, false)
	fighter.ringout_y = 100000.0
	# Frey's real defeat strip was applied on 2026-10-29 (it plays at her adopted speed); keep the
	# fixture on the stand-in row below so the timings here stay fixed.
	var frames: SpriteFrames = fighter.character_sprite.sprite_frames
	if frames.has_animation(&"frey_defeat"):
		frames.remove_animation(&"frey_defeat")
	return fighter

func _floor() -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(800, 40)
	shape.shape = rect
	body.add_child(shape)
	arena.add_child(body)
	body.global_position = Vector2(0, 20)
	return body

## A stand-in `defeat` row: six copies of the hurt frame at 10 fps.
func _lend_defeat_row(fighter: Node) -> void:
	var frames: SpriteFrames = fighter.character_sprite.sprite_frames
	frames.add_animation(&"frey_defeat")
	frames.set_animation_speed(&"frey_defeat", 10.0)
	frames.set_animation_loop(&"frey_defeat", false)
	for index in 6:
		frames.add_frame(&"frey_defeat", frames.get_frame_texture(&"frey_hurt", 0))

func _settle(fighter: Node) -> void:
	for frame in 20:
		await physics_frame
	if not fighter.is_on_floor():
		_fail("Test setup: the fighter should stand on the floor")

func _test_no_row_vanishes() -> void:
	var ground := _floor()
	var frey := _fighter(Vector2(0, -2))
	await _settle(frey)
	frey._defeat(null)
	if frey.visible:
		_fail("Without a defeat row a knocked-out fighter should vanish at once")
	frey.queue_free()
	ground.queue_free()
	await process_frame

func _test_row_plays_then_fades() -> void:
	var ground := _floor()
	var frey := _fighter(Vector2(0, -2))
	await _settle(frey)
	_lend_defeat_row(frey)
	frey._defeat(null)
	if not frey.visible or frey.character_sprite.animation != &"frey_defeat":
		_fail("On the ground the fighter should stay and play its defeat row (visible %s, animation %s)" % [frey.visible, frey.character_sprite.animation])
	# 6 drawings at 10 fps, then the hold: still there, fully drawn.
	await create_timer(0.6 + frey.DEFEAT_HOLD * 0.5).timeout
	if not frey.visible or frey.modulate.a < 0.99:
		_fail("The last drawing should hold before the fade (visible %s, alpha %.2f)" % [frey.visible, frey.modulate.a])
	await create_timer(frey.DEFEAT_HOLD * 0.5 + frey.DEFEAT_FADE + 0.2).timeout
	if frey.visible or absf(frey.modulate.a - 1.0) > 0.01:
		_fail("After the fade the fighter should be hidden with its alpha restored (visible %s, alpha %.2f)" % [frey.visible, frey.modulate.a])
	frey.queue_free()
	ground.queue_free()
	await process_frame

func _test_in_air_vanishes() -> void:
	var frey := _fighter(Vector2(0, -400))
	await physics_frame
	_lend_defeat_row(frey)
	frey._defeat(null)
	if frey.visible:
		_fail("A fighter knocked out in the air should vanish at once")
	frey.queue_free()
	await process_frame
