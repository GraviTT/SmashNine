extends SceneTree
## Measures crystal payouts in a seeded real 8-bot match without changing its rules.

const MAIN_SCENE := "res://scenes/Main.tscn"

var seed_value := 1
var seconds := 180.0
var main: Node
var connected: Array[Node] = []
var breaks_by_player: Dictionary = {}
var breaks_by_realm: Dictionary = {}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			seed_value = int(arg.get_slice("=", 1))
		elif arg.begins_with("--seconds="):
			seconds = float(arg.get_slice("=", 1))
	call_deferred("_run")

func _run() -> void:
	node_added.connect(_on_node_added)
	main = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	main.match_seed = seed_value
	main.player_count = 8
	root.add_child(main)
	await process_frame
	for crystal in get_nodes_in_group("soul_crystals"):
		_connect_crystal(crystal)
	var frames := 0
	while not main.match_over and frames < int(seconds * 60.0):
		await physics_frame
		frames += 1
	var total_souls := 0
	var rows: Array[Dictionary] = []
	var crystal_rows: Array[Dictionary] = []
	for crystal in get_nodes_in_group("soul_crystals"):
		crystal_rows.append({"realm": crystal.realm_index, "hp": crystal.hp, "x": snappedf(crystal.global_position.x, 0.1), "y": snappedf(crystal.global_position.y, 0.1)})
	for player in main.players:
		total_souls += int(player.souls)
		rows.append({"id": player.player_id, "character": player.character_id, "souls": player.souls, "crystal_breaks": int(breaks_by_player.get(player.player_id, 0))})
	var total_breaks := 0
	for count in breaks_by_player.values():
		total_breaks += int(count)
	print("CRYSTAL_ECONOMY ", JSON.stringify({
		"seed": seed_value,
		"seconds": snappedf(main.director.match_elapsed, 0.1),
		"match_over": main.match_over,
		"total_souls": total_souls,
		"crystal_breaks": total_breaks,
		"crystal_souls": total_breaks * 10,
		"crystal_share_of_final_souls": snappedf(float(total_breaks * 10) / maxf(float(total_souls), 1.0), 0.001),
		"crystals_observed": connected.size(),
		"breaks_by_realm": breaks_by_realm,
		"standing_crystals": crystal_rows,
		"players": rows
	}))
	quit(0)

func _on_node_added(node: Node) -> void:
	call_deferred("_connect_crystal", node)

func _connect_crystal(crystal: Node) -> void:
	if not is_instance_valid(crystal) or not crystal.is_in_group("soul_crystals") or connected.has(crystal):
		return
	connected.append(crystal)
	crystal.broken.connect(_on_crystal_broken.bind(crystal.realm_index))

func _on_crystal_broken(_crystal: Node, attacker: Node, realm_index: int) -> void:
	if not is_instance_valid(attacker):
		return
	breaks_by_player[attacker.player_id] = int(breaks_by_player.get(attacker.player_id, 0)) + 1
	breaks_by_realm[realm_index] = int(breaks_by_realm.get(realm_index, 0)) + 1
