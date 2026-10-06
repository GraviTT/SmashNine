extends RefCounted

const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

static func get_characters() -> Dictionary:
	return CHARACTER_REGISTRY.get_characters()
