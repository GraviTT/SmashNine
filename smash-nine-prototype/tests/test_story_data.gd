extends SceneTree
## Catalog, bilingual ID expansion, exit topology, checkpoint IO isolation and Easy rules.
const STORY := preload("res://scripts/story/StoryCatalog.gd")
const PROGRESS := preload("res://scripts/story/StoryProgress.gd")
const LAYOUT := preload("res://scripts/realms/RealmLayout.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const DIRECTOR := preload("res://scripts/story/StoryDirector.gd")
const FACTORY := preload("res://scripts/PlayerFactory.gd")
const CARDS := preload("res://scripts/match/SoulCards.gd")
var failed := false
var assertions := 0
var table: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failed = true
		push_error(message)

func _run() -> void:
	var file := FileAccess.open("res://assets/i18n/story.csv", FileAccess.READ)
	_check(file != null, "story.csv must exist")
	if file == null:
		quit(1)
		return
	_check(file.get_csv_line() == PackedStringArray(["keys", "en", "ko"]), "Story CSV schema")
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() == 1 and row[0] == "":
			continue
		_check(row.size() == 3, "Malformed story row")
		if row.size() != 3:
			continue
		_check(row[0].begins_with("story.") and not table.has(row[0]), "Unique ID namespace: " + row[0])
		_check(not row[1].strip_edges().is_empty() and not row[2].strip_edges().is_empty(), "Both languages: " + row[0])
		_check(row[1].count("%s") == row[2].count("%s"), "Story placeholders: " + row[0])
		table[row[0]] = [row[1], row[2]]
	var layout := LAYOUT.new()
	var stages := STORY.stages()
	_check(stages.size() == 9, "Nine stages")
	var realm_order := [1, 0, 3, 5, 6, 7, 4, 2, 8]
	var rival_order := ["", "frey", "luna", "rio", "", "nova", "", "yuki", ""]
	for index in stages.size():
		var data: Dictionary = stages[index]
		_check(int(data.id) == index + 1 and int(data.realm) == realm_order[index], "Plan's stage/realm order")
		_check(str(data.rival) == rival_order[index], "Plan's rival order")
		_check(bool(data.ready) == (index < 4), "Only stages 1-4 ready")
		_check(not data.waves.is_empty(), "Every stage has objective wave data")
		_check(str(data.home_elite) == str(layout.get_realm(data.realm).monsters.melee), "Realm-specific home guardian")
		_check(table.has(data.title) and table.has(data.goal), "Stage title/goal IDs")
		for tip in data.tips:
			_check(table.has(tip), "Tip ID: " + str(tip))
		if index < 7:
			var destination := layout.find_by_grid(Vector2i(layout.get_realm(data.realm).grid) + Vector2i(data.exit))
			_check(destination == realm_order[index + 1], "Exit leads to next realm, stage " + str(index + 1))
		else:
			_check(data.exit == Vector2i.ZERO, "Root/ending uses no grid exit")
		for hero in REGISTRY.get_character_ids():
			for scene in data.dialogue:
				for line: Array in data.dialogue[scene]:
					var id := STORY.resolve_id(str(line[1]), hero, str(data.rival))
					_check(table.has(id), "Expanded dialogue ID: " + id)
					_check(line[0] in ["hero", "rival", "narrator"] or REGISTRY.get_character_ids().has(line[0]), "Supported speaker")
			if STORY.is_home(data, hero):
				var wave: Array = STORY.waves_for(data, hero)[0]
				_check(wave.size() == 3 and wave[0].get("elite", false), "Home is elite + two normals")
		for id in data.rival_mods.cards:
			_check(not CARDS.find(id).is_empty(), "Valid rival upgrade: " + str(id))
	for locale in ["en", "ko"]:
		TranslationServer.set_locale(locale)
		for id: String in table:
			_check(tr(id) == table[id][0 if locale == "en" else 1], "Re-import story translation: " + id)
	TranslationServer.set_locale("en")
	_check(not PROGRESS.uses_real_save(), "Tests never use real story.cfg")
	var existed := FileAccess.file_exists(PROGRESS.SAVE_PATH)
	var mtime := FileAccess.get_modified_time(PROGRESS.SAVE_PATH) if FileAccess.file_exists(PROGRESS.SAVE_PATH) else 0
	PROGRESS.runs.clear()
	PROGRESS.new_journey("luna", "easy")
	PROGRESS.complete_stage("luna", 1, 32, ["power"])
	PROGRESS.complete_stage("luna", 2, 62, ["power", "power"])
	PROGRESS.complete_stage("luna", 1, 0, [])
	_check(PROGRESS.continue_stage("luna") == 3, "Replay cannot roll back progress")
	_check(PROGRESS.checkpoint("luna", 3).cards == ["power", "power"], "Stacked card checkpoint")
	var temp_path := OS.get_environment("TEMP").path_join("smashnine-story-test-%d.cfg" % OS.get_process_id())
	_check(PROGRESS.save(temp_path) == OK, "Explicit temporary save")
	PROGRESS.runs.clear()
	PROGRESS.load_saved(temp_path)
	_check(PROGRESS.get_run("luna").difficulty == "easy" and PROGRESS.checkpoint("luna", 3).cards == ["power", "power"], "Config round-trip preserves difficulty/checkpoints/stacks")
	DirAccess.remove_absolute(temp_path)
	PROGRESS.new_journey("frey", "normal")
	_check(PROGRESS.get_run("luna").cleared == 2 and PROGRESS.get_run("frey").cleared == 0, "Per-fighter progress isolation")
	_check(FileAccess.file_exists(PROGRESS.SAVE_PATH) == existed, "Real story file not created/removed")
	_check((FileAccess.get_modified_time(PROGRESS.SAVE_PATH) if FileAccess.file_exists(PROGRESS.SAVE_PATH) else 0) == mtime, "Real story mtime untouched")
	var director := DIRECTOR.new()
	director.configure(STORY.stage(2), "easy")
	director.setup(layout)
	root.add_child(director)
	var hero := FACTORY.create("luna")
	root.add_child(hero)
	hero.setup(REGISTRY.get_characters().luna, 1, true)
	director.hero = hero
	director.register_combatant(hero)
	_check(is_equal_approx(director.get_combat_damage_scale_for(hero), 0.28), "Easy hero damage x0.7")
	_check(director.get_playable_indices() == [0], "Only stage realm open")
	director.running = true
	director.advance(500.0)
	_check(not director.match_over and director.events.is_empty() and director.get_playable_indices() == [0], "No battle royale timeline or last-survivor finish")
	director.open_exit()
	_check(director.exit_open and director.is_playable(3), "Objective opens real exit realm")
	director.use_exit()
	_check(director.match_over and director.winner == hero, "Portal completes story objective")
	hero.free()
	director.free()
	PROGRESS.runs.clear()
	if not failed:
		print("Story data tests passed (%d assertions, 9 stages, %d bilingual IDs, save isolation, Easy rules)" % [assertions, table.size()])
	quit(1 if failed else 0)
