extends SceneTree
## Runtime smoke/measurement only. Both sides use the unchanged bot brain.
## These results are NOT a human difficulty verdict, especially in the hero-only band.
const MAIN := preload("res://scripts/Main.gd")
const PROGRESS := preload("res://scripts/story/StoryProgress.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const SPEED := preload("res://scripts/GameSpeed.gd")
const ART := preload("res://scripts/ArtSettings.gd")
const SCENE := preload("res://scenes/Main.tscn")
const SEED := 20261022
const LIMIT := 240.0
var results: Array[Dictionary] = []
var stalls_only := false

func _initialize() -> void:
	stalls_only = OS.get_cmdline_user_args().has("--stage8-stalls")
	call_deferred("_run")

func _run() -> void:
	ART.style = ART.STYLE_ORIGINAL
	for id in REGISTRY.get_character_ids():
		if stalls_only and id not in ["yuki", "nova", "rio"]:
			continue
		for number in [6, 7, 8, 9]:
			if stalls_only and number != 8:
				continue
			SPEED.factor = 1.0
			PROGRESS.runs.clear()
			PROGRESS.new_journey(id, "normal")
			for previous in range(1, number):
				PROGRESS.complete_stage(id, previous, 75, ["power", "vitality", "sky_step"])
			MAIN.story_hero = id
			MAIN.story_stage = number
			MAIN.story_difficulty = "normal"
			MAIN.human_body = REGISTRY.get_bodies(id)[0]
			MAIN.story_art_state = {}
			MAIN.next_screen = "story_stage"
			var main := SCENE.instantiate()
			main.match_seed = SEED
			root.add_child(main)
			current_scene = main
			await _frames(3)
			main.story_session.begin_dialogue()
			main.story_session.dialogue._activate("dialogue_skip", "")
			main.story_session.hero.is_human = false
			var peak_minions := 0
			var boss_actions := 0
			var wave_one_seconds := -1.0
			var band_outside_seconds := 0.0
			for frame in int(LIMIT * 60) + 60:
				var session: Node = main.story_session
				if session.phase == "mid":
					wave_one_seconds = main.director.match_elapsed
					session.dialogue._activate("dialogue_skip", "")
				if session.phase == "post" or main.match_over:
					break
				var living_minions := 0
				for enemy: Variant in session.reinforcements:
					if is_instance_valid(enemy) and enemy.hp > 0.0:
						living_minions += 1
				peak_minions = maxi(peak_minions, living_minions)
				if is_instance_valid(session.rival) and session.rival.get("is_boss") == true:
					boss_actions = maxi(boss_actions, int(session.rival.attack_serial))
				if main.director.band_started_at >= 0.0:
					var band: Vector2 = main.director.get_sudden_death_band()
					if session.hero.global_position.x < band.x or session.hero.global_position.x > band.y:
						band_outside_seconds += 1.0 / 60.0
				if main.director.match_elapsed >= LIMIT:
					break
				await _frames(1)
			main.story_session._update_damage()
			var opponent_hp := 0.0
			for enemy: Variant in main.story_session.enemies:
				if is_instance_valid(enemy):
					opponent_hp += enemy.hp
			var hero: Node = main.story_session.hero
			var result := {"hero": id, "stage": number, "seed": SEED, "difficulty": "normal", "carried_cards": ["power", "vitality", "sky_step"],
				"objective_clear": main.story_session.phase == "post", "hero_defeated": hero.is_defeated, "seconds": snappedf(main.director.match_elapsed, 0.1),
				"hero_hp": snappedf(hero.hp, 0.1), "hero_max_hp": hero.max_hp, "damage_taken": snappedf(main.story_session.damage_taken, 0.1),
				"ringouts": hero.respawn_count, "opponent_hp_left": snappedf(opponent_hp, 0.1), "peak_minions": peak_minions, "boss_actions": boss_actions,
				"wave_one_seconds": snappedf(wave_one_seconds, 0.1), "band_outside_seconds": snappedf(band_outside_seconds, 0.1)}
			if main.director.match_elapsed >= LIMIT and main.story_session.phase == "combat":
				result.hero_ai = hero.ai_controller.debug_snapshot(hero)
				result.hero_position = _local_position(main, hero)
				var actors: Array = []
				for enemy: Variant in main.story_session.enemies:
					if is_instance_valid(enemy) and enemy.hp > 0.0:
						actors.append({"name": enemy.display_name, "position": _local_position(main, enemy), "ai": enemy.ai_controller.debug_snapshot(enemy) if enemy.get("ai_controller") != null else {"state": enemy.state}})
				result.alive_opponents = actors
			results.append(result)
			print("STORY_COMBAT_RESULT ", JSON.stringify(result))
			current_scene = null
			main.queue_free()
			await _frames(3)
	var file := FileAccess.open(ProjectSettings.globalize_path("res://../reports/codex-sys-04/combat-probe%s.json" % ("-stalls" if stalls_only else "")), FileAccess.WRITE)
	file.store_string(JSON.stringify({"note": "Unchanged bot brain on both sides; not human difficulty. Hero-only band is unknown to the hero bot too.", "results": results}, "\t") + "\n")
	file.close()
	PROGRESS.runs.clear()
	print("Story combat probe completed (%d real-combat runs, unchanged bot brain, no real save)" % results.size())
	quit(0)

func _local_position(main: Node, actor: Node) -> Array:
	var point: Vector2 = actor.global_position - main.layout.get_origin(actor.realm_index)
	return [snappedf(point.x, 0.1), snappedf(point.y, 0.1)]

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame
