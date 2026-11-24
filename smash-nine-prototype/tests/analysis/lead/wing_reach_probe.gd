extends SceneTree
## How far Frey's wing dash-slash reaches, per direction (2026-11-24, for the bot's wing rule).
## A bot Frey hovers and dashes at a still target placed `d` px away along the dash direction;
## prints the distances at which the target was hit.
## Usage: <godot> --headless --path . --fixed-fps 60 -s tests/analysis/lead/wing_reach_probe.gd

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var arena: Node2D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	for way in [Vector2(1, 0), Vector2(1, 1), Vector2(1, -1), Vector2(0, 1), Vector2(0, -1)]:
		var direction: Vector2 = (way as Vector2).normalized()
		var hits: Array[int] = []
		for d in range(60, 441, 20):
			if await _trial(direction, float(d)):
				hits.append(d)
		print("WING_REACH way=%s hit at %s" % [way, hits])
	quit(0)

func _fighter(character_id: String, player_id: int, at: Vector2) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(character_id)
	arena.add_child(fighter)
	fighter.global_position = at
	fighter.setup(CHARACTER_REGISTRY.get_characters()[character_id], player_id, false)
	fighter.ringout_y = 100000.0
	fighter.is_dummy = true
	return fighter

func _trial(direction: Vector2, distance: float) -> bool:
	var start := Vector2(0, -3000)
	var frey := _fighter("frey", 1, start)
	var foe := _fighter("yuki", 2, start + direction * distance)
	foe.set_physics_process(false)
	for frame in 3:
		await physics_frame
	frey.global_position = start
	frey.velocity = Vector2.ZERO
	frey.air_jumps_left = frey.max_air_jumps
	frey.ai_controller.wing_aim = direction
	var hp: float = foe.hp
	var started: bool = frey.try_wing_hover()
	var travel := Vector2.ZERO
	var dashing := false
	for frame in 50:
		await physics_frame
		if float(frey.skill_dash_timer) > 0.0:
			dashing = true
		elif dashing and travel == Vector2.ZERO:
			travel = frey.global_position - start
	var hit: bool = started and float(foe.hp) < hp
	if distance == 440.0:
		# Nothing in the way at this distance: how far the dash itself carries her in 50 frames
		# (the fall after it included for the sideways and downward ways).
		print("WING_TRAVEL way=%s moved %s in 50 frames, dash part %s" % [direction, (frey.global_position - start).round(), travel.round()])
	frey.queue_free()
	foe.queue_free()
	await process_frame
	return hit
