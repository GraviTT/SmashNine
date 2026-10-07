extends SceneTree

const CONTACT_SHEET_PATH := "res://assets/art/realm_center/contact_sheet.png"
const SCREENSHOT_PATH := "../reports/codex-art-01/realm_preview.png"


func _initialize() -> void:
	DisplayServer.window_set_title("Smash Nine Realms - Yggdrasil Heart art preview")
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	var contact_sheet := Image.load_from_file(ProjectSettings.globalize_path(CONTACT_SHEET_PATH))
	var frame := contact_sheet.get_region(Rect2i(0, 0, 1920, 1080))
	var texture_rect := TextureRect.new()
	texture_rect.texture = ImageTexture.create_from_image(frame)
	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root.add_child(texture_rect)
	_capture.call_deferred()


func _capture() -> void:
	await process_frame
	await process_frame
	var screenshot := root.get_texture().get_image()
	var error := screenshot.save_png(ProjectSettings.globalize_path(SCREENSHOT_PATH))
	if error != OK:
		push_error("Failed to save preview screenshot: " + error_string(error))
		quit(1)
		return
	print("ART_PREVIEW_OK size=", screenshot.get_size(), " path=", ProjectSettings.globalize_path(SCREENSHOT_PATH))
	quit()
