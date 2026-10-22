extends RefCounted
## D43 data only. Stage numbers are 1-based; realm indices are RealmCatalog indices.
const REALMS := preload("res://scripts/realms/RealmCatalog.gd")
const ORDER := [1, 0, 3, 5, 6, 7, 4, 2, 8]
const RIVALS := ["", "frey", "luna", "rio", "", "nova", "", "yuki", ""]
const EXITS := [Vector2i.LEFT, Vector2i.DOWN, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.UP, Vector2i.UP, Vector2i.ZERO, Vector2i.ZERO]

static func stages() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var realms := REALMS.build_maps()
	for index in 9:
		var number := index + 1
		var prefix := "story.s%02d" % number
		var realm: int = ORDER[index]
		var rival: String = RIVALS[index]
		var skins: Dictionary = realms[realm].monsters
		var waves: Array = []
		if number == 1:
			waves = [[{"kind": "melee", "skin": skins.melee}, {"kind": "ranged", "skin": skins.ranged}], [{"kind": "melee", "skin": skins.melee}, {"kind": "ranged", "skin": skins.ranged}]]
		elif rival != "":
			waves = [[{"kind": "rival", "id": rival}]]
		elif number == 5:
			waves = [[{"kind": "crystal", "count": 3}, {"kind": "melee", "skin": skins.melee, "aggressive": true}, {"kind": "ranged", "skin": skins.ranged, "aggressive": true}]]
		elif number == 7:
			waves = [[{"kind": "boss", "skin": skins.melee, "scale": 2.0, "elite_hp": 4.0}, {"kind": "ranged", "skin": skins.ranged}]]
		else:
			waves = [[{"kind": "shadows", "hp": 0.6}], [{"kind": "hero_shadow", "hp": 1.5, "cards": 3}]]
		var dialogue := {"pre": [["narrator", prefix + ".pre.1"], ["hero", "story.voice.{hero}.challenge"]], "post": [["hero", "story.voice.{hero}.victory"], ["narrator", prefix + ".post.1"]], "home_pre": [["hero", prefix + ".home_pre.1"]], "home_post": [["hero", prefix + ".home_post.1"]]}
		if rival != "":
			dialogue.pre.append(["rival", "story.voice.{rival}.challenge"])
		result.append({
			"id": number, "realm": realm, "exit": EXITS[index],
			"title": prefix + ".title", "goal": prefix + ".goal", "tips": [prefix + ".tip.1", prefix + ".tip.2"],
			"rival": rival, "home_elite": skins.melee, "waves": waves,
			"rules": {"damage_scale": 0.3 if number == 1 else 0.4, "ringout_damage": 15.0 if number == 1 else (30.0 if number == 9 else (25.0 if number in [6, 8] else 20.0)), "recovery": 3.0 if number == 1 else 1.5, "aggression": 1.0, "hazards": true, "escape_seconds": 60.0 if number == 5 else 0.0, "shrink": number == 9, "intermission_heal": 0.3 if number == 9 else 0.0},
			"rival_mods": {"hp": 0.8 if number == 2 else (1.2 if number == 6 else (1.3 if number == 8 else 1.0)), "cards": ["power"] if number == 6 else (["power", "sky_step"] if number == 8 else [])},
			"souls_reward": 15 if rival != "" else 0, "dialogue": dialogue, "ready": number <= 4
		})
	return result

static func stage(number: int) -> Dictionary:
	return stages()[clampi(number, 1, 9) - 1]

static func is_home(data: Dictionary, hero: String) -> bool:
	return data.rival != "" and data.rival == hero

static func waves_for(data: Dictionary, hero: String) -> Array:
	if not is_home(data, hero):
		return data.waves.duplicate(true)
	var skins: Dictionary = REALMS.build_maps()[data.realm].monsters
	return [[{"kind": "melee", "skin": data.home_elite, "elite": true}, {"kind": "melee", "skin": skins.melee}, {"kind": "ranged", "skin": skins.ranged}]]

static func dialogue_for(data: Dictionary, hero: String, scene: String) -> Array:
	return data.dialogue[("home_" if is_home(data, hero) else "") + scene].duplicate(true)

static func resolve_id(id: String, hero: String, rival: String) -> String:
	return id.replace("{hero}", hero).replace("{rival}", rival)
