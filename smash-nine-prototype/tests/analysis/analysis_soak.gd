extends SceneTree
## Analysis-only soak runner. It instantiates the real match scene and observes
## public state/signals without replacing any game rule.

const MAIN_SCENE := "res://scenes/Main.tscn"
const FRAME_TIME := 1.0 / 60.0

var main: Node
var seconds := 480.0
var seed_value := 1
var player_count := 8
var first_pvp_hit := -1.0
var elimination_log: Array[Dictionary] = []
var card_log: Array[Dictionary] = []
var maximum_nodes := 0
var nan_positions := 0
var previous_damage: Dictionary = {}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seconds="):
			seconds = float(arg.get_slice("=", 1))
		elif arg.begins_with("--players="):
			player_count = int(arg.get_slice("=", 1))
		elif arg.begins_with("--seed="):
			seed_value = int(arg.get_slice("=", 1))
	call_deferred("_run")

func _run() -> void:
	seed(seed_value)
	main = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	main.match_seed = seed_value
	main.player_count = player_count
	root.add_child(main)
	await process_frame
	main.soul_growth.offer_closed.connect(_on_offer_closed)
	for player in main.players:
		player.defeated.connect(_on_defeated)
		previous_damage[player] = float(player.damage_dealt)
	var started_usec := Time.get_ticks_usec()
	var frame_limit := int(seconds / FRAME_TIME)
	var finished_early := false
	for frame in frame_limit:
		await physics_frame
		_observe_frame()
		if main.match_over:
			finished_early = true
			break
	var wall_seconds := float(Time.get_ticks_usec() - started_usec) / 1000000.0
	var result := _collect_result(finished_early, wall_seconds)
	print("ANALYSIS_RESULT ", JSON.stringify(result))
	main.queue_free()
	await process_frame
	quit(0)

func _observe_frame() -> void:
	maximum_nodes = maxi(maximum_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	for player in main.players:
		if not is_instance_valid(player):
			continue
		if is_nan(player.global_position.x) or is_nan(player.global_position.y):
			nan_positions += 1
		var old_damage := float(previous_damage.get(player, 0.0))
		var new_damage := float(player.damage_dealt)
		if first_pvp_hit < 0.0 and new_damage > old_damage:
			first_pvp_hit = main.director.match_elapsed
		previous_damage[player] = new_damage

func _on_offer_closed(player: Node, card: Dictionary, auto_picked: bool) -> void:
	card_log.append({
		"time": snappedf(main.director.match_elapsed, 0.1),
		"player_id": player.player_id,
		"character": player.character_id,
		"card": str(card.id),
		"auto": auto_picked,
		"souls": player.souls,
		"hp": snappedf(player.hp, 0.1),
		"ringouts": player.respawn_count
	})

func _on_defeated(player: Node, attacker: Node) -> void:
	elimination_log.append({
		"time": snappedf(main.director.match_elapsed, 0.1),
		"player_id": player.player_id,
		"character": player.character_id,
		"cause": _attacker_kind(attacker),
		"attacker_id": attacker.player_id if is_instance_valid(attacker) and attacker.is_in_group("players") else -1,
		"ringouts": player.respawn_count,
		"damage_dealt": snappedf(player.damage_dealt, 0.1),
		"souls": player.souls,
		"cards": player.upgrades.duplicate()
	})

func _attacker_kind(attacker: Variant) -> String:
	if not is_instance_valid(attacker):
		return "environment"
	if attacker.is_in_group("players"):
		return "player"
	if attacker.is_in_group("realm_monsters"):
		return "monster"
	return "other"

func _collect_result(finished_early: bool, wall_seconds: float) -> Dictionary:
	var winner: Node = main.get_winner()
	var player_rows: Array[Dictionary] = []
	var total_ringouts := 0
	for player in main.players:
		if not is_instance_valid(player):
			continue
		total_ringouts += int(player.respawn_count)
		player_rows.append({
			"player_id": player.player_id,
			"character": player.character_id,
			"alive": not player.is_defeated,
			"hp": snappedf(player.hp, 0.1),
			"max_hp": snappedf(player.max_hp, 0.1),
			"score": player.score,
			"damage_dealt": snappedf(player.damage_dealt, 0.1),
			"souls": player.souls,
			"soul_picks": player.soul_picks,
			"cards": player.upgrades.duplicate(),
			"ringouts": player.respawn_count,
			"realm": player.realm_index
		})
	return {
		"seed": seed_value,
		"players": player_count,
		"seconds_simulated": snappedf(main.director.match_elapsed, 0.1),
		"wall_seconds": snappedf(wall_seconds, 0.001),
		"wall_per_sim_second": snappedf(wall_seconds / maxf(main.director.match_elapsed, 0.001), 0.0001),
		"match_over": finished_early,
		"finish_reason": main.director.finish_reason,
		"winner_id": winner.player_id if is_instance_valid(winner) else -1,
		"winner_character": winner.character_id if is_instance_valid(winner) else "",
		"first_pvp_hit": snappedf(first_pvp_hit, 0.1),
		"ringouts": total_ringouts,
		"nan_positions": nan_positions,
		"maximum_nodes": maximum_nodes,
		"final_nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"eliminations": elimination_log,
		"card_picks": card_log,
		"player_results": player_rows
	}
