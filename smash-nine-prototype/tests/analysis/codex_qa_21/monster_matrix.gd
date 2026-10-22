extends SceneTree
## Real realm geometry, all 18 skins x ordinary/elite. Protected stationary Frey target.
const MAIN := preload("res://scripts/Main.gd")
const MONSTER := preload("res://scripts/RealmMonster.gd")
const ARCHETYPES := preload("res://scripts/monsters/MonsterArchetypes.gd")
const ART := preload("res://scripts/ArtSettings.gd")
var rows: Array = []
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	MAIN.next_screen = "title"
	ART.style = "original"
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	main.match_seed = 2103
	root.add_child(main)
	current_scene = main
	main.set_process(false)
	await _frames(3)
	for realm in main.layout.realm_count():
		main.director.realm_states[realm] = main.director.STATE_STABLE
		var profile: Dictionary = main.layout.get_realm(realm)
		for kind in ["melee", "ranged"]:
			var skin: String = profile.monsters[kind]
			for elite in [false, true]:
				var platform: Rect2 = main.layout.get_platform_rects(realm)[0]
				var point := Vector2(platform.get_center().x, platform.position.y - 2)
				var hero: Node = main._add_player("frey", true, point + Vector2(75, 0), realm, "female")
				hero.is_dummy = true
				hero.set_realm_active(true)
				hero.grant_protection(10000.0)
				var monster: Node = MONSTER.new()
				monster.setup("mossling" if kind == "melee" else "ember_imp", realm, point, skin)
				monster.hostile = true
				if elite:
					monster.make_elite()
				main.add_child(monster)
				var windups := 0
				var unannounced := 0
				var previous_phase := "idle"
				var previous_serial := 0
				var armed := false
				var outside := 0
				var bounds: Rect2 = main.layout.get_bounds(realm).grow(80)
				var low_y: float = monster.global_position.y
				var high_y: float = low_y
				for frame in 480:
					await physics_frame
					await process_frame
					# Target stays in the original attack lane; only the real monster moves.
					hero.global_position = point + Vector2(75, 0)
					hero.velocity = Vector2.ZERO
					if not is_instance_valid(monster):
						break
					if monster.action_phase == "windup" and previous_phase != "windup":
						windups += 1
						armed = true
					if monster.attack_serial != previous_serial:
						if not armed:
							unannounced += 1
						armed = false
					previous_phase = monster.action_phase
					previous_serial = monster.attack_serial
					if not bounds.has_point(monster.global_position):
						outside += 1
					low_y = minf(low_y, monster.global_position.y)
					high_y = maxf(high_y, monster.global_position.y)
				var alive: bool = is_instance_valid(monster) and monster.hp > 0.0
				var row := {"realm": realm, "skin": skin, "elite": elite, "frames": 480, "windups": windups, "strikes": previous_serial, "unannounced": unannounced, "outside_frames": outside, "alive": alive, "y_range": [low_y, high_y], "six_row": monster.six_row_art if alive else false, "art": monster.art_sheet_path if alive else ""}
				rows.append(row)
				print("QA21_MONSTER ", JSON.stringify(row))
				if not alive or previous_serial == 0 or unannounced > 0 or outside > 0:
					failures += 1
				if is_instance_valid(monster):
					monster.queue_free()
				main.players.erase(hero)
				hero.queue_free()
				for child in main.get_children():
					if child is Area2D:
						child.queue_free()
				await _frames(2)
	var file := FileAccess.open("res://../reports/codex-qa-21/monster-matrix.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"seed": 2103, "flagged_cases": failures, "rows": rows}, "\t") + "\n")
	print("QA21_MONSTER_SUMMARY cases=", rows.size(), " flagged=", failures)
	quit(0)

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame
