extends RefCounted

## Xion (2026-11-18, the user's kit). Start values: a little lighter and faster than Rio, one air
## jump (L is her lift). "story": false keeps her out of story mode until it is written for her (D43).
static func get_data() -> Dictionary:
	return {
		"id": "xion",
		"name": "Xion",
		"role": "Gun-Kata Gunslinger",
		"ultimate_name": "Equilibrium",
		"ultimate_window": 2.5,
		"color": Color(0.88, 0.22, 0.32),
		"bodies": ["female"],
		"story": false,
		"max_hp": 94.0,
		"attack": 108.0,
		"defense": 9.0,
		"speed": 335.0,
		"jump": -740.0,
		"weight": 0.92,
		"growth": {"max_hp": 4.5, "attack": 3.0, "defense": 1.0, "speed": 0.9}
	}
