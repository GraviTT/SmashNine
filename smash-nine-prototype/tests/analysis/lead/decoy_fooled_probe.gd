extends "res://tests/soak_match.gd"
## Whole bot matches with another chance that a bot takes Rio's decoy for him (2026-11-25, the
## lead's question: is Rio strong by his kit, or because bots are fooled 60% of the time?).
## The game's number stays EnemyAI.DECOY_FOOLED_CHANCE 0.6; every bot's brain is swapped before
## the first frame for a copy that rolls against --fooled instead.
## Usage: <godot> --headless --path . --fixed-fps 60 -s tests/analysis/lead/decoy_fooled_probe.gd -- --seconds=480 --seed=2001 --fooled=0.3
## --fooled=0.6 must replay tests/soak_match.gd. The SOAK_RESULT line gains "fooled", per
## character the ring-outs and knock-outs credited to it ("ringouts_by", "kos_by"), and how long
## bots really were fooled: "fooled_spells" (times a bot took a decoy for Rio), "fooled_seconds"
## (their sum), "fooled_long" (spells of 0.25 s or more: the decoy outlived the swing it was left
## for).

const FOOLED_AI := preload("res://tests/analysis/lead/decoy_fooled_ai.gd")

var fooled := 0.6
var swapped := false
var ringouts_by: Dictionary = {}
var kos_by: Dictionary = {}
## Per bot (instance id): frames of the spell it is in.
var spell_frames: Dictionary = {}
var fooled_spells := 0
var fooled_frames := 0
var fooled_long := 0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fooled="):
			fooled = float(arg.get_slice("=", 1))
	super._initialize()

## soak_match.gd calls this once a physics frame, at the frame's start: the first call comes
## before any bot has thought once.
func _check_positions() -> void:
	super._check_positions()
	_count_fooled()
	if swapped:
		return
	swapped = true
	for player in main.players:
		var old_ai = player.ai_controller
		var new_ai = FOOLED_AI.new()
		for property in old_ai.get_property_list():
			if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
				new_ai.set(str(property.name), old_ai.get(str(property.name)))
		new_ai.fooled_chance = fooled
		player.ai_controller = new_ai

func _count_fooled() -> void:
	for player in main.players:
		if not is_instance_valid(player):
			continue
		var key: int = player.get_instance_id()
		var now: bool = not bool(player.is_defeated) and is_instance_valid(player.ai_controller.fooled_by)
		var frames := int(spell_frames.get(key, 0))
		if now:
			if frames == 0:
				fooled_spells += 1
			spell_frames[key] = frames + 1
			fooled_frames += 1
		elif frames > 0:
			if frames >= 15:
				fooled_long += 1
			spell_frames[key] = 0

func _on_defeated(player: Node, attacker: Node) -> void:
	super._on_defeated(player, attacker)
	if is_instance_valid(attacker) and attacker.is_in_group("players"):
		var id := str(attacker.character_id)
		kos_by[id] = int(kos_by.get(id, 0)) + 1

func _on_damaged(player: Node, amount: float, attacker: Variant, source: String) -> void:
	super._on_damaged(player, amount, attacker, source)
	if source == "environment" and is_instance_valid(attacker) and attacker.is_in_group("players"):
		var id := str(attacker.character_id)
		ringouts_by[id] = int(ringouts_by.get(id, 0)) + 1

func _collect_result(finished_early: bool) -> Dictionary:
	var result := super._collect_result(finished_early)
	result["fooled"] = fooled
	result["fooled_spells"] = fooled_spells
	result["fooled_seconds"] = snappedf(float(fooled_frames) * FRAME_TIME, 0.1)
	result["fooled_long"] = fooled_long
	result["ringouts_by"] = ringouts_by
	result["kos_by"] = kos_by
	return result
