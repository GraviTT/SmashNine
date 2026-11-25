extends SceneTree
## The UI direction reel (2026-11-25, reports/ui-direction-2026-11-25): the same scripted 24
## seconds of a match as P1 (Frey) under the game's own HUD ("now") or under a prototype HUD
## ("a" or "b", hud_proto.gd). This script plays P1 by calling the functions her keys call, so
## every variant shows the same fight. Three parts, one folder each:
##   hud      0-8 s    sword swings, a jump, a hit taken, K, souls coming in
##   cards    8-14 s   a soul card offer opens, the fight goes on, card 2 is picked after 4 s
##   warning  14-24 s  the corner realms' collapse warning (2:00), the ultimate, low HP
## No game code or art changes. Windowed, with --fixed-fps 60 so the variants match frame for
## frame; a JPG every second frame (30 fps) goes to <out>/<part>/####.jpg. The live bot panel is on
## in all three, as the game has it while it is tested (--bots=off hides it). --stills saves a few moments instead (and, for "a" and "b", a mocked offer of the
## three D54 card kinds with the longest card text).
##   <godot> --audio-driver Dummy --fixed-fps 60 --path . -s tests/analysis/ui_audit/ui_direction_capture.gd -- --variant=a --out=<dir> [--stills] [--lang=ko]

const MAIN_SCENE := "res://scenes/Main.tscn"
const MAIN := preload("res://scripts/Main.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const PROTO := preload("res://tests/analysis/ui_audit/hud_proto.gd")
const PARTS := [["hud", 0, 480], ["cards", 480, 840], ["warning", 840, 1440]]
const REEL_FRAMES := 1440
## The collapse warning (match time 2:00) comes one second into the last part.
const START_TIME := 105.0
const STILL_FRAMES := [110, 300, 560, 716, 780, 960, 1040, 1100, 1260]
const MOCK_OFFER := {"time_left": 6.2, "cards": [
	{"id": "power", "title": "Power", "text": "Attack +12%", "kind": "stat", "kind_name": "수치"},
	{"id": "air_dash", "title": "공중 대시", "text": "공중에서 가드 키를 누르면 바라보는 쪽으로 짧게 대시한다. 착지 전 한 번", "kind": "action", "kind_name": "행동"},
	{"id": "second_wing", "title": "두 번째 날갯짓", "text": "발키리의 날개를 공중에서 두 번 쓸 수 있다", "kind": "exclusive", "kind_name": "전용 · 프레이"}]}

var variant := "now"
var out_dir := ""
var lang := "ko"
var stills := false
var bots := true
var main: Node
var human: Node
var rival: Node
var proto: CanvasLayer
var saved := 0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--variant="):
			variant = arg.get_slice("=", 1)
		elif arg.begins_with("--out="):
			out_dir = arg.get_slice("=", 1)
		elif arg.begins_with("--lang="):
			lang = arg.get_slice("=", 1)
		elif arg == "--stills":
			stills = true
		elif arg == "--bots=off":
			bots = false
	if out_dir == "":
		push_error("--out=<dir> is required")
		quit(1)
		return
	for part: Array in PARTS:
		DirAccess.make_dir_recursive_absolute(out_dir.path_join(str(part[0])))
	call_deferred("_run")

func _frames(count: int) -> void:
	for frame in count:
		await process_frame

func _save(path: String) -> void:
	await RenderingServer.frame_post_draw
	saved += 1
	root.get_texture().get_image().save_jpg(path, 0.95)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("The reel must be windowed")
		quit(1)
		return
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	LANGUAGE.load_saved()
	LANGUAGE.set_locale(lang)
	MAIN.human_body = "male"
	MAIN.session_bot_panel = bots
	MAIN.next_screen = "title"
	main = load(MAIN_SCENE).instantiate()
	main.match_seed = 4242
	root.add_child(main)
	current_scene = main
	await _frames(6)
	main._start_match("frey")
	await _frames(60)
	human = main.players[0]
	while main.director.match_elapsed < START_TIME - 0.6:
		main.director.advance(minf(0.5, START_TIME - 0.6 - main.director.match_elapsed))
		main._apply_phase_rules()
		await process_frame
	var far_one: Node = null
	for fighter in main.players:
		if fighter == human:
			continue
		if fighter.realm_index == human.realm_index:
			rival = fighter
		elif far_one == null:
			far_one = fighter
	if rival == null:
		rival = main.players[1]
		main.layout.assign_combatant(rival, human.realm_index)
	# A third fighter waits at the far end of this realm: the mark on the screen edge.
	var points: Array[Vector2] = main.layout.get_spawn_points(human.realm_index)
	var far_point := points[0]
	for point in points:
		if absf(point.x - human.global_position.x) > absf(far_point.x - human.global_position.x):
			far_point = point
	main.layout.assign_combatant(far_one, human.realm_index)
	far_one.reset_for_map(far_point, points)
	main._sync_combatant_visibility()
	far_one.process_mode = Node.PROCESS_MODE_DISABLED
	human.hp = human.max_hp
	human.velocity = Vector2.ZERO
	human.ultimate_cooldown_timer = 0.0
	rival.global_position = human.global_position + Vector2(170, 0)
	rival.velocity = Vector2.ZERO
	if variant != "now":
		main.hud.visible = false
		proto = PROTO.new()
		main.add_child(proto)
		proto.setup(main, variant, bots)
	# Settle until the reel's first frame falls on START_TIME.
	while main.director.match_elapsed < START_TIME:
		await process_frame
	for frame in REEL_FRAMES:
		_act(frame)
		await process_frame
		if stills:
			if STILL_FRAMES.has(frame):
				await _save(out_dir.path_join("still_%04d.jpg" % frame))
		elif frame % 2 == 0:
			for part: Array in PARTS:
				if frame >= int(part[1]) and frame < int(part[2]):
					await _save(out_dir.path_join(str(part[0])).path_join("%04d.jpg" % ((frame - int(part[1])) / 2 + 1)))
	if stills and proto != null:
		proto.mock_offer = MOCK_OFFER
		await _frames(3)
		await _save(out_dir.path_join("still_mock_cards.jpg"))
	LANGUAGE.set_locale("en")
	print("UI direction reel '%s': %d frames in %s (match time at the end %.1f)" % [variant, saved, out_dir, main.director.match_elapsed])
	quit(0)

func _swing() -> void:
	if human._can_start_attack():
		human.basic_attack()
	else:
		human.attack_buffer_timer = human.ATTACK_BUFFER

func _hurt(amount: float) -> void:
	human.invulnerable_timer = 0.0
	human.apply_environment_damage(amount, rival)

## P1's script, by frame (60 a second).
func _act(frame: int) -> void:
	if not is_instance_valid(human) or human.is_defeated:
		return
	match frame:
		20, 56, 92, 340, 376, 560, 600, 660, 1260, 1300, 1340:
			_swing()
		150, 430:
			human.jump_buffer_timer = human.JUMP_BUFFER
		172:
			_swing()
		230:
			_hurt(28.0)
		280:
			human.skill_one()
		400:
			human.add_souls(12)
		500:
			human.add_souls(13)
		740:
			main.soul_growth.choose(human, 1)
		1020:
			human.ultimate_cooldown_timer = 0.0
			human.ultimate()
		1200:
			_hurt(maxf(human.hp - human.max_hp * 0.22, 1.0))
