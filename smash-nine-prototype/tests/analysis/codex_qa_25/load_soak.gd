extends "res://tests/soak_match.gd"
var worker := "1"
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--worker="): worker = arg.trim_prefix("--worker=")
	var file := FileAccess.open("res://../reports/codex-qa-25/worker-" + worker + ".pid", FileAccess.WRITE)
	file.store_string(str(OS.get_process_id()))
	file.close()
	process_frame.connect(_stop_requested)
	super()

func _stop_requested() -> void:
	if FileAccess.file_exists("res://../reports/codex-qa-25/stop-workers.txt"):
		print("QA25_LOAD_STOP requested pid=", OS.get_process_id())
		quit(0)
