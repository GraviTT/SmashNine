extends RefCounted
## Names shown for fighters when one character takes several seats (2026-11-27, the lead's pick A
## of the three ways compared in reports/ui-nine-sixteen-2026-11-27): a fighter whose name another
## fighter in the match shares takes a number after it ("Nova 2"), counted in the seat order the
## match began with. P1 counts in that order but shows as "P1 Frey" without a number, so bots of
## P1's character start at 2. Main numbers the seats once when a battle royale (or a bots-only
## match) starts; every place that shows a fighter's name asks here, so the overhead name, the
## announcements, the bot panel and the results carry the same number.

const META := "name_number"

## Gives each fighter whose name is shared its place among the fighters with that name, in the
## array's (seat) order; a fighter with a name of its own has no number. Returns the fighters whose
## number changed, so their overhead names can be drawn again.
static func number_doubles(fighters: Array) -> Array:
	var counts := {}
	for fighter in fighters:
		if is_instance_valid(fighter):
			var key := str(fighter.display_name)
			counts[key] = int(counts.get(key, 0)) + 1
	var seen := {}
	var changed: Array = []
	for fighter in fighters:
		if not is_instance_valid(fighter):
			continue
		var key := str(fighter.display_name)
		var number := 0
		if int(counts[key]) > 1:
			number = int(seen.get(key, 0)) + 1
			seen[key] = number
		if number != number_of(fighter):
			changed.append(fighter)
		fighter.set_meta(META, number)
	return changed

## The fighter's number among the fighters sharing its name, 0 when it has none.
static func number_of(fighter) -> int:
	if not is_instance_valid(fighter) or not fighter.has_meta(META):
		return 0
	return int(fighter.get_meta(META))

## " 2" after a numbered bot's name; nothing for P1, for a fighter with a name of its own or for a
## monster.
static func suffix(fighter) -> String:
	if not is_instance_valid(fighter) or fighter.get("is_human") == true:
		return ""
	var number := number_of(fighter)
	return " %d" % number if number > 0 else ""

## The name as the player reads it, in the game's language: "노바 2", "Nova 2"; P1 and a fighter
## with a name of its own show the name alone.
static func shown(fighter) -> String:
	if not is_instance_valid(fighter):
		return ""
	return str(TranslationServer.translate(str(fighter.display_name))) + suffix(fighter)

## The English name with its number ("Nova 2"), for the bot panel and the debug lines, which stay
## in English.
static func plain(fighter) -> String:
	if not is_instance_valid(fighter):
		return ""
	return str(fighter.display_name) + suffix(fighter)
