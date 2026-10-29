extends SceneTree
## SYS-04 opt-in hostility and boss profile, through real physics and attack collision.
const MONSTER := preload("res://scripts/RealmMonster.gd")
const ARCHETYPES := preload("res://scripts/monsters/MonsterArchetypes.gd")
var failed := false
var checks := 0
var arena: Node2D

class Fighter extends CharacterBody2D:
	var realm_index := 4
	var is_realm_active := true
	var is_defeated := false
	var hp := 1000.0
	var hits := 0
	func apply_hit(_source: Node, damage: float, _knockback: float, _direction: Vector2, _kind := "normal") -> bool:
		if is_defeated:
			return false
		hp -= damage
		hits += 1
		return true

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error(message)

func _fighter(at: Vector2, realm := 4) -> Fighter:
	var fighter := Fighter.new()
	fighter.realm_index = realm
	fighter.position = at
	fighter.collision_layer = 2
	fighter.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 64)
	shape.shape = rect
	shape.position.y = -32
	fighter.add_child(shape)
	arena.add_child(fighter)
	fighter.add_to_group("players")
	return fighter

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	var floor_body := StaticBody2D.new()
	floor_body.position.y = 320
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 40)
	shape.shape = rect
	floor_body.add_child(shape)
	arena.add_child(floor_body)
	var near := _fighter(Vector2(70, 300))
	var far := _fighter(Vector2(500, 300))
	var other_realm := _fighter(Vector2(20, 300), 2)
	var dead := _fighter(Vector2(10, 300))
	dead.is_defeated = true
	var inactive := _fighter(Vector2(15, 300))
	inactive.is_realm_active = false
	var monster := MONSTER.new()
	monster.setup("mossling", 4, Vector2(0, 300))
	arena.add_child(monster)
	_check(not monster.hostile and not monster.is_boss, "Monster options are off by default")
	monster.wander_direction = 0.0
	monster.wander_timer = 10.0
	for frame in 35:
		await physics_frame
	_check(monster.state == MONSTER.State.NEUTRAL and near.hits == 0, "Default monster never acquires an unprovoked approaching fighter")
	monster.hostile = true
	for frame in 50:
		await physics_frame
	_check(monster.target == near and monster.state == MONSTER.State.AGGRO, "Hostile picks nearest living active fighter in the same realm")
	_check(not monster.was_hit and near.hits > 0, "Hostile attacks through a real hitbox without ever being hit")
	_check(far.hits == 0 and other_realm.hits == 0 and dead.hits == 0 and inactive.hits == 0, "Hostility does not attack wrong-realm/dead/inactive targets")
	near.global_position.x = 3000.0
	far.global_position.x = 3000.0
	monster.return_to_neutral()
	monster._update_behavior(0.01)
	_check(monster.state == MONSTER.State.NEUTRAL and monster.target == null, "Hostile respects sight range")
	var boss := MONSTER.new()
	boss.setup("mossling", 4, Vector2(1000, 300), "muspelheim_magma_boar")
	var base_hp: float = boss.max_hp
	var base_damage: float = boss.attack_damage
	var base_windup: float = boss.windup_duration
	var base_range: float = boss.attack_range
	boss.make_boss()
	arena.add_child(boss)
	_check(boss.is_boss and boss.is_elite and boss.scale == Vector2(2, 2), "Boss has exact x2 body size")
	_check(is_equal_approx(boss.max_hp, base_hp * 3.0 * 4.0) and is_equal_approx(boss.hp, boss.max_hp), "Boss HP is elite HP x4")
	_check(is_equal_approx(boss.attack_damage, base_damage * 1.5 * 2.0), "Boss damage is elite damage x2")
	_check(is_equal_approx(boss.windup_duration, base_windup * 1.4 * 1.2), "Boss readable windup is elite windup x1.2")
	_check(is_equal_approx(boss.attack_range, base_range * 2.0), "Boss engagement range follows its x2 body")
	boss._spawn_body_attack(Vector2(58, 44), Vector2(20, -25), 0.65)
	_check(boss.active_attack.shape.shape.size == Vector2(58, 44) * MONSTER.GAME_SCALE.WORLD * 2.0 and boss.active_attack.follow_offset == Vector2(40, -50), "Boss body attack and follow offset match its doubled body")
	boss._cancel_action()
	_check(boss._attack_knockback(false) <= 420.0 and boss._attack_knockback(true) <= 420.0, "Boss knockback capped at 420")
	_check(boss.spawn_slot == -1, "Direct-spawned boss owns no spawner respawn slot")
	boss.make_boss()
	_check(is_equal_approx(boss.max_hp, base_hp * 12.0), "make_boss is idempotent")
	boss.apply_hit(near, 100000.0, 0.0, Vector2.RIGHT, "fixed")
	# Six-row death (all monsters since 2026-10-29): 0.5 s defeat row + 0.3 s fade.
	for frame in 60:
		await physics_frame
	_check(not is_instance_valid(boss), "Boss death frees it without creating a replacement")
	arena.queue_free()
	await process_frame
	if not failed:
		print("Monster option tests passed (%d checks; default neutral, hostile acquisition/collision, boss profile/death)" % checks)
	quit(1 if failed else 0)
