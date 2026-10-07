extends RefCounted

static func get_data() -> Dictionary:
	return {
		"id": "rio",
		"name": "Rio",
		"role": "Spellblade Assassin",
		"ultimate_name": "Infinity Overdrive",
		"ultimate_window": 1.8,
		"color": Color(0.5, 0.72, 1.0),
		"bodies": ["male", "female"],
		"max_hp": 96.0,
		"attack": 112.0,
		"defense": 10.0,
		"speed": 350.0,
		"jump": -740.0,
		"weight": 0.94,
		"air_jumps": 2,
		"growth": {"max_hp": 4.5, "attack": 3.2, "defense": 1.0, "speed": 1.0}
	}
