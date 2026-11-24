extends "res://tests/analysis/lead/luna_beam_probe.gd"
## The star beam watched as luna_beam_probe.gd does, with some of its numbers changed for the
## run (2026-11-25). Probe-only: the game's numbers stay as they are; each beam is retuned right
## after Luna sets it up, before the physics step it could first hit in.
## Usage: <godot> --headless --path . --fixed-fps 60 -s tests/analysis/lead/luna_blast_probe.gd -- --seconds=480 --seed=2002 [--final-knockback=600] [--tick-knockback=0] [--normal-hitstop]
##   --final-knockback=N  the last blast's knockback (the game: Luna.BEAM_FINAL_KNOCKBACK 760)
##   --tick-knockback=N   each tick's knockback (the game: Luna.BEAM_TICK_KNOCKBACK 70)
##   --normal-hitstop     the beam's hits freeze their target 0.065 s, not 0.143 s: Luna's ultimate
##                        window is closed as the beam starts (PlayerBase._hitstop_scale_from gives
##                        2.2x while it is open, and a fighter in hitstop neither moves nor loses
##                        knockback, so at 0.15 s a tick the ticks' knockback piles up)
## The bots' rule is the current one. The SOAK_RESULT line names the variant ("kb600", "tickkb0",
## "hitstop1", joined by "-").

const HEART_LASER_SCRIPT := preload("res://characters/luna/LunaHeartLaser.gd")

var final_knockback := -1.0
var tick_knockback := -1.0
var normal_hitstop := false
var hooked_parents: Array[Node] = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--final-knockback="):
			final_knockback = float(arg.get_slice("=", 1))
		elif arg.begins_with("--tick-knockback="):
			tick_knockback = float(arg.get_slice("=", 1))
		elif arg == "--normal-hitstop":
			normal_hitstop = true
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
	if not is_instance_valid(laser):
		return
	if final_knockback >= 0.0:
		laser.final_knockback = final_knockback
	if tick_knockback >= 0.0:
		laser.knockback_per_tick = tick_knockback
	if normal_hitstop and is_instance_valid(laser.source):
		laser.source.ultimate_window_timer = 0.0

func _collect_result(finished_early: bool) -> Dictionary:
	var result := super._collect_result(finished_early)
	var names: Array[String] = []
	if final_knockback >= 0.0:
		names.append("kb%d" % int(final_knockback))
	if tick_knockback >= 0.0:
		names.append("tickkb%d" % int(tick_knockback))
	if normal_hitstop:
		names.append("hitstop1")
	if not names.is_empty():
		result["variant"] = "-".join(names)
	return result
