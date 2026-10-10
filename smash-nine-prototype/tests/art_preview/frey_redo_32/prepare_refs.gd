extends SceneTree

const CELL := 128
const BASE_SHEET := "res://assets/art/frey/frey_sheet.png"
const MOVE_SHEET := "res://assets/art/frey/frey_moves_sheet.png"
const OUTPUT_DIR := "res://tests/art_preview/frey_redo_32"
const ROWS := [
	["attack_up", 4],
	["attack_down", 4],
	["attack_air_side", 4],
	["dash_strike", 4],
	["rising_cleave", 5],
	["spike_followup", 4],
	["descent", 6],
	["tumble", 4],
]


func _init() -> void:
	var base := Image.load_from_file(BASE_SHEET)
	var moves := Image.load_from_file(MOVE_SHEET)
	if base.is_empty() or moves.is_empty():
		printerr("prepare_refs: failed to load source sheets")
		quit(1)
		return
	var err := base.get_region(Rect2i(0, 0, CELL, CELL)).save_png(OUTPUT_DIR + "/idle_reference.png")
	if err != OK:
		printerr("prepare_refs: idle save failed: %s" % error_string(err))
		quit(1)
		return
	err = moves.save_png(OUTPUT_DIR + "/before_sheet.png")
	if err != OK:
		printerr("prepare_refs: sheet save failed: %s" % error_string(err))
		quit(1)
		return
	for row_index in ROWS.size():
		var row: Array = ROWS[row_index]
		var strip := moves.get_region(Rect2i(0, row_index * CELL, int(row[1]) * CELL, CELL))
		err = strip.save_png(OUTPUT_DIR + "/%s_before_strip.png" % row[0])
		if err != OK:
			printerr("prepare_refs: %s save failed: %s" % [row[0], error_string(err)])
			quit(1)
			return
	print("prepare_refs: idle + 8 before strips written")
	quit(0)
