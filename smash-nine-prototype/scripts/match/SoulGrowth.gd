extends Node
## Turns soul thresholds into card offers (design D4). The match never pauses:
## a human has CHOICE_TIME seconds to press 1-3, then the first card is taken;
## bots pick after BOT_THINK_TIME from a seeded RNG, so a seed replays the same picks.

signal offer_opened(player: Node, cards: Array[Dictionary])
signal offer_closed(player: Node, card: Dictionary, auto_picked: bool)

const SOUL_CARDS := preload("res://scripts/match/SoulCards.gd")
const CHOICE_TIME := 5.0
const BOT_THINK_TIME := 0.6

var match_seed := 0
## player -> {"cards": Array[Dictionary], "time_left": float}
var active_offers: Dictionary = {}
## player -> number of offers still waiting behind the active one
var queued_offers: Dictionary = {}
var _rngs: Dictionary = {}

func register_player(player: Node) -> void:
	player.soul_threshold_reached.connect(_on_threshold_reached)
	player.defeated.connect(_on_player_defeated)

func _on_threshold_reached(player: Node, _pick_number: int) -> void:
	if active_offers.has(player):
		queued_offers[player] = int(queued_offers.get(player, 0)) + 1
		return
	_open_offer(player)

func _open_offer(player: Node) -> void:
	var cards: Array[Dictionary] = SOUL_CARDS.draw_offer(_rng_for(player), player.upgrades)
	if cards.is_empty():
		return
	active_offers[player] = {"cards": cards, "time_left": CHOICE_TIME if player.is_human else BOT_THINK_TIME}
	offer_opened.emit(player, cards)

func _rng_for(player: Node) -> RandomNumberGenerator:
	if not _rngs.has(player):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([match_seed, player.player_id, "souls"])
		_rngs[player] = rng
	return _rngs[player]

func _process(delta: float) -> void:
	for player in active_offers.keys():
		if not is_instance_valid(player):
			active_offers.erase(player)
			continue
		var offer: Dictionary = active_offers[player]
		offer.time_left = float(offer.time_left) - delta
		if offer.time_left <= 0.0:
			var index := 0 if player.is_human else _rng_for(player).randi_range(0, offer.cards.size() - 1)
			_close_offer(player, index, player.is_human)

## Human choice (0-based index into the active offer). Returns false when there is no offer.
func choose(player: Node, index: int) -> bool:
	if not active_offers.has(player):
		return false
	var cards: Array = active_offers[player].cards
	if index < 0 or index >= cards.size():
		return false
	_close_offer(player, index, false)
	return true

func get_offer(player: Node) -> Dictionary:
	return active_offers.get(player, {})

func _close_offer(player: Node, index: int, auto_picked: bool) -> void:
	var offer: Dictionary = active_offers[player]
	active_offers.erase(player)
	var card: Dictionary = offer.cards[index]
	player.apply_upgrade(card)
	offer_closed.emit(player, card, auto_picked)
	var waiting := int(queued_offers.get(player, 0))
	if waiting > 0:
		queued_offers[player] = waiting - 1
		_open_offer(player)

func _on_player_defeated(player: Node, _attacker: Node) -> void:
	active_offers.erase(player)
	queued_offers.erase(player)
