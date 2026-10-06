extends SceneTree
## Match rule regression tests (design/DECISIONS.md D1-D4, D7, D13). The match
## director is driven with virtual time; combatants run with physics disabled
## unless a test needs real frames.

const MAIN_SCENE := "res://scenes/Main.tscn"
const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const REALM_LAYOUT := preload("res://scripts/realms/RealmLayout.gd")
const MATCH_DIRECTOR := preload("res://scripts/match/MatchDirector.gd")
const SOUL_GROWTH := preload("res://scripts/match/SoulGrowth.gd")
const PROJECTILE := preload("res://scripts/Projectile.gd")

var arena: Node2D
var characters: Dictionary
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	characters = CHARACTER_REGISTRY.get_characters()
	var tests: Array[Callable] = [
		_test_timeline_transitions,
		_test_elimination_is_permanent_and_single_winner,
		_test_ringout_damage_and_respawn,
		_test_collapse_penalty_relocates,
		_test_final_judgment_picks_highest_hp,
		_test_soul_thresholds_and_cards,
		_test_ultimate_cooldown,
		_test_projectile_lifetime,
		_test_spawn_pairs_in_corners,
		_test_simultaneous_collapse_elimination,
		_test_combat_double_ko_is_draw,

		_test_relocation_cancels_startup_attack,
		_test_last_stand_offered_once
	]
	for test in tests:
		await test.call()
		if failed:
			quit(1)
			return
	print("Match rule tests passed (%d)" % tests.size())
	arena.queue_free()
	await process_frame
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	failed = true

func _new_director() -> Node:
	var director: Node = MATCH_DIRECTOR.new()
	arena.add_child(director)
	director.setup(REALM_LAYOUT.new())
	return director

func _new_player(character_id: String, player_id: int, director: Node, realm_index: int) -> Node:
	var player: Node = PLAYER_FACTORY.create(character_id)
	arena.add_child(player)
	player.setup(characters[character_id], player_id, false)
	player.set_physics_process(false)
	director.layout.assign_combatant(player, realm_index)
	player.global_position = director.layout.pick_spawn(realm_index)
	director.register_combatant(player)
	return player

func _advance_to(director: Node, time: float) -> void:
	while director.match_elapsed < time and not director.match_over:
		director.advance(clampf(time - director.match_elapsed, 0.000001, 0.05))

func _test_timeline_transitions() -> void:
	var director := _new_director()
	var layout: RefCounted = director.layout
	var transitions: Array[String] = []
	director.realm_state_changed.connect(func(realm_index: int, state: String) -> void:
		transitions.append("%.2f:%d:%s" % [director.match_elapsed, realm_index, state]))
	var corners: Array[int] = layout.get_corner_indices()
	var edges: Array[int] = layout.get_edge_indices()
	_advance_to(director, 119.9)
	if not transitions.is_empty():
		_fail("Realm state changed before 120 s: %s" % str(transitions))
		return
	_advance_to(director, 120.0)
	for realm_index in corners:
		if director.get_state(realm_index) != "warning":
			_fail("Corner %d not warned at 120 s" % realm_index)
			return
	if director.get_warning_seconds_left() != 30:
		_fail("Corner warning should last 30 s, got %d" % director.get_warning_seconds_left())
		return
	_advance_to(director, 150.0)
	for realm_index in corners:
		if director.get_state(realm_index) != "collapsed":
			_fail("Corner %d not collapsed at 150 s" % realm_index)
			return
	if director.get_state(REALM_LAYOUT.CENTRAL_REALM_INDEX) != "locked":
		_fail("Center opened before 210 s")
		return
	_advance_to(director, 210.0)
	if director.get_state(REALM_LAYOUT.CENTRAL_REALM_INDEX) != "stable":
		_fail("Center not open at 210 s")
		return
	for realm_index in edges:
		if director.get_state(realm_index) != "warning":
			_fail("Edge %d not warned at 210 s" % realm_index)
			return
		var portals: Array = layout.get_portals(realm_index, Callable(director, "get_state"))
		var reaches_center := false
		for portal in portals:
			reaches_center = reaches_center or portal.destination == REALM_LAYOUT.CENTRAL_REALM_INDEX
		if not reaches_center:
			_fail("Warned edge %d has no portal to the open center" % realm_index)
			return
	_advance_to(director, 240.0)
	for realm_index in edges:
		if director.get_state(realm_index) != "collapsed":
			_fail("Edge %d not collapsed at 240 s" % realm_index)
			return
	if director.phase != MATCH_DIRECTOR.PHASE_CENTRAL:
		_fail("Phase should be central brawl at 240 s, got %s" % director.phase)
		return
	_advance_to(director, 360.0)
	if director.phase != MATCH_DIRECTOR.PHASE_SUDDEN_DEATH:
		_fail("Sudden death did not start at 360 s")
		return
	# 4 corner warnings + 4 corner collapses + center open + 4 edge warnings + 4 edge collapses.
	if transitions.size() != 17:
		_fail("Expected 17 realm transitions, got %d: %s" % [transitions.size(), str(transitions)])
		return
	_advance_to(director, 420.0)
	if not director.match_over or director.finish_reason != "no survivors":
		_fail("Final judgment did not end an empty match at 420 s")
		return
	director.queue_free()

func _test_elimination_is_permanent_and_single_winner() -> void:
	var director := _new_director()
	var players: Array[Node] = []
	for i in 3:
		players.append(_new_player(["frey", "yuki", "nova"][i], i + 1, director, 0))
	var winners: Array = []
	director.match_finished.connect(func(winner: Node, _reason: String) -> void: winners.append(winner))
	players[0].apply_environment_damage(500.0)
	await create_timer(0.2).timeout
	_advance_to(director, 10.0)
	if not players[0].is_defeated:
		_fail("HP 0 combatant came back")
		return
	if not winners.is_empty():
		_fail("Winner declared with two survivors")
		return
	players[1].apply_environment_damage(500.0)
	players[1].apply_environment_damage(500.0)
	await process_frame
	if winners.size() != 1 or winners[0] != players[2]:
		_fail("Expected exactly one winner signal for Nova, got %s" % str(winners))
		return
	var standings: Array[Node] = director.get_standings()
	if standings[0] != players[2] or standings[1] != players[1] or standings[2] != players[0]:
		_fail("Standings should be winner, then eliminations in reverse order")
		return
	for player in players:
		player.queue_free()
	director.queue_free()

func _test_ringout_damage_and_respawn() -> void:
	var director := _new_director()
	var player := _new_player("frey", 1, director, 0)
	player.ringout_damage = 25.0
	var hp_before: float = player.hp
	player.global_position = Vector2(player.blast_left - 50.0, player.global_position.y)
	player._ringout()
	if not is_equal_approx(player.hp, hp_before - 25.0):
		_fail("Ring-out should cost exactly 25 HP, cost %.1f" % (hp_before - player.hp))
		return
	if player.realm_index != 0 or not director.layout.get_bounds(0).has_point(player.global_position):
		_fail("Ring-out survivor should respawn inside the same realm")
		return
	if not player.is_invulnerable():
		_fail("Ring-out respawn should grant protection")
		return
	if player.apply_hit(null, 10.0, 100.0, Vector2.RIGHT):
		_fail("Protected combatant took a hit")
		return
	player.queue_free()
	director.queue_free()

func _test_collapse_penalty_relocates() -> void:
	var director := _new_director()
	var corner: int = director.layout.get_corner_indices()[0]
	var survivor := _new_player("yuki", 1, director, corner)
	var doomed := _new_player("luna", 2, director, corner)
	var bystander := _new_player("nova", 3, director, director.layout.get_edge_indices()[0])
	doomed.hp = 20.0
	var hp_before: float = survivor.hp
	_advance_to(director, 150.0)
	if director.get_state(survivor.realm_index) == "collapsed" or not director.is_playable(survivor.realm_index):
		_fail("Collapse survivor was not moved to a playable realm")
		return
	if not is_equal_approx(survivor.hp, hp_before - MATCH_DIRECTOR.COLLAPSE_PENALTY):
		_fail("Collapse penalty should be %d HP" % int(MATCH_DIRECTOR.COLLAPSE_PENALTY))
		return
	if not survivor.is_invulnerable():
		_fail("Collapse survivor should be protected for a moment")
		return
	if not doomed.is_defeated:
		_fail("A 20 HP combatant should be eliminated by the 30 HP collapse penalty")
		return
	for player in [survivor, doomed, bystander]:
		player.queue_free()
	director.queue_free()

func _test_final_judgment_picks_highest_hp() -> void:
	var director := _new_director()
	var center: int = REALM_LAYOUT.CENTRAL_REALM_INDEX
	var low := _new_player("frey", 1, director, center)
	var high := _new_player("yuki", 2, director, center)
	# Stand in the middle so the sudden-death band never reaches them.
	low.global_position = director.layout.get_bounds(center).get_center()
	high.global_position = low.global_position
	low.hp = 30.0
	high.hp = 60.0
	_advance_to(director, 420.0)
	if director.winner != high or director.finish_reason != "final judgment":
		_fail("Final judgment should pick the survivor with the most HP")
		return
	low.queue_free()
	high.queue_free()
	director.queue_free()

func _test_soul_thresholds_and_cards() -> void:
	var director := _new_director()
	var growth: Node = SOUL_GROWTH.new()
	growth.match_seed = 7
	arena.add_child(growth)
	var bot := _new_player("yuki", 1, director, 0)
	growth.register_player(bot)
	var thresholds: Array[int] = []
	bot.soul_threshold_reached.connect(func(_player: Node, pick: int) -> void: thresholds.append(pick))
	var base_attack: float = bot.attack_power
	bot.add_souls(24)
	if not thresholds.is_empty():
		_fail("Threshold fired below 25 souls")
		return
	bot.add_souls(60)
	if str(thresholds) != "[1, 2, 3]":
		_fail("Crossing 25/50/75 at once should fire 1, 2, 3; got %s" % str(thresholds))
		return
	for attempt in 40:
		await create_timer(0.1).timeout
		if bot.soul_picks >= 3:
			break
	if bot.soul_picks != 3 or bot.upgrades.size() != 3:
		_fail("Bot should have taken exactly 3 cards, took %d" % bot.soul_picks)
		return
	bot.add_souls(100)
	await create_timer(1.0).timeout
	if bot.soul_picks != 3:
		_fail("A fourth soul pick happened")
		return
	if bot.attack_power <= base_attack:
		_fail("Three picks should advance the growth curve (attack %.1f -> %.1f)" % [base_attack, bot.attack_power])
		return
	var human := _new_player("frey", 2, director, 0)
	human.is_human = true
	growth.register_player(human)
	human.add_souls(25)
	if growth.get_offer(human).is_empty():
		_fail("Human did not get a card offer")
		return
	await create_timer(SOUL_GROWTH.CHOICE_TIME - 1.0).timeout
	if human.soul_picks != 0:
		_fail("Human card was auto-picked before %d s" % int(SOUL_GROWTH.CHOICE_TIME))
		return
	await create_timer(1.5).timeout
	if human.soul_picks != 1:
		_fail("Human card was not auto-picked after %d s" % int(SOUL_GROWTH.CHOICE_TIME))
		return
	bot.queue_free()
	human.queue_free()
	growth.queue_free()
	director.queue_free()

func _test_ultimate_cooldown() -> void:
	var director := _new_director()
	var frey := _new_player("frey", 1, director, 0)
	frey.ultimate()
	if frey.is_ultimate_ready():
		_fail("Ultimate did not start its cooldown")
		return
	frey.attack_lock_timer = 0.0
	frey.action_locked_until_land = false
	frey.ultimate_cooldown_timer = 1.0
	frey.ultimate()
	if not is_equal_approx(frey.ultimate_cooldown_timer, 1.0):
		_fail("Ultimate fired again during cooldown")
		return
	frey.queue_free()
	director.queue_free()

func _test_projectile_lifetime() -> void:
	for lifetime in [0.2, 1.0, 1.35]:
		var owner_node := Node2D.new()
		arena.add_child(owner_node)
		var projectile := Area2D.new()
		projectile.set_script(PROJECTILE)
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		projectile.add_child(shape)
		var visual := ColorRect.new()
		visual.name = "Visual"
		projectile.add_child(visual)
		arena.add_child(projectile)
		projectile.configure(owner_node, Vector2(10, 10), 1.0, 1.0, Vector2.RIGHT, Color.WHITE, 0.0, lifetime)
		var frames := 0
		while is_instance_valid(projectile) and not projectile.is_queued_for_deletion() and frames < 400:
			await physics_frame
			frames += 1
		var expected := roundi(lifetime * Engine.physics_ticks_per_second)
		# physics_frame fires before nodes process, so the count trails by one frame.
		if absi(frames - expected) > 2:
			_fail("Projectile lifetime %.2f s lasted %d physics frames, expected %d +/- 2" % [lifetime, frames, expected])
			return
		owner_node.queue_free()

func _test_spawn_pairs_in_corners() -> void:
	var main: Node = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	main.player_count = 8
	main.match_seed = 11
	root.add_child(main)
	await process_frame
	var counts: Dictionary = {}
	for player in main.players:
		counts[player.realm_index] = int(counts.get(player.realm_index, 0)) + 1
	var corners: Array[int] = main.layout.get_corner_indices()
	for realm_index in counts:
		if not corners.has(realm_index) or counts[realm_index] != 2:
			_fail("8 players should start two per corner realm, got %s" % str(counts))
			break
	var seats: Dictionary = {}
	for player in main.players:
		var pair: Array = seats.get(player.realm_index, [])
		pair.append(player.character_id)
		seats[player.realm_index] = pair
	for realm_index in seats:
		if seats[realm_index][0] == seats[realm_index][1]:
			_fail("Opening pair in realm %d is a mirror match: %s" % [realm_index, str(seats[realm_index])])
			break
	main.queue_free()
	await process_frame

## CODEX-ANALYST-01/02 P0: when a collapse wave would take the last fighters out,
## the healthiest one keeps 1 HP and wins - same realm or different realms of the
## wave. A winner is never a defeated fighter.
func _test_simultaneous_collapse_elimination() -> void:
	var corners: Array[int] = REALM_LAYOUT.new().get_corner_indices()
	for case_realms in [[corners[0], corners[0]], [corners[0], corners[1]]]:
		var director := _new_director()
		var first := _new_player("frey", 1, director, case_realms[0])
		var second := _new_player("yuki", 2, director, case_realms[1])
		first.hp = 20.0
		second.hp = 25.0
		var finishes: Array[String] = []
		director.match_finished.connect(func(_winner: Node, reason: String) -> void: finishes.append(reason))
		_advance_to(director, 150.0)
		await process_frame
		var label := "same realm" if case_realms[0] == case_realms[1] else "different realms"
		if finishes.size() != 1 or director.winner != second or second.is_defeated:
			_fail("%s: expected Yuki (25 HP) to survive the collapse and win once, got %s, winner defeated=%s" % [label, str(finishes), str(second.is_defeated)])
			return
		if not is_equal_approx(second.hp, 1.0) or not first.is_defeated:
			_fail("%s: expected Frey out and Yuki at 1 HP, got Yuki HP %.1f" % [label, second.hp])
			return
		first.queue_free()
		second.queue_free()
		director.queue_free()

## The last two knock each other out in the same frame of combat: a draw, not a dead winner.
func _test_combat_double_ko_is_draw() -> void:
	var director := _new_director()
	var first := _new_player("frey", 1, director, 0)
	var second := _new_player("yuki", 2, director, 0)
	first.hp = 5.0
	second.hp = 5.0
	first.apply_hit(second, 50.0, 100.0, Vector2.RIGHT)
	second.apply_hit(first, 50.0, 100.0, Vector2.LEFT)
	await process_frame
	if not director.match_over or director.winner != null or director.finish_reason != "double KO":
		_fail("Same-frame double KO should end as a draw, got winner %s (%s)" % [str(director.winner), director.finish_reason])
		return
	first.queue_free()
	second.queue_free()
	director.queue_free()

## CODEX-ANALYST-01 P1: a relocation during an attack's start-up cancels the attack.
func _test_relocation_cancels_startup_attack() -> void:
	var director := _new_director()
	var yuki := _new_player("yuki", 1, director, 0)
	var created: Array[Node] = []
	var on_node_added := func(node: Node) -> void:
		if node is Area2D and node.get_script() != null:
			created.append(node)
	node_added.connect(on_node_added)
	yuki.basic_attack()
	yuki.reset_for_map(director.layout.pick_spawn(1), director.layout.get_spawn_points(1))
	await create_timer(0.4).timeout
	node_added.disconnect(on_node_added)
	if not created.is_empty():
		_fail("A start-up attack fired after relocation (%d hitboxes)" % created.size())
		return
	yuki.queue_free()
	director.queue_free()

## CODEX-ANALYST-01 P2: Last Stand (ring-out damage x0.7) is not offered after one copy.
func _test_last_stand_offered_once() -> void:
	var cards := preload("res://scripts/match/SoulCards.gd")
	var rng := RandomNumberGenerator.new()
	var owned: Array[String] = ["last_stand"]
	for attempt in 200:
		rng.seed = attempt
		for card in cards.draw_offer(rng, owned):
			if card.id == "last_stand":
				_fail("Last Stand offered again to a player who owns it")
				return
