extends SceneTree
## Checks that tests/support/frame_watchdog.gd fires: a guard of 0.5 s (30 frames) on a run that
## never ends by itself. Expect exit code 1, the guard's error, and FRAMES_SEEN 30 printed by the
## guard's own frame (2026-11-27).
##   <godot> --headless --path . -s tests/analysis/lead/frame_watchdog_probe.gd
const FRAME_WATCHDOG := preload("res://tests/support/frame_watchdog.gd")

var frames := 0

func _initialize() -> void:
	process_frame.connect(func() -> void:
		frames += 1
		if frames == 30:
			print("FRAMES_SEEN ", frames))
	FRAME_WATCHDOG.start(self, 0.5, "Probe timed out")
