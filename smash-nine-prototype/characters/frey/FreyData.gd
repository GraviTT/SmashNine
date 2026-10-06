extends RefCounted

static func get_data() -> Dictionary:
	return {
		"id": "frey",
		"name": "Frey",
		"role": "Valkyrie Bruiser",
		"color": Color(1.0, 0.72, 0.36),
		"max_hp": 115.0,
		"attack": 118.0,
		"defense": 18.0,
		"speed": 305.0,
		"jump": -700.0,
		"weight": 1.15,
		"growth": {"max_hp": 4.0, "attack": 2.0, "defense": 0.8, "speed": 0.8}
	}

