extends "res://tests/playtest/real_input_core.gd"
## CODEX-RETEST-02: run the original real-input core sequence unchanged while
## keeping all new artifacts in this unit's writable report directory.

const RETEST_OUT_RELATIVE := "../reports/codex-tester-02"

func _initialize() -> void:
	out_dir = ProjectSettings.globalize_path("res://").path_join(RETEST_OUT_RELATIVE)
	DirAccess.make_dir_recursive_absolute(out_dir)
	call_deferred("_run")
