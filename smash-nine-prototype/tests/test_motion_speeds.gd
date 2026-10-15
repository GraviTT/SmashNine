extends SceneTree
## Motion speeds the user adopted in the motion viewer (2026-10-15: "모션 별 시간은 모션 뷰어에서 직접
## 조절 후 채택 버튼을 눌러 기록"): the game plays every recorded row at its adopted fps, for the right
## character, form and body, and rows without a record keep the table fps they were drawn for.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const MOTION_SPEEDS := preload("res://characters/common/MotionSpeeds.gd")

var arena: Node2D
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error(message)
	failed = true

func _fighter(id: String, body: String) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(id, body)
	arena.add_child(fighter)
	fighter.setup(CHARACTER_REGISTRY.get_characters()[id], 1, false)
	fighter.is_dummy = true
	fighter.ringout_y = 100000.0
	fighter.global_position = Vector2(0, -400)
	return fighter

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	var fighters := {}
	var checked := 0
	for key in MOTION_SPEEDS.FPS:
		var parts := String(key).split("/")
		var prefix := parts[0]
		var body := "" if parts[1] == "default" else parts[1]
		# Brave Luna's rows belong to Luna (luna_brave_*).
		var id := "luna" if prefix == "luna_brave" else prefix
		if not fighters.has(id + "/" + body):
			fighters[id + "/" + body] = _fighter(id, body)
			await physics_frame
		var frames: SpriteFrames = fighters[id + "/" + body].character_sprite.sprite_frames
		var animation := StringName("%s_%s" % [prefix, parts[2]])
		if not frames.has_animation(animation):
			_fail("%s: the game has no %s row" % [key, animation])
			continue
		var wanted := float(MOTION_SPEEDS.FPS[key])
		if absf(frames.get_animation_speed(animation) - wanted) > 0.001:
			_fail("%s should play at the adopted %.2f fps (got %.2f)" % [key, wanted, frames.get_animation_speed(animation)])
		checked += 1
	if checked < 90:
		_fail("Expected the 91 adopted rows of 2026-10-15 at least (checked %d)" % checked)
	# The two bodies keep their own speeds (Rio's attack row: male 14.7, female 13.65 fps).
	var rio_male: SpriteFrames = fighters["rio/male"].character_sprite.sprite_frames
	var rio_female: SpriteFrames = fighters["rio/female"].character_sprite.sprite_frames
	if absf(rio_male.get_animation_speed(&"rio_attack") - rio_female.get_animation_speed(&"rio_attack")) < 0.5:
		_fail("Rio's bodies should keep their own adopted attack speeds")
	# A row without a record plays at its table fps (Rio's tumble, Frey's idle).
	if absf(rio_male.get_animation_speed(&"rio_tumble") - 21.0) > 0.001:
		_fail("Rio's tumble has no record and should keep its 21 fps (got %.2f)" % rio_male.get_animation_speed(&"rio_tumble"))
	var frey: SpriteFrames = fighters["frey/"].character_sprite.sprite_frames
	if absf(frey.get_animation_speed(&"frey_idle") - 6.3) > 0.001:
		_fail("Frey's idle has no record and should keep 6.3 fps (D37)")
	# A one-body character's own body name (Frey is drawn female) finds the single-body record.
	if absf(MOTION_SPEEDS.fps("frey", "female", "walk", 13.3) - float(MOTION_SPEEDS.FPS["frey/default/walk"])) > 0.001:
		_fail("Frey's female body should play the default record")
	# No body asked for (tests, the dummy): male first, as the sheet loader picks the file.
	if absf(MOTION_SPEEDS.fps("rio", "", "attack", 21.0) - float(MOTION_SPEEDS.FPS["rio/male/attack"])) > 0.001:
		_fail("Rio without a body should use the male records, like its sheet")
	for fighter in fighters.values():
		fighter.queue_free()
	arena.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Motion speed tests passed (%d rows)" % checked)
	quit(0)
