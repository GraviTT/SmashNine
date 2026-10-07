extends SceneTree
## Visual check of the ultimates (windowed, not headless): for each character the camera goes
## to that fighter, the ultimate is cast (follow-up presses included) and screenshots are
## taken at the cut-in and mid-effect.
## Usage: godot --path . -s tests/capture_ultimates.gd -- --out=../reports/ultimates

const MAIN_SCENE := "res://scenes/Main.tscn"
## Follow-up presses after the cast, in seconds (Nova's slingshot stages, Luna's laser).
const FOLLOWUPS := {"nova": [0.35, 0.55], "luna": [0.9]}
## When to shoot after the cast.
const SHOTS := {"frey": [0.18, 0.36], "yuki": [0.9, 3.2], "luna": [0.3, 1.2], "nova": [0.6, 1.5], "rio": [0.45, 0.85]}

var out_dir := ""
var main: Node

func _initialize() -> void:
	out_dir = ProjectSettings.globalize_path("res://").path_join("../reports/ultimates")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = ProjectSettings.globalize_path("res://").path_join(arg.get_slice("=", 1))
	DirAccess.make_dir_recursive_absolute(out_dir)
	call_deferred("_run")

func _run() -> void:
	main = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	main.match_seed = 5150
	main.realm_hazards = false
	root.add_child(main)
	await _seconds(1.0)
	for id in ["frey", "yuki", "luna", "nova", "rio"]:
		var caster := _find(id)
		if caster == null:
			continue
		main.spectate_target = caster
		main._set_map(caster.realm_index)
		await _seconds(0.3)
		for wait in 40:
			if caster.is_on_floor():
				break
			await _seconds(0.05)
		_ready_to_cast(caster)
		caster.ultimate()
		var elapsed := 0.0
		var followups: Array = FOLLOWUPS.get(id, []).duplicate()
		var shots: Array = SHOTS[id].duplicate()
		var shot_index := 0
		var next_follow := 0.0
		while not shots.is_empty():
			var next_shot: float = shots[0]
			var wait := next_shot - elapsed
			if not followups.is_empty():
				next_follow += float(followups[0])
				if next_follow < next_shot:
					await _seconds(next_follow - elapsed)
					elapsed = next_follow
					followups.pop_front()
					caster.ultimate()
					continue
				next_follow -= float(followups[0])
			await _seconds(wait)
			elapsed = next_shot
			shots.pop_front()
			await _shot("%s_%d" % [id, shot_index])
			shot_index += 1
	print("Ultimate screens saved to ", out_dir)
	quit(0)

func _find(id: String) -> Node:
	for player in main.players:
		if is_instance_valid(player) and player.character_id == id and not player.is_defeated:
			return player
	return null

## Clears whatever the bot was doing so the cast is accepted.
func _ready_to_cast(caster: Node) -> void:
	caster.attack_lock_timer = 0.0
	caster.hitstun_timer = 0.0
	caster.ultimate_cooldown_timer = 0.0
	caster.is_guarding = false

func _seconds(duration: float) -> void:
	if duration > 0.0:
		await create_timer(duration).timeout

func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := out_dir.path_join("%s.png" % shot_name)
	root.get_texture().get_image().save_png(path)
	print("saved ", path)
