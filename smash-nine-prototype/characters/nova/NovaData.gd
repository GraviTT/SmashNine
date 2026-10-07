extends RefCounted

static func get_data() -> Dictionary:
	return {
		"id": "nova",
		"name": "Nova",
		"role": "Gravity Hero",
		"ultimate_name": "Event Horizon",
		"ultimate_window": 3.2,
		"color": Color(0.32, 0.95, 1.0),
		"bodies": ["male", "female"],
		"max_hp": 104.0,
		"attack": 114.0,
		"defense": 14.0,
		"speed": 360.0,
		"jump": -760.0,
		"weight": 1.0,
		"growth": {"max_hp": 4.5, "attack": 2.8, "defense": 1.0, "speed": 0.6}
	}
