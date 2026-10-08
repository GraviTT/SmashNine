extends SceneTree
## Yuki's dropping talisman bursts when it hits a fighter. The burst resizes the collision
## shape; done inside the body-entered callback it raised "Can't change this state while
## flushing queries" (found 2026-10-08 once bots started aiming down; run_all fails on engine
## errors, so this test fails if it comes back). With the original art the burst draws Yuki's
## ward-burst strip, not the light-blue placeholder box (2026-10-09).

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var arena := Node2D.new()
	root.add_child(arena)
	var yuki: Node = PLAYER_FACTORY.create("yuki")
	arena.add_child(yuki)
	yuki.global_position = Vector2(0, 0)
	yuki.setup(CHARACTER_REGISTRY.get_characters()["yuki"], 1, false)
	yuki.set_physics_process(false)
	var victim: Node = PLAYER_FACTORY.create("frey")
	arena.add_child(victim)
	victim.global_position = Vector2(30, 230)
	victim.setup(CHARACTER_REGISTRY.get_characters()["frey"], 2, false)
	victim.set_physics_process(false)
	# Air-down talisman: falls onto the fighter below and bursts.
	yuki._spawn_talisman(Vector2(24, 28), 8, 295, Vector2(0.12, 1.0), 610.0, 1.0, "drop", Vector2(94, 50))
	var talisman: Node = null
	for child in arena.get_children():
		if child.get("burst_size") != null:
			talisman = child
	var burst_seen := false
	var box_shown := false
	var burst_art := false
	for frame in 40:
		await physics_frame
		if not is_instance_valid(talisman):
			break
		if float(talisman.burst_time) > 0.0:
			burst_seen = true
			box_shown = box_shown or talisman.visual.color.a > 0.0
			for child in arena.get_children():
				if str(child.name).begins_with("Vfx_yuki_l"):
					burst_art = true
	arena.queue_free()
	await process_frame
	if not burst_seen:
		push_error("The dropping talisman should burst on the fighter it hits")
		quit(1)
		return
	if box_shown or not burst_art:
		push_error("The burst should draw the ward-burst art, not the placeholder box (box %s, art %s)" % [box_shown, burst_art])
		quit(1)
		return
	print("Talisman burst tests passed")
	quit(0)
