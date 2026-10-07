extends SceneTree
## Ultimate performance in real bot matches (lead probe, routine 2026-10-08).
## A cast is detected when a fighter's ultimate cooldown jumps up. For each cast we count the
## damage that fighter's hits deal inside the ultimate's window (Luna: the whole Brave form),
## knock-outs it scores inside the window + 2 s, and compare with the fighter's normal damage
## rate outside windows (gain = window damage - normal rate x window length).
## Usage: godot --headless --path . --fixed-fps 60 -s tests/analysis/lead/ult_probe.gd -- --seed=1001
## Prints one "ULT_RESULT {json}" line.

const MAIN_SCENE := "res://scenes/Main.tscn"
const FRAME_TIME := 1.0 / 60.0
const MAX_SECONDS := 480.0
## Seconds after the cast that count as the ultimate: the fighter's own ultimate_window
## (character data). Until 03:00 on 2026-10-08 this was a copy that gave Yuki 3.5 s, which
## missed the ward's final pulse (it lands about 3.57 s after the press).
const KO_GRACE := 2.0

var main: Node
var seed_value := 1001
var last_cooldown: Dictionary = {}
var casts: Dictionary = {}          # player -> Array[{"t", "damage", "hits", "kos"}]
var window_until: Dictionary = {}   # player -> end time of the current window
var normal_damage: Dictionary = {}  # player -> damage outside windows
var normal_time: Dictionary = {}    # player -> seconds alive outside windows

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			seed_value = int(arg.get_slice("=", 1))
	call_deferred("_run")

func _run() -> void:
	seed(seed_value)
	main = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	main.match_seed = seed_value
	root.add_child(main)
	await process_frame
	for player in main.players:
		last_cooldown[player] = 0.0
		casts[player] = []
		window_until[player] = -1.0
		normal_damage[player] = 0.0
		normal_time[player] = 0.0
		player.damaged.connect(_on_damaged)
		player.defeated.connect(_on_defeated)
	var frames := int(MAX_SECONDS / FRAME_TIME)
	for frame in frames:
		await physics_frame
		var now: float = main.director.match_elapsed
		for player in main.players:
			if not is_instance_valid(player) or player.is_defeated:
				continue
			var cooldown: float = player.ultimate_cooldown_timer
			if cooldown > float(last_cooldown[player]) + 10.0:
				casts[player].append({"t": now, "damage": 0.0, "hits": 0, "kos": 0})
				window_until[player] = now + float(player.ultimate_window)
			last_cooldown[player] = cooldown
			if now > float(window_until[player]):
				normal_time[player] = float(normal_time[player]) + FRAME_TIME
		if main.match_over:
			break
	_report()
	quit(0)

func _current_cast(attacker: Node, grace := 0.0) -> Variant:
	if not casts.has(attacker) or casts[attacker].is_empty():
		return null
	var now: float = main.director.match_elapsed
	if now <= float(window_until[attacker]) + grace:
		return casts[attacker][-1]
	return null

func _on_damaged(_player: Node, amount: float, attacker: Variant, source: String) -> void:
	if source != "hit" or not (attacker is Node) or not is_instance_valid(attacker) or not casts.has(attacker):
		return
	var cast: Variant = _current_cast(attacker)
	if cast == null:
		normal_damage[attacker] = float(normal_damage[attacker]) + amount
		return
	cast.damage = float(cast.damage) + amount
	cast.hits = int(cast.hits) + 1

func _on_defeated(_player: Node, attacker: Variant) -> void:
	if not (attacker is Node) or not is_instance_valid(attacker):
		return
	var cast: Variant = _current_cast(attacker, KO_GRACE)
	if cast != null:
		cast.kos = int(cast.kos) + 1

func _report() -> void:
	var by_character: Dictionary = {}
	for player in casts:
		if not is_instance_valid(player):
			continue
		var id: String = player.character_id
		var entry: Dictionary = by_character.get(id, {"casts": 0, "hit_casts": 0, "damage": 0.0, "kos": 0, "normal_damage": 0.0, "normal_time": 0.0, "fighters": 0})
		entry.fighters += 1
		for cast in casts[player]:
			entry.casts += 1
			entry.hit_casts += 1 if int(cast.hits) > 0 else 0
			entry.damage += float(cast.damage)
			entry.kos += int(cast.kos)
		entry.normal_damage += float(normal_damage[player])
		entry.normal_time += float(normal_time[player])
		by_character[id] = entry
	print("ULT_RESULT " + JSON.stringify({"seed": seed_value, "length": snappedf(main.director.match_elapsed, 0.1), "characters": by_character}))
