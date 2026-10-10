extends SceneTree
## CODEX-ART-28: every attacker selects its own four-frame hit strip, missing character art falls
## back to the common strip, and the two real PlayerBase status states show ART-25 icons above UI.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const IDS := ["frey", "luna", "luna_brave", "nova", "rio", "yuki"]

var arena: Node2D
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_art_files()
	arena = Node2D.new()
	root.add_child(arena)
	var victim := _fighter("frey", 90)
	for index in IDS.size():
		var attacker := _fighter(IDS[index], index + 1)
		_expect_spark(victim, attacker, "res://assets/art/effects/hit/%s_hit.png" % IDS[index])
		attacker.queue_free()
		await process_frame
	var dummy := PLAYER_FACTORY.create()
	arena.add_child(dummy)
	dummy.setup_dummy(99)
	dummy.set_physics_process(false)
	_expect_spark(victim, dummy, "res://assets/art/effects/hit_spark.png")
	_test_status_icons(victim)
	arena.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Hit spark and fighter status icon tests passed")
	quit(0)

func _fighter(id: String, player_id: int) -> Node:
	var registry_id := "luna" if id == "luna_brave" else id
	var fighter := PLAYER_FACTORY.create(registry_id)
	arena.add_child(fighter)
	fighter.setup(CHARACTER_REGISTRY.get_characters()[registry_id], player_id, false)
	if id == "luna_brave":
		fighter.transformed = true
	fighter.set_physics_process(false)
	return fighter

func _test_art_files() -> void:
	for id in IDS:
		var path := "res://assets/art/effects/hit/%s_hit.png" % id
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image.is_empty():
			_fail("Missing hit strip: %s" % path)
			continue
		if image.get_size() != Vector2i(384, 96) or image.get_format() != Image.FORMAT_RGBA8:
			_fail("%s must be 384x96 RGBA8, got %s format %s" % [id, image.get_size(), image.get_format()])
		for frame in 4:
			var visible := 0
			for y in 96:
				for x in 96:
					var alpha := image.get_pixel(frame * 96 + x, y).a
					if alpha > 0.0 and alpha < 1.0:
						_fail("%s frame %d has partial alpha" % [id, frame])
					if alpha >= 0.5:
						visible += 1
			if visible < 12:
				_fail("%s frame %d is empty or unreadable (%d pixels)" % [id, frame, visible])

func _expect_spark(victim: Node, attacker: Node, expected_path: String) -> void:
	var before := arena.get_child_count()
	victim._spawn_hit_effect(Vector2(20, -20), 8.0, 420.0, attacker)
	var burst: AnimatedSprite2D
	for index in range(before, arena.get_child_count()):
		var child := arena.get_child(index)
		if child is AnimatedSprite2D and child.has_meta("hit_spark_path"):
			burst = child
			break
	if burst == null:
		_fail("No animated hit spark spawned for attacker %s" % attacker.character_id)
		return
	if str(burst.get_meta("hit_spark_path")) != expected_path:
		_fail("Attacker %s selected %s, expected %s" % [attacker.character_id, burst.get_meta("hit_spark_path"), expected_path])
	if burst.sprite_frames.get_frame_count(&"burst") != 4:
		_fail("Attacker %s spark should have four frames" % attacker.character_id)
	burst.queue_free()

func _test_status_icons(fighter: Node) -> void:
	var icon := fighter.get_node_or_null("StatusIcon") as Sprite2D
	if icon == null:
		_fail("PlayerBase should create a StatusIcon helper")
		return
	if icon.position.y + 14.0 >= fighter.name_label.position.y:
		_fail("Status icon overlaps the name/HP area")
	fighter.ultimate_armor_timer = 0.5
	fighter._update_status_icon(0.0)
	_expect_status(icon, "super_armor")
	fighter.hitstun_timer = 0.8
	fighter._play_stun_effect(0.8)
	fighter._update_status_icon(0.0)
	_expect_status(icon, "stun")
	fighter.hitstun_timer = 0.0
	fighter.status_stun_timer = 0.0
	fighter.ultimate_armor_timer = 0.0
	fighter._update_status_icon(0.0)
	if icon.visible:
		_fail("Status icon should hide when no supported state lasts")

func _expect_status(icon: Sprite2D, kind: String) -> void:
	if not icon.visible or icon.texture == null:
		_fail("%s status icon should be visible" % kind)
		return
	if icon.texture.resource_path != "res://assets/art/ui/status/%s.png" % kind:
		_fail("%s status selected wrong texture: %s" % [kind, icon.texture.resource_path])

func _fail(message: String) -> void:
	push_error(message)
	failed = true
