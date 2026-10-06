extends RefCounted
## Static realm definitions: name, theme colors and the 1280x720 platform layout
## each realm repeats across its 3x3 tiles.

const PLATFORM_MAIN := "main"
const PLATFORM_SUB := "sub"

static func build_maps() -> Array:
	return [
	{
		"name": "1. Valkyrie Gate",
		"subtitle": "Balanced starter arena",
		"grid": Vector2i(0, 0),
		"gimmick": "Clean neutral ground",
		"hazard": "Low edge pressure",
		"identity": "Baseline combat feel",
		"background": Color(0.02, 0.04, 0.08),
		"accent": Color(1.0, 0.72, 0.34),
		"platforms": [
			main_platform(Vector2(640, 620), Vector2(1060, 52), Color(0.18, 0.21, 0.25)),
			sub_platform(Vector2(230, 475), Vector2(270, 34), Color(0.22, 0.25, 0.3)),
			sub_platform(Vector2(1050, 475), Vector2(270, 34), Color(0.22, 0.25, 0.3)),
			sub_platform(Vector2(640, 345), Vector2(370, 34), Color(0.24, 0.27, 0.33)),
			sub_platform(Vector2(420, 240), Vector2(210, 30), Color(0.2, 0.23, 0.29)),
			sub_platform(Vector2(860, 240), Vector2(210, 30), Color(0.2, 0.23, 0.29))
		],
		"spawns": [Vector2(250, 540), Vector2(480, 540), Vector2(800, 540), Vector2(1030, 540), Vector2(230, 400), Vector2(520, 270), Vector2(760, 270), Vector2(1050, 400)]
	},
	{
		"name": "2. Moon Bridge",
		"subtitle": "Long bridge with high side shelves",
		"grid": Vector2i(1, 0),
		"gimmick": "Long sightline",
		"hazard": "Side ledge traps",
		"identity": "Horizontal control",
		"background": Color(0.035, 0.035, 0.09),
		"accent": Color(0.7, 0.82, 1.0),
		"platforms": [
			main_platform(Vector2(640, 600), Vector2(900, 46), Color(0.18, 0.2, 0.32)),
			sub_platform(Vector2(210, 420), Vector2(240, 32), Color(0.22, 0.24, 0.38)),
			sub_platform(Vector2(1070, 420), Vector2(240, 32), Color(0.22, 0.24, 0.38)),
			sub_platform(Vector2(640, 315), Vector2(310, 30), Color(0.24, 0.27, 0.42)),
			sub_platform(Vector2(410, 215), Vector2(170, 28), Color(0.2, 0.22, 0.36)),
			sub_platform(Vector2(870, 215), Vector2(170, 28), Color(0.2, 0.22, 0.36))
		],
		"spawns": [Vector2(270, 520), Vector2(500, 520), Vector2(780, 520), Vector2(1010, 520), Vector2(210, 350), Vector2(640, 245), Vector2(1070, 350), Vector2(870, 155)]
	},
	{
		"name": "3. Sunken Temple",
		"subtitle": "Low center with safer high corners",
		"grid": Vector2i(2, 0),
		"gimmick": "Low center basin",
		"hazard": "Center comeback tax",
		"identity": "High-ground decisions",
		"background": Color(0.0, 0.055, 0.065),
		"accent": Color(0.22, 0.95, 0.9),
		"platforms": [
			main_platform(Vector2(640, 650), Vector2(520, 46), Color(0.13, 0.26, 0.27)),
			main_platform(Vector2(250, 555), Vector2(350, 40), Color(0.12, 0.23, 0.25)),
			main_platform(Vector2(1030, 555), Vector2(350, 40), Color(0.12, 0.23, 0.25)),
			sub_platform(Vector2(640, 425), Vector2(280, 32), Color(0.15, 0.3, 0.3)),
			sub_platform(Vector2(315, 300), Vector2(230, 30), Color(0.12, 0.24, 0.27)),
			sub_platform(Vector2(965, 300), Vector2(230, 30), Color(0.12, 0.24, 0.27))
		],
		"spawns": [Vector2(280, 485), Vector2(500, 585), Vector2(780, 585), Vector2(1000, 485), Vector2(315, 230), Vector2(640, 355), Vector2(965, 230), Vector2(640, 570)]
	},
	{
		"name": "4. Skyline Spires",
		"subtitle": "Tall vertical routes and risky gaps",
		"grid": Vector2i(0, 1),
		"gimmick": "Vertical climbs",
		"hazard": "Open fall lanes",
		"identity": "Aerial chase and recovery",
		"background": Color(0.025, 0.055, 0.105),
		"accent": Color(0.38, 0.85, 1.0),
		"platforms": [
			main_platform(Vector2(640, 640), Vector2(360, 44), Color(0.16, 0.21, 0.31)),
			sub_platform(Vector2(260, 540), Vector2(250, 34), Color(0.18, 0.24, 0.34)),
			sub_platform(Vector2(1020, 540), Vector2(250, 34), Color(0.18, 0.24, 0.34)),
			sub_platform(Vector2(430, 405), Vector2(230, 30), Color(0.2, 0.27, 0.38)),
			sub_platform(Vector2(850, 405), Vector2(230, 30), Color(0.2, 0.27, 0.38)),
			sub_platform(Vector2(640, 270), Vector2(240, 30), Color(0.22, 0.29, 0.42)),
			sub_platform(Vector2(640, 150), Vector2(160, 26), Color(0.18, 0.23, 0.36))
		],
		"spawns": [Vector2(260, 470), Vector2(430, 335), Vector2(640, 570), Vector2(850, 335), Vector2(1020, 470), Vector2(640, 200), Vector2(560, 570), Vector2(720, 570)]
	},
	{
		"name": "5. Ember Ring",
		"subtitle": "Compact brawl pit",
		"grid": Vector2i(2, 1),
		"gimmick": "Close-range pressure",
		"hazard": "Short escape routes",
		"identity": "Forced brawls",
		"background": Color(0.075, 0.025, 0.015),
		"accent": Color(1.0, 0.36, 0.16),
		"platforms": [
			main_platform(Vector2(640, 610), Vector2(760, 52), Color(0.28, 0.15, 0.12)),
			sub_platform(Vector2(370, 455), Vector2(220, 32), Color(0.34, 0.18, 0.13)),
			sub_platform(Vector2(910, 455), Vector2(220, 32), Color(0.34, 0.18, 0.13)),
			sub_platform(Vector2(640, 325), Vector2(280, 32), Color(0.38, 0.2, 0.14)),
			sub_platform(Vector2(190, 315), Vector2(170, 28), Color(0.28, 0.14, 0.12)),
			sub_platform(Vector2(1090, 315), Vector2(170, 28), Color(0.28, 0.14, 0.12))
		],
		"spawns": [Vector2(380, 540), Vector2(560, 540), Vector2(720, 540), Vector2(900, 540), Vector2(370, 385), Vector2(640, 255), Vector2(910, 385), Vector2(640, 540)]
	},
	{
		"name": "6. Frost Steps",
		"subtitle": "Staggered platforms for chase fights",
		"grid": Vector2i(0, 2),
		"gimmick": "Stair-step routes",
		"hazard": "Split recovery paths",
		"identity": "Pursuit and disengage",
		"background": Color(0.02, 0.065, 0.085),
		"accent": Color(0.66, 0.95, 1.0),
		"platforms": [
			main_platform(Vector2(280, 620), Vector2(360, 44), Color(0.15, 0.25, 0.3)),
			main_platform(Vector2(1000, 620), Vector2(360, 44), Color(0.15, 0.25, 0.3)),
			sub_platform(Vector2(520, 505), Vector2(260, 34), Color(0.18, 0.29, 0.34)),
			sub_platform(Vector2(760, 390), Vector2(260, 34), Color(0.19, 0.31, 0.36)),
			sub_platform(Vector2(360, 275), Vector2(230, 30), Color(0.17, 0.27, 0.34)),
			sub_platform(Vector2(920, 275), Vector2(230, 30), Color(0.17, 0.27, 0.34)),
			sub_platform(Vector2(640, 170), Vector2(190, 28), Color(0.2, 0.32, 0.38))
		],
		"spawns": [Vector2(280, 550), Vector2(520, 435), Vector2(760, 320), Vector2(1000, 550), Vector2(360, 205), Vector2(920, 205), Vector2(640, 100), Vector2(640, 440)]
	},
	{
		"name": "7. Gravity Well",
		"subtitle": "Open center with orbiting ledges",
		"grid": Vector2i(1, 2),
		"gimmick": "Open center",
		"hazard": "Thin safe platforms",
		"identity": "Position resets",
		"background": Color(0.035, 0.025, 0.075),
		"accent": Color(0.48, 0.42, 1.0),
		"platforms": [
			main_platform(Vector2(640, 620), Vector2(360, 46), Color(0.18, 0.16, 0.3)),
			sub_platform(Vector2(260, 500), Vector2(230, 32), Color(0.2, 0.18, 0.34)),
			sub_platform(Vector2(1020, 500), Vector2(230, 32), Color(0.2, 0.18, 0.34)),
			sub_platform(Vector2(640, 440), Vector2(250, 32), Color(0.23, 0.2, 0.38)),
			sub_platform(Vector2(430, 300), Vector2(210, 30), Color(0.19, 0.17, 0.34)),
			sub_platform(Vector2(850, 300), Vector2(210, 30), Color(0.19, 0.17, 0.34)),
			sub_platform(Vector2(640, 195), Vector2(170, 28), Color(0.21, 0.18, 0.38))
		],
		"spawns": [Vector2(260, 430), Vector2(520, 550), Vector2(760, 550), Vector2(1020, 430), Vector2(430, 230), Vector2(640, 370), Vector2(850, 230), Vector2(640, 125)]
	},
	{
		"name": "8. Market Rooftops",
		"subtitle": "Asymmetric streets and rooftops",
		"grid": Vector2i(2, 2),
		"gimmick": "Asymmetric routes",
		"hazard": "Uneven retreat angles",
		"identity": "Route reading",
		"background": Color(0.045, 0.04, 0.03),
		"accent": Color(0.95, 0.72, 0.42),
		"platforms": [
			main_platform(Vector2(340, 615), Vector2(470, 46), Color(0.25, 0.2, 0.16)),
			main_platform(Vector2(930, 590), Vector2(430, 46), Color(0.24, 0.18, 0.14)),
			sub_platform(Vector2(185, 440), Vector2(220, 32), Color(0.29, 0.23, 0.18)),
			sub_platform(Vector2(560, 450), Vector2(270, 32), Color(0.31, 0.24, 0.18)),
			sub_platform(Vector2(1010, 375), Vector2(250, 32), Color(0.3, 0.22, 0.17)),
			sub_platform(Vector2(405, 280), Vector2(190, 28), Color(0.26, 0.2, 0.16)),
			sub_platform(Vector2(760, 240), Vector2(210, 28), Color(0.26, 0.2, 0.16))
		],
		"spawns": [Vector2(270, 545), Vector2(470, 545), Vector2(850, 520), Vector2(1040, 520), Vector2(185, 370), Vector2(560, 380), Vector2(1010, 305), Vector2(760, 170)]
	},
	{
		"name": "9. Starfall Shrine",
		"subtitle": "Final arena with layered center control",
		"grid": Vector2i(1, 1),
		"gimmick": "Locked central realm",
		"hazard": "Final convergence pressure",
		"identity": "Endgame brawl",
		"background": Color(0.055, 0.025, 0.065),
		"accent": Color(1.0, 0.55, 0.95),
		"platforms": [
			main_platform(Vector2(640, 640), Vector2(980, 50), Color(0.22, 0.16, 0.27)),
			sub_platform(Vector2(320, 505), Vector2(260, 34), Color(0.26, 0.18, 0.32)),
			sub_platform(Vector2(960, 505), Vector2(260, 34), Color(0.26, 0.18, 0.32)),
			sub_platform(Vector2(640, 390), Vector2(330, 34), Color(0.29, 0.2, 0.36)),
			sub_platform(Vector2(250, 285), Vector2(190, 28), Color(0.24, 0.17, 0.31)),
			sub_platform(Vector2(1030, 285), Vector2(190, 28), Color(0.24, 0.17, 0.31)),
			sub_platform(Vector2(640, 205), Vector2(220, 28), Color(0.3, 0.2, 0.38))
		],
		"spawns": [Vector2(270, 570), Vector2(500, 570), Vector2(780, 570), Vector2(1010, 570), Vector2(320, 435), Vector2(640, 320), Vector2(960, 435), Vector2(640, 135)]
	}
	]

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
