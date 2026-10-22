extends "res://tests/soak_match.gd"
const RECORDER := preload("res://tests/analysis/codex_qa_22/audio_recorder.gd")
var recorder: Node

func _initialize() -> void:
	recorder = RECORDER.new()
	recorder.name = "AudioManager"
	recorder.probe_enabled = true
	call_deferred("_install_recorder")
	super._initialize()

func _install_recorder() -> void:
	root.add_child(recorder)

func _check_positions() -> void:
	# The first match-start request occurs before the first observer tick. Attach
	# then too through watch(), overridden below by stamp's watched callable later.
	recorder.observed_main = main
	super._check_positions()

func _collect_result(finished_early: bool) -> Dictionary:
	var result := super._collect_result(finished_early)
	result.seed = seed_value
	recorder.save_capture("res://../reports/codex-sys-08/sound-br-%d.json" % seed_value, result)
	return result
