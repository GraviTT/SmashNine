extends Logger
## What the engine logs while a test runs, so that a test can fail on it by itself (run_all also
## reads the output for error lines, but a test run alone used to end with exit 0 under a script
## error: the function that hit it just stops).
##
## Kept: script errors (a freed node handed to a typed parameter, a missing property) and engine
## errors (a freed object looked up in a typed array). Left out: warnings, and pushed errors,
## which are how the tests report their own failures.
##
##   const CATCHER := preload("res://tests/support/error_catcher.gd")
##   var catcher := CATCHER.new()
##   OS.add_logger(catcher) ... for line in catcher.take(): fail(line) ... OS.remove_logger(catcher)

const WARNING := 1
const SHADER := 3

## The engine may log from any thread.
var lock := Mutex.new()
var errors: Array[String] = []

func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array) -> void:
	if error_type == WARNING or error_type == SHADER or function == "push_error":
		return
	lock.lock()
	errors.append("%s:%d %s: %s %s" % [file.get_file(), line, function, code, rationale])
	lock.unlock()

func _log_message(_message: String, _error: bool) -> void:
	pass

## The errors since the last call.
func take() -> Array[String]:
	lock.lock()
	var taken := errors.duplicate()
	errors.clear()
	lock.unlock()
	return taken
