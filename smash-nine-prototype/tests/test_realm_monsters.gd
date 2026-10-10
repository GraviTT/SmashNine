extends SceneTree
## CODEX-ART-31: every realm supplies art for both unchanged generic behaviours.
## A missing skin file still falls back to the corresponding generic art.

const CATALOG := preload("res://scripts/realms/RealmCatalog.gd")
const SPAWNER_SCRIPT := preload("res://scripts/RealmMonsterSpawner.gd")
const MONSTER_SCRIPT := preload("res://scripts/RealmMonster.gd")

const EXPECTED := {
	0: {"melee": "asgard_aegis_ram", "ranged": "asgard_runic_raven"},
	1: {"melee": "mossling", "ranged": "midgard_rooftop_slinger"},
	2: {"melee": "niflheim_glacier_wolf", "ranged": "niflheim_frost_owl"},
	3: {"melee": "alfheim_moon_stag", "ranged": "alfheim_moon_moth"},
	4: {"melee": "muspelheim_magma_boar", "ranged": "ember_imp"},
	5: {"melee": "svartalfheim_gear_beetle", "ranged": "svartalfheim_cog_drone"},
	6: {"melee": "vanaheim_vine_hound", "ranged": "vanaheim_seed_sprite"},
	7: {"melee": "jotunheim_rune_golem", "ranged": "jotunheim_storm_wisp"},
	8: {"melee": "yggdrasil_root_guardian", "ranged": "yggdrasil_root_oracle"},
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
	print("Realm monster tests passed (9 themed pairs, behaviour preservation, missing-file fallback)")
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
		if maps[realm_index].get("monsters", {}) != expected:
			_fail("Realm %d catalog monsters are %s, expected %s" % [realm_index, maps[realm_index].get("monsters", {}), expected])
			continue
		spawner._spawn_missing_for_realm(realm_index)
		var monsters: Array = spawner.monsters_by_realm.get(realm_index, [])
		var melee := 0
		var ranged := 0
		for monster: Node in monsters:
			if monster.monster_type == "mossling" and monster.skin_id == expected.melee:
				melee += 1
			elif monster.monster_type == "ember_imp" and monster.skin_id == expected.ranged:
				ranged += 1
			else:
				_fail("Realm %d mismatched behaviour/skin: %s / %s" % [realm_index, monster.monster_type, monster.skin_id])
		if melee != 2 or ranged != 2:
			_fail("Realm %d should spawn 2 melee + 2 ranged themed monsters, got %d + %d" % [realm_index, melee, ranged])
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
