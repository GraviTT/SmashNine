extends SceneTree
## Ultimates (routine 2026-10-08): a real cast emits ultimate_cast once and opens the
## character's ultimate window (follow-up presses do not re-emit); hits inside the window
## get the longer hitstop; the HUD cut-in shows the caster and fades out.
## Codex QA-12 findings: a map move ends the window; Yuki's ward ends with Yuki and its hits
## signal like a strike.

const MAIN_SCENE := "res://scenes/Main.tscn"
const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const VFX := preload("res://scripts/Vfx.gd")
const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")

var arena: Node2D
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	for test in [_test_cast_signal_and_window, _test_ultimate_hitstop, _test_window_ends_on_map_move, _test_yuki_ward_lifecycle, _test_cutin, _test_effects, _test_attack_art, _test_nova_pull]:
		await test.call()
		if failed:
			quit(1)
			return
	print("Ultimate tests passed")
	arena.queue_free()
	await process_frame
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	failed = true

func _fighter(character_id: String, player_id: int, at: Vector2) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(character_id)
	arena.add_child(fighter)
	fighter.global_position = at
	fighter.setup(CHARACTER_REGISTRY.get_characters()[character_id], player_id, false)
	fighter.ringout_y = 100000.0
	fighter.set_physics_process(false)
	return fighter

func _test_cast_signal_and_window() -> void:
	var characters := CHARACTER_REGISTRY.get_characters()
	for id in CHARACTER_REGISTRY.get_character_ids():
		var fighter := _fighter(id, 1, Vector2(0, 0))
		var casts: Array = []
		fighter.ultimate_cast.connect(func(player: Node) -> void: casts.append(player))
		fighter.ultimate()
		if casts.size() != 1 or not is_equal_approx(fighter.ultimate_window_timer, float(characters[id].ultimate_window)):
			_fail("%s: a cast should emit once and open a %.1f s window (casts %d, window %.2f)" % [id, float(characters[id].ultimate_window), casts.size(), fighter.ultimate_window_timer])
		if str(fighter.ultimate_name) == "" or str(fighter.ultimate_name) == "Ultimate":
			_fail("%s has no ultimate name" % id)
		# Follow-up presses (Nova's stages, Luna's laser) or a press on cooldown: no new cast.
		fighter.attack_lock_timer = 0.0
		fighter.ultimate()
		if casts.size() != 1:
			_fail("%s: a second press emitted another cast" % id)
		fighter.queue_free()
		await process_frame
		if failed:
			return

func _test_ultimate_hitstop() -> void:
	var attacker := _fighter("frey", 1, Vector2(0, 0))
	var victim := _fighter("yuki", 2, Vector2(60, 0))
	victim.apply_hit(attacker, 5.0, 200.0, Vector2.RIGHT)
	var normal: float = victim.hitstop_timer
	attacker.ultimate_window_timer = 1.0
	victim.hitstop_timer = 0.0
	victim.hitstun_timer = 0.0
	victim.apply_hit(attacker, 5.0, 200.0, Vector2.RIGHT)
	if victim.hitstop_timer <= normal * 1.5:
		_fail("Hits inside an ultimate window should freeze longer (%.3f vs %.3f)" % [victim.hitstop_timer, normal])
	var hits: Array = []
	attacker.ultimate_hit.connect(func(_p: Node, _at: Vector2) -> void: hits.append(true))
	attacker.on_attack_landed(Vector2.ZERO, 5.0, 200.0)
	if hits.size() != 1 or attacker.hitstop_timer <= attacker.ATTACKER_HITSTOP * 1.5:
		_fail("An ultimate hit should signal once and give the attacker the longer hitstop")
	attacker.queue_free()
	victim.queue_free()
	await process_frame

func _test_window_ends_on_map_move() -> void:
	var fighter := _fighter("frey", 1, Vector2.ZERO)
	fighter.ultimate_window_timer = 1.25
	var points: Array[Vector2] = [Vector2.ZERO]
	fighter.reset_for_map(Vector2.ZERO, points)
	var hits: Array = []
	fighter.ultimate_hit.connect(func(_p: Node, _at: Vector2) -> void: hits.append(true))
	fighter.on_attack_landed(Vector2.ZERO, 5.0, 200.0)
	if fighter.ultimate_window_timer > 0.0 or not hits.is_empty():
		_fail("A map move should end the ultimate window (timer %.2f, ultimate hits %d)" % [fighter.ultimate_window_timer, hits.size()])
	fighter.queue_free()
	await process_frame

func _test_yuki_ward_lifecycle() -> void:
	var yuki := _fighter("yuki", 1, Vector2.ZERO)
	var victim := _fighter("frey", 2, Vector2(40, 0))
	var ward := Node2D.new()
	ward.set_script(load("res://characters/yuki/YukiGrandWard.gd"))
	arena.add_child(ward)
	ward.global_position = Vector2.ZERO
	ward.configure(yuki, yuki.realm_index)
	# A landed pulse inside the window signals ultimate_hit (camera shake) once.
	yuki.ultimate_window_timer = 3.0
	var hits: Array = []
	yuki.ultimate_hit.connect(func(_p: Node, _at: Vector2) -> void: hits.append(true))
	ward._pulse(false)
	if hits.size() != 1:
		_fail("A ward pulse that lands should signal ultimate_hit once (got %d)" % hits.size())
	# Yuki defeated: the ward does no more damage and goes away.
	yuki.is_defeated = true
	victim.hitstun_timer = 0.0
	victim.hitstop_timer = 0.0
	var hp_before: float = victim.hp
	ward._pulse(false)
	await physics_frame
	await physics_frame
	if victim.hp < hp_before or (is_instance_valid(ward) and not ward.is_queued_for_deletion()):
		_fail("Yuki's ward should end when Yuki is defeated (damage %.2f, ward alive %s)" % [hp_before - victim.hp, is_instance_valid(ward)])
	yuki.queue_free()
	victim.queue_free()
	await process_frame

func _test_cutin() -> void:
	var main: Node = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	main.player_count = 2
	root.add_child(main)
	await process_frame
	var caster: Node = main.players[0]
	main._set_map(caster.realm_index)
	# Bots are fighting, so a press can be refused (hitstun, attack lock): test the wiring and
	# the handler directly.
	if not caster.ultimate_cast.is_connected(main._on_ultimate_cast):
		_fail("Main should listen to every fighter's ultimate_cast")
	# The other bots keep fighting; none may cast its own ultimate (a new cut-in) during the
	# check (flaked once in run_all, 2026-10-08).
	for fighter in main.players:
		fighter.ultimate_cooldown_timer = 100.0
	main._on_ultimate_cast(caster)
	await process_frame
	if not main.hud.cutin_root.visible or main.hud.cutin_title.text != str(caster.ultimate_name).to_upper():
		_fail("Casting on screen should show the cut-in with the ultimate name")
	await create_timer(1.2).timeout
	if main.hud.cutin_root.visible:
		_fail("The cut-in should be gone after about a second")
	main.queue_free()
	await process_frame

## Every ultimate effect strip plays with its frame count in the original style; the plain
## style (F2) falls back to the old shapes.
func _test_effects() -> void:
	for effect in VFX.SPECS:
		var sprite := VFX.spawn(arena, effect, Vector2.ZERO)
		if sprite == null or sprite.sprite_frames.get_frame_count(&"play") != int(VFX.SPECS[effect][0]):
			_fail("Effect %s did not load with %d frames" % [effect, int(VFX.SPECS[effect][0])])
			return
		sprite.queue_free()
	ART_SETTINGS.style = ART_SETTINGS.STYLE_PROTOTYPE
	var plain := VFX.spawn(arena, "frey_ult_wave", Vector2.ZERO)
	ART_SETTINGS.style = ART_SETTINGS.STYLE_ORIGINAL
	if plain != null:
		_fail("The plain style should not draw effect art")
	await process_frame

## Melee hits draw the character's slash strip (CODEX-ART-13) and hide the coloured
## rectangle; the plain style (F2) keeps the rectangle and draws no art.
func _test_attack_art() -> void:
	var frey := _fighter("frey", 1, Vector2(0, 0))
	var points: Array[Vector2] = [Vector2(14, -34), Vector2(58, -32)]
	frey._spawn_sweeping_attack(Vector2(42, 34), points, 1.0, 10.0, Vector2.RIGHT, Color.WHITE, 0.2)
	var attack := _last_attack()
	var slash := arena.find_child("Vfx_frey_slash", true, false)
	if attack == null or slash == null or attack.get_node("Visual").visible:
		_fail("A melee hit should draw frey_slash and hide its rectangle (attack %s, slash %s)" % [attack, slash])
	ART_SETTINGS.style = ART_SETTINGS.STYLE_PROTOTYPE
	frey._spawn_sweeping_attack(Vector2(42, 34), points, 1.0, 10.0, Vector2.RIGHT, Color.WHITE, 0.2)
	var plain := _last_attack()
	ART_SETTINGS.style = ART_SETTINGS.STYLE_ORIGINAL
	if plain == null or not plain.get_node("Visual").visible:
		_fail("The plain style should keep the hit rectangle")
	frey.queue_free()
	await process_frame

func _last_attack() -> Node:
	var found: Node = null
	for child in arena.get_children():
		if child is Area2D and child.get("art_drawn") != null:
			found = child
	return found

## Nova's core drags nearby opponents toward it while it stands.
func _test_nova_pull() -> void:
	var nova := _fighter("nova", 1, Vector2(0, 0))
	var victim := _fighter("frey", 2, Vector2(300, 0))
	nova.ultimate_phase = nova.ULTIMATE_CORE
	nova.ultimate_center = Vector2(150, 0)
	nova._update_ultimate(0.1)
	if victim.knockback_velocity.x >= 0.0:
		_fail("Nova's core should pull a nearby opponent toward it (velocity %s)" % victim.knockback_velocity)
	# Slinging off collapses the core: a burst appears where the core stood.
	nova.ultimate_phase = nova.ULTIMATE_ORBIT
	nova._begin_ultimate_launch(Vector2.RIGHT)
	var collapse_found := false
	for child in arena.get_children():
		if child is Area2D and child.get("hit_tag") == "ultimate" and child.global_position.distance_to(nova.ultimate_center + Vector2(0, -32)) < 1.0:
			collapse_found = true
	if not collapse_found:
		_fail("Nova's launch should collapse the core with a burst at its centre")
	nova._cancel_ultimate()
	nova.ultimate_phase = nova.ULTIMATE_NONE
	nova.queue_free()
	victim.queue_free()
	await process_frame
