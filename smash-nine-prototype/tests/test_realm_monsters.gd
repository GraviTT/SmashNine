extends SceneTree
## CODEX-ART-25: every themed realm substitutes one generic behaviour with its own art skin.
## The other behaviour remains generic, and a missing skin file falls back to generic art.

const CATALOG := preload("res://scripts/realms/RealmCatalog.gd")
const SPAWNER_SCRIPT := preload("res://scripts/RealmMonsterSpawner.gd")
const MONSTER_SCRIPT := preload("res://scripts/RealmMonster.gd")

const EXPECTED := {
	0: {"skin": "asgard_aegis_ram", "kind": "melee"},
	2: {"skin": "niflheim_frost_owl", "kind": "ranged"},
	3: {"skin": "alfheim_moon_moth", "kind": "ranged"},
	5: {"skin": "svartalfheim_gear_beetle", "kind": "melee"},
	6: {"skin": "vanaheim_vine_hound", "kind": "melee"},
	7: {"skin": "jotunheim_rune_golem", "kind": "melee"},
	8: {"skin": "yggdrasil_root_oracle", "kind": "ranged"},
}

var failed := false
var arena: Node2D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	await _check_catalog_and_spawns()
	await _check_missing_skin_fallback()
	if failed:
		quit(1)
		return
	print("Realm monster tests passed (7 skins, generic pair preservation, missing-file fallback)")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	failed = true

func _check_catalog_and_spawns() -> void:
	var maps := CATALOG.build_maps()
	var spawner := Node.new()
	spawner.set_script(SPAWNER_SCRIPT)
	arena.add_child(spawner)
	spawner.configure(func(_realm: int) -> Array: return [Vector2.ZERO], func() -> Array: return EXPECTED.keys())
	for realm_index: int in EXPECTED:
		var expected: Dictionary = EXPECTED[realm_index]
		if maps[realm_index].get("monster", {}) != expected:
			_fail("Realm %d catalog monster is %s, expected %s" % [realm_index, maps[realm_index].get("monster", {}), expected])
			continue
		spawner._spawn_missing_for_realm(realm_index)
		var monsters: Array = spawner.monsters_by_realm.get(realm_index, [])
		var themed := 0
		var generic_other := 0
		for monster: Node in monsters:
			if monster.skin_id == expected.skin:
				themed += 1
				var expected_type := "mossling" if expected.kind == "melee" else "ember_imp"
				if monster.monster_type != expected_type:
					_fail("%s changed behaviour kind to %s" % [expected.skin, monster.monster_type])
			elif monster.skin_id == monster.monster_type:
				generic_other += 1
		if themed != 2 or generic_other != 2:
			_fail("Realm %d should spawn 2 themed + 2 generic-other monsters, got %d + %d" % [realm_index, themed, generic_other])
	spawner.queue_free()
	await process_frame

func _check_missing_skin_fallback() -> void:
	var monster := CharacterBody2D.new()
	monster.set_script(MONSTER_SCRIPT)
	monster.setup("ember_imp", 0, Vector2.ZERO, "missing_skin_for_test")
	arena.add_child(monster)
	await process_frame
	if monster.art_sprite == null:
		_fail("A missing custom skin should fall back to the generic ranged sheet")
	else:
		var frame: AtlasTexture = monster.art_sprite.sprite_frames.get_frame_texture(&"idle", 0)
		if frame.atlas.resource_path != "res://assets/art/monsters/ember_imp_sheet.png":
			_fail("Missing skin fallback loaded %s" % frame.atlas.resource_path)
	monster.queue_free()
	await process_frame
