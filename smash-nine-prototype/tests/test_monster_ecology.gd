extends SceneTree
## Deterministic action probes plus real collision/flight/lifecycle regression checks.
const MONSTER := preload("res://scripts/RealmMonster.gd")
const SPAWNER := preload("res://scripts/RealmMonsterSpawner.gd")
const ARCHETYPES := preload("res://scripts/monsters/MonsterArchetypes.gd")
const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
var arena: Node2D
var failed := false
var checks := 0
var phase := "Exploration"
var playable: Array[int] = [7]
var announcements: Array[String] = []

class Fighter extends CharacterBody2D:
	var is_defeated := false
	var realm_index := 7
	var is_realm_active := true
	var hp := 1000.0
	var souls := 0
	var hits := 0
	var last_knockback := 0.0
	var slow := 0.0
	func apply_hit(_source: Node, damage: float, knockback: float, _direction: Vector2, _type := "normal") -> bool:
		hp -= damage
		hits += 1
		last_knockback = knockback
		return true
	func apply_control_pull(_center: Vector2, _strength: float, _delta: float, duration: float) -> void:
		slow = duration
	func add_souls(amount: int) -> void:
		souls += amount

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error(message)

func _run() -> void:
	seed(42)
	arena = Node2D.new()
	root.add_child(arena)
	var floor_body := StaticBody2D.new()
	var floor_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2000, 40)
	floor_shape.shape = rect
	floor_body.add_child(floor_shape)
	floor_body.position = Vector2(0, 320)
	arena.add_child(floor_body)
	await physics_frame
	for skin: String in ARCHETYPES.SKINS:
		await _check_action(skin)
	await _check_shell_and_status()
	await _check_floor_safety()
	await _check_collisions_and_cancellation()
	await _check_bomb_burst()
	await _check_real_fighter_and_bot_api()
	await _check_flight_home()
	await _check_pacing_and_elites()
	await _check_death_and_orphans()
	arena.queue_free()
	await process_frame
	if failed:
		quit(1)
	else:
		print("Monster ecology tests passed (%d checks; 18 skins / 10 archetypes, windups, elite, pacing, lifecycle)" % checks)
		quit(0)

func _fighter(at := Vector2(140, 300)) -> Fighter:
	var fighter := Fighter.new()
	fighter.position = at
	fighter.collision_layer = 2
	fighter.collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(40, 64)
	shape.shape = box
	shape.position.y = -32
	fighter.add_child(shape)
	arena.add_child(fighter)
	fighter.add_to_group("players")
	return fighter

func _monster(skin: String, at := Vector2(0, 300), elite := false) -> Node:
	var monster := CharacterBody2D.new()
	monster.set_script(MONSTER)
	monster.setup("ember_imp" if ARCHETYPES.SKINS.get(skin) in ["bolt", "lob", "homing", "blink", "swoop"] else "mossling", 7, at, skin)
	if elite:
		monster.make_elite()
	arena.add_child(monster)
	monster.set_physics_process(false)
	return monster

func _shots_for(monster: Node) -> Array[Node]:
	var shots: Array[Node] = []
	for child in arena.get_children():
		if child is Area2D and child.get("source") == monster and not child.is_queued_for_deletion():
			shots.append(child)
	return shots

func _clear_shots() -> void:
	for child in arena.get_children():
		if child is Area2D:
			child.queue_free()

func _check_action(skin: String) -> void:
	var fighter := _fighter()
	var monster := _monster(skin)
	# Establish CharacterBody's real contact state before probing ground archetypes.
	monster.velocity = Vector2(0, 10)
	monster.move_and_slide()
	monster.state = MONSTER.State.AGGRO
	monster.target = fighter
	if monster.archetype == "bite":
		fighter.position.x = 60
	if monster.archetype == "swoop":
		monster.position.y = 150
	monster._update_behavior(0.016)
	monster._update_art(0.0)
	_check(monster.archetype == ARCHETYPES.SKINS[skin], "%s archetype mapping" % skin)
	_check(monster.action_phase == "windup" and monster.action_timer > 0.0, "%s must wind up before acting" % skin)
	_check(monster.art_sprite.frame == 0 and not monster.art_sprite.is_playing(), "%s holds its anticipation pose during the telegraph" % skin)
	_check(_shots_for(monster).is_empty(), "%s spawned damage before windup" % skin)
	var before: Vector2 = monster.position
	monster._update_behavior(monster.windup_duration * 0.5)
	_check(monster.action_phase == "windup" and _shots_for(monster).is_empty(), "%s half windup is safe" % skin)
	monster._update_behavior(monster.windup_duration * 0.5 + 0.001)
	var shots := _shots_for(monster)
	match monster.archetype:
		"charge", "shell":
			_check(monster.velocity.x > 0.0 and shots.size() == 1, "%s rush starts after telegraph" % skin)
			monster._physics_process(0.016)
			_check(monster.position.x > before.x, "%s rush actually moves" % skin)
		"leap":
			_check(monster.velocity.y < 0.0 and shots.size() == 1, "%s leaps upward" % skin)
			monster._physics_process(0.016)
			_check(monster.position.y < before.y, "%s leaves the floor" % skin)
		"slam":
			_check(shots.size() == 2 and shots[0].projectile_kind == "shockwave" and shots[0].direction.x == -shots[1].direction.x, "%s bilateral shockwaves" % skin)
		"bolt", "homing", "lob":
			var count := 3 if skin == "vanaheim_seed_sprite" else 1
			_check(shots.size() == count, "%s projectile count" % skin)
			if not shots.is_empty():
				_check(shots[0].projectile_kind == monster.archetype, "%s projectile mode" % skin)
				if monster.archetype == "lob":
					var start_velocity: Vector2 = shots[0].flight_velocity
					shots[0]._physics_process(0.05)
					_check(shots[0].flight_velocity.y > start_velocity.y, "%s projectile follows gravity" % skin)
				if monster.archetype == "homing":
					fighter.position.y -= 100
					var start_direction: Vector2 = shots[0].direction
					shots[0]._physics_process(0.1)
					_check(shots[0].direction != start_direction, "Oracle orb turns toward moving target")
		"blink":
			_check(monster.position.x != before.x and monster.action_phase == "arrival" and shots.is_empty(), "Moth relocates before its delayed burst")
			monster._update_behavior(0.26)
			shots = _shots_for(monster)
			_check(shots.size() == 1, "Moth arrival burst")
		"swoop":
			if skin == "svartalfheim_cog_drone":
				_check(shots.size() == 1 and shots[0].projectile_kind == "bomb", "Drone drops bomb")
			else:
				monster._update_behavior(0.02)
				_check(monster.velocity.y > 0.0 and shots.size() == 1, "Raven dives toward target")
		"bite":
			_check(shots.size() == 1, "Mossling bite after startup")
	_check(monster.art_sprite.animation == &"attack" and monster.art_sprite.is_playing(), "%s attack motion starts with its hit" % skin)
	for shot in shots:
		_check(shot.knockback <= (110.0 if shot.get("projectile_kind") != null else 140.0), "%s D7 knockback" % skin)
		_check(shot.damage >= 5.0 and shot.damage <= 9.0, "%s D7 damage" % skin)
	_clear_shots()
	monster.queue_free()
	fighter.queue_free()
	await process_frame

func _check_shell_and_status() -> void:
	var fighter := _fighter(Vector2(90, 300))
	var shell := _monster("svartalfheim_gear_beetle")
	shell.action_phase = "active"
	shell.facing = 1
	var hp_before: float = shell.hp
	shell.apply_hit(fighter, 10.0, 0.0, Vector2.LEFT)
	_check(is_equal_approx(hp_before - shell.hp, 5.0), "Rolling shell halves frontal damage")
	fighter.position.x = -90
	hp_before = shell.hp
	shell.apply_hit(fighter, 10.0, 0.0, Vector2.RIGHT)
	_check(is_equal_approx(hp_before - shell.hp, 10.0), "Rolling shell takes full damage from rear")
	shell.action_phase = "idle"
	fighter.position.x = 90
	hp_before = shell.hp
	shell.apply_hit(fighter, 10.0, 0.0, Vector2.LEFT)
	_check(is_equal_approx(hp_before - shell.hp, 10.0), "Idle shell has no armour")
	shell.queue_free()
	for skin in ["niflheim_frost_owl", "vanaheim_vine_hound"]:
		var monster := _monster(skin)
		monster.target = fighter
		monster.locked_target_position = fighter.position
		if skin == "niflheim_frost_owl":
			monster._spawn_projectile(Vector2.RIGHT)
		else:
			monster._spawn_body_attack(Vector2(40, 40), Vector2.ZERO, 0.3)
		var attack: Node = _shots_for(monster)[0]
		fighter.slow = 0.0
		if attack.has_method("_hit_body"):
			attack._hit_body(fighter)
		else:
			attack._on_body_entered(fighter)
		_check(fighter.slow > 0.0 and fighter.slow <= 0.55, "%s applies a short slow" % skin)
		_clear_shots()
		monster.queue_free()
	fighter.queue_free()
	await process_frame

func _check_pacing_and_elites() -> void:
	var spawner := SPAWNER.new()
	arena.add_child(spawner)
	spawner.set_physics_process(false)
	spawner.configure(func(_realm: int) -> Array: return [Vector2(0, 300)], func() -> Array: return playable, func() -> String: return phase, 42)
	spawner._physics_process(30.0)
	_check(spawner.get_monster_count() == 0 and spawner.elapsed == 0.0, "Start screen does not spawn or advance monster timers")
	spawner.announcement.connect(func(message: String) -> void: announcements.append(message))
	spawner.sync_playable_realms(playable)
	_check(spawner.get_monster_count(7) == 4 and spawner.elite_by_realm.is_empty(), "Exploration has four regulars and no elite")
	for monster in spawner.monsters_by_realm[7]:
		monster.set_physics_process(false)
		_check(not monster.hp_back.visible, "Untouched regular HP bar hidden")
	var fighter := _fighter()
	var first: Node = spawner.slots_by_realm[7][0]
	first.apply_hit(fighter, 1.0, 0.0, Vector2.LEFT)
	_check(first.hp_back.visible, "First hit reveals regular HP bar")
	first._die(fighter)
	var deadline: float = spawner.refill_at_by_realm[7][0]
	_check(deadline >= 12.0 and deadline <= 18.0, "Refill scheduled in 12-18 seconds")
	spawner.elapsed = deadline - 0.01
	spawner.sync_playable_realms(playable)
	spawner._try_respawn_realm(7)
	_check(spawner.get_monster_count(7) == 3, "Sync and respawn cannot refill a slot early")
	spawner.elapsed = deadline
	spawner.sync_playable_realms(playable)
	_check(spawner.get_monster_count(7) == 4, "Slot refills when deadline expires")
	phase = "Corner collapse warning"
	spawner.sync_playable_realms(playable)
	var elite: Node = spawner.elite_by_realm.get(7)
	_check(is_instance_valid(elite) and spawner.get_monster_count(7) == 5, "Phase two adds one elite")
	if is_instance_valid(elite):
		elite.set_physics_process(false)
		var regular := _monster(elite.skin_id)
		_check(elite.max_hp == regular.max_hp * 3.0 and elite.soul_reward == regular.soul_reward * 4, "Elite HP and souls multipliers")
		_check(elite.attack_damage == regular.attack_damage * 1.5 and elite.windup_duration > regular.windup_duration and elite.scale == Vector2.ONE * 1.35, "Elite size, damage and longer windup")
		_check(elite.hp_back.visible and elite.display_name.begins_with("Elite "), "Elite HP/name always readable")
		_check(elite._attack_knockback(false) <= 320.0 and elite._attack_knockback(true) <= 320.0, "Elite knockback capped at 320")
		spawner.sync_playable_realms(playable)
		_check(announcements.size() == 1 and announcements[0].contains("Jotunheim"), "Exactly one elite announcement")
		var souls_before: int = fighter.souls
		elite._die(fighter)
		_check(fighter.souls - souls_before == regular.soul_reward * 4, "Elite pays x4 souls exactly once")
		var elite_deadline: float = spawner.elite_due[7]
		_check(elite_deadline - spawner.elapsed >= 70.0 and elite_deadline - spawner.elapsed <= 90.0, "Elite refill waits 70-90 seconds after defeat")
		spawner.elapsed = elite_deadline - 0.01
		spawner.sync_playable_realms(playable)
		_check(not is_instance_valid(spawner.elite_by_realm.get(7)), "No early elite replacement")
		spawner.elapsed = elite_deadline
		spawner.announcement_timer = 0.0
		spawner.sync_playable_realms(playable)
		_check(is_instance_valid(spawner.elite_by_realm.get(7)) and announcements.size() == 2, "Elite returns at deadline")
		regular.queue_free()
	phase = "Central brawl"
	spawner.sync_playable_realms(playable)
	var regular_count := 0
	for monster in spawner.monsters_by_realm[7]:
		if not monster.is_elite:
			regular_count += 1
	_check(regular_count == 3, "Central brawl trims regular population to three")
	playable = [7, 8]
	spawner.sync_playable_realms(playable)
	_check(spawner.get_monster_count(8) == 4 and is_instance_valid(spawner.elite_by_realm.get(8)), "Newly opened center gets three regulars plus one elite in central phase")
	_check(announcements.size() == 2 and spawner.pending_announcements.size() == 1, "Simultaneous announcements queue without overwriting")
	spawner._physics_process(2.81)
	_check(announcements.size() == 3 and spawner.pending_announcements.is_empty(), "Queued elite announcement is delivered once after spacing")
	playable = []
	spawner.sync_playable_realms(playable)
	_check(spawner.get_monster_count() == 0 and spawner.elite_by_realm.is_empty(), "Collapse removes regulars and elites")
	spawner.elapsed += 100.0
	spawner._try_respawn_realm(7)
	_check(spawner.get_monster_count() == 0, "Collapsed realm cannot refill")
	spawner.queue_free()
	fighter.queue_free()
	await process_frame

func _check_floor_safety() -> void:
	var ledge := StaticBody2D.new()
	ledge.position = Vector2(3000, 320)
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(180, 40)
	shape.shape = box
	ledge.add_child(shape)
	arena.add_child(ledge)
	await physics_frame
	var fighter := _fighter(Vector2(3180, 300))
	for skin in ["asgard_aegis_ram", "muspelheim_magma_boar", "svartalfheim_gear_beetle"]:
		var monster := _monster(skin, Vector2(3010, 300))
		monster.velocity = Vector2(0, 10)
		monster.move_and_slide()
		monster.target = fighter
		monster.state = MONSTER.State.AGGRO
		monster._begin_windup()
		monster._tick_action(monster.windup_duration + 0.01)
		for i in 60:
			monster._physics_process(1.0 / 60.0)
		_check(monster.position.x < 3070.0 and monster.position.y <= 301.0, "%s stops safely before ledge" % skin)
		_check(monster.action_phase != "active", "%s ends rolling/charge at ledge" % skin)
		monster.queue_free()
		_clear_shots()
		await process_frame
	fighter.queue_free()
	ledge.queue_free()
	await process_frame

func _check_collisions_and_cancellation() -> void:
	var fighter := _fighter()
	var monster := _monster("ember_imp")
	monster.target = fighter
	monster._spawn_projectile(Vector2.RIGHT)
	var shot: Node = _shots_for(monster)[0]
	shot.set_physics_process(false)
	await physics_frame
	var before := fighter.hits
	shot._physics_process(0.25)
	_check(fighter.hits == before + 1 and shot.is_queued_for_deletion(), "Swept projectile collision hits a fighter between frames")
	await process_frame
	monster._spawn_projectile(Vector2.RIGHT)
	shot = _shots_for(monster)[0]
	fighter.realm_index = 8
	before = fighter.hits
	shot._on_body_entered(fighter)
	_check(fighter.hits == before, "Projectiles cannot hit a fighter in another realm")
	fighter.realm_index = 7
	fighter.is_realm_active = false
	shot._on_body_entered(fighter)
	_check(fighter.hits == before, "Projectiles cannot hit an inactive fighter")
	fighter.is_realm_active = true
	monster.set_realm_active(false)
	shot._on_body_entered(fighter)
	_check(fighter.hits == before and shot.is_queued_for_deletion(), "Realm deactivation cancels live shots")
	monster.set_realm_active(true)
	monster.set_physics_process(false)
	monster.state = MONSTER.State.AGGRO
	monster._begin_windup()
	monster.apply_hit(fighter, 1.0, 100.0, Vector2.LEFT)
	monster._physics_process(0.016)
	_check(monster.action_phase == "idle", "Hitstun cancels a pending windup")
	monster._begin_windup()
	fighter.is_defeated = true
	monster._update_behavior(1.0)
	_check(monster.action_phase == "idle" and monster.state == MONSTER.State.NEUTRAL, "Defeated target cancels the action and returns monster to neutral")
	_check(monster.name_label.text.ends_with("Neutral"), "Returning to neutral refreshes the visible disposition label")
	monster.queue_free()
	fighter.queue_free()
	_clear_shots()
	await process_frame

func _check_flight_home() -> void:
	for skin in ["asgard_runic_raven", "svartalfheim_cog_drone"]:
		var flyer := _monster(skin)
		var original_home: Vector2 = flyer.patrol_center
		flyer.global_position = original_home + Vector2(700, 220)
		flyer.return_to_neutral()
		_check(flyer.patrol_center == original_home, "%s keeps its home when a target is lost" % skin)
		flyer._update_behavior(0.016)
		_check(flyer.velocity.x < 0.0, "%s returns horizontally after being displaced beyond its patrol" % skin)
		flyer.global_position = original_home - Vector2(0, flyer.hover_height)
		flyer._update_behavior(0.016)
		_check(is_zero_approx(flyer.velocity.y), "%s stabilizes at its original hover height after disengaging" % skin)
		flyer.queue_free()
	await process_frame

func _check_death_and_orphans() -> void:
	var fighter := _fighter()
	var monster := _monster("ember_imp")
	monster.target = fighter
	monster._spawn_projectile(Vector2.RIGHT)
	var shot: Node = _shots_for(monster)[0]
	var rewards: Array[int] = []
	monster.defeated.connect(func(_monster: Node, _attacker: Node, reward: int) -> void: rewards.append(reward))
	monster._die(fighter)
	monster._die(fighter)
	# Six-row sheets (all monsters since 2026-10-29) play the defeat row for 0.5 s, then fade over 0.3 s;
	# the 4-row layout shows the hurt drawing and fades over 0.55 s.
	var death_row := &"defeat" if monster.six_row_art else &"hurt"
	var motion := 0.5 if monster.six_row_art else 0.0
	var fade := 0.3 if monster.six_row_art else 0.55
	_check(monster.state == MONSTER.State.DEFEATED and monster.visible and monster.art_sprite.animation == death_row, "Defeat shows its death drawing before fade")
	_check(rewards.size() == 1, "Defeat reward emitted once")
	var hits_before := fighter.hits
	shot._on_body_entered(fighter)
	_check(fighter.hits == hits_before, "Defeated source cannot deal projectile damage")
	monster._physics_process(motion + fade * 0.45)
	_check(monster.modulate.a > 0.0 and monster.modulate.a < 1.0, "Defeat fades instead of disappearing immediately")
	monster._physics_process(fade * 0.6)
	_check(monster.is_queued_for_deletion(), "Defeat animation cleans itself up")
	fighter.queue_free()
	await process_frame

func _check_bomb_burst() -> void:
	var direct_target := _fighter(Vector2(140, 300))
	var nearby_target := _fighter(Vector2(205, 300))
	var monster := _monster("svartalfheim_cog_drone", Vector2(0, 150))
	monster.target = direct_target
	monster.locked_target_position = direct_target.position
	var bomb: Node = monster._spawn_ecology_projectile(Vector2.DOWN, "bomb")
	bomb.global_position = Vector2(140, 200)
	bomb.flight_velocity = Vector2(0, 600)
	# Exercise the real body_entered physics callback, including deferred blast attach.
	for i in 30:
		await physics_frame
	_check(direct_target.hits == 1, "Bomb direct hit and explosion never double-hit a fighter")
	_check(nearby_target.hits == 1, "Bomb explodes into a short area burst")
	_check(direct_target.last_knockback <= 110.0 and nearby_target.last_knockback <= 110.0, "Bomb and burst respect projectile knockback cap")
	_check(_shots_for(monster).is_empty(), "Bomb and blast expire without leaving an area behind")
	monster.queue_free()
	direct_target.queue_free()
	nearby_target.queue_free()
	await process_frame

func _check_real_fighter_and_bot_api() -> void:
	var bot: Node = PLAYER_FACTORY.create("frey")
	arena.add_child(bot)
	bot.setup(REGISTRY.get_characters().frey, 1, false)
	bot.global_position = Vector2(140, 300)
	bot.realm_index = 7
	bot.invulnerable_timer = 0.0
	bot.set_physics_process(false)
	var owl := _monster("niflheim_frost_owl")
	owl.target = bot
	owl._spawn_projectile(Vector2.RIGHT)
	var shot: Node = _shots_for(owl)[0]
	var before: float = bot.hp
	shot._on_body_entered(bot)
	_check(bot.hp < before and is_equal_approx(bot.control_slow_timer, 0.55), "Frost slow reaches the real PlayerBase after a landed hit")
	var hound := _monster("vanaheim_vine_hound")
	bot.control_slow_timer = 0.0
	hound._spawn_body_attack(Vector2(40, 40), Vector2.ZERO, 0.3)
	var attack: Node = _shots_for(hound)[0]
	attack._hit_body(bot)
	_check(is_equal_approx(bot.control_slow_timer, 0.45), "Vine hound root reaches the real PlayerBase")
	var elite := _monster("jotunheim_rune_golem", Vector2(200, 300), true)
	_check(bot.ai_controller._is_valid_target_candidate(bot, elite), "Unmodified EnemyAI recognizes a living elite as a monster target")
	elite.apply_hit(bot, 1.0, 0.0, Vector2.RIGHT)
	_check(elite.last_attacker == bot and elite.last_hit_frame == Engine.get_physics_frames() and elite.state == MONSTER.State.AGGRO, "Elite preserves bot progress memory and retaliation API")
	elite.hp = 0.0
	_check(not bot.ai_controller._is_valid_target_candidate(bot, elite), "Unmodified EnemyAI ignores defeated elites")
	bot.queue_free()
	owl.queue_free()
	hound.queue_free()
	elite.queue_free()
	_clear_shots()
	await process_frame
