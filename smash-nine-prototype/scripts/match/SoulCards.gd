extends RefCounted
## Soul growth card pool (design D4). Effects are PlayerBase.upgrade_modifiers keys:
## *_multiplier / *_scale multiply, bonus_* add. "kind" separates stat cards from
## cards that change how a character moves or survives.

const CARDS: Array[Dictionary] = [
	{"id": "power", "title": "Power", "kind": "stat", "text": "Attack +12%", "effects": {"attack_multiplier": 1.12}},
	{"id": "vitality", "title": "Vitality", "kind": "stat", "text": "Max HP +15, heal 15", "effects": {"bonus_max_hp": 15.0}},
	{"id": "swiftness", "title": "Swiftness", "kind": "stat", "text": "Move speed +8%", "effects": {"speed_multiplier": 1.08}},
	{"id": "anchor", "title": "Anchor", "kind": "stat", "text": "Knockback taken -15%", "effects": {"weight_multiplier": 1.15}},
	{"id": "sky_step", "title": "Sky Step", "kind": "action", "text": "+1 air jump", "effects": {"bonus_air_jumps": 1}},
	{"id": "last_stand", "title": "Last Stand", "kind": "action", "text": "Ring-out damage -30%", "effects": {"ringout_damage_scale": 0.7}}
]
const OFFER_SIZE := 3

## Three distinct cards drawn with the given RNG. Sky Step is offered at most twice per player.
static func draw_offer(rng: RandomNumberGenerator, owned: Array[String]) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for card in CARDS:
		if card.id == "sky_step" and owned.count("sky_step") >= 2:
			continue
		pool.append(card)
	var offer: Array[Dictionary] = []
	while offer.size() < OFFER_SIZE and not pool.is_empty():
		var index := rng.randi_range(0, pool.size() - 1)
		offer.append(pool[index])
		pool.remove_at(index)
	return offer

static func find(card_id: String) -> Dictionary:
	for card in CARDS:
		if card.id == card_id:
			return card
	return {}
