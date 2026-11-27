extends Node
## Quality track 4 (2026-11-27): what one frame of a bots-only match costs in the web build.
## Not part of the game. tests/ is left out of the web export, so a measurement build (never
## merged) copies this file to res://scripts/_measure/WebFrameMeasure.gd, and a hook at the top
## of Main._ready reads index.html?measure=16&seed=3001&panel=0, starts that bots-only match at
## 100% speed and adds this node.
## The page times every main-loop iteration (one requestAnimationFrame callback: physics steps,
## scripts, handing the frame to WebGL) into window.__frames (web_measure_harness.js, put into
## the build's index.html). This node writes, per iteration, the fighters alive, the phase, the
## physics steps run and whether Main refreshed the bot panel, and when the match ends hands the
## page where its stretch starts and ends and that list (window.__mark_start, __mark_end,
## __meta). The first second (loading) is left out, as in frame_time_probe.gd.

const SKIP_FRAMES := 60

var main: Node
var frame := 0
## [alive, phase, physics steps in this iteration, bot panel refreshed in this iteration]
var meta: Array = []
var steps := 0
var last_panel_timer := 0.0
var marked := false
var finished := false

func _init() -> void:
	# Last in the frame, after Main's _process wrote the HUD and counted the panel's refresh down.
	process_priority = 100000

func _physics_process(_delta: float) -> void:
	steps += 1

func _process(_delta: float) -> void:
	if finished or main == null:
		return
	frame += 1
	if frame == SKIP_FRAMES:
		# This iteration is the next one the page writes down.
		JavaScriptBridge.eval("window.__mark_start = window.__frames.length;", true)
		marked = true
	var panel_timer: float = main.bot_panel_timer
	if marked:
		var alive := 0
		for player in main.players:
			if is_instance_valid(player) and not player.is_defeated:
				alive += 1
		meta.append([alive, str(main.director.get_phase_name()), steps, panel_timer > last_panel_timer])
	last_panel_timer = panel_timer
	steps = 0
	if marked and main.match_over:
		finished = true
		JavaScriptBridge.eval("window.__mark_end = window.__frames.length; window.__meta = %s;" % JSON.stringify(meta), true)
		print("WEB_MEASURE_DONE iterations=%d players=%d seed=%d panel=%s" % [meta.size(), main.players.size(), main.match_seed, main.hud.bot_panel_wanted])
