extends SceneTree
## Moves against bodies that vanish (2026-11-26; the lead approved it after the same kind of bug
## came up four times: Rio's flurry and counter, Nova's orb, and Rio's cuts under practice's reset).
##
## In a match only monsters are freed while a fight goes on: one dies, and its node is gone while a
## move still holds it. Handing a freed node to a typed parameter is a script error that stops the
## move where it stands, and what should have run after it never does (a list not cleared, a key
## dead until the next hit).
##
## So: every fighter uses every move beside three monsters (the one in front is hostile and hits
## back), and all three are freed at one moment of the move: seven moments, a lane each, played
## side by side, and an eighth lane where nobody presses and nothing is freed. The same key is
## pressed again three times for the moves that have later presses. Luna does it once more as
## Brave Luna. Then, for every lane: the engine logged no script error and no engine error, the
## fighter can start an attack again, and its ultimate starts again once its cooldown is filled.
## -- --only=<fighter> runs one fighter ("brave" for Brave Luna).

const FRAME_WATCHDOG := preload("res://tests/support/frame_watchdog.gd")
const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const MONSTER := preload("res://scripts/RealmMonster.gd")
const CATCHER := preload("res://tests/support/error_catcher.gd")

## Physics frames after the first press at which the lane's monsters are freed.
const MOMENTS: Array[int] = [1, 4, 9, 16, 26, 40, 60]
## The same key again at these frames (Frey's L, Rio's K, U and I, Nova's I, Xion's U, Luna's I).
const AGAIN: Array[int] = [14, 34, 70]
const PLAY_FRAMES := 130
## A fighter is given this long to be free again after the play (Rio's stuck swords wait 3 s).
const RECOVER_FRAMES := 420
const LANE_GAP := 6000.0
const MOVES: Array[String] = ["j", "k", "l", "u", "i"]
const MONSTER_PLACES: Array[Vector2] = [Vector2(110, -40), Vector2(-150, -40), Vector2(300, -40)]

var arena: Node2D
## Script errors and engine errors logged while the test runs.
var catcher := CATCHER.new()
var failed := false
var only := ""
var batches := 0

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			only = argument.trim_prefix("--only=")
	# Hang guard in frames, not seconds: under load the test needs more time, not more frames.
	FRAME_WATCHDOG.start(self, 540.0, "Freed target test timed out")
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error(message)
	failed = true

func _run() -> void:
	OS.add_logger(catcher)
	arena = Node2D.new()
	root.add_child(arena)
	for character_id in CHARACTER_REGISTRY.get_character_ids():
		if only != "" and only != character_id:
			continue
		for move in MOVES:
			await _batch(character_id, move, false)
	if only == "" or only == "brave":
		for move in ["j", "k", "l", "i"]:
			await _batch("luna", move, true)
	arena.queue_free()
	await process_frame
	OS.remove_logger(catcher)
	if failed:
		quit(1)
		return
	print("Freed target tests passed (%d fighter-and-move sets, %d moments each; no script error, every fighter free again)" % [batches, MOMENTS.size()])
	quit(0)

func _floor(at: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.add_to_group("platforms")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2400, 40)
	shape.shape = rect
	body.add_child(shape)
	body.position = at + Vector2(0, 20)
	arena.add_child(body)

## A person's fighter with nobody at the keys: it does what the test presses.
func _person(character_id: String, player_id: int, at: Vector2, lane: int) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(character_id)
	arena.add_child(fighter)
	fighter.global_position = at
	fighter.setup(CHARACTER_REGISTRY.get_characters()[character_id], player_id, true)
	fighter.set_process_unhandled_input(false)
	fighter.ringout_y = 100000.0
	# Its own realm: nothing of one lane looks for targets in another.
	fighter.realm_index = lane
	return fighter

func _monster(lane: int, at: Vector2, hostile: bool) -> Node:
	var monster := CharacterBody2D.new()
	monster.set_script(MONSTER)
	monster.setup("mossling", lane, at)
	arena.add_child(monster)
	monster.set_realm_active(true)
	monster.hostile = hostile
	return monster

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame

func _press(fighter: Node, move: String) -> void:
	match move:
		"j":
			fighter.basic_attack()
		"k":
			fighter.skill_one()
		"l":
			fighter.press_skill_two()
		"u":
			fighter.press_skill_three()
		"i":
			fighter.ultimate()

func _report(what: String) -> void:
	for line in catcher.take():
		_fail("%s: %s" % [what, line])

## One fighter, one move: seven lanes whose monsters go at seven moments, and a lane left alone.
func _batch(character_id: String, move: String, brave: bool) -> void:
	var name := "%s%s %s" % ["Brave " if brave else "", character_id, move.to_upper()]
	var lanes: Array[Dictionary] = []
	for lane in MOMENTS.size() + 1:
		var origin := Vector2(lane * LANE_GAP, 0.0)
		_floor(origin)
		var fighter := _person(character_id, lane + 1, origin + Vector2(0, -2), lane)
		var monsters: Array[Node] = []
		for index in MONSTER_PLACES.size():
			monsters.append(_monster(lane, origin + MONSTER_PLACES[index], index == 0 and lane < MOMENTS.size()))
		lanes.append({"fighter": fighter, "monsters": monsters, "moment": MOMENTS[lane] if lane < MOMENTS.size() else -1})
	if move == "u" and not bool(lanes[0].fighter.has_skill_three()):
		await _clear()
		return
	batches += 1
	await _frames(24)
	var acting := lanes.slice(0, MOMENTS.size())
	if brave:
		for lane: Dictionary in acting:
			lane.fighter.ultimate()
		await _frames(90)
		for lane: Dictionary in acting:
			if not bool(lane.fighter.transformed):
				_fail("Test setup: Luna should be Brave Luna before %s" % name)
			lane.fighter.refill_cooldowns()
	for lane: Dictionary in acting:
		lane.fighter.facing = 1
	for frame in PLAY_FRAMES:
		for lane: Dictionary in acting:
			if frame == 0 or AGAIN.has(frame):
				_press(lane.fighter, move)
			if frame == int(lane.moment):
				for monster: Node in lane.monsters:
					if is_instance_valid(monster):
						monster.queue_free()
		await physics_frame
	_report("%s, while the move played" % name)
	# The lane left alone: no move of another lane reached it.
	var still: Dictionary = lanes[MOMENTS.size()]
	if still.fighter.hp < still.fighter.max_hp:
		_fail("%s: a fighter in another realm, 6000 px away, was hurt (HP %.1f of %.1f)" % [name, still.fighter.hp, still.fighter.max_hp])
	for monster: Node in still.monsters:
		if not is_instance_valid(monster) or monster.hp < monster.max_hp:
			_fail("%s: a monster in another realm, 6000 px away, was hurt" % name)
	# Every fighter is free to attack again...
	var waited := 0
	while waited < RECOVER_FRAMES:
		var busy := false
		for lane: Dictionary in acting:
			if not lane.fighter._can_start_attack() or float(lane.fighter.movement_freeze_timer) > 0.0:
				busy = true
		if not busy:
			break
		await physics_frame
		waited += 1
	for lane: Dictionary in acting:
		var fighter: Node = lane.fighter
		if not fighter._can_start_attack() or float(fighter.movement_freeze_timer) > 0.0:
			_fail("%s, monsters freed at frame %d: the fighter is still held %d frames after the move (lock %.2f, hitstun %.2f, freeze %.2f, guard recovery %.2f, locked until land %s)" % [name, int(lane.moment), PLAY_FRAMES + RECOVER_FRAMES, fighter.attack_lock_timer, fighter.hitstun_timer, fighter.movement_freeze_timer, fighter.guard_recovery_timer, fighter.action_locked_until_land])
	_report("%s, after the move" % name)
	# ...and its ultimate starts again once it is ready (a move cut short left Rio's I dead).
	for lane: Dictionary in acting:
		var fighter: Node = lane.fighter
		if not fighter._can_start_attack():
			continue
		fighter.refill_cooldowns()
		var followups := float(fighter.move_counts.get("i2", 0.0))
		fighter.ultimate()
		if float(fighter.ultimate_cooldown_timer) <= 0.0 and float(fighter.move_counts.get("i2", 0.0)) <= followups:
			_fail("%s, monsters freed at frame %d: the ultimate does not start afterwards" % [name, int(lane.moment)])
	await _frames(40)
	_report("%s, in the ultimate afterwards" % name)
	await _clear()

func _clear() -> void:
	for child in arena.get_children():
		child.queue_free()
	await process_frame
	await physics_frame
	_report("clearing the lanes")
