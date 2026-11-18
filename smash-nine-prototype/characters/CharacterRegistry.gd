extends RefCounted

const ENTRIES := {
	"frey": {
		"scene": preload("res://characters/frey/Frey.tscn"),
		"data": preload("res://characters/frey/FreyData.gd")
	},
	"yuki": {
		"scene": preload("res://characters/yuki/Yuki.tscn"),
		"data": preload("res://characters/yuki/YukiData.gd")
	},
	"luna": {
		"scene": preload("res://characters/luna/Luna.tscn"),
		"data": preload("res://characters/luna/LunaData.gd")
	},
	"nova": {
		"scene": preload("res://characters/nova/Nova.tscn"),
		"data": preload("res://characters/nova/NovaData.gd")
	},
	"rio": {
		"scene": preload("res://characters/rio/Rio.tscn"),
		"data": preload("res://characters/rio/RioData.gd")
	},
	"xion": {
		"scene": preload("res://characters/xion/Xion.tscn"),
		"data": preload("res://characters/xion/XionData.gd")
	}
}

static func get_characters() -> Dictionary:
	var result := {}
	for character_id in ENTRIES:
		result[character_id] = ENTRIES[character_id].data.get_data()
	return result

static func get_scene(character_id: String) -> PackedScene:
	if not ENTRIES.has(character_id):
		return null
	return ENTRIES[character_id].scene as PackedScene

static func get_character_ids() -> Array[String]:
	var result: Array[String] = []
	result.assign(ENTRIES.keys())
	return result

## The heroes story mode offers: data "story": false keeps a character out until its story is
## written (Xion, 2026-11-18; D43).
static func get_story_character_ids() -> Array[String]:
	var result: Array[String] = []
	for character_id in ENTRIES:
		if bool(ENTRIES[character_id].data.get_data().get("story", true)):
			result.append(character_id)
	return result

## Body types a character is drawn in (user 2026-10-07: female characters female only,
## male characters both). Data without "bodies" means one female body.
static func get_bodies(character_id: String) -> Array[String]:
	var result: Array[String] = ["female"]
	if ENTRIES.has(character_id):
		result.assign(ENTRIES[character_id].data.get_data().get("bodies", ["female"]))
	return result
