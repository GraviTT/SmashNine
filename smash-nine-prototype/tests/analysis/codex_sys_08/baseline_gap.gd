extends "res://scripts/audio/AudioManager.gd"
## QA-22 policy, used only to replay its already captured requests.
func gap_usec(_id: String) -> int:
	return 40000
