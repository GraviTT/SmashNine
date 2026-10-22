extends SceneTree

func _initialize() -> void:
	var node := Node.new()
	var modes := {node: Node.PROCESS_MODE_INHERIT}
	node.free()
	for child: Node in modes:
		print("Freed dictionary key valid: ", is_instance_valid(child))
	quit()
