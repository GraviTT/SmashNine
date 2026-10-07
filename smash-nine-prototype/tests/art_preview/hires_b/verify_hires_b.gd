extends SceneTree

const USED_COUNTS := [4, 6, 1, 1, 4, 6, 1]
const SHEETS := [
	"res://assets/art/rio/rio_male_sheet.png",
	"res://assets/art/rio/rio_female_sheet.png",
	"res://assets/art/luna/luna_sheet.png",
	"res://assets/art/luna/luna_brave_sheet.png"
]
const ILLUSTRATIONS := [
	"res://assets/art/rio/rio_male_illustration.png",
	"res://assets/art/rio/rio_female_illustration.png",
	"res://assets/art/luna/luna_illustration.png"
]
const FACES := [
	"res://assets/art/rio/rio_male_face.png",
	"res://assets/art/rio/rio_female_face.png",
	"res://assets/art/luna/luna_face.png"
]

var failures: PackedStringArray = PackedStringArray()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for path in ILLUSTRATIONS:
		_check_size(path, Vector2i(1024, 1536))
	for path in FACES:
		_check_size(path, Vector2i(256, 256))
	for path in SHEETS:
		_check_sheet(path)
	_check_size("res://../reports/codex-art-08b/contact_sheet.png", Vector2i(2048, 3584))
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("HIRES_B_VERIFY_OK illustrations=3 faces=3 sheets=4 frames=92 unused_cells=76")
	quit()

func _check_size(path: String, expected: Vector2i) -> void:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		failures.append("Missing image: %s" % path)
		return
	if image.get_size() != expected:
		failures.append("Wrong size %s: %s expected %s" % [path, image.get_size(), expected])

func _check_sheet(path: String) -> void:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		failures.append("Missing sheet: %s" % path)
		return
	if image.get_size() != Vector2i(768, 896):
		failures.append("Wrong sheet size %s: %s" % [path, image.get_size()])
		return
	for row in 7:
		for column in 6:
			var opaque := _opaque_count(image, Rect2i(column * 128, row * 128, 128, 128))
			var should_be_used: bool = column < int(USED_COUNTS[row])
			if should_be_used and opaque == 0:
				failures.append("Empty used cell %s row=%d col=%d" % [path, row, column])
			if not should_be_used and opaque != 0:
				failures.append("Non-transparent unused cell %s row=%d col=%d pixels=%d" % [path, row, column, opaque])

func _opaque_count(image: Image, area: Rect2i) -> int:
	var count := 0
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if image.get_pixel(x, y).a > 0.04:
				count += 1
	return count
