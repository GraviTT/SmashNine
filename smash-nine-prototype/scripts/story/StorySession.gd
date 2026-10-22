extends Node
## A single stage's actors/objective/dialogue. Main only routes mode, screens and portals.
const CATALOG := preload("res://scripts/story/StoryCatalog.gd")
const PROGRESS := preload("res://scripts/story/StoryProgress.gd")
const CARDS := preload("res://scripts/match/SoulCards.gd")
const MONSTER := preload("res://scripts/RealmMonster.gd")
const DIALOGUE := preload("res://scripts/ui/StoryDialogue.gd")
const SPEED := preload("res://scripts/GameSpeed.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
var main: Node
var data: Dictionary
var hero: Node
var rival: Node
var rival_hp_scale := 1.0
var rival_scaled_max := 0.0
var enemies: Array[Node] = []
var waves: Array = []
var wave_index := 0
var defeated_count := 0
var total_enemies := 0
var phase := "start"
var dialogue: DIALOGUE
var damage_taken := 0.0
var last_hp := 0.0
var frozen_modes: Dictionary = {}
var frozen_protection: Dictionary = {}
var rival_bar: Control
var rival_fill: ColorRect
var rival_name: Label
var _wave_check_pending := false
var _restored_enemies: Array = []

func start(owner_main: Node, stage_data: Dictionary, art_state: Dictionary = {}) -> void:
	main = owner_main
	data = stage_data
	var realm := int(data.realm)
	var points: Array[Vector2] = main.layout.get_spawn_points(realm)
	hero = main._add_player(main.story_hero, true, points[0], realm, main._pick_body(main.story_hero, true))
	main.director.hero = hero
	var checkpoint: Dictionary = art_state.get("hero", PROGRESS.checkpoint(main.story_hero, int(data.id)))
	hero.souls = int(checkpoint.souls)
	for id in checkpoint.cards:
		var card := CARDS.find(id)
		if not card.is_empty():
			hero.apply_upgrade(card)
	hero.hp = hero.max_hp
	if not art_state.is_empty():
		hero.hp = clampf(float(checkpoint.hp), 0.0, hero.max_hp)
		hero.global_position = checkpoint.position
		hero.ultimate_cooldown_timer = float(checkpoint.get("ultimate", 0.0))
		hero.damage_dealt = float(checkpoint.get("damage", 0.0))
		hero.score = int(checkpoint.get("score", 0))
		wave_index = int(art_state.wave)
		defeated_count = int(art_state.defeated)
		damage_taken = float(art_state.damage)
		main.director.match_elapsed = float(art_state.elapsed)
		_restored_enemies = art_state.enemies
	last_hp = hero.hp
	waves = CATALOG.waves_for(data, main.story_hero)
	for wave: Array in waves:
		total_enemies += wave.size()
	if wave_index < waves.size() and art_state.get("phase", "start") != "result":
		_spawn_wave()
	main.soul_growth.offer_closed.connect(_on_rival_card_chosen)
	main._set_map(realm)
	main._sync_combatant_visibility()
	main._apply_phase_rules()
	dialogue = DIALOGUE.new()
	main.hud.add_child(dialogue)
	dialogue.visible = false
	dialogue.finished.connect(_on_dialogue_finished)
	_build_rival_bar()
	# MatchHud's battle-royale banner starts at y=96. Story adds the rival bar
	# there, so keep realm hazard warnings below it in this mode only.
	main.hud.warning_label.position.y = 158
	set_frozen(true)
	main.hud.frontend.show_stage_card(data)
	main.hud.overlay_background_art.visible = false
	main.hud.overlay_back.color = Color(0.02, 0.025, 0.05, 0.65)
	main.hud.overlay.visible = true
	main.hud._set_match_hud_visible(false)
	main.hud.frontend.visible = true
	if not art_state.is_empty():
		_restore_art_screen(art_state)

func _spawn_wave() -> void:
	if wave_index >= waves.size():
		_objective_done()
		return
	enemies.clear()
	var realm := int(data.realm)
	var points: Array[Vector2] = main.layout.get_spawn_points(realm)
	var wave: Array = waves[wave_index]
	for index in wave.size():
		var spec: Dictionary = wave[index]
		var point := points[(index + 2) % points.size()]
		var restored: Dictionary = _restored_enemies[index] if index < _restored_enemies.size() else {}
		if not restored.is_empty() and float(restored.hp) <= 0.0:
			continue
		if not restored.is_empty():
			point = restored.position
		var enemy: Node
		if spec.kind == "rival":
			enemy = main._add_player(str(spec.id), false, point, realm, str(restored.get("body", REGISTRY.get_bodies(str(spec.id))[0])))
			for id in restored.get("cards", data.rival_mods.cards):
				var card := CARDS.find(id)
				if not card.is_empty():
					enemy.apply_upgrade(card)
			rival_hp_scale = float(data.rival_mods.hp) * (0.8 if main.story_difficulty == "easy" else 1.0)
			enemy.max_hp *= rival_hp_scale
			rival_scaled_max = enemy.max_hp
			enemy.hp = enemy.max_hp
			enemy.souls = int(restored.get("souls", 0))
			if not restored.get("offer", {}).is_empty():
				main.soul_growth.active_offers[enemy] = restored.offer.duplicate(true)
				main.soul_growth.queued_offers[enemy] = int(restored.get("queued", 0))
			rival = enemy
			enemy.defeated.connect(_on_rival_defeated)
		else:
			enemy = MONSTER.new()
			enemy.setup("ember_imp" if spec.kind == "ranged" else "mossling", realm, point, str(spec.skin))
			if spec.get("elite", false):
				enemy.make_elite()
			enemy.max_hp *= 0.8 if main.story_difficulty == "easy" else 1.0
			enemy.hp = enemy.max_hp
			main.add_child(enemy)
			enemy.defeated.connect(_on_monster_defeated)
			enemy.set_realm_active(true)
		if not restored.is_empty():
			enemy.hp = clampf(float(restored.hp), 0.0, enemy.max_hp)
			enemy.set_meta("story_wave_slot", index)
		enemies.append(enemy)
		enemy.set_meta("story_wave_slot", index)
	_restored_enemies.clear()

func _on_monster_defeated(_enemy: Node, attacker: Node, soul_reward: int) -> void:
	if is_instance_valid(attacker) and attacker.has_method("add_souls"):
		attacker.add_souls(soul_reward)
	_enemy_fell()

func _on_rival_defeated(_enemy: Node, _attacker: Node) -> void:
	if is_instance_valid(hero) and not hero.is_defeated:
		hero.add_souls(int(data.souls_reward))
	_enemy_fell()

func _on_rival_card_chosen(player: Node, _card: Dictionary, _auto_picked: bool) -> void:
	if player != rival or not is_instance_valid(rival) or rival.is_defeated:
		return
	# apply_upgrade rebuilds the character's unscaled max HP and heals its increase.
	# Reapply the stage rule, correcting that heal against the previous scaled max.
	var plain_max: float = rival.max_hp
	var scaled_max := plain_max * rival_hp_scale
	var plain_gain := maxf(plain_max - rival_scaled_max, 0.0)
	var scaled_gain := maxf(scaled_max - rival_scaled_max, 0.0)
	rival.max_hp = scaled_max
	rival.hp = clampf(rival.hp + scaled_gain - plain_gain, 0.0, scaled_max)
	rival_scaled_max = scaled_max

func _enemy_fell() -> void:
	defeated_count += 1
	if not _wave_check_pending:
		_wave_check_pending = true
		call_deferred("_check_wave")

func _check_wave() -> void:
	_wave_check_pending = false
	if main.match_over or hero.is_defeated:
		return
	for enemy: Variant in enemies:
		if is_instance_valid(enemy) and enemy.hp > 0.0:
			return
	wave_index += 1
	_spawn_wave()

func begin_dialogue() -> void:
	if phase != "start":
		return
	main.hud.hide_overlay()
	phase = "pre"
	dialogue.play(CATALOG.dialogue_for(data, main.story_hero, "pre"), main.story_hero, "" if CATALOG.is_home(data, main.story_hero) else str(data.rival), main.human_body)
	main.hud.hide_card_offer()

func _on_dialogue_finished() -> void:
	if phase == "pre":
		phase = "combat"
		set_frozen(false)
	elif phase == "post":
		phase = "exit"
		set_frozen(false)
		main.director.open_exit()
		# The last foe cannot leave stray attacks hitting a hero at an opened exit.
		for enemy: Variant in enemies:
			if is_instance_valid(enemy):
				enemy.process_mode = Node.PROCESS_MODE_DISABLED

func _objective_done() -> void:
	if main.match_over or hero.is_defeated:
		return
	phase = "post"
	set_frozen(true)
	# The objective is complete: discard already-spawned attacks instead of waking
	# them behind the post scene. Realm hazards still run once the exit opens.
	for child in main.get_children():
		if child is Area2D:
			child.queue_free()
	rival_bar.visible = false
	dialogue.play(CATALOG.dialogue_for(data, main.story_hero, "post"), main.story_hero, "" if CATALOG.is_home(data, main.story_hero) else str(data.rival), main.human_body)
	main.hud.hide_card_offer()

func set_frozen(frozen: bool) -> void:
	main.director.running = not frozen
	main.soul_growth.set_process(not frozen)
	main.hazards.set_process(not frozen)
	if frozen:
		for child in main.get_children():
			if child is CharacterBody2D or child is Area2D:
				if not frozen_modes.has(child):
					frozen_modes[child] = child.process_mode
		for player in main.players:
			if is_instance_valid(player) and not frozen_protection.has(player):
				frozen_protection[player] = player.invulnerable_timer
		main._freeze_combat()
	else:
		# A projectile can queue_free during the post scene. Keep loop values Variant
		# until validity is checked; assigning a freed key to Node already throws.
		for child: Variant in frozen_modes:
			if is_instance_valid(child):
				child.process_mode = frozen_modes[child]
		for player: Variant in frozen_protection:
			if is_instance_valid(player):
				player.invulnerable_timer = frozen_protection[player]
		frozen_modes.clear()
		frozen_protection.clear()

func accepts_gameplay() -> bool:
	return phase in ["combat", "exit"] and not main.match_over and is_instance_valid(hero) and not hero.is_defeated

func use_portal(portal: Dictionary) -> bool:
	if phase != "exit" or int(portal.destination) != main.director.exit_realm:
		return false
	if not main.soul_growth.get_offer(hero).is_empty():
		main._show_message(tr("Choose a soul card first."))
		return true
	main.director.use_exit()
	return true

func pause_stage() -> void:
	if not accepts_gameplay():
		return
	main.hud.frontend.show_story_pause()
	main.hud.overlay_background_art.visible = false
	main.hud.overlay_back.color = Color(0.02, 0.025, 0.05, 0.72)
	main.hud.overlay.visible = true
	main.hud.hide_card_offer()
	get_tree().paused = true
	# Character start-up waits deliberately use process_always SceneTreeTimers.
	# Freezing scaled time as well preserves their remaining waits during pause.
	Engine.time_scale = 0.0

func resume_stage() -> void:
	SPEED.apply_to_match()
	get_tree().paused = false
	main.hud.hide_overlay()
	# Esc/Enter used to resume must not become a combat input in that frame.
	get_viewport().set_input_as_handled()

func finish(clear: bool) -> void:
	get_tree().paused = false
	_update_damage()
	phase = "result"
	dialogue.visible = false
	rival_bar.visible = false
	main.hud._set_match_hud_visible(false)
	main.hud.hide_card_offer()
	if clear:
		PROGRESS.complete_stage(main.story_hero, int(data.id), hero.souls, hero.upgrades)
	main.story_last_result = {"clear": clear, "stage": int(data.id), "seconds": main.director.match_elapsed, "damage": damage_taken, "cards": hero.upgrades.duplicate()}
	main.hud.frontend.show_story_result(main.story_last_result)
	main.hud.overlay.visible = true
	main.hud.overlay_background_art.visible = false
	main.hud.overlay_back.color = Color(0.02, 0.025, 0.05, 0.86)

func objective_text() -> String:
	if phase == "exit":
		var arrows := {Vector2i.LEFT: "←", Vector2i.RIGHT: "→", Vector2i.UP: "↑", Vector2i.DOWN: "↓"}
		return tr("Use the portal  %s  Q") % str(arrows.get(data.exit, ""))
	if is_instance_valid(rival) and rival.hp > 0.0:
		return tr("Defeat %s") % tr(str(rival.display_name))
	return tr("Monsters %d/%d") % [defeated_count, total_enemies]

func _build_rival_bar() -> void:
	rival_bar = main.hud._hud_frame("hp_bar", Vector2(420, 46), Color(0.07, 0.03, 0.06, 0.95), "StoryRivalHP")
	rival_bar.position = Vector2(430, 100)
	main.hud.add_child(rival_bar)
	main.hud._pin(rival_bar, Vector2(0.5, 0.0))
	rival_fill = ColorRect.new()
	rival_fill.position = Vector2(8, 30)
	rival_fill.size = Vector2(404, 8)
	rival_fill.color = Color("dd637b")
	rival_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rival_bar.add_child(rival_fill)
	rival_name = Label.new()
	rival_name.position = Vector2(8, 2)
	rival_name.size = Vector2(404, 28)
	rival_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rival_name.add_theme_font_size_override("font_size", 18)
	rival_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rival_bar.add_child(rival_name)
	rival_bar.visible = false

func update_hud() -> void:
	main.hud.clock_label.text = tr("STAGE %d") % int(data.id) + "   |   " + objective_text()
	main.hud.clock_label.visible = phase != "result" and not main.hud.overlay.visible
	rival_bar.visible = is_instance_valid(rival) and rival.hp > 0.0 and accepts_gameplay() and not main.hud.overlay.visible
	if rival_bar.visible:
		rival_fill.size.x = 404.0 * clampf(rival.hp / rival.max_hp, 0.0, 1.0)
		rival_name.text = "%s   %d / %d" % [tr(str(rival.display_name)), ceili(rival.hp), ceili(rival.max_hp)]
	if phase in ["pre", "post"] or main.hud.overlay.visible:
		main.hud.hide_card_offer()

func _update_damage() -> void:
	if is_instance_valid(hero):
		damage_taken += maxf(last_hp - hero.hp, 0.0)
		last_hp = hero.hp

func _physics_process(_delta: float) -> void:
	if phase in ["combat", "exit"]:
		_update_damage()

## F2 reloads a screen without resetting progress, an open exit or the dialogue line.
## This is temporary in-process state, separate from the durable stage-start checkpoint.
func art_snapshot() -> Dictionary:
	_update_damage()
	var actors: Array = []
	if wave_index < waves.size():
		for spec in waves[wave_index]:
			actors.append({"hp": 0.0})
	for enemy: Variant in enemies:
		if not is_instance_valid(enemy):
			continue
		var slot := int(enemy.get_meta("story_wave_slot", 0))
		if slot < actors.size():
			actors[slot] = {"hp": enemy.hp, "position": enemy.global_position, "body": enemy.body_type if enemy.get("body_type") != null else ""}
			if enemy == rival:
				actors[slot].cards = rival.upgrades.duplicate()
				actors[slot].souls = rival.souls
				actors[slot].offer = main.soul_growth.get_offer(rival).duplicate(true)
				actors[slot].queued = main.soul_growth.queued_offers.get(rival, 0)
	return {"seed": main.match_seed, "phase": phase, "paused": get_tree().paused, "wave": wave_index, "defeated": defeated_count, "elapsed": main.director.match_elapsed, "damage": damage_taken,
		"hero": {"souls": hero.souls, "cards": hero.upgrades.duplicate(), "hp": hero.hp, "position": hero.global_position, "ultimate": hero.ultimate_cooldown_timer, "damage": hero.damage_dealt, "score": hero.score},
		"enemies": actors, "offer": main.soul_growth.get_offer(hero).duplicate(true), "queued": main.soul_growth.queued_offers.get(hero, 0),
		"line": dialogue.line_index, "shown": dialogue.line_label.visible_characters if is_instance_valid(dialogue.line_label) else 0,
		"card_ms": maxi(0, main.hud.frontend.card_deadline - Time.get_ticks_msec())}

func _restore_art_screen(state: Dictionary) -> void:
	phase = str(state.phase)
	if not state.offer.is_empty():
		main.soul_growth.active_offers[hero] = state.offer.duplicate(true)
		main.soul_growth.queued_offers[hero] = int(state.queued)
	match phase:
		"pre", "post":
			main.hud.hide_overlay()
			dialogue.play(CATALOG.dialogue_for(data, main.story_hero, phase), main.story_hero, "" if CATALOG.is_home(data, main.story_hero) else str(data.rival), main.human_body)
			dialogue.line_index = int(state.line)
			dialogue._show_line()
			dialogue.line_label.visible_characters = int(state.shown)
			dialogue._characters = dialogue.line_label.get_total_character_count() if int(state.shown) < 0 else int(state.shown)
		"combat", "exit":
			main.hud.hide_overlay()
			set_frozen(false)
			if phase == "exit":
				main.director.open_exit()
			if state.paused:
				pause_stage()
			elif phase == "combat":
				call_deferred("_check_wave")
		"result":
			main.match_over = true
			main.director.match_over = true
			main.director.winner = hero if main.story_last_result.clear else null
			main.director.finish_reason = "stage clear" if main.story_last_result.clear else "stage failed"
			SPEED.reset_engine()
			main.hud.frontend.show_story_result(main.story_last_result)
		"start":
			main.hud.frontend.card_deadline = Time.get_ticks_msec() + int(state.card_ms)
