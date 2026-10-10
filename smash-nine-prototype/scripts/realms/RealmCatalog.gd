extends RefCounted
## Static realm definitions (design/DECISIONS.md D5, D6): name, grid cell, theme,
## colours, size, platforms, spawn points and portal stand points.
## Coordinates are local to one tile of `size`; `tiles` repeats the tile (1x1 by default).
## Rises between standable platforms stay under the bots' 185 px jump reach.
## The numbers here are the authored 1280x720 layouts; RealmLayout reads them through
## scaled_maps(), which grows positions and spans by GameScale.WORLD (platform thickness,
## hazard heights of bush tops and bridge thickness stay: fighters keep their size).
## "hazard" (optional) is read by RealmHazards: ice (floor traction), eruption (telegraphed
## fire pillars on platforms), quake (telegraphed stun for everyone on the ground), bushes
## (standing in one hides a fighter; "spots" are bush bottoms on platform tops), beams
## (telegraphed light columns that stun), vines (a temporary one-way bridge; "bridges"
## are realm-local rects).

const PLATFORM_MAIN := "main"
const PLATFORM_SUB := "sub"
const OUTER_SIZE := Vector2(1280, 720)
const CENTER_SIZE := Vector2(1920, 1080)
const UP := Vector2i(0, -1)
const DOWN := Vector2i(0, 1)
const LEFT := Vector2i(-1, 0)
const RIGHT := Vector2i(1, 0)

static func build_maps() -> Array:
	return [
	{
		"name": "Asgard",
		"subtitle": "Realm of the gods",
		"grid": Vector2i(0, 0),
		"theme": "valkyrie_gate",
		"identity": "Balanced ground",
		"monster": {"skin": "asgard_aegis_ram", "kind": "melee"},
		"hazard": {"type": "beams", "text": "Light of Asgard", "warn_text": "Light of Asgard - step out of the glowing columns!", "interval": [9.0, 12.0], "warning": 1.1, "active": 0.5, "count": 3, "width": 70.0, "height": 720.0, "damage": 6.0, "knockback": 120.0, "stun": 0.45},
		"art": {"dir": "res://assets/art/realm_asgard", "cap_main": 52, "cap_sub": 32, "dim": 0.38},
		"background": Color(0.02, 0.04, 0.08),
		"accent": Color(1.0, 0.72, 0.34),
		"size": OUTER_SIZE,
		"platforms": [
			main_platform(Vector2(640, 620), Vector2(1060, 52), Color(0.18, 0.21, 0.25)),
			sub_platform(Vector2(230, 475), Vector2(270, 34), Color(0.22, 0.25, 0.3)),
			sub_platform(Vector2(1050, 475), Vector2(270, 34), Color(0.22, 0.25, 0.3)),
			sub_platform(Vector2(640, 345), Vector2(370, 34), Color(0.24, 0.27, 0.33)),
			sub_platform(Vector2(420, 240), Vector2(210, 30), Color(0.2, 0.23, 0.29)),
			sub_platform(Vector2(860, 240), Vector2(210, 30), Color(0.2, 0.23, 0.29))
		],
		"spawns": [Vector2(250, 540), Vector2(480, 540), Vector2(800, 540), Vector2(1030, 540), Vector2(230, 400), Vector2(520, 270), Vector2(760, 270), Vector2(1050, 400)],
		"portals": {LEFT: Vector2(150, 458), RIGHT: Vector2(1130, 458), UP: Vector2(640, 328), DOWN: Vector2(640, 594)}
	},
	{
		"name": "Midgard",
		"subtitle": "World of humans",
		"grid": Vector2i(1, 0),
		"theme": "market_rooftops",
		"identity": "Asymmetric streets",
		"monster": {"skin": "mossling", "kind": "melee"},
		"art": {"dir": "res://assets/art/realm_midgard", "cap_main": 46, "cap_sub": 32, "dim": 0.38},
		"hazard": {"type": "bushes", "text": "Hiding bushes", "spots": [Vector2(230, 592), Vector2(1020, 567), Vector2(560, 434)], "size": Vector2(150, 64), "reveal": 0.8, "notice_range": 140.0},
		"background": Color(0.045, 0.04, 0.03),
		"accent": Color(0.95, 0.72, 0.42),
		"size": OUTER_SIZE,
		"platforms": [
			main_platform(Vector2(340, 615), Vector2(470, 46), Color(0.25, 0.2, 0.16)),
			main_platform(Vector2(930, 590), Vector2(430, 46), Color(0.24, 0.18, 0.14)),
			sub_platform(Vector2(185, 440), Vector2(220, 32), Color(0.29, 0.23, 0.18)),
			sub_platform(Vector2(560, 450), Vector2(270, 32), Color(0.31, 0.24, 0.18)),
			sub_platform(Vector2(1010, 375), Vector2(250, 32), Color(0.3, 0.22, 0.17)),
			sub_platform(Vector2(405, 280), Vector2(190, 28), Color(0.26, 0.2, 0.16)),
			sub_platform(Vector2(760, 240), Vector2(210, 28), Color(0.26, 0.2, 0.16))
		],
		"spawns": [Vector2(270, 545), Vector2(470, 545), Vector2(850, 520), Vector2(1040, 520), Vector2(185, 370), Vector2(560, 380), Vector2(1010, 305), Vector2(760, 170)],
		"portals": {LEFT: Vector2(125, 424), RIGHT: Vector2(1090, 359), UP: Vector2(760, 226), DOWN: Vector2(340, 592)}
	},
	{
		"name": "Niflheim",
		"subtitle": "Land of ice",
		"grid": Vector2i(2, 0),
		"theme": "frost_steps",
		"identity": "Stair-step chases",
		"monster": {"skin": "niflheim_frost_owl", "kind": "ranged"},
		"art": {"dir": "res://assets/art/realm_niflheim", "cap_main": 44, "cap_sub": 32, "dim": 0.38},
		"hazard": {"type": "ice", "text": "Slippery ice", "traction": 0.22},
		"background": Color(0.02, 0.065, 0.085),
		"accent": Color(0.66, 0.95, 1.0),
		"size": OUTER_SIZE,
		"platforms": [
			main_platform(Vector2(280, 620), Vector2(360, 44), Color(0.15, 0.25, 0.3)),
			main_platform(Vector2(1000, 620), Vector2(360, 44), Color(0.15, 0.25, 0.3)),
			sub_platform(Vector2(520, 505), Vector2(260, 34), Color(0.18, 0.29, 0.34)),
			sub_platform(Vector2(760, 390), Vector2(260, 34), Color(0.19, 0.31, 0.36)),
			sub_platform(Vector2(360, 275), Vector2(230, 30), Color(0.17, 0.27, 0.34)),
			sub_platform(Vector2(920, 275), Vector2(230, 30), Color(0.17, 0.27, 0.34)),
			sub_platform(Vector2(640, 170), Vector2(190, 28), Color(0.2, 0.32, 0.38))
		],
		"spawns": [Vector2(280, 550), Vector2(520, 435), Vector2(760, 320), Vector2(1000, 550), Vector2(360, 205), Vector2(920, 205), Vector2(640, 100), Vector2(640, 440)],
		"portals": {LEFT: Vector2(150, 598), RIGHT: Vector2(1130, 598), UP: Vector2(640, 156), DOWN: Vector2(980, 598)}
	},
	{
		"name": "Alfheim",
		"subtitle": "Realm of the light elves",
		"grid": Vector2i(0, 1),
		"theme": "moon_bridge",
		"identity": "Long sightlines",
		"monster": {"skin": "alfheim_moon_moth", "kind": "ranged"},
		"art": {"dir": "res://assets/art/realm_alfheim", "cap_main": 46, "cap_sub": 32, "dim": 0.38},
		"background": Color(0.035, 0.035, 0.09),
		"accent": Color(0.7, 0.82, 1.0),
		"size": OUTER_SIZE,
		"platforms": [
			main_platform(Vector2(640, 600), Vector2(900, 46), Color(0.18, 0.2, 0.32)),
			sub_platform(Vector2(210, 420), Vector2(240, 32), Color(0.22, 0.24, 0.38)),
			sub_platform(Vector2(1070, 420), Vector2(240, 32), Color(0.22, 0.24, 0.38)),
			sub_platform(Vector2(640, 315), Vector2(310, 30), Color(0.24, 0.27, 0.42)),
			sub_platform(Vector2(410, 215), Vector2(170, 28), Color(0.2, 0.22, 0.36)),
			sub_platform(Vector2(870, 215), Vector2(170, 28), Color(0.2, 0.22, 0.36))
		],
		"spawns": [Vector2(270, 520), Vector2(500, 520), Vector2(780, 520), Vector2(1010, 520), Vector2(210, 350), Vector2(640, 245), Vector2(1070, 350), Vector2(870, 155)],
		"portals": {LEFT: Vector2(140, 404), RIGHT: Vector2(1140, 404), UP: Vector2(640, 300), DOWN: Vector2(640, 577)}
	},
	{
		"name": "Muspelheim",
		"subtitle": "Land of fire",
		"grid": Vector2i(2, 1),
		"theme": "ember_ring",
		"identity": "Forced brawls",
		"monster": {"skin": "ember_imp", "kind": "ranged"},
		"art": {"dir": "res://assets/art/realm_muspelheim", "cap_main": 52, "cap_sub": 32, "dim": 0.38},
		"hazard": {"type": "eruption", "text": "Magma eruptions", "warn_text": "Magma rising - get off the glowing vents!", "interval": [7.0, 10.0], "warning": 1.2, "active": 0.7, "count": 2, "width": 80.0, "height": 460.0, "damage": 7.0, "knockback": 560.0},
		"background": Color(0.075, 0.025, 0.015),
		"accent": Color(1.0, 0.36, 0.16),
		"size": OUTER_SIZE,
		"platforms": [
			main_platform(Vector2(640, 610), Vector2(760, 52), Color(0.28, 0.15, 0.12)),
			sub_platform(Vector2(370, 455), Vector2(220, 32), Color(0.34, 0.18, 0.13)),
			sub_platform(Vector2(910, 455), Vector2(220, 32), Color(0.34, 0.18, 0.13)),
			sub_platform(Vector2(640, 325), Vector2(280, 32), Color(0.38, 0.2, 0.14)),
			sub_platform(Vector2(190, 315), Vector2(170, 28), Color(0.28, 0.14, 0.12)),
			sub_platform(Vector2(1090, 315), Vector2(170, 28), Color(0.28, 0.14, 0.12))
		],
		"spawns": [Vector2(380, 540), Vector2(560, 540), Vector2(720, 540), Vector2(900, 540), Vector2(370, 385), Vector2(640, 255), Vector2(910, 385), Vector2(640, 540)],
		"portals": {LEFT: Vector2(160, 301), RIGHT: Vector2(1120, 301), UP: Vector2(640, 309), DOWN: Vector2(640, 584)}
	},
	{
		"name": "Svartalfheim",
		"subtitle": "Clockwork city of the dwarves",
		"grid": Vector2i(0, 2),
		"theme": "skyline_spires",
		"identity": "Vertical climbs",
		"monster": {"skin": "svartalfheim_gear_beetle", "kind": "melee"},
		"art": {"dir": "res://assets/art/realm_svartalfheim", "cap_main": 44, "cap_sub": 32, "dim": 0.38},
		"background": Color(0.05, 0.045, 0.035),
		"accent": Color(0.95, 0.62, 0.25),
		"size": OUTER_SIZE,
		"platforms": [
			main_platform(Vector2(640, 640), Vector2(360, 44), Color(0.24, 0.21, 0.17)),
			sub_platform(Vector2(260, 540), Vector2(250, 34), Color(0.27, 0.23, 0.18)),
			sub_platform(Vector2(1020, 540), Vector2(250, 34), Color(0.27, 0.23, 0.18)),
			sub_platform(Vector2(430, 405), Vector2(230, 30), Color(0.29, 0.25, 0.19)),
			sub_platform(Vector2(850, 405), Vector2(230, 30), Color(0.29, 0.25, 0.19)),
			sub_platform(Vector2(640, 270), Vector2(240, 30), Color(0.31, 0.26, 0.2)),
			sub_platform(Vector2(640, 150), Vector2(160, 26), Color(0.27, 0.23, 0.18))
		],
		"spawns": [Vector2(260, 470), Vector2(430, 335), Vector2(640, 570), Vector2(850, 335), Vector2(1020, 470), Vector2(640, 200), Vector2(560, 570), Vector2(720, 570)],
		"portals": {LEFT: Vector2(185, 523), RIGHT: Vector2(1095, 523), UP: Vector2(640, 137), DOWN: Vector2(640, 618)}
	},
	{
		"name": "Vanaheim",
		"subtitle": "Forest of nature spirits",
		"grid": Vector2i(1, 2),
		"theme": "sunken_temple",
		"identity": "High-ground decisions",
		"monster": {"skin": "vanaheim_vine_hound", "kind": "melee"},
		"hazard": {"type": "vines", "text": "Growing vines", "warn_text": "Vines are growing a new path", "interval": [8.0, 11.0], "warning": 1.2, "active": 9.0, "bridges": [Rect2(440, 288, 400, 24), Rect2(390, 470, 150, 24), Rect2(740, 470, 150, 24)]},
		"art": {"dir": "res://assets/art/realm_vanaheim", "cap_main": 46, "cap_sub": 32, "dim": 0.38},
		"background": Color(0.0, 0.055, 0.045),
		"accent": Color(0.42, 0.95, 0.55),
		"size": OUTER_SIZE,
		"platforms": [
			main_platform(Vector2(640, 650), Vector2(520, 46), Color(0.13, 0.26, 0.2)),
			main_platform(Vector2(250, 555), Vector2(350, 40), Color(0.12, 0.23, 0.18)),
			main_platform(Vector2(1030, 555), Vector2(350, 40), Color(0.12, 0.23, 0.18)),
			sub_platform(Vector2(640, 425), Vector2(280, 32), Color(0.15, 0.3, 0.22)),
			sub_platform(Vector2(315, 300), Vector2(230, 30), Color(0.12, 0.24, 0.19)),
			sub_platform(Vector2(965, 300), Vector2(230, 30), Color(0.12, 0.24, 0.19))
		],
		"spawns": [Vector2(280, 485), Vector2(500, 585), Vector2(780, 585), Vector2(1000, 485), Vector2(315, 230), Vector2(640, 355), Vector2(965, 230), Vector2(640, 570)],
		"portals": {LEFT: Vector2(130, 535), RIGHT: Vector2(1150, 535), UP: Vector2(640, 409), DOWN: Vector2(640, 627)}
	},
	{
		"name": "Jotunheim",
		"subtitle": "Land of the giants",
		"grid": Vector2i(2, 2),
		"theme": "gravity_well",
		"identity": "Thin ledges, open center",
		"monster": {"skin": "jotunheim_rune_golem", "kind": "melee"},
		"art": {"dir": "res://assets/art/realm_jotunheim", "cap_main": 46, "cap_sub": 32, "dim": 0.38},
		"hazard": {"type": "quake", "text": "Earthquakes", "warn_text": "Earthquake! Jump to avoid it", "interval": [12.0, 16.0], "warning": 1.6, "stun": 0.55, "damage": 4.0, "pop": 260.0},
		"background": Color(0.03, 0.035, 0.06),
		"accent": Color(0.62, 0.72, 0.95),
		"size": OUTER_SIZE,
		"platforms": [
			main_platform(Vector2(640, 620), Vector2(360, 46), Color(0.2, 0.22, 0.3)),
			sub_platform(Vector2(260, 500), Vector2(230, 32), Color(0.22, 0.24, 0.33)),
			sub_platform(Vector2(1020, 500), Vector2(230, 32), Color(0.22, 0.24, 0.33)),
			sub_platform(Vector2(640, 440), Vector2(250, 32), Color(0.25, 0.27, 0.37)),
			sub_platform(Vector2(430, 300), Vector2(210, 30), Color(0.21, 0.23, 0.32)),
			sub_platform(Vector2(850, 300), Vector2(210, 30), Color(0.21, 0.23, 0.32)),
			sub_platform(Vector2(640, 195), Vector2(170, 28), Color(0.23, 0.25, 0.36))
		],
		"spawns": [Vector2(260, 430), Vector2(520, 550), Vector2(760, 550), Vector2(1020, 430), Vector2(430, 230), Vector2(640, 370), Vector2(850, 230), Vector2(640, 125)],
		"portals": {LEFT: Vector2(190, 484), RIGHT: Vector2(1090, 484), UP: Vector2(640, 181), DOWN: Vector2(640, 597)}
	},
	{
		"name": "Yggdrasil Heart",
		"subtitle": "The final arena",
		"grid": Vector2i(1, 1),
		"theme": "starfall_shrine",
		"identity": "Endgame brawl",
		"monster": {"skin": "yggdrasil_root_oracle", "kind": "ranged"},
		"art": {"dir": "res://assets/art/realm_center", "cap_main": 54, "cap_sub": 32},
		"background": Color(0.055, 0.025, 0.065),
		"accent": Color(1.0, 0.55, 0.95),
		"size": CENTER_SIZE,
		"platforms": [
			main_platform(Vector2(960, 940), Vector2(1500, 54), Color(0.22, 0.16, 0.27)),
			sub_platform(Vector2(420, 800), Vector2(300, 34), Color(0.26, 0.18, 0.32)),
			sub_platform(Vector2(1500, 800), Vector2(300, 34), Color(0.26, 0.18, 0.32)),
			sub_platform(Vector2(960, 790), Vector2(360, 34), Color(0.27, 0.19, 0.34)),
			sub_platform(Vector2(300, 650), Vector2(220, 30), Color(0.24, 0.17, 0.31)),
			sub_platform(Vector2(1620, 650), Vector2(220, 30), Color(0.24, 0.17, 0.31)),
			sub_platform(Vector2(640, 660), Vector2(280, 32), Color(0.28, 0.2, 0.36)),
			sub_platform(Vector2(1280, 660), Vector2(280, 32), Color(0.28, 0.2, 0.36)),
			sub_platform(Vector2(960, 520), Vector2(340, 32), Color(0.29, 0.2, 0.38)),
			sub_platform(Vector2(560, 400), Vector2(240, 28), Color(0.25, 0.18, 0.33)),
			sub_platform(Vector2(1360, 400), Vector2(240, 28), Color(0.25, 0.18, 0.33)),
			sub_platform(Vector2(960, 280), Vector2(260, 28), Color(0.3, 0.2, 0.38))
		],
		"spawns": [Vector2(500, 860), Vector2(800, 860), Vector2(1120, 860), Vector2(1420, 860), Vector2(420, 730), Vector2(1500, 730), Vector2(960, 720), Vector2(960, 460)],
		"portals": {LEFT: Vector2(270, 913), RIGHT: Vector2(1650, 913), UP: Vector2(960, 263), DOWN: Vector2(960, 913)}
	}
	]

## build_maps() with every position and span times scale (routine 2026-10-08: realms 1.5x).
static func scaled_maps(scale: float) -> Array:
	var maps := build_maps()
	for map: Dictionary in maps:
		map["size"] = map.get("size", OUTER_SIZE) * scale
		var authored: Array = map.platforms.duplicate(true)
		for platform_data: Dictionary in map.platforms:
			platform_data["center"] = platform_data.center * scale
			platform_data["size"] = Vector2(platform_data.size.x * scale, platform_data.size.y)
		var spawns: Array = []
		for spawn: Vector2 in map.spawns:
			spawns.append(_scaled_stand_point(spawn, authored, scale))
		map["spawns"] = spawns
		var portals := {}
		for side in map.portals:
			portals[side] = _scaled_stand_point(map.portals[side], authored, scale)
		map["portals"] = portals
		if map.has("hazard"):
			map["hazard"] = _scaled_hazard(map.hazard, scale, authored)
	return maps

## A point that stands on (or floats a little above) a platform keeps its height above that
## platform's top: platform centres scale but their thickness does not, so plain scaling would
## lift portals, bush bottoms and spawns off the platforms (CODEX-QA-13). Points over no
## platform scale plainly.
static func _scaled_stand_point(point: Vector2, authored: Array, scale: float) -> Vector2:
	var best_gap := INF
	var best_top := 0.0
	var best_height := 0.0
	for platform_data: Dictionary in authored:
		var top: float = platform_data.center.y - platform_data.size.y * 0.5
		var gap: float = top - point.y
		if absf(point.x - platform_data.center.x) <= platform_data.size.x * 0.5 + 8.0 and gap >= -4.0 and gap < best_gap:
			best_gap = gap
			best_top = top
			best_height = platform_data.size.y
	if best_gap == INF:
		return point * scale
	var scaled_top := (best_top + best_height * 0.5) * scale - best_height * 0.5
	return Vector2(point.x * scale, scaled_top - best_gap)

static func _scaled_hazard(hazard: Dictionary, scale: float, authored: Array) -> Dictionary:
	var scaled := hazard.duplicate(true)
	for key in ["width", "height", "notice_range"]:
		if scaled.has(key):
			scaled[key] = float(scaled[key]) * scale
	if scaled.has("spots"):
		var spots: Array = []
		for spot: Vector2 in scaled.spots:
			spots.append(_scaled_stand_point(spot, authored, scale))
		scaled["spots"] = spots
	if scaled.has("size"):
		scaled["size"] = Vector2(scaled.size.x * scale, scaled.size.y)
	if scaled.has("bridges"):
		var bridges: Array = []
		for rect: Rect2 in scaled.bridges:
			bridges.append(Rect2(rect.position * scale, Vector2(rect.size.x * scale, rect.size.y)))
		scaled["bridges"] = bridges
	return scaled

static func main_platform(center: Vector2, size: Vector2, color: Color, concept_tags: Array[String] = []) -> Dictionary:
	return platform(center, size, color, PLATFORM_MAIN, concept_tags)

static func sub_platform(center: Vector2, size: Vector2, color: Color, concept_tags: Array[String] = []) -> Dictionary:
	return platform(center, size, color, PLATFORM_SUB, concept_tags)

static func platform(center: Vector2, size: Vector2, color: Color, role: String, concept_tags: Array[String]) -> Dictionary:
	return {
		"center": center,
		"size": size,
		"color": color,
		"role": role,
		"concept_tags": concept_tags.duplicate()
	}
