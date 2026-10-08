extends SceneTree
## Why do final duels drag (routine 2026-10-08 work)? Same match setup as analysis_soak.gd;
## once at most `--alive` fighters remain, prints every `--every` seconds where each one is,
## what its bot is doing, whom it targets, and how far apart they are.
## Usage: godot --headless --path . --fixed-fps 60 -s tests/analysis/lead/duel_probe.gd --
##        --seed=7 [--alive=2] [--every=5] [--seconds=480]

const MAIN_SCENE := "res://scenes/Main.tscn"
const FRAME_TIME := 1.0 / 60.0

var seed_value := 7
var alive_limit := 2
var every := 5.0
var seconds := 480.0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		var value := arg.get_slice("=", 1)
		if arg.begins_with("--seed="):
			seed_value = int(value)
		elif arg.begins_with("--alive="):
			alive_limit = int(value)
		elif arg.begins_with("--every="):
			every = float(value)
		elif arg.begins_with("--seconds="):
			seconds = float(value)
	call_deferred("_run")

func _run() -> void:
	seed(seed_value)
	var main: Node = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	main.match_seed = seed_value
	main.player_count = 8
	root.add_child(main)
	await process_frame
	var next_report := 0.0
	for frame in int(seconds / FRAME_TIME):
		await physics_frame
		if main.match_over:
			print("DUEL match over at %.0f s" % main.director.match_elapsed)
			break
		var alive: Array = []
		for player in main.players:
			if is_instance_valid(player) and not player.is_defeated:
				alive.append(player)
		var now: float = main.director.match_elapsed
		if alive.size() > alive_limit or now < next_report:
			continue
		next_report = now + every
		var lines: Array[String] = []
		for player in alive:
			var ai = player.ai_controller
			var target = ai.target
			var target_text := "-"
			if is_instance_valid(target):
				var gap: Vector2 = target.global_position - player.global_position
				target_text = "%s r%d gap(%.0f,%.0f)" % [str(target.get("character_id")) if target.get("character_id") != null else target.name, int(target.get("realm_index")) if target.get("realm_index") != null else -1, gap.x, gap.y]
			var bounds: Rect2 = main.layout.get_bounds(player.realm_index)
			var local: Vector2 = player.global_position - bounds.position
			var wander_local: Vector2 = ai.wander_target - bounds.position if ai.wander_target != Vector2.ZERO else Vector2(-1, -1)
			var nav_local: Vector2 = ai._navigation_destination(player, ai.wander_target) - bounds.position if ai.wander_target != Vector2.ZERO else Vector2(-1, -1)
			lines.append("%s hp%.0f r%d local(%.0f,%.0f) floor%s vel(%.0f,%.0f) state=%s target=%s guard=%s wander(%.0f,%.0f) nav(%.0f,%.0f) intent=%s ult=%s lock=%.2f stun=%.2f freeze=%.2f active=%s dash=%.2f" % [player.character_id, player.hp, player.realm_index, local.x, local.y, str(player.is_on_floor()), player.velocity.x, player.velocity.y, ai.state, target_text, str(player.is_guarding), wander_local.x, wander_local.y, nav_local.x, nav_local.y, str(ai.get("current_intent")) if ai.get("current_intent") != null else "?", str(player.get("ultimate_phase")), player.attack_lock_timer, player.hitstun_timer, player.movement_freeze_timer, str(player.is_realm_active), player.skill_dash_timer])
		print("DUEL t=%.0f phase=%s\n  %s" % [now, main.director.get_phase_name(), "\n  ".join(lines)])
	main.queue_free()
	await process_frame
	quit(0)
