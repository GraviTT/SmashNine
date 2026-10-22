extends RefCounted
## D43 data only. Stage numbers are 1-based; realm indices are RealmCatalog indices.
const REALMS := preload("res://scripts/realms/RealmCatalog.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
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
			waves = [[{"kind": "melee", "skin": skins.melee, "hostile": true}, {"kind": "ranged", "skin": skins.ranged, "hostile": true}]]
		elif number == 7:
			waves = [[{"kind": "boss", "skin": skins.melee, "hostile": true}]]
		else:
			waves = [[{"kind": "shadows", "hp": 0.6}], [{"kind": "hero_shadow", "hp": 1.5, "cards": 3}]]
		var dialogue := _dialogue(number)
		result.append({
			"id": number, "realm": realm, "exit": EXITS[index],
			"title": prefix + ".title", "goal": prefix + ".goal", "tips": [prefix + ".tip.1", prefix + ".tip.2"],
			"rival": rival, "home_elite": skins.melee, "waves": waves,
			"rules": {"damage_scale": 0.3 if number == 1 else 0.4, "ringout_damage": 15.0 if number == 1 else (30.0 if number == 9 else (25.0 if number in [6, 8] else 20.0)), "recovery": 3.0 if number == 1 else 1.5, "aggression": 1.0, "hazards": true, "escape_seconds": 60.0 if number == 5 else 0.0, "shrink": number == 9, "intermission_heal": 0.3 if number == 9 else 0.0},
			"rival_mods": {"hp": 0.8 if number == 2 else (1.2 if number == 6 else (1.3 if number == 8 else 1.0)), "cards": ["power"] if number == 6 else (["power", "sky_step"] if number == 8 else [])},
			"objective": "crystals" if number == 5 else ("boss" if number == 7 else ("shadows" if number == 9 else "defeat")),
			"crystals": 3 if number == 5 else 0,
			"reinforcements": {"interval": 20.0, "count": 2, "limit": 4, "skin": skins.ranged} if number == 7 else {},
			"shadow_band": {"seconds": 60.0, "fraction": 0.2, "damage": 8.0} if number == 9 else {},
			"souls_reward": 15 if rival != "" else 0, "dialogue": dialogue, "ready": true
		})
	return result

## The script of design/STORY.md: [speaker, story.csv ID] per line. Rival stages open with the
## rival (Nova and Yuki size the hero up before the hero answers); a hero meeting their own home
## realm gets the home lines instead. Stage 9's shadow lines come with the shadow stage (SYS-04).
static func _dialogue(number: int) -> Dictionary:
	var prefix := "story.s%02d" % number
	var lines := {"home_pre": [], "home_post": []}
	match number:
		1:
			lines.pre = [["narrator", prefix + ".pre.1"], ["narrator", prefix + ".pre.2"], ["narrator", prefix + ".pre.3"], ["hero", "story.voice.{hero}.arrive"], ["narrator", prefix + ".pre.4"]]
			lines.post = [["narrator", prefix + ".post.1"], ["narrator", prefix + ".post.2"]]
		5, 7:
			lines.pre = [["narrator", prefix + ".pre.1"], ["narrator", prefix + ".pre.2"]]
			lines.post = [["narrator", prefix + ".post.1"]]
		9:
			lines.pre = [["narrator", prefix + ".pre.1"], ["narrator", prefix + ".pre.2"]]
			lines.mid = [["narrator", prefix + ".mid.1"], ["shadow", "story.shadow.{hero}.1"], ["hero", "story.voice.{hero}.echo", {"cg": "", "face": "angry"}], ["shadow", "story.shadow.{hero}.2"]]
			lines.post = [["narrator", prefix + ".post.1"], ["narrator", prefix + ".post.2"]]
		_:
			lines.pre = [["rival", prefix + ".pre.1"], ["hero", "story.voice.{hero}.challenge", {"cg": "", "face": "angry"}], ["rival", prefix + ".pre.2"]]
			if number in [6, 8]:
				lines.pre = [["rival", prefix + ".pre.1"], ["rival", prefix + ".pre.2"], ["hero", "story.voice.{hero}.challenge", {"cg": "", "face": "angry"}]]
			lines.post = [["rival", prefix + ".post.1"], ["rival", prefix + ".post.2"], ["hero", "story.voice.{hero}.victory"]]
			lines.home_pre = [["hero", prefix + ".home.pre.1"], ["hero", prefix + ".home.pre.2"]]
			lines.home_post = [["hero", prefix + ".home.post.1"], ["hero", prefix + ".home.post.2"]]
	# Sparse face tags; all other lines keep the neutral face. Empty cg keeps the
	# existing third-field scene-picture metadata contract.
	match number:
		2:
			lines.pre[0].append({"cg": "", "face": "angry"})
			lines.pre[2].append({"cg": "", "face": "angry"})
			lines.home_pre[1].append({"cg": "", "face": "angry"})
		3:
			lines.pre[2].append({"cg": "", "face": "happy"})
			lines.home_pre[1].append({"cg": "", "face": "angry"})
			lines.home_post[1].append({"cg": "", "face": "hurt"})
		4:
			lines.pre[0].append({"cg": "", "face": "happy"})
			lines.home_pre[1].append({"cg": "", "face": "angry"})
		8:
			lines.home_pre[1].append({"cg": "", "face": "hurt"})
	# Scene pictures (ART-70, StoryDialogue) behind the prologue, the opened root seal and the calm heart.
	match number:
		1:
			for index in 3:
				lines.pre[index].append({"cg": "prologue"})
		8:
			for line: Array in lines.post + lines.home_post:
				line.append({"cg": "root"})
		9:
			for line: Array in lines.post:
				line.append({"cg": "epilogue"})
	return lines

static func stage(number: int) -> Dictionary:
	return stages()[clampi(number, 1, 9) - 1]

static func is_home(data: Dictionary, hero: String) -> bool:
	return data.rival != "" and data.rival == hero

static func waves_for(data: Dictionary, hero: String) -> Array:
	if int(data.id) == 9:
		var shadows: Array = []
		var group: Dictionary = data.waves[0][0]
		var own: Dictionary = data.waves[1][0]
		for id in REGISTRY.get_character_ids():
			if id != hero:
				shadows.append({"kind": "shadow", "id": id, "hp": float(group.hp), "cards": int(group.get("cards", 0))})
		return [shadows, [{"kind": "shadow", "id": hero, "hp": float(own.hp), "cards": int(own.cards)}]]
	if not is_home(data, hero):
		return data.waves.duplicate(true)
	var skins: Dictionary = REALMS.build_maps()[data.realm].monsters
	return [[{"kind": "melee", "skin": data.home_elite, "elite": true}, {"kind": "melee", "skin": skins.melee}, {"kind": "ranged", "skin": skins.ranged}]]

static func dialogue_for(data: Dictionary, hero: String, scene: String) -> Array:
	return data.dialogue.get(("home_" if is_home(data, hero) else "") + scene, []).duplicate(true)

static func ending_ids(hero: String) -> Array[String]:
	return ["story.ending.%s.1" % hero, "story.ending.%s.2" % hero, "story.ending.%s.3" % hero]

static func resolve_id(id: String, hero: String, rival: String) -> String:
	return id.replace("{hero}", hero).replace("{rival}", rival)
