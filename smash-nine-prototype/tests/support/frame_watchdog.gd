extends RefCounted
## A test's hang guard that counts process frames instead of seconds (the lead's rule,
## 2026-11-27). This PC is often busy (Codex units, other sessions, the user's own builds). A test
## that moves on once a frame then needs more real time but no more frames, and a real-time guard
## failed it anyway: test_story_flow went over its 240 s in a run_all under load and passed in
## 110 s alone; it needs the same frames either way.
##
## The limit is the old one in seconds at 60 frames a second (240 s -> 14,400 frames). Headless
## runs about 114 frames a second when frames are light, so with the PC idle this limit comes no
## later than the old one; under load it waits for the frames, not the clock. It counts while
## the tree is paused too.
##
##   const FRAME_WATCHDOG := preload("res://tests/support/frame_watchdog.gd")
##   FRAME_WATCHDOG.start(self, 240.0, "Story flow timed out")

static func start(tree: SceneTree, seconds: float, message: String) -> void:
	var limit := roundi(seconds * 60.0)
	var old := ("%d" % roundi(seconds)) if is_equal_approx(seconds, roundf(seconds)) else ("%.1f" % seconds)
	var counted := [0]
	tree.process_frame.connect(func() -> void:
		counted[0] += 1
		if counted[0] == limit:
			push_error("%s (%d frames: the old %s s at 60 frames a second)" % [message, limit, old])
			tree.quit(1))
