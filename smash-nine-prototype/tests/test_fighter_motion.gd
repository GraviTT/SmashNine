extends SceneTree
## SYS-06: real legacy frames supply optional strips; no art files or imports are written.
const FACTORY := preload("res://scripts/PlayerFactory.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
var arena: Node2D
var checks := 0
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error(message)

func _fighter(id := "frey", body := "") -> Node:
	var fighter: Node = FACTORY.create(id, body)
	arena.add_child(fighter)
	fighter.setup(REGISTRY.get_characters()[id], 1, false)
	fighter.is_dummy = true
	fighter.set_physics_process(false)
	fighter.ringout_y = 100000.0
	# Keep the absent-row fixture independent of any art adopted after this card.
	var frames: SpriteFrames = fighter.character_sprite.sprite_frames
	for prefix in [id, "luna_brave"]:
		for row in ["jump", "fall", "hurt", "land", "victory"]:
			var name := StringName(prefix + "_" + row)
			if not frames.has_animation(name):
				continue
			var texture := frames.get_frame_texture(name, 0)
			frames.remove_animation(name)
			if row in ["jump", "fall", "hurt"]:
				frames.add_animation(name)
				frames.set_animation_speed(name, 1.0)
				frames.set_animation_loop(name, false)
				frames.add_frame(name, texture)
	return fighter

func _lend(fighter: Node, row: String, prefix := "") -> void:
	var stem: String = fighter.character_id if prefix == "" else prefix
	var frames: SpriteFrames = fighter.character_sprite.sprite_frames
	var original: Texture2D = frames.get_frame_texture(StringName(stem + "_hurt"), 0)
	for spec in fighter.OPTIONAL_MOTION_ROWS:
		if spec[0] != row:
			continue
		var cell := 192 if row == "victory" else 128
		var strip := Image.create(cell * int(spec[1]), cell, false, Image.FORMAT_RGBA8)
		for index in int(spec[1]):
			var margin := (cell - 128) / 2
			strip.blit_rect(original.get_image(), Rect2i(0, 0, 128, 128), Vector2i(index * cell + margin, margin))
		_check(fighter._add_optional_motion_strip(frames, stem, ImageTexture.create_from_image(strip), spec), "valid %s strip should load" % row)

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	for id in REGISTRY.get_character_ids():
		for body in REGISTRY.get_bodies(id):
			var old := _fighter(id, body)
			for row in ["jump", "fall", "hurt"]:
				_check(old.character_sprite.sprite_frames.get_frame_count(StringName(id + "_" + row)) == 1, "%s %s legacy %s stays one drawing" % [id, body, row])
			_check(not old._has_motion_row(&"land") and not old._has_motion_row(&"victory"), "missing optional rows stay absent")
			old.play_victory()
			_check(old.character_sprite.animation == StringName(id + "_idle"), "victory without row uses idle")
			old.velocity.y = -50.0
			old._update_character_sprite()
			_check(old.character_sprite.animation == StringName(id + "_jump") and old.character_sprite.frame == 0, "legacy rising pose")
			old.velocity.y = 50.0
			old._update_character_sprite()
			_check(old.character_sprite.animation == StringName(id + "_fall") and old.character_sprite.frame == 0, "legacy falling pose")
			old._play_sprite_action(&"hurt", 0.3)
			old._update_character_sprite()
			_check(old.character_sprite.speed_scale == 1.0 and old.character_sprite.frame == 0, "legacy hurt keeps original speed and frame")
			old.free()
	await _air_and_hurt("frey", false)
	await _air_and_hurt("luna", false)
	await _air_and_hurt("luna", true)
	await _landing()
	await _gameplay_parity()
	await _hitstop_and_stun()
	arena.queue_free()
	await process_frame
	print("Fighter motion: %d checks, failed=%s" % [checks, failed])
	quit(1 if failed else 0)

func _air_and_hurt(id: String, brave: bool) -> void:
	var fighter := _fighter(id)
	var prefix := "luna_brave" if brave else id
	if brave:
		fighter.transformed = true
	for row in ["jump", "fall", "hurt", "victory"]:
		_lend(fighter, row, prefix)
	fighter.velocity.y = -100.0
	fighter._update_character_sprite()
	await create_timer(0.36).timeout
	_check(fighter.character_sprite.animation == StringName(prefix + "_jump") and fighter.character_sprite.frame == 2 and not fighter.character_sprite.is_playing(), "jump plays once and holds last (%s)" % prefix)
	fighter._update_visuals()
	_check(fighter.character_sprite.frame == 2 and not fighter.character_sprite.is_playing(), "bar refresh keeps the held jump drawing")
	fighter._restart_jump_motion()
	_check(fighter.character_sprite.frame == 0, "air jump restarts multi drawing jump")
	fighter.velocity.y = 100.0
	fighter._update_character_sprite()
	await create_timer(0.16).timeout
	_check(fighter.character_sprite.frame == 1, "fall advances to second drawing")
	await create_timer(0.12).timeout
	_check(fighter.character_sprite.frame == 0 and fighter.character_sprite.is_playing(), "fall loops")
	fighter._play_sprite_action(&"hurt", 0.6)
	fighter._update_character_sprite()
	await create_timer(0.24).timeout
	_check(fighter.character_sprite.frame == 1, "hurt spans the hitstun rather than the table fps")
	await create_timer(0.43).timeout
	_check(fighter.character_sprite.frame == 2 and not fighter.character_sprite.is_playing(), "hurt holds the last drawing")
	fighter._update_visuals()
	_check(fighter.character_sprite.frame == 2 and not fighter.character_sprite.is_playing(), "bar refresh keeps the held hurt drawing")
	fighter._play_sprite_action(&"hurt", 0.6)
	fighter._update_character_sprite()
	_check(fighter.character_sprite.frame == 0, "a repeated hit restarts hurt")
	fighter.play_victory()
	await create_timer(0.82).timeout
	_check(fighter.character_sprite.animation == StringName(prefix + "_victory") and fighter.character_sprite.frame == 5 and not fighter.character_sprite.is_playing(), "victory plays once and holds (%s)" % prefix)
	fighter._update_visuals()
	_check(fighter.character_sprite.frame == 5, "victory remains selected on update")
	fighter.free()

func _floor() -> void:
	var ground := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(3000, 40)
	shape.shape = rect
	ground.add_child(shape)
	ground.position.y = 20
	arena.add_child(ground)

func _settle(fighter: Node) -> void:
	fighter.position = Vector2(0, -2)
	fighter.set_physics_process(true)
	for index in 10:
		await physics_frame
	fighter.set_physics_process(false)
	_check(fighter.is_on_floor(), "fixture should stand on a real floor")

func _landing() -> void:
	_floor()
	var fighter := _fighter()
	await _settle(fighter)
	fighter.was_on_floor_last_frame = false
	fighter._handle_landing_state()
	fighter._update_character_sprite()
	_check(fighter.landing_motion_timer == 0.0 and fighter.character_sprite.animation == &"frey_idle", "without land row contact remains idle")
	_lend(fighter, "land")
	for cut in ["none", "move", "guard", "attack", "jump"]:
		fighter.is_guarding = false
		fighter.move_input = 0.0
		fighter.velocity = Vector2.ZERO
		fighter.sprite_action_timer = 0.0
		fighter.attack_lock_timer = 0.0
		fighter.was_on_floor_last_frame = false
		fighter._handle_landing_state()
		fighter._update_character_sprite()
		_check(fighter.character_sprite.animation == &"frey_land", "landing selects optional row")
		match cut:
			"none":
				await create_timer(0.19).timeout
				_check(fighter.character_sprite.frame == 1 and not fighter.character_sprite.is_playing(), "land is two drawings at 12 fps, once")
				fighter.landing_motion_timer = 0.0
			"move": fighter.move_input = 0.05
			"guard": fighter.is_guarding = true
			"attack": fighter._play_sprite_action(&"attack", 0.2)
			"jump":
				fighter.jump_buffer_timer = 0.12
				fighter._apply_movement(1.0 / 60.0)
		fighter._update_character_sprite()
		_check(fighter.character_sprite.animation != &"frey_land" and fighter.landing_motion_timer == 0.0, "land yields to %s immediately" % cut)
		if cut == "jump":
			_check(fighter.velocity.y < 0.0, "landing art does not delay jump")
	fighter.free()

func _gameplay_parity() -> void:
	var old := _fighter()
	var fresh := _fighter()
	for row in ["jump", "fall", "hurt", "land", "victory"]:
		_lend(fresh, row)
	for fighter in [old, fresh]:
		fighter.apply_hit(null, 3.0, 100.0, Vector2.RIGHT)
	_check(old.hp == fresh.hp and old.hitstun_timer == fresh.hitstun_timer and old.knockback_velocity == fresh.knockback_velocity and old.hitstop_timer == fresh.hitstop_timer, "new art leaves damage, stun, launch and hitstop identical")
	old._play_sprite_pose(&"attack", 0, 5, 0.4, 0.1)
	fresh._play_sprite_pose(&"attack", 0, 5, 0.4, 0.1)
	_check(old.sprite_pose_times == fresh.sprite_pose_times, "D38 attack timeline unchanged")
	for fighter in [old, fresh]:
		fighter._advance_sprite_pose(0.15)
	_check(old.character_sprite.frame == fresh.character_sprite.frame, "D38 selects the same attack drawing")
	old.free()
	fresh.free()

func _hitstop_and_stun() -> void:
	var fighter := _fighter()
	var frames: SpriteFrames = fighter.character_sprite.sprite_frames
	var original := frames.get_frame_texture(&"frey_jump", 0)
	var invalid := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	_check(not fighter._add_optional_motion_strip(frames, "frey", null, fighter.OPTIONAL_MOTION_ROWS[0]), "absent strip is rejected")
	_check(not fighter._add_optional_motion_strip(frames, "frey", ImageTexture.create_from_image(invalid), fighter.OPTIONAL_MOTION_ROWS[0]), "short strip is rejected")
	_check(frames.get_frame_count(&"frey_jump") == 1 and frames.get_frame_texture(&"frey_jump", 0) == original, "rejected strip leaves original row untouched")
	_lend(fighter, "hurt")
	fighter.apply_stun_hit(null, 1.0, 100.0, Vector2.RIGHT, 0.6)
	_check(fighter.hitstun_timer == 0.6 and fighter.sprite_action_timer == 0.6 and fighter.hurt_motion_duration == 0.6, "extended stun scales only the new hurt motion to full hitstun")
	await create_timer(0.1).timeout
	_check(fighter.character_sprite.frame == 0 and not fighter.character_sprite.is_playing(), "new hurt waits for hitstop before advancing")
	fighter._physics_process(fighter.hitstop_timer + 0.001)
	_check(not fighter.character_sprite.is_playing() and fighter.hitstun_timer == 0.6, "hitstop update preserves hurt and stun clocks")
	fighter._physics_process(1.0 / 60.0)
	_check(fighter.character_sprite.is_playing(), "hurt starts with first hitstun physics update")
	fighter.free()
