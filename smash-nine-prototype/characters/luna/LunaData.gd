extends RefCounted

static func get_data() -> Dictionary:
	return {
		"id": "luna",
		"name": "Luna",
		"role": "Star Magical Girl",
		"color": Color(1.0, 0.48, 0.9),
		"max_hp": 98.0,
		"attack": 112.0,
		"defense": 12.0,
		"speed": 320.0,
		"jump": -735.0,
		"weight": 0.98,
		"growth": {"max_hp": 5.5, "attack": 3.5, "defense": 1.3, "speed": 1.0}
	}

