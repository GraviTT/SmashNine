extends Node
## A single stage's actors/objective/dialogue. Main only routes mode, screens and portals.
const CATALOG := preload("res://scripts/story/StoryCatalog.gd")
const PROGRESS := preload("res://scripts/story/StoryProgress.gd")
const CARDS := preload("res://scripts/match/SoulCards.gd")
const MONSTER := preload("res://scripts/RealmMonster.gd")
const DIALOGUE := preload("res://scripts/ui/StoryDialogue.gd")
const SPEED := preload("res://scripts/GameSpeed.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const CRYSTAL := preload("res://scripts/SoulCrystal.gd")
const VFX := preload("res://scripts/Vfx.gd")
const SHADOW_TINT := Color(0.42, 0.24, 0.62)
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
var crystals: Array[Node] = []
var crystals_broken := 0
var reinforcements: Array[Node] = []
var next_reinforcement := 20.0

func start(owner_main: Node, stage_data: Dictionary, art_state: Dictionary = {}) -> void:
	main = owner_main
	data = stage_data
	next_reinforcement = float(data.reinforcements.get("interval", 20.0))
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
		crystals_broken = int(art_state.get("crystals_broken", 0))
		next_reinforcement = float(art_state.get("next_reinforcement", next_reinforcement))
		main.director.band_started_at = float(art_state.get("band_started_at", -1.0))
		if main.director.band_started_at >= 0.0:
			main.director.phase = main.director.PHASE_SUDDEN_DEATH
	last_hp = hero.hp
	waves = CATALOG.waves_for(data, main.story_hero)
	for wave: Array in waves:
		total_enemies += wave.size()
	if wave_index < waves.size() and art_state.get("phase", "start") not in ["result", "ending", "mid"]:
		_spawn_wave()
	elif art_state.get("phase", "") == "mid":
		_restored_enemies.clear()
	if int(data.id) == 5:
		_spawn_crystals(art_state.get("crystals", []))
	if int(data.id) == 7:
		for actor: Dictionary in art_state.get("reinforcements", []):
			if float(actor.hp) > 0.0:
				_spawn_reinforcement(actor)
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
		if spec.kind in ["rival", "shadow"]:
			var shadow: bool = spec.kind == "shadow"
			var enemy_body: String = hero.body_type if shadow and str(spec.id) == main.story_hero else REGISTRY.get_bodies(str(spec.id))[0]
			enemy = main._add_player(str(spec.id), false, point, realm, str(restored.get("body", enemy_body)))
			var initial_cards: Array = _shadow_cards(int(spec.cards), index) if shadow else data.rival_mods.cards
			for id in restored.get("cards", initial_cards):
				var card := CARDS.find(id)
				if not card.is_empty():
					enemy.apply_upgrade(card)
			var hp_scale := float(spec.hp if shadow else data.rival_mods.hp) * (0.8 if main.story_difficulty == "easy" else 1.0)
			enemy.max_hp *= hp_scale
			enemy.set_meta("story_hp_scale", hp_scale)
			enemy.set_meta("story_scaled_max", enemy.max_hp)
			enemy.hp = enemy.max_hp
			enemy.souls = int(restored.get("souls", 0))
			if not restored.get("offer", {}).is_empty():
				main.soul_growth.active_offers[enemy] = restored.offer.duplicate(true)
				main.soul_growth.queued_offers[enemy] = int(restored.get("queued", 0))
			if not shadow or wave_index == 1:
				rival = enemy
				rival_hp_scale = hp_scale
				rival_scaled_max = enemy.max_hp
			if shadow:
				_style_shadow(enemy)
			enemy.defeated.connect(_on_rival_defeated)
		else:
			enemy = MONSTER.new()
			enemy.setup("ember_imp" if spec.kind == "ranged" else "mossling", realm, point, str(spec.skin))
			if spec.get("elite", false):
				enemy.make_elite()
			if spec.kind == "boss":
				enemy.make_boss()
				rival = enemy
			enemy.hostile = bool(spec.get("hostile", false))
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

func _shadow_cards(count: int, slot: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([main.match_seed, "story_shadow", main.story_hero, wave_index, slot])
	var result: Array[String] = []
	for pick in count:
		var offer := CARDS.draw_offer(rng, result)
		result.append(str(offer[rng.randi_range(0, offer.size() - 1)].id))
	return result

func _style_shadow(enemy: Node) -> void:
	enemy.set_meta("story_shadow", true)
	enemy.display_name = tr("Shadow %s") % tr(str(main.characters[enemy.character_id].name))
	enemy.modulate = SHADOW_TINT
	enemy._update_visuals()
	var readable_tint := Color(1.0 / SHADOW_TINT.r, 1.0 / SHADOW_TINT.g, 1.0 / SHADOW_TINT.b)
	# Tint the body while keeping the world-space name readable above violet smoke.
	enemy.name_label.self_modulate = readable_tint
	# Cancel the inherited body tint on the already-violet aura, retaining its authored colours.
	VFX.spawn(enemy, "shadow_aura", Vector2.ZERO, Vector2.ONE, true, -1, readable_tint, true)

func _spawn_crystals(restored: Array) -> void:
	var realm := int(data.realm)
	var points: Array[Vector2] = main.layout.get_spawn_points(realm)
	# The third crystal floats above the upper vine bridge, between the two high ledges.
	# Pin this stage's vine choices to that existing bridge so access is never a seed lottery.
	var bridge: Rect2 = main.layout.get_realm(realm).hazard.bridges[0]
	var hazard: Dictionary = main.hazards._realms[realm]
	hazard.hazard = hazard.hazard.duplicate(true)
	hazard.hazard.bridges = [bridge]
	var positions: Array[Vector2] = [points[0], points[3], main.layout.get_origin(realm) + Vector2(bridge.get_center().x, bridge.position.y - 100.0)]
	for index in int(data.crystals):
		var actor: Dictionary = restored[index] if index < restored.size() else {}
		if not actor.is_empty() and float(actor.hp) <= 0.0:
			continue
		var crystal := CRYSTAL.new()
		crystal.setup(realm, positions[index])
		main.add_child(crystal)
		crystal.set_meta("story_crystal_slot", index)
		if not actor.is_empty():
			crystal.hp = float(actor.hp)
		crystal.broken.connect(_on_crystal_broken)
		crystals.append(crystal)

func _on_crystal_broken(_crystal: Node, attacker: Node) -> void:
	if is_instance_valid(attacker) and attacker.has_method("add_souls"):
		attacker.add_souls(CRYSTAL.SOUL_REWARD)
	crystals_broken += 1
	if crystals_broken >= int(data.crystals) and phase == "combat":
		main.director.stop_escape()
		call_deferred("_objective_done")

func _spawn_reinforcement(restored: Dictionary = {}) -> void:
	var points: Array[Vector2] = main.layout.get_spawn_points(int(data.realm))
	var enemy := MONSTER.new()
	enemy.setup("ember_imp", int(data.realm), restored.get("position", points[0 if reinforcements.size() % 2 == 0 else 3]), str(data.reinforcements.skin))
	enemy.hostile = true
	enemy.max_hp *= 0.8 if main.story_difficulty == "easy" else 1.0
	enemy.hp = clampf(float(restored.get("hp", enemy.max_hp)), 0.0, enemy.max_hp)
	main.add_child(enemy)
	enemy.defeated.connect(_on_reinforcement_defeated)
	reinforcements.append(enemy)

func _on_reinforcement_defeated(_enemy: Node, attacker: Node, soul_reward: int) -> void:
	if is_instance_valid(attacker) and attacker.has_method("add_souls"):
		attacker.add_souls(soul_reward)

func _tick_reinforcements() -> void:
	if not is_instance_valid(rival) or rival.hp <= 0.0 or main.director.match_elapsed < next_reinforcement:
		return
	# One batch per deadline, no burst of historical batches after a large advance.
	next_reinforcement = main.director.match_elapsed + float(data.reinforcements.interval)
	reinforcements = reinforcements.filter(func(actor: Variant) -> bool: return is_instance_valid(actor) and actor.hp > 0.0)
	for index in mini(int(data.reinforcements.count), maxi(int(data.reinforcements.limit) - reinforcements.size(), 0)):
		_spawn_reinforcement()

func _on_monster_defeated(_enemy: Node, attacker: Node, soul_reward: int) -> void:
	if is_instance_valid(attacker) and attacker.has_method("add_souls"):
		attacker.add_souls(soul_reward)
	_enemy_fell()

func _on_rival_defeated(_enemy: Node, _attacker: Node) -> void:
	var aura := _enemy.get_node_or_null("Vfx_shadow_aura")
	if aura != null:
		aura.queue_free()
	if is_instance_valid(hero) and not hero.is_defeated:
		hero.add_souls(int(data.souls_reward))
	_enemy_fell()

func _on_rival_card_chosen(player: Node, _card: Dictionary, _auto_picked: bool) -> void:
	if player == hero:
		if phase == "root":
			call_deferred("_finish_root_if_ready")
		return
	if not is_instance_valid(player) or player == hero or player.is_defeated or not player.has_meta("story_hp_scale"):
		return
	# apply_upgrade rebuilds the character's unscaled max HP and heals its increase.
	# Reapply the stage rule, correcting that heal against the previous scaled max.
	var previous_max := float(player.get_meta("story_scaled_max"))
	var plain_max: float = player.max_hp
	var scaled_max := plain_max * float(player.get_meta("story_hp_scale"))
	var plain_gain := maxf(plain_max - previous_max, 0.0)
	var scaled_gain := maxf(scaled_max - previous_max, 0.0)
	player.max_hp = scaled_max
	player.hp = clampf(player.hp + scaled_gain - plain_gain, 0.0, scaled_max)
	player.set_meta("story_scaled_max", scaled_max)
	if player == rival:
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
	if phase != "combat":
		return
	if int(data.id) == 5:
		# A reload may capture the last broken crystal before its deferred completion.
		if crystals_broken >= int(data.crystals):
			_objective_done()
		return
	for enemy: Variant in enemies:
		if is_instance_valid(enemy) and enemy.hp > 0.0:
			return
	wave_index += 1
	if int(data.id) == 9 and wave_index == 1:
		_update_damage()
		hero.hp = minf(hero.hp + hero.max_hp * float(data.rules.intermission_heal), hero.max_hp)
		last_hp = hero.hp
		_play_scene("mid")
		return
	_spawn_wave()

func begin_dialogue() -> void:
	if phase != "start":
		return
	main.hud.hide_overlay()
	# Scenes play without the match HUD (minimap, status, skill bar); it returns with the fight.
	main.hud._set_match_hud_visible(false)
	phase = "pre"
	dialogue.play(CATALOG.dialogue_for(data, main.story_hero, "pre"), main.story_hero, "" if CATALOG.is_home(data, main.story_hero) else str(data.rival), main.human_body)
	main.hud.hide_card_offer()

func _on_dialogue_finished() -> void:
	main.hud._set_match_hud_visible(true)
	if phase == "pre":
		phase = "combat"
		main.director.begin_combat()
		if int(data.id) == 5:
			main.hazards.trigger(int(data.realm))
		set_frozen(false)
	elif phase == "mid":
		phase = "combat"
		_spawn_wave()
		main.director.start_shadow_band()
		main._sync_combatant_visibility()
		main._apply_phase_rules()
		set_frozen(false)
	elif phase == "post":
		if data.exit == Vector2i.ZERO:
			# Stage 8 has no physical exit at which to resolve a newly-earned card.
			# Let the existing panel finish its offers before checkpoint 9 is written.
			if int(data.id) == 8 and not main.soul_growth.get_offer(hero).is_empty():
				phase = "root"
				set_frozen(false)
				return
			main.director._finish(hero, "stage clear")
			return
		phase = "exit"
		set_frozen(false)
		main.director.open_exit()
		# The last foe cannot leave stray attacks hitting a hero at an opened exit.
		_stop_remaining_enemies()

func _stop_remaining_enemies() -> void:
	for enemy: Variant in enemies + reinforcements:
		if is_instance_valid(enemy):
			enemy.process_mode = Node.PROCESS_MODE_DISABLED

func _objective_done() -> void:
	if main.match_over or hero.is_defeated or phase in ["post", "exit", "result", "ending"]:
		return
	main.director.stop_escape()
	_play_scene("post")

func _play_scene(scene: String) -> void:
	phase = scene
	set_frozen(true)
	# The objective is complete: discard already-spawned attacks instead of waking
	# them behind the post scene. Realm hazards still run once the exit opens.
	for child in main.get_children():
		if child is Area2D:
			child.queue_free()
	rival_bar.visible = false
	main.hud._set_match_hud_visible(false)
	dialogue.play(CATALOG.dialogue_for(data, main.story_hero, scene), main.story_hero, "" if CATALOG.is_home(data, main.story_hero) else str(data.rival), main.human_body)
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
	return phase in ["combat", "exit", "root"] and not main.match_over and is_instance_valid(hero) and not hero.is_defeated

func _finish_root_if_ready() -> void:
	if phase == "root" and not main.match_over and not hero.is_defeated and main.soul_growth.get_offer(hero).is_empty() and int(main.soul_growth.queued_offers.get(hero, 0)) == 0:
		main.director._finish(hero, "stage clear")

func use_portal(portal: Dictionary) -> bool:
	if phase != "exit" or int(portal.destination) != main.director.exit_realm:
		return false
	if not main.soul_growth.get_offer(hero).is_empty():
		main._show_message(tr("Choose a soul card first."))
		return true
	preload("res://scripts/audio/AudioManager.gd").sound(hero, "portal")
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
	main.story_last_result.reason = main.director.finish_reason
	if clear and int(data.id) == 9:
		phase = "ending"
		main.hud.frontend.show_story_ending()
	else:
		main.hud.frontend.show_story_result(main.story_last_result)
	main.hud.overlay.visible = true
	main.hud.overlay_background_art.visible = false
	main.hud.overlay_back.color = Color(0.02, 0.025, 0.05, 0.86)

func objective_text() -> String:
	if phase == "root":
		return tr("Choose a soul card first.")
	if phase == "exit":
		var arrows := {Vector2i.LEFT: "←", Vector2i.RIGHT: "→", Vector2i.UP: "↑", Vector2i.DOWN: "↓"}
		return tr("Use the portal  %s  Q") % str(arrows.get(data.exit, ""))
	if int(data.id) == 5:
		var seconds: int = main.director.get_warning_seconds_left()
		return tr("Soul crystals %d/%d · %s") % [crystals_broken, int(data.crystals), "%d:%02d" % [seconds / 60, seconds % 60]]
	if int(data.id) == 9 and wave_index == 0:
		return tr("Shadows %d/%d") % [defeated_count, 4]
	if is_instance_valid(rival) and rival.hp > 0.0:
		return tr("Defeat %s") % _enemy_title(rival)
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

func _enemy_title(enemy: Node) -> String:
	if enemy.get("is_boss") == true:
		return tr("Boss %s") % tr(str(enemy.display_name).trim_prefix("Elite "))
	return tr(str(enemy.display_name))

func update_hud() -> void:
	main.hud.clock_label.text = tr("STAGE %d") % int(data.id) + "   |   " + objective_text()
	main.hud.clock_label.visible = phase in ["combat", "exit", "root"] and not main.hud.overlay.visible
	if int(data.id) == 5 and phase == "combat" and not main.match_over:
		main.hud.warning_label.text = tr("Collapse warning") + "  " + tr("%ds") % main.director.get_warning_seconds_left() + "\n" + tr("Break all soul crystals to open the exit.")
	rival_bar.visible = is_instance_valid(rival) and rival.hp > 0.0 and accepts_gameplay() and not main.hud.overlay.visible
	if rival_bar.visible:
		rival_fill.size.x = 404.0 * clampf(rival.hp / rival.max_hp, 0.0, 1.0)
		rival_name.text = "%s   %d / %d" % [_enemy_title(rival), ceili(rival.hp), ceili(rival.max_hp)]
	if phase in ["pre", "mid", "post"] or main.hud.overlay.visible:
		main.hud.hide_card_offer()
	if phase in ["pre", "mid", "post"]:
		# Main refreshes timed realm warnings even while combat is frozen. Keep the
		# complete HUD hidden on every scene frame, not only on scene entry.
		main.hud._set_match_hud_visible(false)

func _update_damage() -> void:
	if is_instance_valid(hero):
		damage_taken += maxf(last_hp - hero.hp, 0.0)
		last_hp = hero.hp

func _physics_process(_delta: float) -> void:
	if phase in ["combat", "exit", "root"]:
		_update_damage()
		if phase == "root":
			_finish_root_if_ready()
		if phase == "combat" and int(data.id) == 7 and not main.match_over:
			_tick_reinforcements()

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
			if enemy.get("upgrades") != null:
				actors[slot].cards = enemy.upgrades.duplicate()
				actors[slot].souls = enemy.souls
				actors[slot].offer = main.soul_growth.get_offer(enemy).duplicate(true)
				actors[slot].queued = main.soul_growth.queued_offers.get(enemy, 0)
	var crystal_actors: Array = []
	for index in int(data.crystals):
		crystal_actors.append({"hp": 0.0})
	for crystal: Variant in crystals:
		if is_instance_valid(crystal):
			crystal_actors[int(crystal.get_meta("story_crystal_slot"))] = {"hp": crystal.hp}
	var reinforcement_actors: Array = []
	for enemy: Variant in reinforcements:
		if is_instance_valid(enemy) and enemy.hp > 0.0:
			reinforcement_actors.append({"hp": enemy.hp, "position": enemy.global_position})
	return {"seed": main.match_seed, "phase": phase, "paused": get_tree().paused, "wave": wave_index, "defeated": defeated_count, "elapsed": main.director.match_elapsed, "damage": damage_taken,
		"crystals": crystal_actors, "crystals_broken": crystals_broken, "reinforcements": reinforcement_actors, "next_reinforcement": next_reinforcement,
		"band_started_at": main.director.band_started_at, "escape_started": main.director.escape_started, "warning_ends_at": main.director.warning_ends_at,
		"hero": {"souls": hero.souls, "cards": hero.upgrades.duplicate(), "hp": hero.hp, "position": hero.global_position, "ultimate": hero.ultimate_cooldown_timer, "damage": hero.damage_dealt, "score": hero.score},
		"enemies": actors, "offer": main.soul_growth.get_offer(hero).duplicate(true), "queued": main.soul_growth.queued_offers.get(hero, 0),
		"line": dialogue.line_index, "shown": dialogue.line_label.visible_characters if is_instance_valid(dialogue.line_label) else 0,
		"card_ms": maxi(0, main.hud.frontend.card_deadline - Time.get_ticks_msec())}

func _restore_art_screen(state: Dictionary) -> void:
	phase = str(state.phase)
	main.director.escape_started = bool(state.get("escape_started", false))
	if phase == "combat" and int(data.id) == 5 and crystals_broken < int(data.crystals):
		main.director.warning_ends_at = float(state.warning_ends_at)
		main.director.warning_realms.assign([int(data.realm)])
		main.director._set_state(int(data.realm), main.director.STATE_WARNING)
	if not state.offer.is_empty():
		main.soul_growth.active_offers[hero] = state.offer.duplicate(true)
		main.soul_growth.queued_offers[hero] = int(state.queued)
	if hero.hp <= 0.0:
		# HP was captured after a fatal hit but potentially before the director's
		# deferred failure. Restore death through the character's existing API.
		hero.apply_environment_damage(1.0)
		if phase not in ["result", "ending"]:
			return
	match phase:
		"pre", "mid", "post":
			main.hud.hide_overlay()
			main.hud._set_match_hud_visible(false)
			dialogue.play(CATALOG.dialogue_for(data, main.story_hero, phase), main.story_hero, "" if CATALOG.is_home(data, main.story_hero) else str(data.rival), main.human_body)
			dialogue.line_index = int(state.line)
			dialogue._show_line()
			dialogue.line_label.visible_characters = int(state.shown)
			dialogue._characters = dialogue.line_label.get_total_character_count() if int(state.shown) < 0 else int(state.shown)
		"combat", "exit", "root":
			main.hud.hide_overlay()
			set_frozen(false)
			if phase == "exit":
				main.director.open_exit()
				_stop_remaining_enemies()
			if state.paused:
				pause_stage()
			elif phase == "combat":
				call_deferred("_check_wave")
		"result", "ending":
			main.match_over = true
			main.director.match_over = true
			main.director.winner = hero if main.story_last_result.clear else null
			main.director.finish_reason = str(main.story_last_result.get("reason", "stage clear" if main.story_last_result.clear else "stage failed"))
			SPEED.reset_engine()
			if phase == "ending":
				main.hud.frontend.show_story_ending()
			else:
				main.hud.frontend.show_story_result(main.story_last_result)
		"start":
			main.hud.frontend.card_deadline = Time.get_ticks_msec() + int(state.card_ms)
