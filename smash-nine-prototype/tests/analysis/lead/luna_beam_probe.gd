extends "res://tests/soak_match.gd"
## Brave Luna's star beam, beam by beam, in whole bot matches (2026-11-25, for the user's choice
## on the beam: reports/luna-beam-2026-11-25/). The match is tests/soak_match.gd's own loop; this
## only watches it, and for the "fixed" variant swaps the Luna bots' brain before the first frame.
## Usage: <godot> --headless --path . --fixed-fps 60 -s tests/analysis/lead/luna_beam_probe.gd -- --seconds=480 --seed=2001 [--variant=current|control|fixed]
##   current  the match as soak_match.gd plays it (the same SOAK_RESULT, plus the "luna" block)
##   control  every bot's brain swapped for an unchanged copy: must replay "current"
##   fixed    Luna bots press the beam 4.4 s after the ultimate press (the rule until 2026-11-24)
## Prints one "LUNA_BEAM {json}" line per beam, then the SOAK_RESULT line.
## A beam line: "into" seconds into her form at the press; "hits" [seconds into the beam, fighter,
## "t" tick or "f" last blast, damage taken, the fighter's damage multiplier]; "ringouts" [fighter,
## seconds after the beam last hit it, ring-out damage, "t" or "f"]: ring-outs credited to her
## (she was the last attacker) within AFTERMATH s of the beam's last hit on that fighter, with the
## line it crossed ("side" or "bottom"). "carried" [fighter, px along the beam between its first
## and last tick, px it fell meanwhile]; "blasts" [fighter, HP % left, on the floor, px to the side
## blast line the beam points at, px above the bottom ring-out line] at the last blast.

const CONTROL_AI := preload("res://tests/analysis/lead/luna_control_ai.gd")
const FIXED_AI := preload("res://tests/analysis/lead/luna_fixed_beam_ai.gd")
const AFTERMATH := 3.0

var variant := "current"
var frame_index := 0
var brains_swapped := false
## Per Luna (instance id): {"node", "formed", "formed_at": frame, "beam": record or null,
## "pending": her last hit not yet told apart}.
var lunas: Dictionary = {}
## Beams that ended, kept AFTERMATH s for the ring-outs that follow them.
var settling: Array[Dictionary] = []
var forms := 0
var forms_without_beam := 0
var beam_count := 0
var beam_hit_count := 0
var beam_ticks := 0
var beam_finals := 0
var beam_damage := 0.0
var beam_ringouts := 0
## Every ring-out credited to a Luna, beam or not.
var luna_ringouts := 0
## Ring-outs and knock-outs credited to each character (the last attacker), all fighters.
var ringouts_by: Dictionary = {}
var kos_by: Dictionary = {}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--variant="):
			variant = arg.get_slice("=", 1)
	if not ["current", "control", "fixed"].has(variant):
		push_error("--variant must be current, control or fixed; got %s" % variant)
		quit(2)
		return
	super._initialize()

## soak_match.gd calls this once a physics frame, at the frame's start: before the fighters'
## own physics step, so the first call comes before any bot has thought once.
func _check_positions() -> void:
	super._check_positions()
	if not brains_swapped:
		brains_swapped = true
		_swap_brains()
		for player in main.players:
			if str(player.character_id) == "luna":
				lunas[player.get_instance_id()] = {"node": player, "formed": false, "formed_at": 0, "beam": null, "pending": null}
	frame_index += 1
	for watch in lunas.values():
		_watch(watch)
	while not settling.is_empty() and frame_index - int(settling[0]._end_frame) > int(AFTERMATH / FRAME_TIME) + 2:
		_report(settling.pop_front())

## The new brain takes over every value the old one already holds (its timers were rolled when
## the fighter was set up).
func _swap_brains() -> void:
	if variant == "current":
		return
	for player in main.players:
		if variant == "fixed" and str(player.character_id) != "luna":
			continue
		var old_ai = player.ai_controller
		var new_ai = (FIXED_AI if variant == "fixed" else CONTROL_AI).new()
		for property in old_ai.get_property_list():
			if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
				new_ai.set(str(property.name), old_ai.get(str(property.name)))
		player.ai_controller = new_ai

func _ticks(luna: Node) -> float:
	return float(luna.move_counts.get("beam_ticks", 0.0))

func _watch(watch: Dictionary) -> void:
	var luna: Node = watch.node
	if not is_instance_valid(luna):
		return
	_settle(watch)
	var formed: bool = bool(luna.transformed)
	if formed and not watch.formed:
		watch.formed = true
		watch.formed_at = frame_index
		forms += 1
	if formed and bool(luna.transformation_finishing) and watch.beam == null:
		watch.beam = {
			"seed": seed_value, "variant": variant, "seat": main.players.find(luna),
			"t": snappedf(main.director.match_elapsed, 0.1),
			"into": snappedf(float(frame_index - int(watch.formed_at)) * FRAME_TIME, 0.01),
			"fired": false, "ticks": 0, "finals": 0, "tick_damage": 0.0, "final_damage": 0.0,
			"other_hits": 0, "other_damage": 0.0, "hits": [], "ringouts": [], "carried": [], "blasts": [],
			"_luna": luna.get_instance_id(), "_end_frame": 0, "_last": {}, "_first_at": {}, "_last_at": {}, "_names": {}
		}
	if watch.beam != null and is_instance_valid(luna.heart_laser):
		watch.beam.fired = true
	if not formed and watch.formed:
		watch.formed = false
		if watch.beam == null:
			forms_without_beam += 1
		else:
			_close(watch)

func _on_defeated(player: Node, attacker: Node) -> void:
	super._on_defeated(player, attacker)
	if is_instance_valid(attacker) and attacker.is_in_group("players"):
		var id := str(attacker.character_id)
		kos_by[id] = int(kos_by.get(id, 0)) + 1

func _on_damaged(player: Node, amount: float, attacker: Variant, source: String) -> void:
	super._on_damaged(player, amount, attacker, source)
	if not is_instance_valid(attacker):
		return
	# Environment damage with an attacker is a ring-out, credited to the last attacker.
	if source == "environment" and attacker.is_in_group("players"):
		var id := str(attacker.character_id)
		ringouts_by[id] = int(ringouts_by.get(id, 0)) + 1
	if not lunas.has(attacker.get_instance_id()):
		return
	var watch: Dictionary = lunas[attacker.get_instance_id()]
	if source == "environment":
		_credit_ringout(watch, player, amount)
		return
	if source != "hit":
		return
	# A hit by a Luna whose beam is out. Which kind it was shows only afterwards: a beam tick
	# raises her "beam_ticks" count right after the hit lands, the beam's last blast does not.
	_settle(watch)
	if watch.beam == null or not is_instance_valid(attacker.heart_laser):
		return
	var laser: Node = attacker.heart_laser
	var multiplier: float = float(attacker.attack_power) / (100.0 + maxf(float(player.defense), 0.0)) * float(player.incoming_damage_scale)
	if float(player.star_mark_timer) > 0.0:
		multiplier *= float(player.STAR_MARK_DAMAGE_SCALE)
	var along: float = float(laser.direction.x)
	var side_line: float = float(player.blast_right) if along > 0.0 else float(player.blast_left)
	watch.pending = {
		"amount": amount, "victim": player, "count": _ticks(attacker),
		"last_frame": float(laser.elapsed) >= float(laser.duration),
		"at": snappedf(float(laser.elapsed), 0.01), "multiplier": snappedf(multiplier, 0.001),
		"where": player.global_position, "along": along,
		"snapshot": [str(player.display_name), snappedf(100.0 * float(player.hp) / maxf(float(player.max_hp), 1.0), 1.0), player.is_on_floor(),
			snappedf(absf(side_line - player.global_position.x), 1.0), snappedf(float(player.ringout_y) - player.global_position.y, 1.0)]
	}

func _settle(watch: Dictionary) -> void:
	if watch.pending == null:
		return
	var hit: Dictionary = watch.pending
	watch.pending = null
	if watch.beam == null:
		return
	var beam: Dictionary = watch.beam
	var amount: float = float(hit.amount)
	var kind := ""
	if _ticks(watch.node) > float(hit.count):
		kind = "t"
		beam.ticks = int(beam.ticks) + 1
		beam.tick_damage = float(beam.tick_damage) + amount
	elif bool(hit.last_frame):
		kind = "f"
		beam.finals = int(beam.finals) + 1
		beam.final_damage = float(beam.final_damage) + amount
		beam.blasts.append(hit.snapshot)
	else:
		beam.other_hits = int(beam.other_hits) + 1
		beam.other_damage = float(beam.other_damage) + amount
		return
	var victim: Node = hit.victim
	var victim_name := str(victim.display_name) if is_instance_valid(victim) else "?"
	beam.hits.append([hit.at, victim_name, kind, snappedf(amount, 0.01), hit.multiplier])
	if is_instance_valid(victim):
		var key: int = victim.get_instance_id()
		beam._last[key] = {"frame": frame_index, "kind": kind}
		if kind == "t":
			var along_beam: Vector2 = Vector2(float(hit.where.x) * float(hit.along), float(hit.where.y))
			if not beam._first_at.has(key):
				beam._first_at[key] = along_beam
			beam._last_at[key] = along_beam
			beam._names[key] = victim_name

func _credit_ringout(watch: Dictionary, victim: Node, amount: float) -> void:
	luna_ringouts += 1
	_settle(watch)
	var candidates: Array = []
	if watch.beam != null:
		candidates.append(watch.beam)
	for index in range(settling.size() - 1, -1, -1):
		if int(settling[index]._luna) == watch.node.get_instance_id():
			candidates.append(settling[index])
	var limit := int(AFTERMATH / FRAME_TIME)
	for beam in candidates:
		var last: Variant = beam._last.get(victim.get_instance_id())
		if last != null and frame_index - int(last.frame) <= limit:
			var how := "bottom" if float(victim.global_position.y) > float(victim.ringout_y) else "side"
			beam.ringouts.append([str(victim.display_name), snappedf(float(frame_index - int(last.frame)) * FRAME_TIME, 0.01), snappedf(amount, 0.1), last.kind, how])
			beam_ringouts += 1
			return

func _close(watch: Dictionary) -> void:
	_settle(watch)
	var beam: Dictionary = watch.beam
	watch.beam = null
	beam._end_frame = frame_index
	settling.append(beam)

func _report(beam: Dictionary) -> void:
	for key in beam._first_at:
		var moved: Vector2 = beam._last_at[key] - beam._first_at[key]
		beam.carried.append([beam._names[key], snappedf(moved.x, 1.0), snappedf(moved.y, 1.0)])
	for key in ["_luna", "_end_frame", "_last", "_first_at", "_last_at", "_names"]:
		beam.erase(key)
	beam.tick_damage = snappedf(float(beam.tick_damage), 0.1)
	beam.final_damage = snappedf(float(beam.final_damage), 0.1)
	beam.other_damage = snappedf(float(beam.other_damage), 0.1)
	beam_count += 1
	if int(beam.ticks) + int(beam.finals) > 0:
		beam_hit_count += 1
	beam_ticks += int(beam.ticks)
	beam_finals += int(beam.finals)
	beam_damage += float(beam.tick_damage) + float(beam.final_damage)
	print("LUNA_BEAM ", JSON.stringify(beam))

func _collect_result(finished_early: bool) -> Dictionary:
	for watch in lunas.values():
		if watch.beam != null:
			_close(watch)
	while not settling.is_empty():
		_report(settling.pop_front())
	var result := super._collect_result(finished_early)
	result["variant"] = variant
	result["luna"] = {
		"seats": lunas.size(), "forms": forms, "forms_without_beam": forms_without_beam,
		"beams": beam_count, "beams_that_hit": beam_hit_count, "ticks": beam_ticks,
		"finals": beam_finals, "damage": snappedf(beam_damage, 0.1),
		"beam_ringouts": beam_ringouts, "ringouts_credited": luna_ringouts
	}
	result["ringouts_by"] = ringouts_by
	result["kos_by"] = kos_by
	return result
