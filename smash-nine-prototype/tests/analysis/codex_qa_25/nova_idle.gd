extends "res://characters/nova/Nova.gd"
## Counterfactual confined to the QA folder; production Nova stays unchanged.
func _wait_action(seconds: float) -> bool:
	var epoch := action_epoch
	await get_tree().create_timer(seconds).timeout
	return epoch == action_epoch and not is_defeated
