extends SceneTree
## Story presentation art (ART-70, D43): the dialogue box uses the 9-slice frame and name plate,
## and the lines the catalog marks show their scene picture behind the box.

const DIALOGUE := preload("res://scripts/ui/StoryDialogue.gd")
const STORY := preload("res://scripts/story/StoryCatalog.gd")
const ART := preload("res://scripts/ArtSettings.gd")
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _cg_lines(stage: int, scene: String) -> Array[String]:
	var marks: Array[String] = []
	for line: Array in STORY.stage(stage).dialogue[scene]:
		marks.append(str(line[2].cg) if line.size() > 2 else "")
	return marks

func _run() -> void:
	root.size = Vector2i(1280, 720)
	# Which lines carry a picture.
	_check(_cg_lines(1, "pre") == ["prologue", "prologue", "prologue", "", ""], "Prologue picture behind the three opening narration lines only")
	_check(_cg_lines(8, "post") == ["root", "root", "root"] and _cg_lines(8, "home_post") == ["root", "root"], "Root picture behind every line after Yuki or the home guardian")
	_check(_cg_lines(9, "post") == ["epilogue", "epilogue"], "Epilogue picture behind the closing narration")
	for stage in [2, 3, 4, 5, 6, 7]:
		_check(_cg_lines(stage, "pre").count("") == STORY.stage(stage).dialogue.pre.size(), "No picture in stage %d" % stage)
	for name in ["prologue", "root", "epilogue"]:
		var texture := ART.original_texture(DIALOGUE.CG_ART % name)
		_check(texture != null and texture.get_size() == Vector2(1600, 900), "Scene picture %s is 1600x900" % name)
	# The box, the plate and the picture in a played scene.
	var dialogue: Control = DIALOGUE.new()
	root.add_child(dialogue)
	await process_frame
	dialogue.play(STORY.dialogue_for(STORY.stage(1), "frey", "pre"), "frey", "", "female")
	var frame: NinePatchRect = null
	for child in dialogue.content.get_children():
		if child is NinePatchRect and child.texture != null and child.texture.resource_path == DIALOGUE.FRAME_ART:
			frame = child
	_check(frame != null and frame.patch_margin_left == DIALOGUE.FRAME_MARGIN and Rect2(frame.position, frame.size) == DIALOGUE.BOX, "Dialogue box uses the 9-slice frame")
	_check(dialogue.name_plate is NinePatchRect and dialogue.name_plate.texture.resource_path == DIALOGUE.PLATE_ART, "Speaker name sits on the name plate")
	_check(dialogue.cg_picture.visible and dialogue.cg_picture.texture.resource_path == DIALOGUE.CG_ART % "prologue", "Line 1 shows the prologue picture")
	_check(dialogue.cg_picture.get_index() < frame.get_index(), "Picture is drawn behind the box")
	var narrator_plate: Rect2 = Rect2(dialogue.name_plate.position, dialogue.name_plate.size)
	_check(is_equal_approx(narrator_plate.get_center().x, 640.0), "Narrator plate is centred")
	for step in 3:
		dialogue.line_index += 1
		dialogue._show_line()
	_check(dialogue.line_index == 3 and not dialogue.cg_picture.visible, "The hero's arrival line has no picture")
	_check(is_equal_approx(dialogue.name_plate.position.x, 212.0), "Hero plate sits over the hero's side")
	_check(dialogue.speaker_label.text == tr("Frey") and dialogue.name_plate.size.x >= 160.0, "Plate fits the speaker's name")
	dialogue.queue_free()
	if not failed:
		print("Story presentation tests passed (scene pictures on the marked lines, 9-slice box and name plate)")
	quit(1 if failed else 0)
