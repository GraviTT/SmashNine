extends SceneTree

const REPORT_CONTACT := "res://../reports/codex-art-08a/contact_sheet.png"
const ROW_HEIGHT := 928
const ENTRIES := [
	["res://assets/art/frey/frey_illustration.png", "res://assets/art/frey/frey_face.png", "res://assets/art/frey/frey_sheet.png", Rect2i(400, 0, 420, 420)],
	["res://assets/art/nova/nova_male_illustration.png", "res://assets/art/nova/nova_male_face.png", "res://assets/art/nova/nova_male_sheet.png", Rect2i(360, 0, 420, 420)],
	["res://assets/art/nova/nova_female_illustration.png", "res://assets/art/nova/nova_female_face.png", "res://assets/art/nova/nova_female_sheet.png", Rect2i(300, 0, 420, 420)],
	["res://assets/art/yuki/yuki_illustration.png", "res://assets/art/yuki/yuki_face.png", "res://assets/art/yuki/yuki_sheet.png", Rect2i(330, 20, 460, 460)],
]

func _initialize() -> void:
	var contact := Image.load_from_file(REPORT_CONTACT)
	for i: int in range(ENTRIES.size()):
		var illustration := Image.load_from_file(ENTRIES[i][0])
		var face := illustration.get_region(ENTRIES[i][3])
		face.resize(256, 256, Image.INTERPOLATE_LANCZOS)
		for y: int in range(face.get_height()):
			for x: int in range(face.get_width()):
				if face.get_pixel(x, y).a < 0.015:
					face.set_pixel(x, y, Color(0, 0, 0, 0))
		face.save_png(ENTRIES[i][1])
		var destination := Vector2i(1584, i * ROW_HEIGHT + 80)
		contact.fill_rect(Rect2i(destination, Vector2i(256, 256)), Color("101827"))
		contact.blend_rect(face, Rect2i(Vector2i.ZERO, face.get_size()), destination)
		var sheet := Image.load_from_file(ENTRIES[i][2])
		var sheet_destination := Vector2i(800, i * ROW_HEIGHT + 16)
		contact.fill_rect(Rect2i(sheet_destination, Vector2i(768, 896)), Color("101827"))
		contact.blend_rect(sheet, Rect2i(Vector2i.ZERO, sheet.get_size()), sheet_destination)
		var illustration_small := illustration.duplicate()
		illustration_small.resize(256, 384, Image.INTERPOLATE_LANCZOS)
		var illustration_destination := Vector2i(1864, i * ROW_HEIGHT + 16)
		contact.fill_rect(Rect2i(illustration_destination, Vector2i(256, 384)), Color("101827"))
		contact.blend_rect(illustration_small, Rect2i(Vector2i.ZERO, illustration_small.get_size()), illustration_destination)
	contact.save_png(REPORT_CONTACT)
	print("[hires_a] refreshed final panels in contact sheet")
	quit()
