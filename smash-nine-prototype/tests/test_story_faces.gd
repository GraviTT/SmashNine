extends SceneTree
## SYS-09: synthetic cached textures exercise real portrait paths without writing any art.
const ART := preload("res://scripts/ArtSettings.gd")
const STORY := preload("res://scripts/story/StoryCatalog.gd")
const DIALOGUE := preload("res://scripts/ui/StoryDialogue.gd")
const REGISTRY := preload("res://characters/CharacterRegistry.gd")
const DIM := Color(0.35, 0.35, 0.45)
const SHADOW := Color(0.42, 0.24, 0.62)
var failed := false
var assertions := 0
var fallback_lines := 0
var textures: Array[Texture2D] = []
var rows: Dictionary = {}
var dialogue: Control

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failed = true
		push_error(message)

func _texture(path: String, color: Color) -> Texture2D:
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture := ImageTexture.create_from_image(image)
	texture.take_over_path(path)
	textures.append(texture)
	_check(ResourceLoader.exists(path) and load(path) == texture, "Synthetic texture is cached at " + path)
	return texture

func _face_path(id: String, body: String) -> String:
	return "res://assets/art/%s/%s%s_face.png" % [id, id, "_" + body if REGISTRY.get_bodies(id).size() > 1 else ""]

func _extra(line: Array) -> Dictionary:
	return line[2] if line.size() > 2 and line[2] is Dictionary else {}

func _show(index: int) -> void:
	dialogue.line_index = index
	dialogue._show_line()

## The pre-SYS-09 selection, independent of the new expression parameter.
func _old_portrait(id: String, body: String) -> Texture2D:
	for kind in ["face", "portrait"]:
		var found := ART._first_existing(id, body, kind)
		if found != null:
			return found
	var sheet := ART.original_character_sheet(id, body)
	if sheet == null:
		return null
	var idle := AtlasTexture.new()
	idle.atlas = sheet
	var cell := float(sheet.get_width() / 6)
	idle.region = Rect2(0, 0, cell, cell)
	return idle

func _same_texture(actual: Texture2D, expected: Texture2D) -> bool:
	if actual is AtlasTexture and expected is AtlasTexture:
		return actual.atlas == expected.atlas and actual.region == expected.region
	return actual == expected

func _baseline() -> void:
	var baseline_available := true
	var table: Dictionary = {}
	var csv := FileAccess.open("res://assets/i18n/story.csv", FileAccess.READ)
	csv.get_csv_line()
	while not csv.eof_reached():
		var row := csv.get_csv_line()
		if row.size() == 3:
			table[row[0]] = {"en": row[1], "ko": row[2]}
	for id in REGISTRY.get_character_ids():
		for body in REGISTRY.get_bodies(id):
			for face in ["happy", "angry", "hurt", "shadow"]:
				if ResourceLoader.exists(_face_path(id, body).get_basename() + "_" + face + ".png"):
					baseline_available = false
	if not baseline_available:
		print("NOTE: legacy no-expression baseline skipped because expression art has been adopted")
	# Every reachable line, including each hero's home variant, both bodies, both languages
	# and both art settings. Keep original neutral textures and independently compare old tints.
	for original in [true, false]:
		ART.style = ART.STYLE_ORIGINAL if original else ART.STYLE_PROTOTYPE
		for locale in ["ko", "en"]:
			TranslationServer.set_locale(locale)
			for hero in REGISTRY.get_character_ids():
				for body in REGISTRY.get_bodies(hero):
					for data: Dictionary in STORY.stages():
						for scene in ["pre", "mid", "post"]:
							var lines := STORY.dialogue_for(data, hero, scene)
							if lines.is_empty():
								continue
							dialogue.play(lines, hero, str(data.rival), body)
							for index in lines.size():
								_show(index)
								var line: Array = lines[index]
								var speaker := str(line[0])
								var hero_speaks := speaker == "hero"
								var narrator := speaker == "narrator"
								var shadow_scene := lines.any(func(entry: Array) -> bool: return entry[0] == "shadow")
								var other := hero if shadow_scene else str(data.rival)
								var tint := SHADOW if shadow_scene else Color.WHITE
								var key := STORY.resolve_id(str(line[1]), hero, str(data.rival))
								var face := str(_extra(line).get("face", ""))
								_check(face == "" or face in ["happy", "angry", "hurt"], "Allowed tag: " + key)
								if baseline_available:
									fallback_lines += 1
									_check(_same_texture(dialogue.left_face.texture, _old_portrait(hero, body)), "Legacy left texture: " + key)
									_check(dialogue.left_face.modulate == (Color.WHITE if hero_speaks else DIM), "Legacy left tint: " + key)
									_check(dialogue.left_face.visible == not narrator, "Legacy left visibility: " + key)
									_check(dialogue.right_face.visible == (not narrator and other != ""), "Legacy right visibility: " + key)
									_check(dialogue.right_face.modulate == (tint * DIM if hero_speaks else tint), "Legacy right tint: " + key)
									if other != "":
										_check(_same_texture(dialogue.right_face.texture, _old_portrait(other, body if shadow_scene else REGISTRY.get_bodies(other)[0])), "Legacy right texture: " + key)
								var cg := str(_extra(line).get("cg", ""))
								_check(dialogue.cg_picture.texture == (ART.original_texture(DIALOGUE.CG_ART % cg) if cg != "" else null), "CG metadata coexists: " + key)
								if rows.has(key):
									_check(rows[key].face == face, "One face per resolved ID: " + key)
								else:
									rows[key] = {"id": key, "speaker": speaker, "ko": table[key].ko, "en": table[key].en, "face": face}
							await process_frame
	ART.style = ART.STYLE_ORIGINAL
	TranslationServer.set_locale("en")

func _expressions() -> void:
	# All seven selectable bodies; the eighth ART-73 form (Brave Luna) is not a story hero.
	for hero in REGISTRY.get_character_ids():
		for body in REGISTRY.get_bodies(hero):
			var neutral := _texture(_face_path(hero, body), Color.GRAY)
			_check(ART.character_portrait(hero, body) == neutral, "Existing two-argument caller unchanged")
			for face in ["happy", "angry", "hurt"]:
				var expression := _texture(_face_path(hero, body).get_basename() + "_" + face + ".png", Color.GREEN)
				var lines := [["hero", "story.voice.{hero}.challenge", {"face": face}], ["hero", "story.voice.{hero}.arrive"], ["rival", "story.s02.pre.1", {"face": face}], ["rival", "story.s02.post.1"]]
				# Rival scenes use distinct IDs; rivals always use their registry default body.
				var other := "luna" if hero == "frey" else "frey"
				dialogue.play(lines, hero, other, body)
				_check(dialogue.left_face.texture == expression and dialogue.left_face.modulate == Color.WHITE, "Hero tag selects " + face)
				_show(1)
				_check(dialogue.left_face.texture == neutral, "Untagged hero resets to neutral")
				dialogue.play(lines, other, hero, REGISTRY.get_bodies(other)[0])
				_show(2)
				var rival_body: String = REGISTRY.get_bodies(hero)[0]
				_check(dialogue.right_face.texture == ART.character_portrait(hero, rival_body, face), "Rival tag uses rival default body")
				_check(dialogue.right_face.modulate == Color.WHITE and dialogue.left_face.modulate == DIM and dialogue.left_face.texture == ART.character_portrait(other, REGISTRY.get_bodies(other)[0]), "Rival speaks, neutral hero dims")
				_show(3)
				_check(dialogue.right_face.texture == ART.character_portrait(hero, rival_body), "Untagged rival resets to neutral")
				expression.take_over_path("user://sys09-retired-%d" % textures.size())
				_check(ART.character_portrait(hero, body, "sys09_absent_" + face) == neutral, "Missing expression falls back")
				await process_frame
			var shadow_lines := [["shadow", "story.shadow.{hero}.1"], ["hero", "story.voice.{hero}.echo", {"face": "angry"}], ["shadow", "story.shadow.{hero}.2", {"face": "happy"}]]
			var shadow_missing := not ResourceLoader.exists(_face_path(hero, body).get_basename() + "_shadow.png")
			dialogue.play(shadow_lines, hero, "", body)
			if shadow_missing:
				_check(dialogue.right_face.texture == neutral and dialogue.right_face.modulate == SHADOW, "Missing shadow uses tinted neutral")
			_show(1)
			if shadow_missing:
				_check(dialogue.right_face.texture == neutral and dialogue.right_face.modulate == SHADOW * DIM, "Inactive fallback shadow stays dimmed")
			var shadow := _texture(_face_path(hero, body).get_basename() + "_shadow.png", Color.PURPLE)
			var angry := _texture(_face_path(hero, body).get_basename() + "_angry.png", Color.RED)
			_show(0)
			_check(dialogue.right_face.texture == shadow and dialogue.right_face.modulate == Color.WHITE, "Adopted shadow has no purple tint")
			_show(1)
			_check(dialogue.left_face.texture == angry and dialogue.left_face.modulate == Color.WHITE, "Hero expression in shadow scene")
			_check(dialogue.right_face.texture == shadow and dialogue.right_face.modulate == DIM, "Inactive painted shadow only dims")
			_show(2)
			_check(dialogue.left_face.texture == neutral and dialogue.left_face.modulate == DIM, "Hero resets when shadow speaks")
			_check(dialogue.right_face.texture == shadow and dialogue.right_face.modulate == Color.WHITE, "Shadow identity takes priority over emotion tag")
			shadow.take_over_path("user://sys09-shadow-%d" % textures.size())
			angry.take_over_path("user://sys09-angry-%d" % textures.size())
			await process_frame
	# A partially adopted body must not borrow the opposite body's expression.
	var male := _texture("res://assets/art/nova/nova_male_face_sys09_partial.png", Color.BLUE)
	_check(ART.character_portrait("nova", "female", "sys09_partial") == ART.character_portrait("nova", "female"), "Female missing expression never borrows male")
	_check(ART.character_portrait("nova", "male", "sys09_partial") == male, "Male adoption is independent")
	_check(ART.character_portrait("nova", "female", "unknown") == ART.character_portrait("nova", "female"), "Unknown missing expression safely falls back")
	# An actual rival stage, with distinct hero and rival IDs, plus narrator/reset transitions.
	var frey := _texture("res://assets/art/frey/frey_face_happy.png", Color.YELLOW)
	dialogue.play([["hero", "story.voice.{hero}.arrive"], ["rival", "story.s02.pre.1", {"face": "happy"}], ["hero", "story.voice.{hero}.victory"], ["narrator", "story.s01.pre.1"]], "rio", "frey", "female")
	_show(1)
	_check(dialogue.right_face.texture == frey and dialogue.right_face.modulate == Color.WHITE, "Stage 2 rival face")
	_show(2)
	_check(dialogue.right_face.texture == ART.character_portrait("frey", "female") and dialogue.right_face.modulate == DIM, "Inactive rival resets to neutral")
	_show(3)
	_check(not dialogue.left_face.visible and not dialogue.right_face.visible, "Narrator hides faces")
	# No face or portrait at all: the old sheet/AtlasTexture fallback must still be purple.
	# This synthetic ID also keeps a missing-shadow fixture available after real art is adopted.
	dialogue._roster["sys09_sheet"] = {"name": "Frey", "color": Color.WHITE}
	var sheet := _texture("res://assets/art/sys09_sheet/sys09_sheet_sheet.png", Color.GRAY)
	dialogue.play([["shadow", "story.shadow.frey.1"]], "sys09_sheet", "", "female")
	_check(dialogue.right_face.texture is AtlasTexture and dialogue.right_face.texture.atlas == sheet, "Sheet-only portrait fallback")
	_check(dialogue.right_face.modulate == SHADOW, "Sheet-only fallback keeps purple tint")
	var independent := _texture("res://assets/art/sys09_sheet/sys09_sheet_face_happy.png", Color.GREEN)
	_check(ART.character_portrait("sys09_sheet", "female", "happy") == independent, "Expression can exist before neutral face art")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	dialogue = DIALOGUE.new()
	root.add_child(dialogue)
	await process_frame
	await _baseline()
	await _expressions()
	var counts := {"happy": 0, "angry": 0, "hurt": 0, "neutral": 0, "shadow": 0}
	for row: Dictionary in rows.values():
		counts[row.face if row.face != "" else ("shadow" if row.speaker == "shadow" else "neutral")] += 1
	var output := {"assertions": assertions, "fallback_lines": fallback_lines, "counts": counts, "rows": rows.values(), "passed": not failed}
	var report := OS.get_environment("STORY_FACE_REPORT")
	if report != "":
		var file := FileAccess.open(report, FileAccess.WRITE)
		file.store_string(JSON.stringify(output, "\t"))
	dialogue.queue_free()
	await process_frame
	print("STORY_FACES_RESULT " + JSON.stringify({"assertions": assertions, "fallback_lines": fallback_lines, "counts": counts, "passed": not failed}))
	quit(1 if failed else 0)
