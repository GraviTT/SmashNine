extends SceneTree
## CODEX-ART-23/29: optional move atlases add distinct animations for each wired move, while a
## missing atlas preserves the old common-sheet pose.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
## Frey redrawn at 6 frames per motion (D33); the J chain moved to the move sheet (D34).
const ROW_COUNTS := {
	"attack_up": 6,
	"attack_down": 6,
	"attack_air_side": 6,
	"dash_strike": 6,
	"rising_cleave": 6,
	"spike_followup": 6,
	"descent": 6,
	"tumble": 6,
	"attack_chain": 6,
}
## Luna and Brave Luna redrawn at 6 frames (2026-10-14, D33-D36); the special transformation is 12.
const LUNA_ROW_COUNTS := {
	"luna_star_up": 6,
	"luna_star_down": 6,
	"luna_star_comet": 6,
	"luna_moon_ring": 6,
	"luna_transform": 12,
	"luna_tumble": 6,
	"luna_star_side": 6,
	"luna_brave_brave_combo": 6,
	"luna_brave_brave_upper": 6,
	"luna_brave_brave_low": 6,
	"luna_brave_brave_air_side": 6,
	"luna_brave_brave_dive": 6,
	"luna_brave_comet_drive": 6,
	"luna_brave_luna_breaker": 6,
	"luna_brave_heart_laser": 6,
	"luna_brave_tumble": 6,
}

var arena: Node2D
var failed := false
var generated_moves_sheet: ImageTexture

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	var image := Image.create(768, 1280, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	generated_moves_sheet = ImageTexture.create_from_image(image)
	var probe := _fighter(false)
	for row in ROW_COUNTS:
		var animation := StringName("frey_%s" % row)
		if not probe.character_sprite.sprite_frames.has_animation(animation):
			_fail("Frey move sheet should add %s" % animation)
		elif probe.character_sprite.sprite_frames.get_frame_count(animation) != int(ROW_COUNTS[row]):
			_fail("%s should have %d frames" % [animation, ROW_COUNTS[row]])
	probe.queue_free()
	await process_frame
	await _check_large_cell_sheet()
	await _check_long_row()

	await _expect_move("up J", "attack_up", func(fighter): fighter.perform_basic_attack("up", Vector2.UP))
	await _expect_move("down J", "attack_down", func(fighter): fighter.perform_basic_attack("down", Vector2.DOWN))
	await _expect_move("air-side J", "attack_air_side", func(fighter): fighter.perform_basic_attack("air_side", Vector2.RIGHT))
	await _expect_chain()
	await _expect_move("dash strike", "dash_strike", func(fighter): fighter.perform_skill_one())
	await _expect_move("rising cleave", "rising_cleave", func(fighter): fighter.perform_skill_two())
	await _expect_move("spike follow-up", "spike_followup", func(fighter):
		fighter.rising_followup_timer = 0.18
		fighter.try_skill_two_followup()
	)
	await _expect_move("descent", "descent", func(fighter): fighter.perform_ultimate())
	await _expect_strong_launch("Frey tumble", false, &"frey_tumble")

	var fallback := _fighter(true)
	fallback.perform_basic_attack("up", Vector2.UP)
	if fallback.character_sprite.animation != &"frey_attack" or int(fallback.character_sprite.frame) != 1:
		_fail("Without the move sheet, up J should fall back to frey_attack frame 1 (got %s frame %d)" % [fallback.character_sprite.animation, fallback.character_sprite.frame])
	if fallback.character_sprite.sprite_frames.has_animation(&"frey_attack_up"):
		_fail("The missing-sheet override should not add frey_attack_up")
	fallback.apply_forced_launch_hit(null, 1.0, Vector2(620.0, -260.0), 0.25, 620.0, Vector2.RIGHT)
	if fallback.character_sprite.animation != &"frey_hurt":
		_fail("Without the move sheet, a strong launch should keep the hurt fallback (got %s)" % fallback.character_sprite.animation)
	fallback.queue_free()
	await process_frame
	await _test_luna_rows_and_moves()
	await _test_character_moves("nova")
	await _test_character_moves("yuki")
	await _test_character_moves("rio")

	arena.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Move sheet tests passed (Frey, Luna, Brave Luna, Nova, Yuki, Rio rows and missing-sheet fallback)")
	quit(0)

func _fighter(missing_moves: bool) -> Node:
	var fighter: Node = PLAYER_FACTORY.create("frey")
	if missing_moves:
		fighter.moves_sheet_path_override = "res://tests/fixtures/missing_moves_sheet.png"
	arena.add_child(fighter)
	fighter.setup(CHARACTER_REGISTRY.get_characters()["frey"], 1, false)
	fighter.set_physics_process(false)
	fighter.is_dummy = true
	return fighter

func _expect_move(label: String, row: String, play: Callable) -> void:
	var fighter := _fighter(false)
	play.call(fighter)
	var expected := StringName("frey_%s" % row)
	if fighter.character_sprite.animation != expected:
		_fail("%s should play %s, got %s" % [label, expected, fighter.character_sprite.animation])
	fighter.queue_free()
	await process_frame

## The neutral J chain plays its own two frames of attack_chain per hit: 1-2, 3-4, 5-6.
func _expect_chain() -> void:
	var fighter := _fighter(false)
	for hit in 3:
		fighter.perform_basic_attack("neutral", Vector2.RIGHT)
		if fighter.character_sprite.animation != &"frey_attack_chain" or int(fighter.character_sprite.frame) != hit * 2:
			_fail("J chain hit %d should start frey_attack_chain frame %d (got %s frame %d)" % [hit + 1, hit * 2, fighter.character_sprite.animation, fighter.character_sprite.frame])
	fighter.queue_free()
	await process_frame

func _expect_strong_launch(label: String, brave: bool, expected: StringName) -> void:
	var fighter := _luna(brave) if label.begins_with("Luna") else _fighter(false)
	fighter.apply_forced_launch_hit(null, 1.0, Vector2(620.0, -260.0), 0.25, 620.0, Vector2.RIGHT)
	if fighter.character_sprite.animation != expected:
		_fail("%s should play %s, got %s" % [label, expected, fighter.character_sprite.animation])
	fighter.queue_free()
	await process_frame

func _test_luna_rows_and_moves() -> void:
	var probe := _luna(false)
	for animation_name in LUNA_ROW_COUNTS:
		var animation := StringName(animation_name)
		if not probe.character_sprite.sprite_frames.has_animation(animation):
			_fail("Luna move sheets should add %s" % animation)
		elif probe.character_sprite.sprite_frames.get_frame_count(animation) != int(LUNA_ROW_COUNTS[animation_name]):
			_fail("%s should have %d frames" % [animation, LUNA_ROW_COUNTS[animation_name]])
	probe.queue_free()
	await process_frame

	await _expect_luna("up star echo", "star_up", false, func(fighter): fighter.perform_basic_attack("up", Vector2.UP))
	await _expect_luna("down star echo", "star_down", false, func(fighter): fighter.perform_basic_attack("down", Vector2.DOWN))
	await _expect_luna("star comet", "star_comet", false, func(fighter): fighter.perform_skill_one())
	await _expect_luna("moon ring", "moon_ring", false, func(fighter): fighter.perform_skill_two())
	await _expect_luna("transformation", "transform", false, func(fighter): fighter.perform_ultimate())
	await _expect_luna("Brave uppercut", "brave_upper", true, func(fighter): fighter.perform_basic_attack("up", Vector2.UP))
	await _expect_luna("Brave low sweep", "brave_low", true, func(fighter): fighter.perform_basic_attack("down", Vector2.DOWN))
	await _expect_luna("Brave flying kick", "brave_air_side", true, func(fighter): fighter.perform_basic_attack("air_side", Vector2.RIGHT))
	await _expect_luna("Brave dive kick", "brave_dive", true, func(fighter): fighter.perform_basic_attack("air_down", Vector2.DOWN))
	await _expect_luna("Comet Drive", "comet_drive", true, func(fighter): fighter.perform_skill_one())
	await _expect_luna("Luna Breaker", "luna_breaker", true, func(fighter): fighter.perform_skill_two())
	await _expect_luna("Heart Laser", "heart_laser", true, func(fighter): fighter.try_ultimate_followup())
	await _expect_strong_launch("Luna normal tumble", false, &"luna_tumble")
	await _expect_strong_launch("Luna Brave tumble", true, &"luna_brave_tumble")

	var combo := _luna(true)
	var starts: Array[int] = []
	for hit in 3:
		combo._perform_brave_basic("neutral")
		starts.append(int(combo.character_sprite.frame))
	# Two frames per hit in the redrawn 6-frame row (2026-10-14): jab 1-2, body kick 3-4, spin kick 5-6.
	if combo.character_sprite.animation != &"luna_brave_brave_combo" or starts != [0, 2, 4]:
		_fail("Brave combo should use one row with jab/body/spin starts 0,2,4 (got %s, %s)" % [combo.character_sprite.animation, starts])
	combo.queue_free()
	await process_frame

func _luna(brave: bool) -> Node:
	var fighter: Node = PLAYER_FACTORY.create("luna")
	arena.add_child(fighter)
	fighter.setup(CHARACTER_REGISTRY.get_characters()["luna"], 2, false)
	fighter.set_physics_process(false)
	fighter.is_dummy = true
	if brave:
		fighter._enter_transformation()
	return fighter

func _expect_luna(label: String, row: String, brave: bool, play: Callable) -> void:
	var fighter := _luna(brave)
	play.call(fighter)
	var expected := StringName("luna_brave_%s" % row) if brave else StringName("luna_%s" % row)
	if fighter.character_sprite.animation != expected:
		_fail("%s should play %s, got %s" % [label, expected, fighter.character_sprite.animation])
	fighter.queue_free()
	await process_frame

func _test_character_moves(character_id: String) -> void:
	var probe := _move_fighter(character_id, true)
	var rows: Array = probe.get_move_sheet_rows()
	for spec in rows:
		var row := String(spec[0])
		var animation := StringName("%s_%s" % [character_id, row])
		if not probe.character_sprite.sprite_frames.has_animation(animation):
			_fail("%s move sheet should add %s" % [character_id.capitalize(), animation])
		elif probe.character_sprite.sprite_frames.get_frame_count(animation) != int(spec[1]):
			_fail("%s should have %d frames" % [animation, int(spec[1])])
	probe.queue_free()
	await process_frame

	for spec in rows:
		var row := String(spec[0])
		var fighter := _move_fighter(character_id, true)
		_play_character_row(fighter, character_id, row)
		var expected := StringName("%s_%s" % [character_id, row])
		if fighter.character_sprite.animation != expected:
			_fail("%s %s should play %s, got %s" % [character_id.capitalize(), row, expected, fighter.character_sprite.animation])
		fighter.queue_free()
		await process_frame

	for spec in rows:
		var row := String(spec[0])
		var fallback := _move_fighter(character_id, false)
		_play_character_row(fallback, character_id, row)
		var expected_fallback := StringName("%s_attack" % character_id)
		if character_id == "nova" and row == "vector_shift":
			expected_fallback = &"nova_jump"
		elif character_id == "rio" and row == "rune_shield":
			expected_fallback = &"rio_shield"
		elif row == "tumble":
			# A strong launch without the tumble row keeps the hurt frame (_play_launch_hit_sprite).
			expected_fallback = StringName("%s_hurt" % character_id)
		if fallback.character_sprite.animation != expected_fallback:
			_fail("%s %s without a move sheet should fall back to %s, got %s" % [character_id.capitalize(), row, expected_fallback, fallback.character_sprite.animation])
		fallback.queue_free()
		await process_frame

func _move_fighter(character_id: String, with_moves: bool) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(character_id)
	# Force setup to ignore any real sheet that may arrive from the parallel art unit.
	fighter.moves_sheet_path_override = "res://tests/fixtures/missing_moves_sheet.png"
	arena.add_child(fighter)
	fighter.setup(CHARACTER_REGISTRY.get_characters()[character_id], 3, false)
	fighter.set_physics_process(false)
	fighter.is_dummy = true
	if with_moves:
		fighter._add_move_sheet_animations(fighter.character_sprite.sprite_frames, character_id, generated_moves_sheet, fighter.get_move_sheet_rows())
	return fighter

func _play_character_row(fighter: Node, character_id: String, row: String) -> void:
	match character_id:
		"nova":
			match row:
				"vector_side": fighter.perform_basic_attack("neutral", Vector2.RIGHT)
				"vector_upper": fighter.perform_basic_attack("up", Vector2.UP)
				"compression_stomp": fighter.perform_basic_attack("down", Vector2.DOWN)
				"air_side": fighter.perform_basic_attack("air_side", Vector2.RIGHT)
				"meteor_kick": fighter.perform_basic_attack("air_down", Vector2.DOWN)
				"vector_shift": fighter.perform_skill_one()
				"gravity_brake": fighter.perform_skill_two()
				"slingshot_start": fighter.perform_ultimate()
				# New for Nova (2026-10-14): a strong launch plays her/his tumble row.
				"tumble": fighter.apply_forced_launch_hit(null, 1.0, Vector2(620.0, -260.0), 0.25, 620.0, Vector2.RIGHT)
		"yuki":
			match row:
				"talisman_side": fighter.perform_basic_attack("neutral", Vector2.RIGHT)
				"talisman_up": fighter.perform_basic_attack("up", Vector2.UP)
				"ground_ward": fighter.perform_basic_attack("down", Vector2.DOWN)
				"talisman_air_side": fighter.perform_basic_attack("air_side", Vector2.RIGHT)
				"talisman_air_down": fighter.perform_basic_attack("air_down", Vector2.DOWN)
				"seal_place": fighter.perform_skill_one()
				"seal_activate": fighter.perform_skill_two()
				"grand_ward": fighter.perform_ultimate()
				# New for Yuki (2026-10-14): a strong launch plays her tumble row.
				"tumble": fighter.apply_forced_launch_hit(null, 1.0, Vector2(620.0, -260.0), 0.25, 620.0, Vector2.RIGHT)
		"rio":
			match row:
				"mana_combo": fighter.perform_basic_attack("neutral", Vector2.RIGHT)
				"rising_slash": fighter.perform_basic_attack("up", Vector2.UP)
				"low_sweep": fighter.perform_basic_attack("down", Vector2.DOWN)
				"air_slash": fighter.perform_basic_attack("air_side", Vector2.RIGHT)
				"plunge": fighter.perform_basic_attack("air_down", Vector2.DOWN)
				"dimension_slash": fighter.perform_skill_one()
				"rune_shield": fighter.perform_skill_two()
				"infinity_overdrive": fighter.perform_ultimate()

## D34: a move sheet may use 192-px cells so big poses keep the idle head size; its frames stay
## 192 px (drawn 1:1, centred), and a cell smaller than the main sheet's is refused.
func _check_large_cell_sheet() -> void:
	var fighter := _move_fighter("frey", false)
	var frames: SpriteFrames = fighter.character_sprite.sprite_frames
	var large := Image.create(192 * 6, 192 * 10, false, Image.FORMAT_RGBA8)
	large.fill(Color.WHITE)
	if not fighter._add_move_sheet_animations(frames, "frey", ImageTexture.create_from_image(large), fighter.get_move_sheet_rows()):
		_fail("a 192-px move sheet should load")
	elif frames.get_frame_texture(&"frey_descent", 0).get_size() != Vector2(192, 192):
		_fail("192-px move frames should stay 192 px, got %s" % frames.get_frame_texture(&"frey_descent", 0).get_size())
	var small := Image.create(100 * 6, 100 * 8, false, Image.FORMAT_RGBA8)
	if fighter._add_move_sheet_animations(frames, "frey", ImageTexture.create_from_image(small), fighter.get_move_sheet_rows()):
		_fail("a move sheet with cells smaller than the main sheet should be refused")
	fighter.queue_free()
	await process_frame

## A row longer than six frames continues on the next sheet row, and the rows after it start below
## it (Luna's 12-frame transformation, 2026-10-14).
func _check_long_row() -> void:
	var fighter := _move_fighter("frey", false)
	var frames: SpriteFrames = fighter.character_sprite.sprite_frames
	var rows := [["probe_a", 4, 10.0, false], ["probe_long", 12, 12.0, false], ["probe_b", 6, 10.0, false]]
	var sheet := Image.create(192 * 6, 192 * 4, false, Image.FORMAT_RGBA8)
	if not fighter._add_move_sheet_animations(frames, "frey", ImageTexture.create_from_image(sheet), rows):
		_fail("a sheet with a 12-frame row (4 sheet rows) should load")
	else:
		var regions := {
			"frey_probe_long:0": Vector2(0, 192), "frey_probe_long:6": Vector2(0, 384),
			"frey_probe_long:11": Vector2(960, 384), "frey_probe_b:0": Vector2(0, 576),
		}
		for key in regions:
			var parts: PackedStringArray = key.split(":")
			var region: Rect2 = (frames.get_frame_texture(StringName(parts[0]), int(parts[1])) as AtlasTexture).region
			if region.position != regions[key]:
				_fail("%s should start at %s, got %s" % [key, regions[key], region.position])
	var short := Image.create(192 * 6, 192 * 3, false, Image.FORMAT_RGBA8)
	if fighter._add_move_sheet_animations(frames, "frey", ImageTexture.create_from_image(short), rows):
		_fail("a sheet one row short of the table's span should be refused")
	fighter.queue_free()
	await process_frame

func _fail(message: String) -> void:
	push_error(message)
	failed = true
