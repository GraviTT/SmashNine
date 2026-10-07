extends SceneTree
## Same pairing/telemetry as tests/analysis/duel_probe.gd, but removes both monsters
## and soul crystals every frame so the result is actually fighter versus fighter.

const MAIN_SCENE := "res://scenes/Main.tscn"

var seed_value := 1
var first_character := "rio"
var spawned: Dictionary = {}
var hits: Dictionary = {}
var falls: Dictionary = {}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			seed_value = int(arg.get_slice("=", 1))
		elif arg.begins_with("--first="):
			first_character = arg.get_slice("=", 1)
	call_deferred("_run")

func _run() -> void:
	var main: Node = load(MAIN_SCENE).instantiate()
	main.match_seed = seed_value
	main.player_count = 2
	root.add_child(main)
	await process_frame
	main._start_match(first_character)
	main.players[0].is_human = false
	_clear_pve()
	main.realm_monster_spawner.set_process(false)
	main.realm_monster_spawner.monsters_by_realm.clear()
	node_added.connect(_on_node_added)
	for player in main.players:
		spawned[player.display_name] = 0
		hits[player.display_name] = 0
		falls[player.display_name] = {"knocked": 0, "self": 0}
		player.damaged.connect(_on_damaged)
	var frames := 0
	while not main.match_over and frames < 60 * 150:
		await physics_frame
		frames += 1
		_clear_pve()
	var parts: Array[String] = []
	for player in main.players:
		parts.append("%s dmg=%.0f hp=%.0f souls=%d ringouts=%d (knocked %d, self %d) spawned=%d hits=%d" % [player.display_name, player.damage_dealt, player.hp, player.souls, player.respawn_count, falls[player.display_name].knocked, falls[player.display_name].self, spawned[player.display_name], hits[player.display_name]])
	var winner: Node = main.director.winner
	print("CLEAN_DUEL seed=%d first=%s t=%.0f winner=%s | %s" % [seed_value, first_character, main.director.match_elapsed, winner.display_name if is_instance_valid(winner) else "none", " | ".join(parts)])
	quit(0)

func _clear_pve() -> void:
	for monster in get_nodes_in_group("realm_monsters"):
		monster.queue_free()
	for crystal in get_nodes_in_group("soul_crystals"):
		crystal.queue_free()

func _on_node_added(node: Node) -> void:
	if node is Area2D:
		call_deferred("_count_spawn", node)

func _count_spawn(node: Node) -> void:
	if not is_instance_valid(node):
		return
	var source = node.get("source")
	if source is Node and is_instance_valid(source) and spawned.has(source.display_name):
		spawned[source.display_name] += 1

func _on_damaged(player: Node, _amount: float, attacker: Variant, source: String) -> void:
	if source == "environment" and falls.has(player.display_name):
		falls[player.display_name]["knocked" if attacker is Node and is_instance_valid(attacker) else "self"] += 1
	if source == "hit" and attacker is Node and is_instance_valid(attacker) and hits.has(attacker.display_name):
		hits[attacker.display_name] += 1
