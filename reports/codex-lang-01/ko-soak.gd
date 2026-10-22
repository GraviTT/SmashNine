extends "res://tests/soak_match.gd"
## Reuse the exact production soak in Korean; Main must keep the selected locale.
const LANGUAGE := preload("res://scripts/Language.gd")

func _initialize() -> void:
	LANGUAGE.load_saved()
	LANGUAGE.set_locale("ko")
	super._initialize()

func _collect_result(finished_early: bool) -> Dictionary:
	assert(LANGUAGE.locale == "ko", "The Korean match must retain Korean through its result screen")
	return super._collect_result(finished_early)
