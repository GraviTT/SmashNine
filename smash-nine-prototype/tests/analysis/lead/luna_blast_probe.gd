extends "res://tests/analysis/lead/luna_beam_probe.gd"
## The star beam watched as luna_beam_probe.gd does, with its last blast at another knockback
## (2026-11-25). Probe-only: the game's number stays Luna.BEAM_FINAL_KNOCKBACK 760; each beam is
## retuned right after Luna sets it up, 3 s before the blast.
## Usage: <godot> --headless --path . --fixed-fps 60 -s tests/analysis/lead/luna_blast_probe.gd -- --seconds=480 --seed=2002 --final-knockback=600
## The bots' rule is the current one. The SOAK_RESULT line says "variant": "kb600".

const HEART_LASER_SCRIPT := preload("res://characters/luna/LunaHeartLaser.gd")

var final_knockback := -1.0
var hooked_parents: Array[Node] = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--final-knockback="):
			final_knockback = float(arg.get_slice("=", 1))
	super._initialize()

func _check_positions() -> void:
	super._check_positions()
	for watch in lunas.values():
		if is_instance_valid(watch.node) and not hooked_parents.has(watch.node.get_parent()):
			hooked_parents.append(watch.node.get_parent())
			watch.node.get_parent().child_entered_tree.connect(_on_child_entered)

## The beam enters the tree before Luna gives it her numbers; the retune runs after them.
func _on_child_entered(node: Node) -> void:
	if node.get_script() == HEART_LASER_SCRIPT:
		_retune.call_deferred(node)

func _retune(laser: Node) -> void:
	if is_instance_valid(laser) and final_knockback >= 0.0:
		laser.final_knockback = final_knockback

func _collect_result(finished_early: bool) -> Dictionary:
	var result := super._collect_result(finished_early)
	if final_knockback >= 0.0:
		result["variant"] = "kb%d" % int(final_knockback)
	return result
