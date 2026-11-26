extends RefCounted
## Soul growth card pool (design D4; 19 cards since D54, 2026-11-25: the user's "카드는 추천대로 해"
## on reports/soul-cards-2026-11-24/).
## "kind" is what the offer screen shows and what the offer rules read:
##   stat       a number goes up
##   action     the fighter can do something new, or something happens when it does (any fighter)
##   character  one fighter's own card ("character" names whose); nobody else is offered it
## "effects" are PlayerBase.upgrade_modifiers keys: *_multiplier and *_scale multiply, bonus_* add.
## A card with no effects is read by its id where it acts (PlayerBase.has_card).
## A card with "max_stacks" is not offered again once the player owns that many (Last Stand x3 cut
## sudden-death ring-outs 40 -> 14); every action and character card of D54 is taken once.

const CARDS: Array[Dictionary] = [
	{"id": "power", "title": "Power", "kind": "stat", "text": "Attack +12%", "effects": {"attack_multiplier": 1.12}},
	{"id": "vitality", "title": "Vitality", "kind": "stat", "text": "Max HP +15, heal 15", "effects": {"bonus_max_hp": 15.0}},
	{"id": "swiftness", "title": "Swiftness", "kind": "stat", "text": "Move speed +8%", "effects": {"speed_multiplier": 1.08}},
	{"id": "anchor", "title": "Anchor", "kind": "stat", "text": "Knockback taken -15%", "effects": {"weight_multiplier": 1.15}},
	{"id": "sky_step", "title": "Sky Step", "kind": "action", "text": "+1 air jump", "effects": {"bonus_air_jumps": 1}, "max_stacks": 2},
	# A stat card in the pool the user approved (D54); it was shown as an action card before.
	{"id": "last_stand", "title": "Last Stand", "kind": "stat", "text": "Ring-out damage -30%", "effects": {"ringout_damage_scale": 0.7}, "max_stacks": 1},
	# Common action cards (D54).
	{"id": "air_dash", "title": "Air Dash", "kind": "action", "text": "In the air, the guard key dashes a short way ahead. Once before landing", "effects": {}, "max_stacks": 1},
	{"id": "meteor_landing", "title": "Meteor Landing", "kind": "action", "text": "Landing from a height sends out a shockwave that lifts foes", "effects": {}, "max_stacks": 1},
	{"id": "riposte", "title": "Riposte", "kind": "action", "text": "A successful parry stuns that foe for 1 s", "effects": {}, "max_stacks": 1},
	{"id": "soul_drain", "title": "Soul Drain", "kind": "action", "text": "Eliminating a foe heals 25 HP", "effects": {}, "max_stacks": 1},
	{"id": "last_flame", "title": "Last Flame", "kind": "action", "text": "At 30% HP or less: attack +25%, move speed +10%", "effects": {}, "max_stacks": 1},
	{"id": "chaser", "title": "Chaser", "kind": "action", "text": "After sending a foe flying: +30% move speed for 2 s", "effects": {}, "max_stacks": 1},
	{"id": "hunter", "title": "Hunter", "kind": "action", "text": "Monsters take 50% more from you. Monsters and crystals give 50% more souls", "effects": {"monster_damage_multiplier": 1.5, "hunt_soul_multiplier": 1.5}, "max_stacks": 1},
	{"id": "overcharge", "title": "Overcharge", "kind": "action", "text": "Ultimate cooldown 30 s -> 22 s", "effects": {"ultimate_cooldown_scale": 22.0 / 30.0}, "max_stacks": 1},
	# One card for each fighter with a new kit (D54). Yuki's comes with her new kit.
	{"id": "second_wingbeat", "title": "Second Wingbeat", "kind": "character", "character": "frey", "text": "Valkyrie's wings can be used twice in the air", "effects": {}, "max_stacks": 1},
	{"id": "twin_stars", "title": "Twin Stars", "kind": "character", "character": "luna", "text": "When J's big star bursts, two more small stars fly out", "effects": {}, "max_stacks": 1},
	{"id": "deep_gravity", "title": "Deep Gravity", "kind": "character", "character": "nova", "text": "Gravity field 6 s -> 9 s, cooldown 12 s -> 10 s", "effects": {}, "max_stacks": 1},
	{"id": "second_decoy", "title": "Second Decoy", "kind": "character", "character": "rio", "text": "You can swap places with the decoy twice", "effects": {}, "max_stacks": 1},
	{"id": "extended_magazine", "title": "Extended Magazine", "kind": "character", "character": "xion", "text": "Magazine 10 rounds -> 14 rounds", "effects": {}, "max_stacks": 1}
]
const OFFER_SIZE := 3
## The kinds that change how a fighter plays: every offer holds at least one (D54).
const ACTION_KINDS: Array[String] = ["action", "character"]
## The fighter's own card is in this offer for certain, when it has one it does not own (D54).
const CHARACTER_CARD_PICK := 2

## The cards `character_id` can be offered now: the common ones and its own, less those it already
## holds as many of as it may. An empty id (a caller that knows no fighter) leaves the own cards out.
static func available(owned: Array[String], character_id := "") -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for card in CARDS:
		if card.has("character") and str(card.character) != character_id:
			continue
		if card.has("max_stacks") and owned.count(card.id) >= int(card.max_stacks):
			continue
		pool.append(card)
	return pool

## Three distinct cards drawn with the given RNG (D54):
## - the fighter's own card, in its offer number CHARACTER_CARD_PICK (`pick_number` counts from 1);
## - at least one action or character card;
## - the rest from everything left.
## The three are then put in a drawn order, so that the card an offer must hold has no fixed place
## (a person who lets the time run out takes the first).
static func draw_offer(rng: RandomNumberGenerator, owned: Array[String], character_id := "", pick_number := 0) -> Array[Dictionary]:
	var pool := available(owned, character_id)
	var offer: Array[Dictionary] = []
	if pick_number == CHARACTER_CARD_PICK:
		for card in pool:
			if card.kind == "character":
				offer.append(card)
				pool.erase(card)
				break
	if offer.is_empty():
		var actions: Array[Dictionary] = []
		for card in pool:
			if ACTION_KINDS.has(str(card.kind)):
				actions.append(card)
		if not actions.is_empty():
			var card: Dictionary = actions[rng.randi_range(0, actions.size() - 1)]
			offer.append(card)
			pool.erase(card)
	while offer.size() < OFFER_SIZE and not pool.is_empty():
		var index := rng.randi_range(0, pool.size() - 1)
		offer.append(pool[index])
		pool.remove_at(index)
	for index in range(offer.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var held: Dictionary = offer[index]
		offer[index] = offer[other]
		offer[other] = held
	return offer

static func find(card_id: String) -> Dictionary:
	for card in CARDS:
		if card.id == card_id:
			return card
	return {}
