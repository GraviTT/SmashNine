extends SceneTree
## Reproducible real-runtime showcase: actual monster art, tell drawing and HP widgets.
## Run windowed: Godot --path smash-nine-prototype -s <absolute path to this script>.
const MONSTER := preload("res://scripts/RealmMonster.gd")
const DATA := preload("res://scripts/monsters/MonsterArchetypes.gd")
var stage: Node2D
var out_dir := ""

func _initialize() -> void:
	root.content_scale_size = Vector2i(1600, 900)
	root.size = Vector2i(1280, 720)
	out_dir = ProjectSettings.globalize_path("res://../reports/codex-sys-01")
	call_deferred("_run")

func _label(text: String, at: Vector2, size := 18, color := Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	stage.add_child(label)

func _run() -> void:
	stage = Node2D.new()
	root.add_child(stage)
	var background := ColorRect.new()
	background.color = Color("111c2b")
	background.size = Vector2(1600, 900)
	stage.add_child(background)
	_label("MONSTER ECOLOGY / ACTUAL GODOT RUNTIME", Vector2(42, 25), 30)
	_label("Gold rings and floor marks warn before every hit. Regular damage 5-9 / knockback 140 melee, 110 projectile.", Vector2(44, 70), 18, Color("b1c8dc"))
	var skins := ["mossling", "asgard_aegis_ram", "niflheim_glacier_wolf", "jotunheim_rune_golem", "svartalfheim_gear_beetle", "niflheim_frost_owl", "vanaheim_seed_sprite", "asgard_runic_raven", "alfheim_moon_moth", "yggdrasil_root_oracle"]
	for i in skins.size():
		var col := i % 5
		var row := i / 5
		var at := Vector2(155 + col * 310, 285 + row * 265)
		var panel := ColorRect.new()
		panel.color = Color("1c2c40")
		panel.position = at - Vector2(125, 165)
		panel.size = Vector2(254, 238)
		stage.add_child(panel)
		_label(str(DATA.SKINS[skins[i]]).to_upper(), at + Vector2(-108, -155), 22, Color("ffd26c"))
		var monster := MONSTER.new()
		monster.setup("ember_imp" if i >= 5 else "mossling", 7, at, skins[i])
		stage.add_child(monster)
		monster.set_physics_process(false)
		monster.name_label.visible = false
		monster.action_phase = "windup"
		monster.action_timer = monster.windup_duration * 0.35
		monster.locked_target_position = at + Vector2(65, 0)
		monster.art_sprite.play(&"attack")
		monster.art_sprite.frame = 0
		monster.art_sprite.pause()
		monster.queue_redraw()
		_label("%.2fs tell / %.0f damage" % [monster.windup_duration, monster.attack_damage], at + Vector2(-108, 31), 17, Color("c7d8e8"))
	_label("ELITE", Vector2(50, 630), 24, Color("ffd26c"))
	var elite := MONSTER.new()
	elite.setup("mossling", 7, Vector2(165, 825), "jotunheim_rune_golem")
	elite.make_elite()
	stage.add_child(elite)
	elite.set_physics_process(false)
	_label("x1.35 size / x3 HP / x1.5 damage / x4 souls", Vector2(310, 692), 22)
	_label("Longer wind-up / gold crown and aura / HP always visible", Vector2(310, 731), 20, Color("c7d8e8"))
	_label("Regular HP appears after its first hit. Defeat: hurt pose -> fade -> small soul burst.", Vector2(310, 773), 18, Color("b1c8dc"))
	_label("Spawn pacing: 4 regulars -> 3 at Central brawl / defeated slot 12-18s / elite replacement 70-90s", Vector2(310, 815), 18, Color("b1c8dc"))
	await process_frame
	await RenderingServer.frame_post_draw
	var screen := root.get_texture().get_image()
	screen.save_png(out_dir.path_join("ecology-runtime.png"))
	print("Saved ecology-runtime.png")
	stage.queue_free()
	await process_frame
	await _readability_capture()
	await _match_capture()
	quit(0)

func _readability_capture() -> void:
	stage = Node2D.new()
	root.add_child(stage)
	var background := ColorRect.new()
	background.size = Vector2(1600, 900)
	background.color = Color("111c2b")
	stage.add_child(background)
	_label("MONSTER READABILITY", Vector2(50, 40), 34)
	_label("Actual runtime widgets and hurt/fade rendering at 2x for inspection.", Vector2(52, 95), 22, Color("b1c8dc"))
	var titles := ["UNTOUCHED", "FIRST HIT", "DEFEATED / 0.25s"]
	var notes := ["HP stays hidden until hit", "HP bar appears after damage", "Hurt pose + fade + soul burst"]
	for i in 3:
		var panel := ColorRect.new()
		panel.position = Vector2(45 + i * 520, 190)
		panel.size = Vector2(470, 510)
		panel.color = Color("1c2c40")
		stage.add_child(panel)
		_label(titles[i], Vector2(80 + i * 520, 215), 27, Color("ffd26c"))
		var monster := MONSTER.new()
		monster.setup("mossling", 7, Vector2(280 + i * 520, 550), "mossling")
		stage.add_child(monster)
		monster.set_physics_process(false)
		monster.scale = Vector2.ONE * 2.0
		if i == 1:
			monster.apply_hit(null, 12.0, 0.0, Vector2.RIGHT)
			monster.art_sprite.play(&"hurt")
		if i == 2:
			monster._die(null)
			monster.set_physics_process(false)
			monster._physics_process(0.25)
		monster.art_sprite.pause()
		_label(notes[i], Vector2(80 + i * 520, 625), 21, Color("c7d8e8"))
	_label("The defeated node and its soul-burst drawing are removed after 0.55 seconds; rewards are paid once.", Vector2(52, 760), 24, Color("b1c8dc"))
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join("readability-runtime.png"))
	print("Saved readability-runtime.png")
	stage.queue_free()
	await process_frame

func _match_capture() -> void:
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	main.bots_only = true
	main.match_seed = 1001
	root.add_child(main)
	for i in 5:
		await physics_frame
	main.set_process(false)
	main.set_physics_process(false)
	main.director.advance(121.0)
	main.realm_monster_spawner.sync_playable_realms(main.director.get_playable_indices())
	main.realm_monster_spawner.set_physics_process(false)
	for player in main.players:
		player.process_mode = Node.PROCESS_MODE_DISABLED
	for monster in get_nodes_in_group("realm_monsters"):
		monster.set_physics_process(false)
	var points: Array = main.layout.get_navigation_points(7)
	var base: Vector2 = points[0]
	var fighter: Node = main.players[0]
	fighter.realm_index = 7
	fighter.global_position = base + Vector2(70, 0)
	var elite: Node = main.realm_monster_spawner.elite_by_realm[7]
	elite.global_position = base - Vector2(160, 0)
	elite.state = MONSTER.State.AGGRO
	elite.target = fighter
	elite._begin_windup()
	elite._update_art(0.0)
	elite.action_timer *= 0.5
	elite._update_visuals()
	elite.queue_redraw()
	var move_index := 3
	for monster in main.realm_monster_spawner.monsters_by_realm[7]:
		if monster != elite and monster.global_position.distance_to(elite.global_position) < 160.0:
			monster.global_position = points[move_index % points.size()]
			move_index += 1
	for i in 8:
		main.realm_monster_spawner._physics_process(2.81)
	main._set_map(7)
	main.camera.global_position = main.layout.get_bounds(7).get_center() + Vector2(0, 190)
	main.camera.zoom = Vector2.ONE * 0.8
	main.camera.reset_smoothing()
	main._update_hud()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join("jotunheim-runtime.png"))
	print("Saved jotunheim-runtime.png (controlled phase-two fixture)")
	main.queue_free()
	await process_frame
