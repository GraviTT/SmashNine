extends Node
## Practice mode (quality track, 2026-11-26): the picked fighter and one target in the central
## realm, with keys to change the target, put everything back, refill cooldowns, call a monster
## and hold any soul card at once. The rules are PracticeDirector's; this owns the two fighters,
## the keys and the practice lines of the HUD.
##
## Keys (read here as key events, before the fighter sees them):
##   H    target: standing dummy -> walking dummy -> fighting bot      N  the bot's fighter
##   R    both back to their start places at full HP, the field cleared
##   E    ultimate and skills ready at once                            M  call a monster
##   C    soul cards (1/2/3 take, A/D turn the page, C or Esc close)   X  give every card back
##   Tab  the fighter's skill list                                     Esc back to the title
##   F1   a menu of all of the above (a gamepad's Start and Back open it: PadInput)
## While the card list or the skill list is open the game is paused, so moving the page with
## A/D moves nothing else.
##
## Nothing here writes a save file: no story progress, no settings.

const CARDS := preload("res://scripts/match/SoulCards.gd")
const MONSTER := preload("res://scripts/RealmMonster.gd")
const FACTORY := preload("res://scripts/PlayerFactory.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const SPEED := preload("res://scripts/GameSpeed.gd")
const SCALE := preload("res://scripts/GameScale.gd")
const FRONTEND := preload("res://scripts/ui/FrontendMenu.gd")
const GLYPHS := preload("res://scripts/input/PadGlyphs.gd")

const MODES: Array[String] = ["stand", "walk", "fight"]
const MODE_NAMES := {"stand": "Standing dummy", "walk": "Walking dummy", "fight": "Fighting bot"}
## Spawn points of the central realm, both on its main floor.
const HERO_SPAWN := 1
const TARGET_SPAWN := 2
## A called monster comes out this far in front of the fighter.
const MONSTER_AHEAD := 300.0
## The walking dummy: about half a fighter's run, this far each side of its start place.
const WALK_SPEED := 150.0
const WALK_REACH := 200.0
## A fallen fighter stands up again after its defeat motion (a training dummy takes the 3 s of
## PlayerBase._defeat).
const REVIVE_DELAY := 1.6
const MONSTER_LIMIT := 3
const CARDS_PER_PAGE := 3
## The practice menu (panel "menu"): what a gamepad has instead of the nine keys.
const MENU_ROWS := [
	["Change the target", "target"], ["Change the bot's fighter", "bot"], ["Reset", "reset"],
	["Refill cooldowns", "refill"], ["Call a monster", "monster"], ["Soul cards", "cards"],
	["Clear cards", "clear"], ["Skill list", "skills"], ["Back to the title", "leave"],
]
const KEY_HELP := "H target   N bot's fighter   R reset   E refill   M monster   C cards   X clear cards   Tab skills   Esc title"
const INK := Color("101827")
const GOLD := Color("f3cd7c")
const DIM := Color("aebbd0")

## The bot's fighter lasts the session (N changes it), like the menu's other choices.
static var bot_id := "frey"

var main: Node
var hero: Node
var target: Node
var mode := "stand"
## Hits the target took, in HP as it lost them (the match's combat damage scale applies).
var last_damage := 0.0
var total_damage := 0.0
## "" while playing, "cards" or "skills" while that list is open (the game is paused then).
var panel := ""
var card_page := 0
var menu_index := 0
var monsters: Array[Node] = []
var info: Label
var skills_panel: Control
var _walk_direction := 1.0
## Main's children when practice began: whatever else sits beside them later was left by the fight.
var _fixed_nodes: Array[Node] = []

func _init() -> void:
	# The lists are read with the game paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

func start(owner_main: Node, character_id: String) -> void:
	main = owner_main
	_fixed_nodes = main.get_children()
	var realm: int = main.CENTRAL_REALM_INDEX
	hero = main._add_player(character_id, true, _start_point(HERO_SPAWN), realm, main._pick_body(character_id, true))
	hero.defeated.connect(_on_fighter_defeated)
	_make_target()
	main._set_map(realm)
	main._apply_phase_rules()
	_build_hud()
	reset_positions(true)
	# The numbers are the central brawl's (PracticeDirector).
	main._show_message(tr("Practice: nothing ends here. Ring-out 30 HP, no regeneration, damage as in a match."))

func _start_point(spawn: int) -> Vector2:
	var points: Array[Vector2] = main.layout.get_spawn_points(main.CENTRAL_REALM_INDEX)
	return points[spawn % points.size()]

# --- The target ---

func _make_target() -> void:
	var realm: int = main.CENTRAL_REALM_INDEX
	var at := _start_point(TARGET_SPAWN)
	if mode == "fight":
		target = main._add_player(bot_id, false, at, realm, main._pick_body(bot_id, false))
		target.defeated.connect(_on_fighter_defeated)
	else:
		target = FACTORY.create()
		main.add_child(target)
		target.global_position = at
		target.setup_dummy(99)
		main.layout.assign_combatant(target, realm)
		target.respawned.connect(main._on_combatant_respawned)
		main.dummy = target
		# Main gives the match's numbers to its players alone; the dummy takes hits by them too.
		target.incoming_damage_scale = main.director.get_combat_damage_scale()
		target.ringout_damage = main.director.get_ringout_damage()
	target.damaged.connect(_on_target_damaged)
	_apply_dummy_mode()
	main._sync_combatant_visibility()

func _remove_target() -> void:
	if not is_instance_valid(target):
		return
	main.players.erase(target)
	main.director.unregister_combatant(target)
	main.hazards.combatants.erase(target)
	if main.dummy == target:
		main.dummy = null
	if main.spectate_target == target:
		main.spectate_target = null
	target.cancel_pending_actions()
	target.character_cleanup()
	target.queue_free()
	target = null

func _apply_dummy_mode() -> void:
	if is_instance_valid(target) and target.is_dummy:
		target.speed = WALK_SPEED * SCALE.MOVE if mode == "walk" else 0.0
		target.dummy_move = 0.0

func target_name() -> String:
	var text := tr(str(MODE_NAMES[mode]))
	if mode == "fight" and is_instance_valid(target):
		text = "%s (%s)" % [text, tr(str(target.display_name))]
	return text

## H: the next kind of target. A dummy and a bot are different bodies, so that change also puts
## everything back (the fighter may hold something aimed at the body that leaves).
func cycle_target() -> void:
	set_mode(MODES[(MODES.find(mode) + 1) % MODES.size()])

func set_mode(next_mode: String) -> void:
	var was_bot := mode == "fight"
	mode = next_mode
	if (mode == "fight") != was_bot or not is_instance_valid(target):
		_remove_target()
		_make_target()
		reset_positions(true)
	_apply_dummy_mode()
	main._show_message(tr("Target: %s") % target_name())

## N: the bot's fighter, the next of the roster.
func next_bot() -> void:
	var ids := REGISTRY.get_character_ids()
	bot_id = ids[(ids.find(bot_id) + 1) % ids.size()]
	var bot_name := tr(str(REGISTRY.get_characters()[bot_id].name))
	if mode != "fight":
		main._show_message(tr("Bot fighter: %s (H brings the fighting bot).") % bot_name)
		return
	_remove_target()
	_make_target()
	reset_positions(true)
	main._show_message(tr("Target: %s") % target_name())

func _physics_process(_delta: float) -> void:
	if get_tree().paused or not is_instance_valid(target) or not target.is_dummy:
		return
	if mode != "walk" or target.is_defeated:
		target.dummy_move = 0.0
		return
	var home := _start_point(TARGET_SPAWN).x
	if target.global_position.x > home + WALK_REACH:
		_walk_direction = -1.0
	elif target.global_position.x < home - WALK_REACH:
		_walk_direction = 1.0
	target.dummy_move = _walk_direction

func _on_target_damaged(_fighter: Node, amount: float, _attacker: Node, source: String) -> void:
	# Ring-out damage is the realm's, not a hit's.
	if source == "hit":
		last_damage = amount
		total_damage += amount

func _on_fighter_defeated(fighter: Node, _attacker: Node) -> void:
	if fighter.is_dummy:
		return
	main._show_message(tr("%s is down, and up again in a moment.") % tr(str(fighter.display_name)))
	# The physics clock, and it stops while a list is open.
	await get_tree().create_timer(REVIVE_DELAY, false, true).timeout
	if is_instance_valid(fighter) and fighter.is_defeated and (fighter == hero or fighter == target):
		fighter.revive()
		fighter.grant_protection()

# --- R, E, M ---

## R: both fighters at their start places with full HP, and nothing of the fight left around
## them. Cards and the ultimate's cooldown stay (X and E are for those).
func reset_positions(quiet := false) -> void:
	for entry in [[hero, HERO_SPAWN, 1], [target, TARGET_SPAWN, -1]]:
		var fighter: Node = entry[0]
		if not is_instance_valid(fighter):
			continue
		if fighter.is_defeated:
			fighter.revive()
		var at := _start_point(int(entry[1]))
		var points: Array[Vector2] = [at]
		fighter.reset_for_map(at, points)
		fighter.facing = int(entry[2])
		fighter.hp = fighter.max_hp
		fighter.invulnerable_timer = 0.0
		fighter.status_stun_timer = 0.0
		fighter.modulate.a = 1.0
		fighter.hp_changed.emit(fighter)
		fighter._update_visuals()
	_clear_leftovers()
	last_damage = 0.0
	total_damage = 0.0
	_walk_direction = 1.0
	main._set_map(main.CENTRAL_REALM_INDEX)
	if not quiet:
		main._show_message(tr("Back to the start: places, HP and the field."))

## What the fight left beside the fighters: shots in flight, hitboxes, decoys, fields, seals,
## doubles, effect sprites and the monsters called with M. A fighter's own state went with
## reset_for_map (character_cleanup); these are the nodes it put on the field.
func _clear_leftovers() -> void:
	for child in main.get_children():
		if child is Node2D and child != hero and child != target and not _fixed_nodes.has(child):
			# Out of the fight at once, not only at the frame's end: on a busy machine a frame runs
			# several physics steps, and a hitbox still there hit the target R had just put back
			# (Rio's cuts, 30 frames into his ultimate, with frames slowed to 50 ms; 2026-11-26).
			# Disabled, a body or an area leaves the physics space (disable_mode REMOVE).
			child.process_mode = Node.PROCESS_MODE_DISABLED
			child.visible = false
			child.queue_free()
	monsters.clear()

## E: the ultimate and every skill ready at once, the bot's too.
func refill() -> void:
	for fighter in [hero, target]:
		if is_instance_valid(fighter) and not fighter.is_dummy:
			fighter.refill_cooldowns()
	main._show_message(tr("Ultimate and skills are ready."))

## M: one monster of the realm, up to three at a time (Hunter is tried on them).
func summon_monster() -> void:
	var alive: Array[Node] = []
	for monster in monsters:
		if is_instance_valid(monster) and not monster.is_queued_for_deletion():
			alive.append(monster)
	monsters = alive
	if monsters.size() >= MONSTER_LIMIT:
		main._show_message(tr("Three monsters are out already."))
		return
	var realm: int = main.CENTRAL_REALM_INDEX
	var monster := CharacterBody2D.new()
	monster.set_script(MONSTER)
	monster.setup("mossling", realm, _monster_point(), str(main.layout.get_realm(realm).monsters.melee))
	main.add_child(monster)
	monster.set_realm_active(true)
	monster.defeated.connect(_on_monster_defeated)
	monsters.append(monster)
	main._show_message(tr("A monster answers the call."))

## In front of the fighter, a little above where it stands, so the monster comes out on screen;
## kept over the realm's main floor so it does not come out over a drop.
func _monster_point() -> Vector2:
	var floor_rect: Rect2 = main.layout.get_platform_rects(main.CENTRAL_REALM_INDEX)[0]
	var at: Vector2 = hero.global_position + Vector2(float(hero.facing) * (MONSTER_AHEAD + monsters.size() * 70.0), -40.0)
	at.x = clampf(at.x, floor_rect.position.x + 90.0, floor_rect.end.x - 90.0)
	return at

func _on_monster_defeated(_monster: Node, attacker: Node, soul_reward: int) -> void:
	if is_instance_valid(attacker) and attacker.has_method("add_hunt_souls"):
		attacker.add_hunt_souls(soul_reward)

# --- Cards (C, X) ---

## The cards this fighter may hold: the common ones and its own.
func card_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for card in CARDS.CARDS:
		if not card.has("character") or str(card.character) == str(hero.character_id):
			list.append(card)
	return list

func card_pages() -> int:
	return ceili(card_list().size() / float(CARDS_PER_PAGE))

func _show_cards() -> void:
	var list := card_list()
	card_page = posmod(card_page, card_pages())
	var shown := list.slice(card_page * CARDS_PER_PAGE, (card_page + 1) * CARDS_PER_PAGE)
	var hud: CanvasLayer = main.hud
	# The HUD's card column without a clock; the header's first part names the page, the rest
	# gives the keys (MatchHud.show_card_list).
	hud.show_card_list(shown, tr("Practice cards  %d / %d    1 / 2 / 3: take    A / D: page    C: close") % [card_page + 1, card_pages()])
	for index in shown.size():
		var card: Dictionary = shown[index]
		var held: int = hero.upgrades.count(str(card.id))
		if held > 0:
			hud.set_card_kind_text(index, tr("%s, held x%d") % [tr(str(card.kind)), held])
	# Main does not draw the HUD while the game is paused: the count of cards and the HP a card
	# changed are brought up to date here.
	_update_status()

## Takes the card in place `index` of the open page. A card held as often as it may be is refused,
## as an offer would not hold it.
func take_card(index: int) -> bool:
	var list := card_list()
	var at := card_page * CARDS_PER_PAGE + index
	if index < 0 or index >= CARDS_PER_PAGE or at >= list.size():
		return false
	var card: Dictionary = list[at]
	if card.has("max_stacks") and hero.upgrades.count(str(card.id)) >= int(card.max_stacks):
		main._show_message(tr("%s is held already.") % tr(str(card.title)))
		return false
	# Each card of a match brings growth with it, and a match gives three: cards past the third
	# bring none here, so attack and HP stay inside what a match can reach.
	var match_cards: int = hero.SOUL_THRESHOLDS.size()
	if hero.soul_picks >= match_cards:
		hero.soul_picks = match_cards - 1
	hero.apply_upgrade(card)
	if panel == "cards":
		_show_cards()
	return true

## X: every card given back, then everything put back (max HP and the kit change with the cards).
func clear_cards() -> void:
	hero.clear_upgrades()
	reset_positions(true)
	main._show_message(tr("No cards held."))

# --- The lists and their pause ---

func open_panel(panel_name: String) -> void:
	panel = panel_name
	get_tree().paused = true
	# Start-up waits of moves run on timers that ignore the pause; frozen time holds them too
	# (as the story's pause does).
	Engine.time_scale = 0.0
	info.visible = false
	if panel == "cards":
		# The message line stays up while the list is open (nothing counts it down in a pause).
		main._show_message(tr("Growth counts for three cards only, as in a match."))
		_show_cards()
	else:
		_show_skills()

func close_panel() -> void:
	panel = ""
	skills_panel.visible = false
	main.hud.hide_card_offer()
	# The note about growth belongs to the card list.
	main.hud.clear_messages()
	SPEED.apply_to_match()
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if main == null or not event is InputEventKey or not event.pressed or event.echo:
		return
	if main._frontend_transition or not main.match_started:
		return
	var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if panel != "":
		_panel_key(code)
		get_viewport().set_input_as_handled()
		return
	match code:
		KEY_ESCAPE:
			leave()
		KEY_H:
			cycle_target()
		KEY_N:
			next_bot()
		KEY_R:
			reset_positions()
		KEY_E:
			refill()
		KEY_M:
			summon_monster()
		KEY_C:
			open_panel("cards")
		KEY_X:
			clear_cards()
		KEY_TAB:
			open_panel("skills")
		KEY_F1:
			open_menu()
		_:
			return
	get_viewport().set_input_as_handled()

## A list is open: its own keys work and every other key does nothing. Esc closes the list; it
## does not also leave practice.
func _panel_key(code: int) -> void:
	if code == KEY_ESCAPE or (panel == "cards" and code == KEY_C) or (panel == "skills" and code == KEY_TAB) or (panel == "menu" and code == KEY_F1):
		close_panel()
	elif panel == "menu":
		if code in [KEY_UP, KEY_W]:
			menu_index = posmod(menu_index - 1, MENU_ROWS.size())
			_show_menu()
		elif code in [KEY_DOWN, KEY_S]:
			menu_index = posmod(menu_index + 1, MENU_ROWS.size())
			_show_menu()
		elif code in [KEY_ENTER, KEY_KP_ENTER, KEY_J]:
			run_menu_row(str(MENU_ROWS[menu_index][1]))
	elif panel == "cards":
		if code in [KEY_A, KEY_LEFT]:
			card_page -= 1
			_show_cards()
		elif code in [KEY_D, KEY_RIGHT]:
			card_page += 1
			_show_cards()
		elif code in [KEY_1, KEY_2, KEY_3]:
			take_card(code - KEY_1)
		elif code in [KEY_KP_1, KEY_KP_2, KEY_KP_3]:
			take_card(code - KEY_KP_1)

# --- The practice menu (F1; a gamepad's Start and Back) ---

## Opens the menu at its first row, the game paused as under the other lists.
func open_menu() -> void:
	menu_index = 0
	panel = "menu"
	get_tree().paused = true
	Engine.time_scale = 0.0
	info.visible = false
	_show_menu()

## The row chosen: the menu closes, then the row does what its key does.
func run_menu_row(row: String) -> void:
	close_panel()
	match row:
		"target":
			cycle_target()
		"bot":
			next_bot()
		"reset":
			reset_positions()
		"refill":
			refill()
		"monster":
			summon_monster()
		"cards":
			open_panel("cards")
		"clear":
			clear_cards()
		"skills":
			open_panel("skills")
		"leave":
			leave()

## The menu, drawn on the panel the skill list uses: the row chosen in gold.
func _show_menu() -> void:
	for child in skills_panel.get_children():
		skills_panel.remove_child(child)
		child.queue_free()
	var back := Panel.new()
	back.size = skills_panel.size
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(INK, 0.96)
	style.border_color = Color("59617c")
	style.set_border_width_all(2)
	back.add_theme_stylebox_override("panel", style)
	skills_panel.add_child(back)
	_skill_label(tr("Practice menu"), Rect2(28, 18, 564, 44), 30, GOLD)
	for index in MENU_ROWS.size():
		var chosen: bool = index == menu_index
		_skill_label((">  " if chosen else "    ") + tr(str(MENU_ROWS[index][0])), Rect2(40, 84.0 + index * 36.0, 540, 30), 20, GOLD if chosen else Color.WHITE)
	_skill_label(tr("Up / Down: choose    Enter: do it    Esc: close"), Rect2(28, skills_panel.size.y - 34.0, 564, 22), 14, DIM)
	skills_panel.visible = true

## With a pad in use the nine keys of the second practice line are no use: it names the button
## that opens the menu instead. Main calls this after update_hud; the lines are made whole again
## (the HUD may have broken the target line in two, so it is not cut out of info.text).
func show_pad_help() -> void:
	if is_instance_valid(info):
		_show_lines()

## Esc with no list open: back to the title.
func leave() -> void:
	main.session_mode = "battle_royale"
	main._reload_frontend("title")

# --- The practice lines of the HUD ---

func _build_hud() -> void:
	var hud: CanvasLayer = main.hud
	# The HUD's practice places: no survivors on the clock, the cards held in the soul row, and
	# these lines as a block at the bottom right over the control hints.
	hud.set_practice_layout()
	info = hud.build_practice_lines()
	skills_panel = Control.new()
	skills_panel.name = "PracticeSkills"
	skills_panel.position = Vector2(330, 110)
	skills_panel.size = Vector2(620, 470)
	skills_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skills_panel.visible = false
	hud.add_child(skills_panel)
	hud._pin(skills_panel, Vector2(0.5, 0.5))
	update_hud()

## Main calls this every frame of play (not while a list is open: the game is paused then).
func update_hud() -> void:
	if panel != "cards":
		main.hud.hide_card_offer()
	info.visible = panel == "" and main.hud.clock_label.visible
	_update_status()
	_show_lines()

## The target and the damage, then the keys, or the pad's menu button while a pad is in use
## (PadGlyphs.practice_line). The HUD breaks the lines to fit its block, so the second line is not
## read back out of info.text.
func _show_lines() -> void:
	main.hud.set_practice_lines(tr("Target: %s    Last hit %.1f HP    Total %.1f HP") % [target_name(), last_damage, total_damage] + "\n" + GLYPHS.practice_line(self, tr(KEY_HELP)))

## The match's survivors and souls to the next card are not practice's: the HUD's player plate
## shows the souls and the cards held instead.
func _update_status() -> void:
	if is_instance_valid(hero):
		main.hud.set_practice_status(hero.upgrades.size(), hero)

func _skill_label(text: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skills_panel.add_child(label)
	return label

## The select screen's kit text (FrontendMenu.KITS) over the match, row by row.
func _show_skills() -> void:
	for child in skills_panel.get_children():
		skills_panel.remove_child(child)
		child.queue_free()
	var back := Panel.new()
	back.size = skills_panel.size
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(INK, 0.96)
	style.border_color = Color("59617c")
	style.set_border_width_all(2)
	back.add_theme_stylebox_override("panel", style)
	skills_panel.add_child(back)
	var kit: Array = FRONTEND.KITS[str(hero.character_id)]
	_skill_label(tr(str(hero.display_name)).to_upper(), Rect2(28, 18, 564, 44), 30, GOLD)
	var about := _skill_label(tr(str(kit[0])), Rect2(28, 66, 564, 48), 15, DIM)
	about.size.y = about.get_line_count() * about.get_line_height()
	var keys: Array = ["J", "K", "L", "U", "I", "PASSIVE"] if kit.size() > 6 else ["J", "K", "L", "I", "PASSIVE"]
	var y := maxf(132.0, about.position.y + about.size.y + 16.0)
	for index in keys.size():
		_skill_label(tr(str(keys[index])), Rect2(28, y, 96, 24), 15, GOLD)
		var line := _skill_label(tr(str(kit[index + 1])), Rect2(128, y, 464, 44), 15, Color.WHITE)
		line.size.y = line.get_line_count() * line.get_line_height()
		y += maxf(40.0, line.size.y + 12.0)
	_skill_label(tr("Tab / Esc: close"), Rect2(28, skills_panel.size.y - 34.0, 564, 22), 14, DIM)
	skills_panel.visible = true
