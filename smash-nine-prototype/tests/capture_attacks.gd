extends SceneTree
## Visual check of basic attacks and skills (windowed, not headless): for each character the
## camera goes to that fighter, who swings J, then K, then L; a screenshot is taken shortly
## after each press. Usage: godot --path . -s tests/capture_attacks.gd -- --out=../reports/attacks

const MAIN_SCENE := "res://scenes/Main.tscn"
## Seconds after each press before the shot (start-up differs per move).
const SHOT_DELAY := {"basic": 0.12, "skill_one": 0.26, "skill_two": 0.3}

var out_dir := ""
var main: Node

func _initialize() -> void:
	out_dir = ProjectSettings.globalize_path("res://").path_join("../reports/attacks")
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
		var fighter := _find(id)
		if fighter == null:
			continue
		main.spectate_target = fighter
		main._set_map(fighter.realm_index)
		await _seconds(0.3)
		for action in ["basic", "skill_one", "skill_two"]:
			for wait in 40:
				if fighter.is_on_floor():
					break
				await _seconds(0.05)
			_ready_to_act(fighter)
			match action:
				"basic":
					fighter.basic_attack()
				"skill_one":
					fighter.skill_one()
				"skill_two":
					fighter.skill_two()
			await _seconds(float(SHOT_DELAY[action]))
			await _shot("%s_%s" % [id, action])
			await _seconds(0.5)
	print("Attack screens saved to ", out_dir)
	quit(0)

func _find(id: String) -> Node:
	for player in main.players:
		if is_instance_valid(player) and player.character_id == id and not player.is_defeated:
			return player
	return null

## Clears whatever the bot was doing so the press is accepted.
func _ready_to_act(fighter: Node) -> void:
	fighter.attack_lock_timer = 0.0
	fighter.hitstun_timer = 0.0
	fighter.is_guarding = false
	if fighter.get("rune_cooldown_timer") != null:
		fighter.rune_cooldown_timer = 0.0

func _seconds(duration: float) -> void:
	if duration > 0.0:
		await create_timer(duration).timeout

func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := out_dir.path_join("%s.png" % shot_name)
	root.get_texture().get_image().save_png(path)
	print("saved ", path)
