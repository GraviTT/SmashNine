extends SceneTree
const MAIN := preload("res://scripts/Main.gd")
const RECORDER := preload("res://tests/analysis/codex_qa_22/audio_recorder.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var recorder := RECORDER.new()
	recorder.name = "AudioManager"
	recorder.probe_enabled = true
	root.add_child(recorder)
	MAIN.next_screen = "title"
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	main.match_seed = 2101
	root.add_child(main)
	current_scene = main
	await _frames(6)
	recorder.mark("title")
	main.hud.frontend.show_select()
	await _frames(3)
	recorder.mark("select")
	main._start_match("frey")
	await _frames(3)
	recorder.mark("battle")
	main.director._finish(main.players[0], "QA22 music screen fixture")
	await _frames(6)
	recorder.mark("results")
	recorder.save_capture("res://../reports/codex-qa-22/music-screens.json", {"seed": 2101, "match_over": main.match_over})
	quit(0 if main.match_over else 1)

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame
