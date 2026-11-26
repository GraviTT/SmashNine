extends "res://tests/soak_match.gd"
## Soul card ablation (2026-11-26, D54): the same bot match with other cards on offer, to see what
## moves a result (with the nineteen cards and their offer rules Xion's bots fell from 8 wins in 48
## matches to none, and Frey's rose from 3 to 8). Nothing in the game changes: an offer is rewritten
## in place when it opens, before the bot takes its pick.
## Usage: <godot> --headless --path . --fixed-fps 60 -s tests/analysis/lead/card_ban_probe.gd -- --seconds=480 --seed=2001 [--ban=...] [--offer=...]
##   --ban=chaser,meteor_landing   those cards are replaced by one that is not banned and not in the
##       offer, of the same kind when there is one (so the offer keeps its action card). --ban=new
##       stands for the thirteen cards of D54, --ban=character for the five character cards.
##   --offer=old    every offer is three different cards drawn at random from the six cards of
##       before D54 that the fighter may still take: the pool and the rule of before.
##   --offer=plain  three different cards at random from all the fighter may take: the nineteen
##       cards without the rules (no action card for certain, no own card in the second offer).
## With neither the match must replay tests/soak_match.gd.
## The SOAK_RESULT line gains "banned", "offer", "swapped" (cards replaced), "big_stars" (big stars
## Luna's bots fired: the fourth J of a volley), "out_order" (player ids in the order they went out)
## and "seats": for every fighter its character, damage dealt, knock-outs, ring-outs taken and the
## cards it took.

const CARDS := preload("res://scripts/match/SoulCards.gd")
const OLD_CARDS: Array[String] = ["power", "vitality", "swiftness", "anchor", "sky_step", "last_stand"]

var banned: Array[String] = []
var offer_mode := ""
var swapped := 0
var hooked := false
var swap_rng := RandomNumberGenerator.new()
var out_players: Array[int] = []
var big_stars := 0
## Per Luna (instance id): her volley step a frame ago.
var volley_step: Dictionary = {}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--offer="):
			offer_mode = arg.get_slice("=", 1)
			if not ["old", "plain"].has(offer_mode):
				push_error("--offer must be old or plain; got %s" % offer_mode)
				quit(2)
				return
		elif arg.begins_with("--ban="):
			for id in arg.get_slice("=", 1).split(",", false):
				if id == "new":
					for card in CARDS.CARDS:
						if not OLD_CARDS.has(str(card.id)):
							banned.append(str(card.id))
				elif id == "character":
					for card in CARDS.CARDS:
						if card.kind == "character":
							banned.append(str(card.id))
				elif CARDS.find(id).is_empty():
					push_error("--ban: no card %s" % id)
					quit(2)
					return
				else:
					banned.append(id)
	super._initialize()

## soak_match.gd calls this once a physics frame, at the frame's start: the first call comes
## before any fighter has souls.
func _check_positions() -> void:
	super._check_positions()
	_count_big_stars()
	if hooked:
		return
	hooked = true
	swap_rng.seed = hash([seed_value, "card_ban"])
	main.soul_growth.offer_opened.connect(_on_offer_opened)

## Luna's volley step goes 0, 1, 2, 3 and back to 0 with the big star (a pause starts it over at
## 1 with the next small star): a step from 3 to 0 is a big star fired.
func _count_big_stars() -> void:
	for player in main.players:
		if not is_instance_valid(player) or str(player.character_id) != "luna":
			continue
		var step := int(player.star_volley_step)
		if int(volley_step.get(player.get_instance_id(), 0)) == 3 and step == 0:
			big_stars += 1
		volley_step[player.get_instance_id()] = step

## The offer's own array (SoulGrowth holds the same one), rewritten in place.
func _on_offer_opened(player: Node, cards: Array) -> void:
	if offer_mode != "":
		var pool: Array[Dictionary] = []
		for card in CARDS.available(player.upgrades, str(player.character_id)):
			if offer_mode == "plain" or OLD_CARDS.has(str(card.id)):
				pool.append(card)
		var size := cards.size()
		cards.clear()
		while cards.size() < size and not pool.is_empty():
			var index := swap_rng.randi_range(0, pool.size() - 1)
			cards.append(pool[index])
			pool.remove_at(index)
		swapped += size
		return
	if banned.is_empty():
		return
	for index in cards.size():
		if not banned.has(str(cards[index].id)):
			continue
		var held: Array[String] = []
		for card in cards:
			held.append(str(card.id))
		var same_kind: Array[Dictionary] = []
		var any_kind: Array[Dictionary] = []
		for card in CARDS.available(player.upgrades, str(player.character_id)):
			if banned.has(str(card.id)) or held.has(str(card.id)):
				continue
			any_kind.append(card)
			if CARDS.ACTION_KINDS.has(str(card.kind)) == CARDS.ACTION_KINDS.has(str(cards[index].kind)):
				same_kind.append(card)
		var pool := same_kind if not same_kind.is_empty() else any_kind
		if pool.is_empty():
			continue
		cards[index] = pool[swap_rng.randi_range(0, pool.size() - 1)]
		swapped += 1

func _on_defeated(player: Node, attacker: Node) -> void:
	super._on_defeated(player, attacker)
	out_players.append(int(player.player_id))

func _collect_result(finished_early: bool) -> Dictionary:
	var result := super._collect_result(finished_early)
	result["banned"] = banned
	result["offer"] = offer_mode
	result["swapped"] = swapped
	result["big_stars"] = big_stars
	var seats: Array = []
	for player in main.players:
		if not is_instance_valid(player):
			continue
		seats.append({"name": str(player.display_name), "id": str(player.character_id), "player": int(player.player_id), "out": bool(player.is_defeated), "damage": snappedf(float(player.damage_dealt), 0.1), "kos": int(player.score), "ringouts": int(player.respawn_count), "cards": player.upgrades.duplicate()})
	result["seats"] = seats
	result["out_order"] = out_players
	return result
