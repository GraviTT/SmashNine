extends RefCounted
## Skin identity owns behaviour; the old melee/ranged type remains a bot/art fallback.
const SKINS := {
	"mossling": "bite",
	"asgard_aegis_ram": "charge", "muspelheim_magma_boar": "charge",
	"niflheim_glacier_wolf": "leap", "alfheim_moon_stag": "leap", "vanaheim_vine_hound": "leap",
	"jotunheim_rune_golem": "slam", "yggdrasil_root_guardian": "slam",
	"svartalfheim_gear_beetle": "shell",
	"ember_imp": "bolt", "niflheim_frost_owl": "bolt", "jotunheim_storm_wisp": "bolt",
	"midgard_rooftop_slinger": "lob", "vanaheim_seed_sprite": "lob",
	"asgard_runic_raven": "swoop", "svartalfheim_cog_drone": "swoop",
	"alfheim_moon_moth": "blink", "yggdrasil_root_oracle": "homing",
}
## Wind-up seconds, engagement distance (unscaled), cooldown, damage per hit.
const PROFILES := {
	"bite": [0.32, 64.0, 1.05, 8.0],
	"charge": [0.65, 250.0, 2.5, 8.0],
	"leap": [0.55, 230.0, 2.6, 7.0],
	"slam": [0.9, 150.0, 3.0, 9.0],
	"shell": [0.65, 240.0, 2.7, 7.0],
	"bolt": [0.45, 310.0, 1.8, 6.0],
	"lob": [0.6, 330.0, 2.4, 5.0],
	"swoop": [0.65, 280.0, 3.0, 7.0],
	"blink": [0.7, 220.0, 2.8, 6.0],
	"homing": [0.7, 330.0, 2.8, 6.0],
}

static func archetype_for(skin: String, fallback: String) -> String:
	return str(SKINS.get(skin, "bolt" if fallback == "ember_imp" else "bite"))

static func title_for(skin: String) -> String:
	var parts := skin.split("_")
	if parts.size() > 1 and parts[0] in ["asgard", "midgard", "niflheim", "alfheim", "muspelheim", "svartalfheim", "vanaheim", "jotunheim", "yggdrasil"]:
		parts.remove_at(0)
	return " ".join(parts).capitalize()
