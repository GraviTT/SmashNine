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
