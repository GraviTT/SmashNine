extends CharacterBody2D

const AUDIO := preload("res://scripts/audio/AudioManager.gd")

signal defeated(monster: Node, attacker: Node, soul_reward: int)

enum State { NEUTRAL, AGGRO, DEFEATED }

## Monsters belong to the realm: distances follow GameScale.WORLD, speeds MOVE, falls and
## knockback the fighters' scales (routine 2026-10-08).
const GAME_SCALE := preload("res://scripts/GameScale.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const GRAVITY := 1850.0 * GAME_SCALE.GRAVITY
const FALL_OUT_DEPTH := 900.0 * GAME_SCALE.WORLD
## Monsters are soul sources, not the main threat: light pushes on one-screen realms (design D7).
const MELEE_KNOCKBACK := 140.0
const PROJECTILE_KNOCKBACK := 110.0
const WORLD_LAYER := 1
const PLAYER_LAYER := 2
const MONSTER_LAYER := 4
const ATTACK_SCRIPT := preload("res://scripts/monsters/MonsterAttack.gd")
const PROJECTILE_SCRIPT := preload("res://scripts/monsters/MonsterProjectile.gd")
const ARCHETYPES := preload("res://scripts/monsters/MonsterArchetypes.gd")
const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
const FRAMES := preload("res://characters/common/CharacterAnimation.gd")
const MONSTER_ART_DIR := "res://assets/art/monsters"
const FIREBALL_ART := "res://assets/art/monsters/ember_fireball.png"
## Original sheets: 6x4 cells, rows idle 4 / walk 6 / attack 4 / hurt 1, feet at 3/4 of the cell.
## The cell size is read from the sheet (width / 6): 96 px cells (CODEX-ART-11) draw at 1x, the
## older 64 px cells (CODEX-ART-05) at 1.5x, so a monster is 96 screen px either way.
const ART_ROWS := [["idle", 4, 6.0, true], ["walk", 6, 10.0, true], ["attack", 4, 12.0, false], ["hurt", 1, 1.0, false]]
const ART_ROWS_SIX := [["idle", 6, 6.0, true], ["walk", 6, 10.0, true], ["windup", 4, 8.0, false], ["attack", 6, 12.0, false], ["hurt", 2, 8.0, false], ["defeat", 4, 8.0, false]]
const ART_SCREEN_CELL := 96.0
## Fireball art: 36 px at 1x, or the older 24 px at 1.5x.
const FIREBALL_SCREEN_SIZE := 36.0
const ATTACK_ANIMATION_TIME := 0.33

var monster_type := "mossling"
## Keep monster_type for existing callers; skin_id selects the ecology behaviour.
var skin_id := "mossling"
var art_sheet_path := ""
var projectile_art_path := ""
var display_name := "Mossling"
var realm_index := 0
var max_hp := 45.0
var hp := 45.0
var move_speed := 105.0
var attack_damage := 7.0
var attack_range := 62.0
var attack_cooldown := 1.1
var soul_reward := 6
var control_slow_timer := 0.0
var last_yuki_activation_hit := -1
var body_color := Color(0.38, 0.82, 0.32)
var state := State.NEUTRAL
var target: Node
## Who hit it last and on which physics frame (bots count hitting their target as progress).
var last_attacker: Node
var last_hit_frame := -100000
var facing := 1
var patrol_center := Vector2.ZERO
var patrol_radius := 230.0
var wander_timer := 0.0
var wander_direction := 0.0
var attack_timer := 0.0
var hitstun_timer := 0.0
var knockback_velocity := Vector2.ZERO
var art_sprite: AnimatedSprite2D
var attack_animation_timer := 0.0
var six_row_art := false
var motion_attack_timer := 0.0
var motion_hurt_timer := 0.0
var is_realm_active := true

var body_visual: ColorRect
var name_label: Label
var hp_fill: ColorRect
var hp_back: ColorRect
var archetype := "bite"
var is_elite := false
## Opt-in story options; neutral battle-royale monsters keep their existing behaviour.
var hostile := false
var is_boss := false
var sight_range := 720.0 * GAME_SCALE.WORLD
var windup_duration := 0.32
var action_phase := "idle"
var action_timer := 0.0
var locked_target_position := Vector2.ZERO
var action_origin := Vector2.ZERO
var action_direction := Vector2.RIGHT
var active_attack: Area2D
var was_hit := false
var defeat_elapsed := 0.0
var spawn_slot := -1
var hover_height := 105.0 * GAME_SCALE.WORLD
var attack_serial := 0

func _init() -> void:
	# Standalone headless probes also start in English, before Main exists.
	LANGUAGE.load_saved()

func make_elite() -> void:
	if is_elite:
		return
	is_elite = true
	max_hp *= 3.0
	hp = max_hp
	soul_reward *= 4
	attack_damage *= 1.5
	windup_duration *= 1.4
	display_name = "Elite " + display_name
	scale = Vector2.ONE * 1.35

## Story spawns bosses directly, without registering a respawn slot in the BR spawner.
func make_boss() -> void:
	if is_boss:
		return
	make_elite()
	is_boss = true
	max_hp *= 4.0
	hp = max_hp
	attack_damage *= 2.0
	windup_duration *= 1.2
	attack_range *= 2.0
	scale = Vector2.ONE * 2.0

func setup(type_id: String, new_realm_index: int, spawn_position: Vector2, new_skin_id := "") -> void:
	monster_type = type_id
	skin_id = type_id if new_skin_id == "" else new_skin_id
	realm_index = new_realm_index
	global_position = spawn_position
	patrol_center = spawn_position
	if monster_type == "ember_imp":
		display_name = "Ember Imp"
		max_hp = 34.0
		move_speed = 125.0
		attack_damage = 6.0
		attack_range = 310.0
		attack_cooldown = 1.65
		soul_reward = 8
		body_color = Color(1.0, 0.38, 0.16)
	else:
		display_name = "Mossling"
		max_hp = 52.0
		move_speed = 105.0
		attack_damage = 8.0
		attack_range = 64.0
		attack_cooldown = 1.05
		soul_reward = 6
		body_color = Color(0.38, 0.82, 0.32)
	hp = max_hp
	move_speed *= GAME_SCALE.MOVE
	attack_range *= GAME_SCALE.WORLD
	patrol_radius *= GAME_SCALE.WORLD
	archetype = ARCHETYPES.archetype_for(skin_id, monster_type)
	var profile: Array = ARCHETYPES.PROFILES[archetype]
	windup_duration = float(profile[0])
	attack_range = float(profile[1]) * GAME_SCALE.WORLD
	attack_cooldown = float(profile[2])
	attack_damage = float(profile[3])
	display_name = ARCHETYPES.title_for(skin_id if ARCHETYPES.SKINS.has(skin_id) else monster_type)

func _ready() -> void:
	add_to_group("realm_monsters")
	collision_layer = MONSTER_LAYER
	collision_mask = WORLD_LAYER
	_build_body()
	wander_timer = randf_range(0.5, 1.8)
	wander_direction = [-1.0, 1.0].pick_random()

func _build_body() -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(42, 44) if monster_type == "mossling" else Vector2(36, 52)
	collision.shape = shape
	collision.position = Vector2(0, -shape.size.y * 0.5)
	add_child(collision)

	body_visual = ColorRect.new()
	body_visual.size = shape.size
	body_visual.position = Vector2(-shape.size.x * 0.5, -shape.size.y)
	body_visual.color = body_color
	body_visual.pivot_offset = shape.size * 0.5
	add_child(body_visual)

	art_sprite = _build_art_sprite()
	if art_sprite != null:
		body_visual.visible = false
		add_child(art_sprite)
	elif monster_type == "mossling":
		var cap := ColorRect.new()
		cap.size = Vector2(50, 14)
		cap.position = Vector2(-25, -50)
		cap.color = Color(0.62, 0.96, 0.38)
		add_child(cap)
	else:
		var horn_left := Polygon2D.new()
		horn_left.polygon = PackedVector2Array([Vector2(-16, -48), Vector2(-7, -67), Vector2(-3, -45)])
		horn_left.color = Color(1.0, 0.78, 0.22)
		add_child(horn_left)
		var horn_right := Polygon2D.new()
		horn_right.polygon = PackedVector2Array([Vector2(16, -48), Vector2(7, -67), Vector2(3, -45)])
		horn_right.color = Color(1.0, 0.78, 0.22)
		add_child(horn_right)

	name_label = Label.new()
	name_label.position = Vector2(-120, -124 if is_elite else -92)
	name_label.size = Vector2(240, 24)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.07))
	name_label.add_theme_constant_override("outline_size", 3)
	add_child(name_label)

	hp_back = ColorRect.new()
	hp_back.color = Color(0.08, 0.08, 0.08, 0.92)
	hp_back.size = Vector2(48, 6)
	hp_back.position = Vector2(-24, -68)
	add_child(hp_back)
	hp_fill = ColorRect.new()
	hp_fill.size = hp_back.size
	hp_fill.color = Color(0.3, 1.0, 0.4)
	hp_back.add_child(hp_fill)
	_update_visuals()

func _physics_process(delta: float) -> void:
	if state == State.DEFEATED:
		defeat_elapsed += delta
		var motion_time := 4.0 / 8.0 if six_row_art else 0.0
		var fade_time := 0.3 if six_row_art else 0.55
		modulate.a = clampf(1.0 - (defeat_elapsed - motion_time) / fade_time, 0.0, 1.0)
		queue_redraw()
		if defeat_elapsed >= motion_time + fade_time:
			queue_free()
		return
	if not is_realm_active:
		return
	# Knocked off the realm: counts as a kill for whoever it was fighting.
	if global_position.y > patrol_center.y + FALL_OUT_DEPTH:
		_die(target if _is_valid_target() else null)
		return
	attack_timer = maxf(attack_timer - delta, 0.0)
	hitstun_timer = maxf(hitstun_timer - delta, 0.0)
	control_slow_timer = maxf(control_slow_timer - delta, 0.0)
	if not is_on_floor() and archetype != "swoop":
		velocity.y = minf(velocity.y + GRAVITY * delta, 900.0 * GAME_SCALE.JUMP_SPEED)

	if hitstun_timer > 0.0:
		velocity.x = knockback_velocity.x
		_cancel_action()
	else:
		_update_behavior(delta)
		if control_slow_timer > 0.0:
			velocity.x *= 0.55
	velocity += knockback_velocity
	move_and_slide()
	velocity -= knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 1050.0 * GAME_SCALE.KNOCKBACK * delta)
	_update_art(delta)
	queue_redraw()

func _build_art_sprite() -> AnimatedSprite2D:
	art_sheet_path = "%s/%s_sheet.png" % [MONSTER_ART_DIR, skin_id]
	var sheet := ART_SETTINGS.original_texture(art_sheet_path)
	if sheet == null and skin_id != monster_type:
		art_sheet_path = "%s/%s_sheet.png" % [MONSTER_ART_DIR, monster_type]
		sheet = ART_SETTINGS.original_texture(art_sheet_path)
	if sheet == null:
		art_sheet_path = ""
		return null
	var cell := sheet.get_width() / 6
	var art_scale := ART_SCREEN_CELL / cell
	var frames := _frames_for_sheet(sheet)
	var sprite := AnimatedSprite2D.new()
	sprite.name = "ArtSprite"
	sprite.sprite_frames = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(art_scale, art_scale)
	# Only the legacy ART-27 golem has feet y=80; all new six-row walkers use y=72.
	var feet_from_center := 32.0 if not six_row_art and art_sheet_path.ends_with("/jotunheim_rune_golem_sheet.png") else cell * 0.25
	sprite.position = Vector2(0, -feet_from_center * art_scale)
	sprite.play(&"idle")
	return sprite

func _frames_for_sheet(sheet: Texture2D) -> SpriteFrames:
	var cell := sheet.get_width() / 6
	six_row_art = sheet.get_height() == 6 * cell
	var rows: Array = ART_ROWS_SIX if six_row_art else ART_ROWS
	var frames := FRAMES.create_frames()
	for row in rows.size():
		var spec: Array = rows[row]
		var loops := archetype in ["charge", "swoop"] if six_row_art and spec[0] == "attack" else bool(spec[3])
		FRAMES.add_grid(frames, StringName(spec[0]), sheet, Vector2i(cell, cell), 6, row * 6, int(spec[1]), float(spec[2]), loops)
	return frames

func _update_art(delta: float) -> void:
	if art_sprite == null:
		return
	attack_animation_timer = maxf(attack_animation_timer - delta, 0.0)
	art_sprite.flip_h = facing < 0
	if six_row_art:
		_update_six_row_art(delta)
		return
	if hitstun_timer <= 0.0 and action_phase in ["windup", "arrival"]:
		# Hold the anticipation drawing while the warning is counting down. Playing
		# the whole attack row here would show a completed swing before any hit exists.
		if art_sprite.animation != &"attack":
			art_sprite.play(&"attack")
		art_sprite.frame = 0
		art_sprite.pause()
		return
	var animation := &"idle"
	if hitstun_timer > 0.0:
		animation = &"hurt"
	elif attack_animation_timer > 0.0 or action_phase != "idle":
		animation = &"attack"
	elif absf(velocity.x) > 15.0:
		animation = &"walk"
	if art_sprite.animation != animation:
		art_sprite.play(animation)

func _update_six_row_art(delta: float) -> void:
	motion_attack_timer = maxf(motion_attack_timer - delta, 0.0)
	motion_hurt_timer = maxf(motion_hurt_timer - delta, 0.0)
	var animation := &"idle"
	if motion_hurt_timer > 0.0:
		animation = &"hurt"
	elif action_phase == "windup":
		art_sprite.animation = &"windup"
		art_sprite.pause()
		var progress := 1.0 - clampf(action_timer / maxf(windup_duration, 0.001), 0.0, 1.0)
		art_sprite.frame = mini(int(progress * 4.0), 3)
		return
	elif motion_attack_timer > 0.0 or action_phase in ["active", "arrival"]:
		animation = &"attack"
	elif absf(velocity.x) > 15.0:
		animation = &"walk"
	if art_sprite.animation != animation:
		art_sprite.speed_scale = 1.0
		art_sprite.play(animation)

func _update_behavior(delta: float) -> void:
	if hostile and (state == State.NEUTRAL or not _is_valid_target()):
		_acquire_visible_fighter()
	if action_phase != "idle":
		if not _is_valid_target():
			_cancel_action()
			return_to_neutral()
			return
		_tick_action(delta)
		return
	if state == State.NEUTRAL:
		_update_neutral_wander(delta)
		if archetype == "swoop":
			velocity.y = clampf((patrol_center.y - hover_height - global_position.y) * 2.0, -150.0, 150.0)
		return
	if not _is_valid_target():
		return_to_neutral()
		return
	var offset: Vector2 = target.global_position - global_position
	if absf(offset.x) > 720.0 * GAME_SCALE.WORLD or absf(offset.y) > 360.0 * GAME_SCALE.WORLD:
		return_to_neutral()
		return
	facing = 1 if offset.x >= 0.0 else -1
	if archetype == "swoop":
		velocity.y = clampf((patrol_center.y - hover_height - global_position.y) * 2.0, -180.0, 180.0)
	var vertical_range := 260.0 if archetype in ["swoop", "lob", "homing", "leap"] else 100.0
	var grounded_ready := is_on_floor() if archetype in ["charge", "shell", "slam", "leap"] else true
	if grounded_ready and absf(offset.x) <= attack_range and absf(offset.y) < vertical_range * GAME_SCALE.WORLD and attack_timer <= 0.0:
		_begin_windup()
		return
	var direction := signf(offset.x)
	if archetype in ["bolt", "lob", "homing"] and absf(offset.x) < 130.0 * GAME_SCALE.WORLD:
		direction = -direction
	velocity.x = direction * move_speed if archetype == "swoop" or _has_floor_ahead(direction) else 0.0

func _begin_windup() -> void:
	AUDIO.sound(self, "monster_windup")
	action_phase = "windup"
	action_timer = windup_duration
	locked_target_position = target.global_position
	action_origin = global_position
	action_direction = (locked_target_position - global_position).normalized()
	facing = 1 if action_direction.x >= 0.0 else -1
	velocity.x = 0.0
	if archetype == "swoop":
		velocity.y = 0.0
	attack_animation_timer = 0.0
	queue_redraw()

func _tick_action(delta: float) -> void:
	action_timer -= delta
	if action_phase == "windup":
		velocity.x = 0.0
		if action_timer <= 0.0:
			_execute_action()
		return
	if action_phase == "arrival":
		if action_timer <= 0.0:
			_spawn_body_attack(Vector2(120, 70), Vector2(0, -30), 0.16)
			_finish_action()
		return
	if action_phase == "active":
		if archetype in ["charge", "shell"]:
			if not is_on_floor() or not _has_floor_ahead(facing) or is_on_wall():
				_finish_action()
				return
			velocity.x = facing * move_speed * 2.5
		elif archetype == "swoop":
			velocity = action_direction * 430.0 * GAME_SCALE.MOVE
		if action_timer <= 0.0 or (archetype == "leap" and is_on_floor() and velocity.y >= 0.0):
			_finish_action()

func _execute_action() -> void:
	AUDIO.sound(self, "monster_" + archetype)
	attack_serial += 1
	action_phase = "active"
	action_timer = 0.65
	if six_row_art:
		_play_strike_animation()
	match archetype:
		"bite":
			_spawn_melee_attack()
			_finish_action()
		"charge", "shell":
			velocity.x = facing * move_speed * 2.5 if _has_floor_ahead(facing) else 0.0
			_spawn_body_attack(Vector2(58, 44), Vector2(20 * facing, -25), action_timer)
		"leap":
			var flight_time := 0.65
			var landing_delta := locked_target_position - global_position
			velocity = Vector2(clampf(landing_delta.x, -340.0, 340.0) / flight_time, clampf(landing_delta.y, -180.0, 180.0) / flight_time - GRAVITY * flight_time * 0.5)
			_spawn_body_attack(Vector2(56, 48), Vector2(0, -25), action_timer)
		"slam":
			var shared_hits: Array[Node] = []
			for side in [-1, 1]:
				var wave := _spawn_ecology_projectile(Vector2(side, 0), "shockwave")
				wave.hit_targets = shared_hits
				wave.global_position = global_position + Vector2(side * 35, -18)
			_finish_action()
		"bolt", "homing":
			_spawn_projectile(action_direction)
			_finish_action()
		"lob":
			var shared_hits: Array[Node] = []
			var fan := [-0.18, 0.0, 0.18] if skin_id == "vanaheim_seed_sprite" else [0.0]
			for angle in fan:
				var shot := _spawn_ecology_projectile(action_direction, "lob")
				shot.hit_targets = shared_hits
				shot.flight_velocity = shot.flight_velocity.rotated(float(angle))
			_finish_action()
		"swoop":
			if skin_id == "svartalfheim_cog_drone":
				_spawn_ecology_projectile(Vector2.DOWN, "bomb")
				_finish_action()
			else:
				action_direction = (locked_target_position + Vector2(0, -24) - global_position).normalized()
				_spawn_body_attack(Vector2(52, 48), Vector2(0, -24), action_timer)
		"blink":
			var destination := Vector2(locked_target_position.x - facing * 60.0, global_position.y)
			destination.x = global_position.x + clampf(destination.x - global_position.x, -180.0 * GAME_SCALE.WORLD, 180.0 * GAME_SCALE.WORLD)
			var floor_ray := PhysicsRayQueryParameters2D.create(destination + Vector2(0, -40), destination + Vector2(0, 100), WORLD_LAYER)
			var floor_hit := get_world_2d().direct_space_state.intersect_ray(floor_ray)
			if not floor_hit.is_empty():
				global_position = floor_hit.position
			velocity = Vector2.ZERO
			action_phase = "arrival"
			action_timer = 0.25
	queue_redraw()

func _finish_action() -> void:
	_cancel_action(false)
	attack_timer = attack_cooldown

func _cancel_action(cancel_animation := true) -> void:
	action_phase = "idle"
	action_timer = 0.0
	if cancel_animation:
		attack_animation_timer = 0.0
		motion_attack_timer = 0.0
	velocity.x = 0.0
	if is_instance_valid(active_attack):
		active_attack.queue_free()
	active_attack = null

func _play_strike_animation() -> void:
	attack_animation_timer = ATTACK_ANIMATION_TIME
	if six_row_art:
		motion_attack_timer = 6.0 / 12.0
	if art_sprite != null:
		art_sprite.play(&"attack")
		art_sprite.frame = 0

func _spawn_body_attack(size: Vector2, offset: Vector2, duration: float) -> void:
	var body_scale := 2.0 if is_boss else 1.0
	size *= body_scale
	offset *= body_scale
	var attack := Area2D.new()
	attack.set_script(ATTACK_SCRIPT)
	attack.collision_layer = 0
	attack.collision_mask = PLAYER_LAYER
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	attack.add_child(shape)
	var visual := ColorRect.new()
	visual.name = "Visual"
	attack.add_child(visual)
	get_parent().add_child(attack)
	attack.global_position = global_position
	attack.configure(self, size * GAME_SCALE.WORLD, offset, attack_damage, _attack_knockback(false), Vector2(facing, -0.12), Color(1.0, 0.7, 0.25, 0.3), duration)
	attack.follow_source = duration > 0.2
	attack.follow_offset = offset
	attack.slow_duration = 0.45 if skin_id == "vanaheim_vine_hound" else 0.0
	_play_strike_animation()
	if attack.follow_source:
		active_attack = attack

func _attack_knockback(projectile: bool) -> float:
	if is_boss:
		return 420.0
	if is_elite:
		return 280.0 if projectile else 320.0
	return PROJECTILE_KNOCKBACK if projectile else MELEE_KNOCKBACK

func _acquire_visible_fighter() -> void:
	var nearest: Node = null
	var nearest_distance := INF
	for fighter in get_tree().get_nodes_in_group("players"):
		if fighter.is_defeated or fighter.realm_index != realm_index or not fighter.is_realm_active:
			continue
		var offset: Vector2 = fighter.global_position - global_position
		if absf(offset.x) > sight_range or absf(offset.y) > 360.0 * GAME_SCALE.WORLD:
			continue
		var distance := offset.length_squared()
		if distance < nearest_distance:
			nearest = fighter
			nearest_distance = distance
	if nearest != null:
		target = nearest
		state = State.AGGRO
		_update_visuals()

func _update_neutral_wander(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_timer = randf_range(1.0, 2.8)
		wander_direction = [-1.0, 0.0, 1.0].pick_random()
	if absf(global_position.x - patrol_center.x) > patrol_radius:
		wander_direction = -signf(global_position.x - patrol_center.x)
	if wander_direction != 0.0 and not _has_floor_ahead(wander_direction):
		wander_direction *= -1.0
	facing = int(wander_direction) if wander_direction != 0.0 else facing
	velocity.x = move_toward(velocity.x, wander_direction * move_speed * 0.55, 850.0 * delta)

func _has_floor_ahead(direction: float) -> bool:
	if not is_on_floor():
		return true
	var lookahead := 55.0 if action_phase == "active" and archetype in ["charge", "shell"] else 30.0
	var from := global_position + Vector2(direction * lookahead, -8.0)
	var to := from + Vector2(0.0, 82.0)
	var query := PhysicsRayQueryParameters2D.create(from, to, WORLD_LAYER)
	query.exclude = [get_rid()]
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _spawn_melee_attack() -> void:
	var attack := Area2D.new()
	attack.set_script(ATTACK_SCRIPT)
	attack.collision_layer = 0
	attack.collision_mask = PLAYER_LAYER
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	attack.add_child(shape)
	var visual := ColorRect.new()
	visual.name = "Visual"
	attack.add_child(visual)
	get_parent().add_child(attack)
	attack.global_position = global_position
	var body_scale := 2.0 if is_boss else 1.0
	attack.configure(self, Vector2(56, 42) * GAME_SCALE.WORLD * body_scale, Vector2(42 * facing, -28) * GAME_SCALE.WORLD * body_scale, attack_damage, _attack_knockback(false), Vector2(facing, -0.16), Color(0.7, 1.0, 0.36, 0.55), 0.16)
	# With the original art the bite shows in the attack animation; the rectangle stays hidden.
	if art_sprite != null:
		attack.art_drawn = true
		attack.get_node("Visual").visible = false
	_play_strike_animation()

func _spawn_projectile(direction: Vector2) -> void:
	_spawn_ecology_projectile(direction, "homing" if archetype == "homing" else "bolt")

func _spawn_ecology_projectile(direction: Vector2, kind: String) -> Area2D:
	var projectile := Area2D.new()
	projectile.set_script(PROJECTILE_SCRIPT)
	projectile.collision_layer = 0
	projectile.collision_mask = PLAYER_LAYER
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	projectile.add_child(shape)
	var visual := ColorRect.new()
	visual.name = "Visual"
	projectile.add_child(visual)
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(32 * facing, -34)
	var shot_speed := 180.0 if kind == "homing" else 390.0
	var duration := 2.2 if kind in ["homing", "lob", "bomb"] else 1.35
	if kind == "shockwave":
		shot_speed = 340.0
		duration = 0.42
	projectile.configure(self, Vector2(30, 22) * GAME_SCALE.WORLD, attack_damage, _attack_knockback(true), direction, Color(1.0, 0.65, 0.2, 0.85), shot_speed * GAME_SCALE.WORLD, duration)
	projectile.projectile_kind = kind
	projectile.target = target
	projectile.ground_check = kind == "shockwave"
	projectile.slow_duration = 0.55 if skin_id == "niflheim_frost_owl" else 0.0
	if kind in ["lob", "bomb"]:
		var flight_time := 0.8
		projectile.arc_gravity = 1050.0 * GAME_SCALE.GRAVITY
		var destination := locked_target_position + Vector2(0, -24)
		projectile.flight_velocity = (destination - projectile.global_position) / flight_time - Vector2(0, projectile.arc_gravity * flight_time * 0.5)
		if kind == "bomb":
			projectile.flight_velocity = Vector2(clampf(projectile.flight_velocity.x, -120.0, 120.0), 60.0)
	projectile.art_scale_multiplier = GAME_SCALE.WORLD
	projectile_art_path = "%s/%s_projectile.png" % [MONSTER_ART_DIR, skin_id]
	var projectile_art := ART_SETTINGS.original_texture(projectile_art_path)
	if projectile_art == null:
		projectile_art_path = FIREBALL_ART
		projectile_art = ART_SETTINGS.original_texture(projectile_art_path)
	if kind == "shockwave":
		# A low, ground-bound crest reads as a shockwave rather than a second fireball.
		visual.visible = false
		var crest := Line2D.new()
		crest.points = PackedVector2Array([Vector2(-16, 12), Vector2(-8, -10), Vector2(0, -22), Vector2(8, -10), Vector2(16, 12)])
		crest.width = 5.0
		crest.default_color = Color(1.0, 0.8, 0.3)
		projectile.add_child(crest)
	elif projectile_art != null:
		projectile.set_art(projectile_art_path, Color.WHITE, FIREBALL_SCREEN_SIZE / projectile_art.get_width())
	_play_strike_animation()
	return projectile

func apply_hit(attacker: Node, damage: float, base_knockback: float, direction: Vector2, damage_type := "normal") -> bool:
	if state == State.DEFEATED:
		return false
	var final_damage := damage
	if damage_type != "fixed" and is_instance_valid(attacker):
		var power_value = attacker.get("attack_power")
		if power_value != null:
			final_damage *= float(power_value) / 100.0
	if archetype == "shell" and action_phase == "active":
		var frontal := direction.x * facing < 0.0
		if is_instance_valid(attacker) and attacker is Node2D:
			frontal = (attacker.global_position.x - global_position.x) * facing > 0.0
		if frontal:
			final_damage *= 0.5
	AUDIO.sound(self, "monster_hurt")
	was_hit = true
	hp = maxf(hp - final_damage, 0.0)
	if is_instance_valid(attacker) and attacker.is_in_group("players"):
		state = State.AGGRO
		target = attacker
		last_attacker = attacker
		last_hit_frame = Engine.get_physics_frames()
	var hit_direction := direction.normalized()
	if hit_direction == Vector2.ZERO:
		hit_direction = Vector2.RIGHT
	knockback_velocity += hit_direction * base_knockback * 0.55 * GAME_SCALE.KNOCKBACK
	hitstun_timer = clampf(base_knockback / 1800.0, 0.08, 0.24)
	if six_row_art and art_sprite != null:
		motion_hurt_timer = 2.0 / 8.0
		art_sprite.play(&"hurt")
		art_sprite.set_frame_and_progress(0, 0.0)
	_flash_hit()
	_update_visuals()
	if hp <= 0.0:
		_die(attacker)
	return true

func apply_forced_launch_hit(attacker: Node, damage: float, launch_velocity: Vector2, hitstun_duration: float, _effect_knockback: float, direction: Vector2, damage_type := "normal") -> bool:
	if not apply_hit(attacker, damage, launch_velocity.length(), direction, damage_type):
		return false
	knockback_velocity += launch_velocity * 0.35 * GAME_SCALE.KNOCKBACK
	hitstun_timer = maxf(hitstun_timer, hitstun_duration)
	return true

func apply_stun_hit(attacker: Node, damage: float, base_knockback: float, direction: Vector2, stun_duration: float, damage_type := "normal") -> bool:
	if not apply_hit(attacker, damage, base_knockback, direction, damage_type):
		return false
	hitstun_timer = maxf(hitstun_timer, stun_duration)
	return true

func apply_control_pull(center: Vector2, strength: float, delta: float, slow_duration: float, _slow_jump := false) -> void:
	if state == State.DEFEATED:
		return
	knockback_velocity += (center - global_position).normalized() * strength * GAME_SCALE.KNOCKBACK * delta
	control_slow_timer = maxf(control_slow_timer, slow_duration)

func apply_yuki_seal_burst(attacker: Node, activation_id: int, damage: float, knockback: float, direction: Vector2) -> bool:
	if last_yuki_activation_hit == activation_id:
		return false
	last_yuki_activation_hit = activation_id
	return apply_hit(attacker, damage, knockback, direction)

func return_to_neutral() -> void:
	_cancel_action()
	state = State.NEUTRAL
	target = null
	# Flyers climb back to the same home after a dive or displacement. Moving their
	# anchor on disengage would ratchet their altitude and let them patrol the void.
	if archetype != "swoop":
		patrol_center = global_position
	wander_timer = 0.0
	_update_visuals()

func set_realm_active(active: bool) -> void:
	if not active:
		_cancel_action()
	is_realm_active = active
	visible = active
	set_physics_process(active or state == State.DEFEATED)
	collision_layer = MONSTER_LAYER if active and state != State.DEFEATED else 0

func _is_valid_target() -> bool:
	return is_instance_valid(target) and not target.is_defeated and target.realm_index == realm_index and target.is_realm_active

func _die(attacker: Node) -> void:
	if state == State.DEFEATED:
		return
	AUDIO.sound(self, "monster_defeat")
	state = State.DEFEATED
	_cancel_action()
	hp = 0.0
	collision_layer = 0
	velocity = Vector2.ZERO
	set_physics_process(true)
	name_label.visible = false
	hp_back.visible = false
	if art_sprite != null:
		art_sprite.speed_scale = 1.0
		art_sprite.play(&"defeat" if six_row_art else &"hurt")
		art_sprite.modulate = Color.WHITE
	defeated.emit(self, attacker, soul_reward)
	queue_redraw()

func _flash_hit() -> void:
	if art_sprite != null:
		art_sprite.modulate = Color(2.2, 2.2, 2.2)
		art_sprite.create_tween().tween_property(art_sprite, "modulate", Color.WHITE, 0.1)
		return
	if not is_instance_valid(body_visual):
		return
	body_visual.color = Color.WHITE
	var tween := create_tween()
	tween.tween_property(body_visual, "color", body_color, 0.1)

func _update_visuals() -> void:
	if not is_instance_valid(name_label) or not is_instance_valid(hp_fill):
		return
	var disposition := "Neutral" if state == State.NEUTRAL else "Hostile"
	var title := tr("Boss %s") % tr(display_name.trim_prefix("Elite ")) if is_boss else (tr("Elite %s") % tr(display_name.trim_prefix("Elite ")) if is_elite else tr(display_name))
	name_label.text = "%s · %s" % [title, tr(disposition)]
	hp_fill.scale.x = clampf(hp / max_hp, 0.0, 1.0)
	hp_back.visible = is_elite or was_hit
	hp_fill.color = Color(0.3, 1.0, 0.4) if state == State.NEUTRAL else Color(1.0, 0.25, 0.16)

func _draw() -> void:
	if state == State.DEFEATED:
		for i in 6:
			var angle := TAU * i / 6.0
			var point := Vector2(cos(angle) * 42.0 * defeat_elapsed, -sin(angle) * 20.0 * defeat_elapsed - 30.0 * defeat_elapsed)
			draw_circle(point, 3.5, Color(0.45, 0.9, 1.0, 0.9))
		return
	if is_elite:
		draw_arc(Vector2(0, -24), 46.0, 0, TAU, 40, Color(1.0, 0.75, 0.2, 0.6), 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-15, -78), Vector2(-19, -94), Vector2(-7, -86), Vector2(0, -100), Vector2(7, -86), Vector2(19, -94), Vector2(15, -78)]), Color(1.0, 0.78, 0.2))
	if action_phase in ["windup", "arrival"]:
		var progress := 1.0 - clampf(action_timer / windup_duration, 0.0, 1.0)
		var tint := Color(1.0, 0.72, 0.18, 0.45 + 0.5 * progress)
		draw_arc(Vector2(0, -25), 36.0 + 8.0 * progress, 0, TAU, 36, tint, 4.0)
		var width := 150.0 if archetype == "slam" else 55.0
		draw_line(Vector2(-width, -3), Vector2(width, -3), tint, 5.0)
		if archetype in ["charge", "shell"]:
			draw_line(Vector2(0, -8), Vector2(facing * 180, -8), tint, 3.0)
		if archetype in ["leap", "swoop", "blink", "lob"]:
			var mark := to_local(locked_target_position)
			draw_arc(mark, 32.0, 0, TAU, 24, tint, 3.0)
