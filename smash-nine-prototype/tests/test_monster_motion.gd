extends SceneTree
const MONSTER := preload("res://scripts/RealmMonster.gd")
const ARCHETYPES := preload("res://scripts/monsters/MonsterArchetypes.gd")
const LEGACY_ROWS := [["idle", 4, 6.0, true], ["walk", 6, 10.0, true], ["attack", 4, 12.0, false], ["hurt", 1, 1.0, false]]
const NEW_COUNTS := {"idle": 6, "walk": 6, "windup": 4, "attack": 6, "hurt": 2, "defeat": 4}
## The sheets applied on 2026-10-29 keep today's 4-row pictures beside the new windup and defeat rows.
const MIXED_COUNTS := {"idle": 4, "walk": 6, "windup": 4, "attack": 4, "hurt": 1, "defeat": 4}
var arena: Node2D
var failed := false
var checks := 0

class Target extends Node2D:
	var is_defeated := false
	var realm_index := 0
	var is_realm_active := true

class SheetMonster:
	extends "res://scripts/RealmMonster.gd"
	var stand_in: Texture2D
	func _frames_for_sheet(_sheet: Texture2D) -> SpriteFrames:
		return super._frames_for_sheet(stand_in)

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error(message)

func _monster(six: bool, behavior := "bite", elite := false) -> Node:
	var monster := CharacterBody2D.new()
	monster.set_script(MONSTER)
	var skin := "mossling"
	for candidate in ARCHETYPES.SKINS:
		if ARCHETYPES.SKINS[candidate] == behavior:
			skin = candidate
			break
	monster.setup("ember_imp" if behavior in ["bolt", "lob", "homing", "blink", "swoop"] else "mossling", 0, Vector2.ZERO, skin)
	if elite:
		monster.make_elite()
	arena.add_child(monster)
	monster.set_physics_process(false)
	# Rebuild the legacy fixture even when the real skin has since adopted six rows.
	var source: SpriteFrames = monster.art_sprite.sprite_frames
	var legacy := Image.create(576, 384, false, Image.FORMAT_RGBA8)
	for row_index in LEGACY_ROWS.size():
		var spec: Array = LEGACY_ROWS[row_index]
		for index in int(spec[1]):
			var texture := source.get_frame_texture(spec[0], mini(index, source.get_frame_count(spec[0]) - 1))
			legacy.blit_rect(texture.get_image(), Rect2i(0, 0, 96, 96), Vector2i(index * 96, row_index * 96))
	monster.art_sprite.sprite_frames = monster._frames_for_sheet(ImageTexture.create_from_image(legacy))
	monster.art_sprite.play(&"idle")
	if six:
		# Assemble a new-layout sheet from the actual old hurt drawing, in memory only.
		var original: Texture2D = monster.art_sprite.sprite_frames.get_frame_texture(&"hurt", 0)
		var sheet := Image.create(576, 576, false, Image.FORMAT_RGBA8)
		for y in 6:
			for x in 6:
				sheet.blit_rect(original.get_image(), Rect2i(0, 0, 96, 96), Vector2i(x * 96, y * 96))
		monster.art_sprite.sprite_frames = monster._frames_for_sheet(ImageTexture.create_from_image(sheet))
		monster.art_sprite.play(&"idle")
	return monster

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	await _legacy()
	for behavior in ARCHETYPES.PROFILES:
		await _new_layout(str(behavior))
		_execution_parity(str(behavior))
	await _death()
	_mixed_layout()
	_golem_pivot()
	arena.queue_free()
	await process_frame
	print("Monster motion: %d checks, failed=%s" % [checks, failed])
	quit(1 if failed else 0)

func _legacy() -> void:
	var monster := _monster(false)
	var frames: SpriteFrames = monster.art_sprite.sprite_frames
	_check(not monster.six_row_art and not frames.has_animation(&"windup") and not frames.has_animation(&"defeat"), "existing 4-row layout remains selected")
	for row in LEGACY_ROWS:
		_check(frames.get_frame_count(row[0]) == row[1] and frames.get_animation_speed(row[0]) == row[2] and frames.get_animation_loop(row[0]) == row[3], "legacy row %s unchanged" % row[0])
	monster.action_phase = "windup"
	monster._update_art(0.0)
	_check(monster.art_sprite.animation == &"attack" and monster.art_sprite.frame == 0 and not monster.art_sprite.is_playing(), "legacy windup keeps paused attack frame zero")
	monster.action_phase = "arrival"
	monster._update_art(0.0)
	_check(monster.art_sprite.frame == 0 and not monster.art_sprite.is_playing(), "legacy arrival keeps anticipation drawing")
	monster.action_phase = "idle"
	monster._play_strike_animation()
	_check(monster.attack_animation_timer == 0.33, "legacy strike timer unchanged")
	monster.apply_hit(null, 1.0, 100.0, Vector2.RIGHT)
	monster._update_art(0.0)
	_check(monster.art_sprite.animation == &"hurt" and monster.art_sprite.frame == 0, "legacy hurt keeps single drawing")
	monster._die(null)
	monster.set_physics_process(false)
	monster._physics_process(0.275)
	_check(is_equal_approx(monster.modulate.a, 0.5) and monster.art_sprite.animation == &"hurt", "legacy death still fades hurt over .55 seconds")
	monster._physics_process(0.28)
	_check(monster.is_queued_for_deletion(), "legacy death frees at .55 seconds")
	await process_frame

func _new_layout(behavior: String) -> void:
	var monster := _monster(true, behavior, true)
	var frames: SpriteFrames = monster.art_sprite.sprite_frames
	_check(monster.six_row_art and frames.has_animation(&"windup") and frames.has_animation(&"defeat"), "six-row layout detected")
	_check(monster.scale == Vector2.ONE * 1.35 and monster.is_elite, "elite size and aura flag retained")
	for row in NEW_COUNTS:
		_check(frames.get_frame_count(row) == NEW_COUNTS[row], "six-row %s count" % row)
	_check(frames.get_animation_loop(&"attack") == (behavior in ["charge", "swoop"]), "%s action loop policy" % behavior)
	_check(frames.get_animation_speed(&"idle") == 6 and frames.get_animation_speed(&"walk") == 10 and frames.get_animation_speed(&"attack") == 12 and frames.get_animation_speed(&"hurt") == 8 and frames.get_animation_speed(&"defeat") == 8, "ART-71 fps")
	monster.action_phase = "windup"
	for ratio in [0.0, 0.3, 0.55, 0.8, 1.0]:
		monster.action_timer = monster.windup_duration * (1.0 - ratio)
		monster._update_art(0.0)
		_check(monster.art_sprite.animation == &"windup" and monster.art_sprite.frame == mini(int(ratio * 4.0), 3), "%s telegraph spans its elite-adjusted windup" % behavior)
	monster.action_phase = "active"
	monster._play_strike_animation()
	monster._update_art(0.0)
	await create_timer(0.56).timeout
	_check(monster.art_sprite.animation == &"attack", "action displays attack row")
	_check(monster.art_sprite.is_playing() if behavior in ["charge", "swoop"] else monster.art_sprite.frame == 5 and not monster.art_sprite.is_playing(), "sustained attacks loop, other attacks hold")
	monster.apply_hit(null, 1.0, 100.0, Vector2.RIGHT)
	_check(monster.art_sprite.animation == &"hurt" and monster.art_sprite.frame == 0, "hit starts hurt immediately")
	await create_timer(0.16).timeout
	_check(monster.art_sprite.frame == 1, "hurt advances to second drawing")
	monster.apply_hit(null, 1.0, 100.0, Vector2.RIGHT)
	_check(monster.art_sprite.frame == 0, "new hit restarts hurt")
	monster._cancel_action()
	_check(monster.motion_attack_timer == 0.0, "cancelled action cannot resume its attack art after hurt")
	monster.free()

func _shots(monster: Node) -> Array:
	var shots: Array = []
	for child in arena.get_children():
		if child is Area2D and child.get("source") == monster:
			shots.append(child)
	return shots

## A six-row row ends at its first empty cell, so the kept 4-row pictures play without blank frames.
func _mixed_layout() -> void:
	var monster := _monster(false)
	var drawing: Image = monster.art_sprite.sprite_frames.get_frame_texture(&"hurt", 0).get_image()
	var sheet := Image.create(576, 576, false, Image.FORMAT_RGBA8)
	var row := 0
	for name in MIXED_COUNTS:
		for x in int(MIXED_COUNTS[name]):
			sheet.blit_rect(drawing, Rect2i(0, 0, 96, 96), Vector2i(x * 96, row * 96))
		row += 1
	var frames: SpriteFrames = monster._frames_for_sheet(ImageTexture.create_from_image(sheet))
	_check(monster.six_row_art, "mixed sheet uses the six-row layout")
	for name in MIXED_COUNTS:
		_check(frames.get_frame_count(name) == MIXED_COUNTS[name], "mixed %s plays only its drawn cells" % name)
	monster.art_sprite.sprite_frames = frames
	monster.action_phase = "windup"
	for ratio in [0.0, 0.3, 0.55, 0.8, 1.0]:
		monster.action_timer = monster.windup_duration * (1.0 - ratio)
		monster._update_art(0.0)
		_check(monster.art_sprite.animation == &"windup" and monster.art_sprite.frame == mini(int(ratio * 4.0), 3), "mixed windup steps through its drawings")
	monster.free()
	# Every monster in the game now has its applied six-row sheet.
	var skins := 0
	for file in DirAccess.get_files_at("res://assets/art/monsters"):
		if not file.ends_with("_sheet.png"):
			continue
		var texture := load("res://assets/art/monsters/" + file) as Texture2D
		skins += 1
		_check(texture.get_size() == Vector2(576, 576), "%s is a six-row sheet" % file)
		_check(MONSTER.drawn_frame_counts(texture, 96) == MIXED_COUNTS.values(), "%s rows hold the applied drawings" % file)
	_check(skins == 18, "18 monster sheets")

func _golem_pivot() -> void:
	# The real golem sheet is six rows now; a 4-row stand-in keeps the legacy exception covered.
	var probe := _monster(false, "slam")
	var drawing: Image = probe.art_sprite.sprite_frames.get_frame_texture(&"hurt", 0).get_image()
	probe.free()
	var four := Image.create(576, 384, false, Image.FORMAT_RGBA8)
	for y in 4:
		for x in int(LEGACY_ROWS[y][1]):
			four.blit_rect(drawing, Rect2i(0, 0, 96, 96), Vector2i(x * 96, y * 96))
	var old := SheetMonster.new()
	old.stand_in = ImageTexture.create_from_image(four)
	old.setup("mossling", 0, Vector2.ZERO, "jotunheim_rune_golem")
	arena.add_child(old)
	old.set_physics_process(false)
	_check(not old.six_row_art and old.art_sprite.position.y == -32.0, "a 4-row golem sheet keeps its y=80 feet exception")
	var sheet := Image.create(576, 576, false, Image.FORMAT_RGBA8)
	for y in 6:
		for x in 6:
			sheet.blit_rect(drawing, Rect2i(0, 0, 96, 96), Vector2i(x * 96, y * 96))
	var fresh := SheetMonster.new()
	fresh.stand_in = ImageTexture.create_from_image(sheet)
	fresh.setup("mossling", 0, Vector2.ZERO, "jotunheim_rune_golem")
	arena.add_child(fresh)
	fresh.set_physics_process(false)
	_check(fresh.six_row_art and fresh.art_sprite.position.y == -24.0, "six-row golem follows the new y=72 feet contract")
	_check(fresh.get_child(0).shape.size == old.get_child(0).shape.size, "new golem pivot never changes collision")
	old.free()
	fresh.free()

func _execution_parity(behavior: String) -> void:
	var target := Target.new()
	target.position = Vector2(100, 0)
	arena.add_child(target)
	var old := _monster(false, behavior)
	var fresh := _monster(true, behavior)
	for monster in [old, fresh]:
		monster.target = target
		monster._begin_windup()
		monster._tick_action(monster.windup_duration * 0.5)
		_check(_shots(monster).is_empty(), "no %s damage during windup, either sheet" % behavior)
		monster._tick_action(monster.windup_duration * 0.5 + 0.001)
		if behavior == "blink":
			_check(monster.action_phase == "arrival" and _shots(monster).is_empty(), "blink arrival delay unchanged")
			monster._tick_action(0.251)
	_check(old.action_phase == fresh.action_phase and old.action_timer == fresh.action_timer and old.attack_timer == fresh.attack_timer and old.velocity == fresh.velocity and old.attack_serial == fresh.attack_serial, "%s execution phases and movement identical" % behavior)
	_check(fresh.art_sprite.animation == &"attack" and fresh.art_sprite.is_playing(), "%s execution starts its new attack row" % behavior)
	var old_shots := _shots(old)
	var new_shots := _shots(fresh)
	_check(old_shots.size() == new_shots.size(), "%s same attack count" % behavior)
	for index in mini(old_shots.size(), new_shots.size()):
		var a: Node = old_shots[index]
		var b: Node = new_shots[index]
		_check(a.damage == b.damage and a.knockback == b.knockback and a.get_node("CollisionShape2D").shape.size == b.get_node("CollisionShape2D").shape.size, "%s same damage, knockback and hit box" % behavior)
	for shot in old_shots + new_shots:
		shot.free()
	old.free()
	fresh.free()
	target.free()

func _death() -> void:
	var monster := _monster(true)
	var reward := [0]
	monster.defeated.connect(func(_m, _a, _s): reward[0] += 1)
	monster._die(null)
	monster.set_physics_process(false)
	_check(monster.collision_layer == 0 and monster.hp == 0.0 and reward[0] == 1, "death disables combat and pays reward immediately")
	await create_timer(0.54).timeout
	monster._physics_process(0.5)
	_check(monster.art_sprite.animation == &"defeat" and monster.art_sprite.frame == 3 and monster.modulate.a == 1.0, "four defeat drawings finish before fade")
	monster._physics_process(0.15)
	_check(is_equal_approx(monster.modulate.a, 0.5) and not monster.is_queued_for_deletion(), "new death fades over .3 seconds")
	monster._physics_process(0.16)
	_check(monster.is_queued_for_deletion() and reward[0] == 1, "new death frees after .8 seconds and reward stays once")
	await process_frame
	# Same hit on old and new art must yield the same gameplay numbers.
	var old := _monster(false)
	var fresh := _monster(true)
	for fighter in [old, fresh]:
		fighter.apply_hit(null, 3.0, 100.0, Vector2.RIGHT)
	_check(old.hp == fresh.hp and old.hitstun_timer == fresh.hitstun_timer and old.knockback_velocity == fresh.knockback_velocity and old.windup_duration == fresh.windup_duration and old.attack_cooldown == fresh.attack_cooldown, "monster art leaves damage, stun, knockback, windup and cooldown identical")
	_check(old.get_child(0).shape.size == fresh.get_child(0).shape.size, "monster hitbox unchanged")
	old.free()
	fresh.free()
