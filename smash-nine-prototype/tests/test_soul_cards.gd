extends SceneTree
## The soul card pool of D54 (2026-11-25, the user's "카드는 추천대로 해" on
## reports/soul-cards-2026-11-24/): nineteen cards, what an offer holds, and what each new card does.
## - The pool: 5 stat, 9 action, 5 character cards; a fighter is offered the common ones and its own.
## - An offer: three different cards, one action or character card at least, the fighter's own card
##   in its second offer; 8 s for a person to choose.
## - Each new card, by a real press and a real overlap (no hit is called by hand): Air Dash, Meteor
##   Landing, Riposte, Soul Drain, Last Flame, Chaser, Hunter, Overcharge; Second Wingbeat, Twin
##   Stars, Deep Gravity, Second Decoy, Extended Magazine. And for bots: Air Dash on the way back
##   and Frey's second wingbeat in one airtime.
## Every scene is played twice, round the world origin and far from it (see test_bot_kits.gd).

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const CARDS := preload("res://scripts/match/SoulCards.gd")
const SOUL_GROWTH := preload("res://scripts/match/SoulGrowth.gd")
const MONSTER := preload("res://scripts/RealmMonster.gd")
const MONSTER_SPAWNER := preload("res://scripts/RealmMonsterSpawner.gd")
const CRYSTAL := preload("res://scripts/SoulCrystal.gd")
const CRYSTAL_SPAWNER := preload("res://scripts/SoulCrystalSpawner.gd")
const AI := preload("res://scripts/EnemyAI.gd")
const SCENES: Array[Vector2] = [Vector2.ZERO, Vector2(9000, 6000)]
const FIGHTERS: Array[String] = ["frey", "yuki", "luna", "nova", "rio", "xion"]
const OWN_CARD := {"frey": "second_wingbeat", "luna": "twin_stars", "nova": "deep_gravity", "rio": "second_decoy", "xion": "extended_magazine"}

var arena: Node2D
var scene := Vector2.ZERO
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	seed(20261126)
	arena = Node2D.new()
	root.add_child(arena)
	_test_pool()
	_test_offer_rules()
	await _test_offer_through_soul_growth()
	for origin in SCENES:
		scene = origin
		for test in [_test_air_dash, _test_meteor_landing, _test_riposte, _test_soul_drain, _test_last_flame, _test_chaser,
				_test_hunter_monster, _test_hunter_crystal, _test_overcharge, _test_second_wingbeat, _test_twin_stars,
				_test_deep_gravity, _test_second_decoy, _test_extended_magazine, _test_bot_air_dash, _test_bot_second_wingbeat]:
			await test.call()
			_release_keys()
			for child in arena.get_children():
				child.queue_free()
			await process_frame
			await physics_frame
	if failed:
		quit(1)
		return
	print("Soul card tests passed (%d cards; each scene round the origin and at %s)" % [CARDS.CARDS.size(), SCENES[1]])
	quit(0)

func _fail(message: String) -> void:
	push_error("%s (scene at %s)" % [message, scene])
	failed = true

# --- Scene helpers ---

func _at(node: Node2D) -> Vector2:
	return node.global_position - scene

func _put(node: Node2D, at: Vector2) -> void:
	node.global_position = scene + at

func _floor(width := 2400.0, at := Vector2.ZERO) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.add_to_group("platforms")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, 40)
	shape.shape = rect
	body.add_child(shape)
	# Placed before it enters the tree: one frame at the origin would push a fighter up.
	body.position = scene + at + Vector2(0, 20)
	arena.add_child(body)
	return body

## A person's fighter with nobody at the keys: it stands, and does what the test presses. With
## `keys` it also hears the keys the test presses (one fighter a scene).
func _person(character_id: String, player_id: int, at: Vector2, keys := false) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(character_id)
	arena.add_child(fighter)
	_put(fighter, at)
	fighter.setup(CHARACTER_REGISTRY.get_characters()[character_id], player_id, true)
	fighter.set_process_unhandled_input(keys)
	fighter.ringout_y = 100000.0
	return fighter

## A training dummy: it stands and takes hits.
func _dummy(player_id: int, at: Vector2) -> Node:
	var dummy: Node = PLAYER_FACTORY.create("")
	arena.add_child(dummy)
	_put(dummy, at)
	dummy.setup_dummy(player_id)
	dummy.ringout_y = 100000.0
	return dummy

func _give(fighter: Node, card_id: String) -> void:
	var card: Dictionary = CARDS.find(card_id)
	if card.is_empty():
		_fail("Test setup: no card %s" % card_id)
		return
	fighter.apply_upgrade(card)

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame

func _wait_for(condition: Callable, timeout: float) -> bool:
	var waited := 0.0
	while not condition.call() and waited < timeout:
		await physics_frame
		waited += 1.0 / 60.0
	return condition.call()

## A key press as the engine delivers it: the action's state and its event, at once.
func _press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _release(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _release_keys() -> void:
	for action in ["guard", "jump", "move_up", "move_down", "move_left", "move_right"]:
		if Input.is_action_pressed(action):
			_release(action)

func _count(fighter: Node, key: String) -> int:
	return int(fighter.move_counts.get(key, 0.0))

## Frames from the foe's swing to the hit on `target`, the swing being a real one.
func _swing_lands_after(foe: Node, target: Node) -> int:
	var before: float = target.hp
	foe.basic_attack()
	var frames := 0
	while target.hp >= before and frames < 60:
		await physics_frame
		frames += 1
	return frames if target.hp < before else -1

# --- The pool and the offers ---

func _test_pool() -> void:
	var kinds := {}
	var ids := {}
	for card in CARDS.CARDS:
		kinds[card.kind] = int(kinds.get(card.kind, 0)) + 1
		if ids.has(card.id):
			_fail("Card id used twice: %s" % card.id)
		ids[card.id] = true
		if card.kind == "character" and not FIGHTERS.has(str(card.get("character", ""))):
			_fail("A character card must name its fighter: %s" % card.id)
		if card.kind != "character" and card.has("character"):
			_fail("Only a character card names a fighter: %s" % card.id)
		if card.kind in ["action", "character"] and int(card.get("max_stacks", 0)) < 1:
			_fail("An action or character card is taken a set number of times: %s" % card.id)
	if CARDS.CARDS.size() != 19 or kinds != {"stat": 5, "action": 9, "character": 5}:
		_fail("The pool is 19 cards: 5 stat, 9 action, 5 character (%d: %s)" % [CARDS.CARDS.size(), kinds])
	for id in FIGHTERS:
		var seen: Array[Dictionary] = CARDS.available([], id)
		var own: Array = seen.filter(func(card: Dictionary) -> bool: return card.kind == "character")
		var expected := 14 if id == "yuki" else 15
		if seen.size() != expected:
			_fail("%s should see %d cards (%d)" % [id, expected, seen.size()])
		if id == "yuki" and not own.is_empty():
			_fail("Yuki has no card of her own yet")
		if id != "yuki" and (own.size() != 1 or str(own[0].id) != OWN_CARD[id]):
			_fail("%s should see its own card and no other fighter's" % id)
	if CARDS.available([], "").size() != 14:
		_fail("With no fighter named only the common cards are on offer")

func _test_offer_rules() -> void:
	var slots := [0, 0, 0]
	for id in FIGHTERS:
		for attempt in 150:
			var rng := RandomNumberGenerator.new()
			rng.seed = hash([id, attempt])
			var owned: Array[String] = []
			for pick in [1, 2, 3]:
				var offer: Array[Dictionary] = CARDS.draw_offer(rng, owned, id, pick)
				var seen := {}
				var actions := 0
				for card in offer:
					seen[card.id] = true
					if CARDS.ACTION_KINDS.has(str(card.kind)):
						actions += 1
					if card.has("character") and str(card.character) != id:
						_fail("%s was offered %s" % [id, card.id])
						return
					if card.has("max_stacks") and owned.count(card.id) >= int(card.max_stacks):
						_fail("%s offered again to a fighter that holds %d" % [card.id, owned.count(card.id)])
						return
				if offer.size() != 3 or seen.size() != 3:
					_fail("An offer is three different cards (%s)" % str(seen.keys()))
					return
				if actions < 1:
					_fail("An offer holds one action or character card at least (%s, pick %d: %s)" % [id, pick, str(seen.keys())])
					return
				if pick == 2 and OWN_CARD.has(id) and not owned.has(OWN_CARD[id]):
					if not seen.has(OWN_CARD[id]):
						_fail("%s's own card is in its second offer (%s)" % [id, str(seen.keys())])
						return
					for index in 3:
						if str(offer[index].id) == OWN_CARD[id]:
							slots[index] += 1
				owned.append(str(offer[rng.randi_range(0, 2)].id))
	if slots.min() < 60:
		_fail("The card an offer must hold has no fixed place among the three (%s)" % str(slots))

## Through SoulGrowth as a match runs it: a person's offer lasts 8 s, a Frey's second offer holds
## her own card, and the offer says its full time for the screen.
func _test_offer_through_soul_growth() -> void:
	var growth := SOUL_GROWTH.new()
	growth.match_seed = 7
	root.add_child(growth)
	growth.set_process(false)
	var frey := _person("frey", 1, Vector2.ZERO)
	frey.set_physics_process(false)
	growth.register_player(frey)
	if not is_equal_approx(SOUL_GROWTH.CHOICE_TIME, 8.0):
		_fail("A person has 8 s to choose (%.1f)" % SOUL_GROWTH.CHOICE_TIME)
	frey.add_souls(25)
	var first: Dictionary = growth.get_offer(frey)
	if first.is_empty() or not is_equal_approx(float(first.time_left), 8.0) or not is_equal_approx(float(first.get("time_total", 0.0)), 8.0):
		_fail("A person's offer opens with 8 s left of 8 (%s)" % str(first))
	else:
		# A stat card, so that the second offer still has her own card to give.
		var taken := false
		for index in first.cards.size():
			if first.cards[index].kind != "character":
				growth.choose(frey, index)
				taken = true
				break
		if not taken:
			growth.choose(frey, 0)
	frey.add_souls(25)
	var second: Dictionary = growth.get_offer(frey)
	var ids: Array = second.get("cards", []).map(func(card: Dictionary) -> String: return str(card.id))
	if not frey.upgrades.has("second_wingbeat") and not ids.has("second_wingbeat"):
		_fail("Frey's second offer in a match holds Second Wingbeat (%s)" % str(ids))
	var bot := _person("yuki", 2, Vector2.ZERO)
	bot.is_human = false
	bot.set_physics_process(false)
	growth.register_player(bot)
	bot.add_souls(25)
	if not is_equal_approx(float(growth.get_offer(bot).get("time_left", 0.0)), SOUL_GROWTH.BOT_THINK_TIME):
		_fail("A bot takes its card after its own short wait")
	growth.queue_free()
	frey.queue_free()
	bot.queue_free()
	await process_frame

# --- Common action cards ---

## In the air the guard key dashes about 120 px the way the fighter faces, once before landing; on
## the floor it still guards; without the card it does nothing in the air.
func _test_air_dash() -> void:
	_floor()
	var fighter := _person("yuki", 1, Vector2(0, -2), true)
	await _frames(15)
	# Without the card: nothing.
	_put(fighter, Vector2(0, -400))
	fighter.velocity = Vector2.ZERO
	await _frames(3)
	_press("guard")
	await _frames(2)
	if float(fighter.skill_dash_timer) > 0.0 or bool(fighter.is_guarding):
		_fail("Without Air Dash the guard key does nothing in the air")
	_release("guard")
	await _wait_for(func() -> bool: return fighter.is_on_floor(), 2.0)
	_give(fighter, "air_dash")
	# On the floor the key still guards.
	_press("guard")
	await _frames(2)
	if not bool(fighter.is_guarding) or _count(fighter, "air_dash") != 0:
		_fail("On the floor the guard key still guards")
	_release("guard")
	await _frames(24)
	for side: int in [1, -1]:
		_put(fighter, Vector2(0, -400))
		fighter.velocity = Vector2.ZERO
		fighter.facing = side
		await _frames(3)
		var from: Vector2 = _at(fighter)
		_press("guard")
		if float(fighter.skill_dash_timer) <= 0.0:
			_fail("With Air Dash the guard key in the air should start a dash")
			return
		await _wait_for(func() -> bool: return float(fighter.skill_dash_timer) <= 0.0, 0.5)
		var moved: Vector2 = _at(fighter) - from
		var reach: float = fighter.AIR_DASH_SPEED * fighter.AIR_DASH_TIME
		if absf(moved.x * side - reach) > 14.0 or absf(moved.y) > 12.0:
			_fail("The dash should go about %.0f px the way the fighter faces and not drop (moved %s, facing %d)" % [reach, moved, side])
		_release("guard")
		# Once before landing.
		_press("guard")
		await _frames(2)
		if float(fighter.skill_dash_timer) > 0.0 or _count(fighter, "air_dash") != (1 if side == 1 else 2):
			_fail("A second press in the same airtime should not dash again (%d dashes)" % _count(fighter, "air_dash"))
		_release("guard")
		if not await _wait_for(func() -> bool: return fighter.is_on_floor(), 2.0):
			_fail("Test setup: the fighter should land")
			return
		await _frames(2)
		if not bool(fighter.air_dash_ready):
			_fail("Landing should make the dash ready again")

## A landing from 380 px lifts and hurts the foe standing beside; a landing from 150 px does not;
## without the card neither does.
func _test_meteor_landing() -> void:
	_floor()
	var fighter := _person("yuki", 1, Vector2(0, -2))
	var foe := _dummy(2, Vector2(70, -2))
	await _frames(15)
	for step in [{"card": false, "drop": 380.0, "hit": false}, {"card": true, "drop": 150.0, "hit": false}, {"card": true, "drop": 380.0, "hit": true}]:
		if bool(step.card) and not fighter.has_card("meteor_landing"):
			_give(fighter, "meteor_landing")
		_put(foe, Vector2(70, -2))
		foe.velocity = Vector2.ZERO
		foe.knockback_velocity = Vector2.ZERO
		await _frames(4)
		var hp: float = foe.hp
		_put(fighter, Vector2(0, -2.0 - float(step.drop)))
		fighter.velocity = Vector2.ZERO
		await _frames(2)
		if not await _wait_for(func() -> bool: return fighter.is_on_floor(), 3.0):
			_fail("Test setup: the fighter should land")
			return
		var highest := 0.0
		for frame in 20:
			await physics_frame
			highest = minf(highest, _at(foe).y + 2.0)
		var hit: bool = foe.hp < hp
		if hit != bool(step.hit):
			_fail("A landing from %.0f px %s the card: the foe beside %s be hit" % [step.drop, "with" if step.card else "without", "should" if step.hit else "should not"])
		elif hit and highest > -20.0:
			_fail("The shockwave should lift the foe (it rose %.0f px)" % -highest)

## A parry stuns the foe whose swing it met for a second; without the card it does not.
func _test_riposte() -> void:
	_floor()
	for with_card: bool in [false, true]:
		var fighter := _person("yuki", 1, Vector2(0, -2), true)
		var foe := _person("frey", 2, Vector2(-70, -2))
		if with_card:
			_give(fighter, "riposte")
		await _frames(15)
		foe.facing = 1
		var lands: int = await _swing_lands_after(foe, fighter)
		if lands < 4:
			_fail("Test setup: the foe's swing should land on the fighter after a start-up (%d frames)" % lands)
			return
		await _frames(50)
		_put(fighter, Vector2(0, -2))
		_put(foe, Vector2(-70, -2))
		for body in [fighter, foe]:
			body.velocity = Vector2.ZERO
			body.knockback_velocity = Vector2.ZERO
		# A body just moved still reports the floor it stood on: let both settle first.
		await _frames(8)
		if not await _wait_for(func() -> bool: return float(fighter.hitstun_timer) <= 0.0 and fighter.is_on_floor(), 2.0):
			_fail("Test setup: the fighter should stand again")
			return
		fighter.attack_lock_timer = 0.0
		foe.attack_lock_timer = 0.0
		foe.facing = 1
		fighter.facing = -1
		var hp: float = fighter.hp
		foe.basic_attack()
		await _frames(lands - 3)
		_press("guard")
		if not bool(fighter.is_guarding):
			_fail("Test setup: the guard key should raise the guard (on the floor: %s)" % fighter.is_on_floor())
			return
		await _frames(8)
		if fighter.hp < hp:
			_fail("Test setup: the swing should be parried (hp %.1f -> %.1f)" % [hp, fighter.hp])
		elif with_card and (float(foe.hitstun_timer) < 0.8 or float(foe.status_stun_timer) <= 0.0):
			_fail("Riposte: the parried foe should be stunned for a second (hitstun %.2f)" % foe.hitstun_timer)
		elif not with_card and float(foe.hitstun_timer) > 0.3:
			_fail("Without Riposte a parry should not stun (hitstun %.2f)" % foe.hitstun_timer)
		_release("guard")
		fighter.queue_free()
		foe.queue_free()
		await _frames(2)

## The fighter that eliminates a foe is healed 25 HP, up to its maximum; without the card it is not.
func _test_soul_drain() -> void:
	_floor()
	var fighter := _person("frey", 1, Vector2(0, -2))
	await _frames(15)
	for step in [{"card": false, "hp": 40.0, "gain": 0.0}, {"card": true, "hp": 40.0, "gain": 25.0}, {"card": true, "hp": -10.0, "gain": 10.0}]:
		if bool(step.card) and not fighter.has_card("soul_drain"):
			_give(fighter, "soul_drain")
		var foe := _dummy(2, Vector2(70, -2))
		await _frames(10)
		foe.hp = 1.0
		fighter.hp = float(step.hp) if float(step.hp) > 0.0 else fighter.max_hp + float(step.hp)
		var before: float = fighter.hp
		fighter.attack_lock_timer = 0.0
		fighter.facing = 1
		fighter.basic_attack()
		if not await _wait_for(func() -> bool: return bool(foe.is_defeated), 1.0):
			_fail("Test setup: the swing should eliminate the foe at 1 HP")
			return
		if not is_equal_approx(fighter.hp - before, float(step.gain)):
			_fail("Eliminating a foe %s Soul Drain should heal %.0f HP (%.1f -> %.1f)" % ["with" if step.card else "without", step.gain, before, fighter.hp])
		foe.queue_free()
		await _frames(50)

## At 30% HP or less attack is x1.25 and speed x1.1, in the numbers and in a real swing's damage.
func _test_last_flame() -> void:
	_floor()
	var fighter := _person("frey", 1, Vector2(0, -2))
	var foe := _dummy(2, Vector2(70, -2))
	foe.weight = 60.0
	_give(fighter, "last_flame")
	await _frames(15)
	var attack: float = fighter.attack_power
	var speed: float = fighter.speed
	fighter.hp = fighter.max_hp * 0.31
	await _frames(2)
	if not is_equal_approx(fighter.attack_power, attack) or bool(fighter.last_flame_on):
		_fail("Above 30% HP Last Flame should not burn")
	var damage: Array[float] = []
	for share: float in [0.31, 0.3]:
		fighter.hp = fighter.max_hp * share
		await _frames(2)
		fighter.attack_lock_timer = 0.0
		fighter.facing = 1
		var hp: float = foe.hp
		fighter.basic_attack()
		await _frames(30)
		damage.append(hp - foe.hp)
		# The chain's first swing again next time.
		await _frames(50)
	if not is_equal_approx(fighter.attack_power, attack * 1.25) or not is_equal_approx(fighter.speed, speed * 1.1):
		_fail("At 30% HP attack should be x1.25 and speed x1.1 (attack %.1f of %.1f, speed %.1f of %.1f)" % [fighter.attack_power, attack, fighter.speed, speed])
	if damage[0] <= 0.0 or absf(damage[1] / damage[0] - 1.25) > 0.01:
		_fail("The same swing should hit 1.25 times as hard at 30% HP (%.2f -> %.2f)" % [damage[0], damage[1]])
	fighter.hp = fighter.max_hp
	await _frames(2)
	if not is_equal_approx(fighter.attack_power, attack) or not is_equal_approx(fighter.speed, speed):
		_fail("Healed above 30% HP the numbers should go back")

## A hit that sends the foe flying gives x1.3 speed for 2 s; a light hit does not.
func _test_chaser() -> void:
	_floor()
	var fighter := _person("frey", 1, Vector2(0, -2))
	_give(fighter, "chaser")
	await _frames(15)
	var speed: float = fighter.speed
	# A heavy foe at full HP: the swing barely moves it.
	var heavy := _dummy(2, Vector2(70, -2))
	heavy.weight = 60.0
	await _frames(10)
	fighter.facing = 1
	fighter.basic_attack()
	await _frames(30)
	if float(fighter.chaser_timer) > 0.0 or not is_equal_approx(fighter.speed, speed):
		_fail("A hit that barely moves the foe should not start Chaser")
	heavy.queue_free()
	await _frames(50)
	# A light foe almost out: the same swing sends it flying.
	var light := _dummy(3, Vector2(70, -2))
	light.weight = 0.3
	await _frames(10)
	light.hp = light.max_hp * 0.05
	fighter.attack_lock_timer = 0.0
	fighter.facing = 1
	fighter.basic_attack()
	if not await _wait_for(func() -> bool: return float(fighter.chaser_timer) > 0.0, 1.0):
		_fail("A hit that sends the foe flying should start Chaser (the foe's knockback %.0f px/s)" % light.knockback_velocity.length())
		return
	await physics_frame
	if not is_equal_approx(fighter.speed, speed * 1.3):
		_fail("Chaser should give x1.3 speed (%.1f of %.1f)" % [fighter.speed, speed])
	await _frames(int(fighter.CHASER_TIME * 60.0) + 12)
	if float(fighter.chaser_timer) > 0.0 or not is_equal_approx(fighter.speed, speed):
		_fail("Chaser should end after 2 s (timer %.2f, speed %.1f of %.1f)" % [fighter.chaser_timer, fighter.speed, speed])

func _monster(at: Vector2) -> Node:
	var monster := CharacterBody2D.new()
	monster.set_script(MONSTER)
	monster.setup("mossling", 0, scene + at)
	arena.add_child(monster)
	return monster

## The same swing takes 1.5 times as much from a monster, and the monster pays 1.5 times the souls
## (through the spawner's own handler, as in a match).
func _test_hunter_monster() -> void:
	_floor()
	var spawner := MONSTER_SPAWNER.new()
	arena.add_child(spawner)
	spawner.set_physics_process(false)
	var fighter := _person("frey", 1, Vector2(0, -2))
	await _frames(15)
	var damage: Array[float] = []
	var souls: Array[int] = []
	for with_card: bool in [false, true]:
		if with_card:
			_give(fighter, "hunter")
		var monster := _monster(Vector2(70, -30))
		monster.defeated.connect(spawner._on_monster_defeated.bind(0))
		await _frames(30)
		_put(monster, Vector2(70, _at(monster).y))
		monster.max_hp = 1000.0
		monster.hp = 1000.0
		fighter.attack_lock_timer = 0.0
		fighter.facing = 1
		fighter.basic_attack()
		await _frames(30)
		# Per point of attack: taking a card also advances the fighter's own growth.
		damage.append((1000.0 - float(monster.hp)) / float(fighter.attack_power))
		await _frames(50)
		# The last hit: the monster pays its souls.
		_put(fighter, Vector2(0, -2))
		_put(monster, Vector2(70, _at(monster).y))
		await _frames(4)
		monster.hp = 0.5
		var before: int = fighter.souls
		fighter.attack_lock_timer = 0.0
		fighter.facing = 1
		fighter.basic_attack()
		await _frames(40)
		souls.append(fighter.souls - before)
		if is_instance_valid(monster):
			monster.queue_free()
		_put(fighter, Vector2(0, -2))
		fighter.velocity = Vector2.ZERO
		fighter.knockback_velocity = Vector2.ZERO
		await _frames(60)
	if damage[0] <= 0.0 or absf(damage[1] / damage[0] - 1.5) > 0.01:
		_fail("Hunter: the same swing should take 1.5 times as much from a monster (per attack point %.4f -> %.4f)" % [damage[0], damage[1]])
	if souls[0] <= 0 or souls[1] != roundi(souls[0] * 1.5):
		_fail("Hunter: a monster should pay 1.5 times the souls (%d -> %d)" % [souls[0], souls[1]])
	# A fighter takes the usual damage from a Hunter.
	var foe := _dummy(2, Vector2(70, -2))
	await _frames(10)
	if not is_equal_approx(fighter.damage_scale_against(foe), 1.0):
		_fail("Hunter is for monsters, not fighters")

## A crystal the spawner placed, broken by real swings, pays 15 souls with Hunter and 10 without.
func _test_hunter_crystal() -> void:
	_floor()
	for with_card: bool in [false, true]:
		var fighter := _person("frey", 1, Vector2(0, -2))
		if with_card:
			_give(fighter, "hunter")
		var spawner := CRYSTAL_SPAWNER.new()
		arena.add_child(spawner)
		var at := scene + Vector2(70, -2)
		spawner.configure(func(_realm: int) -> Array: return [at], func() -> Array[int]: return [0], 3)
		spawner.sync_playable_realms([0])
		var crystal: Node = spawner.get_crystal(0)
		if crystal == null:
			_fail("Test setup: the spawner should place a crystal")
			return
		await _frames(15)
		var before: int = fighter.souls
		for swing in CRYSTAL.HITS_TO_BREAK + 2:
			if not is_instance_valid(crystal) or crystal.is_queued_for_deletion():
				break
			fighter.attack_lock_timer = 0.0
			fighter.facing = 1
			fighter.basic_attack()
			await _frames(70)
		var paid: int = fighter.souls - before
		var expected := 15 if with_card else 10
		if paid != expected:
			_fail("A broken crystal should pay %d souls %s Hunter (%d)" % [expected, "with" if with_card else "without", paid])
		fighter.queue_free()
		spawner.queue_free()
		await _frames(2)

## The ultimate comes back in 22 s, on the timer and on the skill bar; 30 s without the card.
func _test_overcharge() -> void:
	_floor()
	for with_card: bool in [false, true]:
		var fighter := _person("yuki", 1, Vector2(0, -2))
		if with_card:
			_give(fighter, "overcharge")
		await _frames(15)
		fighter.ultimate()
		var expected := 22.0 if with_card else 30.0
		if not is_equal_approx(float(fighter.ultimate_cooldown_timer), expected) or not is_equal_approx(float(fighter.skill_cooldown("i").y), expected):
			_fail("The ultimate's cooldown should be %.0f s %s Overcharge (timer %.1f, bar %s)" % [expected, "with" if with_card else "without", fighter.ultimate_cooldown_timer, fighter.skill_cooldown("i")])
		fighter.queue_free()
		await _frames(2)

# --- Character cards ---

## Frey hovers and dashes twice in one airtime with her card, once without; a third hold does nothing.
func _test_second_wingbeat() -> void:
	for with_card: bool in [false, true]:
		var frey := _person("frey", 1, Vector2(0, -3000))
		if with_card:
			_give(frey, "second_wingbeat")
		await _frames(4)
		frey.air_jumps_left = frey.max_air_jumps
		for hold in 3:
			Input.action_press("jump")
			await _frames(14)
			Input.action_release("jump")
			Input.action_press("move_right")
			await _frames(30)
			Input.action_release("move_right")
			await _frames(6)
		var expected := 2 if with_card else 1
		if _count(frey, "wings") != expected:
			_fail("Frey should use her wings %d time(s) in one airtime %s Second Wingbeat (%d)" % [expected, "with" if with_card else "without", _count(frey, "wings")])
		frey.queue_free()
		await _frames(2)

## Luna's fourth J is the big star: with her card its burst throws two small stars on, which reach
## the foe standing behind the one it struck and pass the one it struck.
func _test_twin_stars() -> void:
	_floor()
	var struck_damage: Array[float] = []
	for with_card: bool in [false, true]:
		var luna := _person("luna", 1, Vector2(0, -2))
		if with_card:
			_give(luna, "twin_stars")
		var near := _dummy(2, Vector2(180, -2))
		var far := _dummy(3, Vector2(310, -2))
		near.weight = 80.0
		far.weight = 80.0
		await _frames(15)
		luna.facing = 1
		var near_hp: float = near.hp
		var far_hp: float = far.hp
		for press in 4:
			if not await _wait_for(func() -> bool: return float(luna.attack_lock_timer) <= 0.0, 1.0):
				_fail("Test setup: Luna should be free for her next J")
				return
			luna.facing = 1
			luna.basic_attack()
			await _frames(2)
		await _frames(50)
		# Per point of attack: taking a card also advances the fighter's own growth.
		struck_damage.append((near_hp - near.hp) / float(luna.attack_power))
		if _count(luna, "twin_stars") != (1 if with_card else 0):
			_fail("The big star's burst should throw two more stars only with Twin Stars (%d bursts counted)" % _count(luna, "twin_stars"))
		if with_card and far.hp >= far_hp:
			_fail("The two small stars should reach the foe 130 px behind the burst")
		if not with_card and far.hp < far_hp:
			_fail("Test setup: without the card nothing should reach the foe behind (the burst ends before it)")
		luna.queue_free()
		near.queue_free()
		far.queue_free()
		await _frames(2)
	if struck_damage.size() == 2 and absf(struck_damage[0] - struck_damage[1]) > 0.0005:
		_fail("The small stars should pass the foe the big star struck (per attack point it took %.4f without the card, %.4f with)" % [struck_damage[0], struck_damage[1]])

## Nova's field lasts 9 s and comes back in 10 s with her card; 6 s and 12 s without.
func _test_deep_gravity() -> void:
	_floor()
	for with_card: bool in [false, true]:
		var nova := _person("nova", 1, Vector2(0, -2))
		if with_card:
			_give(nova, "deep_gravity")
		await _frames(15)
		nova.skill_two()
		await _frames(20)
		if not is_instance_valid(nova.field):
			_fail("Test setup: L should cast the gravity field")
			return
		var time := 9.0 if with_card else 6.0
		var cooldown := 10.0 if with_card else 12.0
		if not is_equal_approx(float(nova.field.duration), time) or not is_equal_approx(float(nova.skill_cooldown("l").y), cooldown) or float(nova.field_cooldown_timer) > cooldown or float(nova.field_cooldown_timer) < cooldown - 1.0:
			_fail("The field should last %.0f s and come back in %.0f s %s Deep Gravity (lasts %.1f, bar %s)" % [time, cooldown, "with" if with_card else "without", nova.field.duration, nova.skill_cooldown("l")])
		nova.queue_free()
		await _frames(2)

## Rio swaps places with his decoy twice with his card, once without.
func _test_second_decoy() -> void:
	_floor()
	for with_card: bool in [false, true]:
		var rio := _person("rio", 1, Vector2(0, -2))
		if with_card:
			_give(rio, "second_decoy")
		await _frames(15)
		rio.facing = 1
		rio.press_skill_three()
		if not is_instance_valid(rio.decoy):
			_fail("Test setup: U should leave a decoy")
			return
		var decoy_at: Vector2 = _at(rio.decoy)
		var stepped_to: Vector2 = _at(rio)
		await _frames(14)
		rio.press_skill_three()
		await _frames(8)
		if _at(rio).distance_to(decoy_at) > 2.0:
			_fail("The second U should swap Rio with his decoy")
			return
		rio.press_skill_three()
		await _frames(8)
		var back: bool = _at(rio).distance_to(stepped_to) <= 2.0
		if back != with_card:
			_fail("A third U %s Second Decoy %s swap again (Rio at %s)" % ["with" if with_card else "without", "should" if with_card else "should not", _at(rio)])
		if _count(rio, "u2") != (2 if with_card else 1) or bool(rio.decoy_swap_ready):
			_fail("The swaps should be spent (%d swaps, ready %s)" % [_count(rio, "u2"), rio.decoy_swap_ready])
		rio.queue_free()
		await _frames(2)

## Xion's magazine holds 14 rounds with her card: taking it loads four, a reload fills to 14, the
## skill bar shows it.
func _test_extended_magazine() -> void:
	_floor()
	var xion := _person("xion", 1, Vector2(0, -2))
	await _frames(15)
	if int(xion.ammo) != 10 or xion.magazine_size() != 10:
		_fail("Test setup: Xion starts with ten rounds")
	_give(xion, "extended_magazine")
	if int(xion.ammo) != 14 or xion.magazine_size() != 14 or xion.skill_counter("j") != "14":
		_fail("Extended Magazine should load four more rounds, fourteen in all (ammo %d, bar %s)" % [xion.ammo, xion.skill_counter("j")])
	xion.facing = 1
	xion.basic_attack()
	await _frames(20)
	if int(xion.ammo) != 13:
		_fail("A shot should use one round of the fourteen (ammo %d)" % xion.ammo)
	xion.ammo = 1
	await _wait_for(func() -> bool: return float(xion.attack_lock_timer) <= 0.0 and float(xion.shot_timer) <= 0.0, 1.5)
	xion.basic_attack()
	await _frames(10)
	if int(xion.ammo) != 0 or float(xion.reload_timer) <= 0.0:
		_fail("Test setup: the last round should start the reload (ammo %d)" % xion.ammo)
	await _frames(int(xion.RELOAD_TIME * 60.0) + 12)
	if int(xion.ammo) != 14:
		_fail("The reload should fill the magazine to fourteen (ammo %d)" % xion.ammo)

# --- Bots ---

## A bot that took Air Dash, falling off the side of the stage, dashes toward it on its way back;
## a bot without the card does not.
func _test_bot_air_dash() -> void:
	_floor(600.0)
	for with_card: bool in [false, true]:
		var bot: Node = PLAYER_FACTORY.create("yuki")
		arena.add_child(bot)
		_put(bot, Vector2(-520, -160))
		bot.setup(CHARACTER_REGISTRY.get_characters()["yuki"], 1, false)
		bot.ringout_y = 100000.0
		bot.realm_origin = scene + Vector2(-300, -540)
		bot.realm_size = Vector2(600, 720)
		var points: Array[Vector2] = [scene + Vector2(-200, -2), scene + Vector2(200, -2)]
		bot.set_spawn_points(points)
		if with_card:
			_give(bot, "air_dash")
		bot.velocity = Vector2(0, 200)
		var from: Vector2 = _at(bot)
		await _frames(40)
		var dashes := _count(bot, "air_dash")
		if with_card and (dashes != 1 or _at(bot).x - from.x < 100.0):
			_fail("A bot with Air Dash should dash toward the stage on its way back (%d dashes, moved %.0f px, %s)" % [dashes, _at(bot).x - from.x, bot.ai_controller.debug_reason])
		if not with_card and dashes != 0:
			_fail("A bot without the card cannot dash")
		bot.queue_free()
		await _frames(2)

## A bot Frey that took Second Wingbeat opens her wings again in the same airtime when a foe is on
## one of her eight ways again; without the card she does not (the test calls her brain itself, as
## test_bot_kits does).
func _test_bot_second_wingbeat() -> void:
	_floor(2400.0)
	for with_card: bool in [false, true]:
		var frey: Node = PLAYER_FACTORY.create("frey")
		arena.add_child(frey)
		_put(frey, Vector2(0, -330))
		frey.setup(CHARACTER_REGISTRY.get_characters()["frey"], 1, false)
		frey.ringout_y = 100000.0
		frey.realm_origin = scene + Vector2(-1200, -900)
		frey.realm_size = Vector2(2400, 1080)
		frey.is_dummy = true
		if with_card:
			_give(frey, "second_wingbeat")
		var foe := _dummy(2, Vector2(140, -190))
		foe.set_physics_process(false)
		foe.max_hp = 100000.0
		foe.hp = 100000.0
		await _frames(3)
		_put(frey, Vector2(0, -330))
		frey.velocity = Vector2.ZERO
		frey.air_jumps_left = frey.max_air_jumps
		var ai = frey.ai_controller
		ai.target = foe
		ai.state = AI.STATE_ENGAGE
		ai.wing_roll = 1
		ai.air_time = 1.0
		ai._drive_frey_wings(frey, 0.016)
		if not bool(frey.wing_hovering):
			_fail("Test setup: the Frey bot should open her wings at the foe on her diagonal")
			return
		# After the first dash the foe stands level with her, ahead: on one of her ways again.
		for frame in 70:
			await physics_frame
			if frey.is_on_floor():
				break
			if not bool(frey.wing_hovering) and float(frey.skill_dash_timer) <= 0.0:
				_put(foe, _at(frey) + Vector2(150, 0))
			ai._drive_frey_wings(frey, 1.0 / 60.0)
		var expected := 2 if with_card else 1
		if _count(frey, "wings") != expected:
			_fail("A Frey bot should use her wings %d time(s) in one airtime %s Second Wingbeat (%d)" % [expected, "with" if with_card else "without", _count(frey, "wings")])
		frey.queue_free()
		foe.queue_free()
		await _frames(2)
