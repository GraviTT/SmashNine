extends SceneTree

const MAIN_SCRIPT := preload("res://scripts/Main.gd")
const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := MAIN_SCRIPT.new()
	var characters := CHARACTER_REGISTRY.get_characters()
	var expected_counts := {
		"frey": {"idle": 4, "walk": 6, "jump": 1, "fall": 1, "attack": 4, "shield": 6, "hurt": 1},
		"yuki": {"idle": 6, "walk": 6, "jump": 5, "fall": 5, "attack": 10, "shield": 1, "hurt": 5},
		"luna": {"idle": 10, "walk": 10, "jump": 5, "fall": 5, "attack": 15, "shield": 1, "hurt": 1},
		"nova": {"idle": 1, "walk": 14, "jump": 4, "fall": 4, "attack": 6, "shield": 1, "hurt": 1}
	}
	for character_id in expected_counts:
		var player := PLAYER_FACTORY.create(character_id)
		root.add_child(player)
		player.setup(characters[character_id], 1, true)
		await process_frame
		var expected_script := "res://characters/%s/%s.gd" % [character_id, character_id.capitalize()]
		if player.get_script().resource_path != expected_script:
			_fail("Wrong character script: %s" % player.get_script().resource_path)
			return
		var sprite := player.get_node("CharacterSprite") as AnimatedSprite2D
		var frames := sprite.sprite_frames
		for base_name in expected_counts[character_id]:
			var animation_name := StringName("%s_%s" % [character_id, base_name])
			if not frames.has_animation(animation_name):
				_fail("Missing animation: %s" % animation_name)
				return
			if frames.get_frame_count(animation_name) != expected_counts[character_id][base_name]:
				_fail("Wrong frame count for %s" % animation_name)
				return
		if not sprite.visible or player.get_node("Body").visible:
			_fail("%s sprite visibility did not replace the placeholder body" % character_id)
			return
		root.remove_child(player)
		player.free()
	print("All character scene and sprite smoke tests passed")
	main.free()
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
