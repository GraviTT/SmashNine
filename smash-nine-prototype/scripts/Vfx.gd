extends RefCounted
## Ultimate effect strips (assets/art/vfx/, CODEX-ART-10): each file is a horizontal strip of
## equal frames. spawn() turns one into an AnimatedSprite2D whose anchor point (from the art's
## README) sits on the given position; a one-shot effect frees itself after its last frame.
## Missing art, or the plain procedural style (F2), returns null so callers keep their shapes.
## Basic attack and skill strips (assets/art/attack_vfx/, CODEX-ART-13) use the same calls.

const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
const DIR := "res://assets/art/vfx/%s.png"
const ATTACK_DIR := "res://assets/art/attack_vfx/%s.png"
const EFFECTS_DIR := "res://assets/art/effects/%s.png"
const SKILL_DIR := "res://assets/art/effects/skill/%s.png"
## Peak opacity of the screen-filling ultimate flashes (Luna's transformation, Nova's collapse,
## Yuki's final burst). At full opacity they hid every fighter on screen for a moment, other
## players too; size and timing stay (sprite audit 2026-10-16, CODEX-QA-19 B7).
const ULTIMATE_FLASH_ALPHA := 0.7
const REALM_EFFECTS_DIR := "res://assets/art/effects/realm/%s.png"
const REALM_CENTER_DIR := "res://assets/art/realm_center/%s.png"
const HAZARDS_DIR := "res://assets/art/hazards/%s.png"
## Motion effects drawn with pixelfx (user 2026-11-04), 1 art px = 1 screen px.
const MOTION_DIR := "res://assets/art/effects/motion/%s.png"
## name: [frames, fps, anchor in the frame, additive(, folder pattern when not DIR)]
const SPECS := {
	"shadow_aura": [6, 10.0, Vector2(64, 160), false, "res://assets/art/story/%s.png"],
	"shadow_dissolve": [6, 12.0, Vector2(96, 152), false, "res://assets/art/story/%s.png"],
	"frey_ult_charge": [6, 24.0, Vector2(64, 124), true],
	"frey_ult_wave": [8, 30.0, Vector2(0, 96), true],
	"yuki_ult_seal": [8, 12.0, Vector2(128, 128), false],
	"yuki_ult_burst": [6, 30.0, Vector2(128, 128), true],
	"luna_ult_transform": [8, 24.0, Vector2(96, 96), true],
	"luna_ult_laser": [4, 24.0, Vector2(0, 48), true],
	"luna_ult_laser_head": [4, 24.0, Vector2(48, 48), true],
	"nova_ult_core": [6, 18.0, Vector2(64, 64), false],
	"nova_ult_burst": [8, 48.0, Vector2(128, 128), false],
	"rio_ult_circle": [6, 18.0, Vector2(96, 96), true],
	"rio_ult_impact": [6, 36.0, Vector2(32, 32), true],
	"frey_slash": [6, 36.0, Vector2(0, 64), true, ATTACK_DIR],
	"frey_k": [6, 30.0, Vector2(0, 48), true, ATTACK_DIR],
	"frey_l": [6, 30.0, Vector2(64, 188), true, ATTACK_DIR],
	"yuki_slash": [6, 30.0, Vector2(0, 64), true, ATTACK_DIR],
	"yuki_k": [6, 18.0, Vector2(64, 64), false, ATTACK_DIR],
	"yuki_l": [6, 24.0, Vector2(96, 96), true, ATTACK_DIR],
	"luna_slash": [6, 30.0, Vector2(0, 64), true, ATTACK_DIR],
	"luna_k": [6, 30.0, Vector2(0, 48), true, ATTACK_DIR],
	"luna_l": [6, 24.0, Vector2(96, 96), true, ATTACK_DIR],
	"luna_brave_slash": [6, 36.0, Vector2(0, 64), true, ATTACK_DIR],
	"nova_slash": [6, 36.0, Vector2(0, 64), true, ATTACK_DIR],
	"nova_k": [6, 30.0, Vector2(0, 48), true, ATTACK_DIR],
	"nova_l": [6, 24.0, Vector2(96, 188), false, ATTACK_DIR],
	"rio_slash": [6, 36.0, Vector2(0, 64), true, ATTACK_DIR],
	"rio_k": [6, 30.0, Vector2(0, 48), true, ATTACK_DIR],
	"rio_l": [6, 18.0, Vector2(0, 80), false, ATTACK_DIR],
	# CODEX-ART-17, drawn 1 art px = 1 screen px: Yuki's waiting seal, the quake (warning cracks
	# tiled along platform tops, impact bursts), animated middles of the hazard columns.
	"yuki_seal_idle": [4, 4.0, Vector2(32, 63), false, EFFECTS_DIR],
	"quake_warning": [4, 8.0, Vector2.ZERO, false, HAZARDS_DIR],
	"quake_impact": [6, 12.0, Vector2(64, 63), false, HAZARDS_DIR],
	"light_beam_mid": [6, 10.0, Vector2.ZERO, false, HAZARDS_DIR],
	"fire_pillar_mid": [6, 12.0, Vector2.ZERO, false, HAZARDS_DIR],
	# CODEX-ART-20, 1 art px = 1 screen px: the short flashes that were coloured rectangles.
	"parry_flash": [6, 40.0, Vector2(64, 64), true, EFFECTS_DIR],
	"landing_dust": [5, 41.667, Vector2(48, 31), false, EFFECTS_DIR],
	"hit_streak": [4, 50.0, Vector2(80, 12), true, EFFECTS_DIR],
	"yuki_seal_break": [5, 33.333, Vector2(48, 48), false, EFFECTS_DIR],
	# CODEX-ART-24, skill effects that replace procedural shapes. Callers retain those shapes
	# whenever this art is missing or F2 selects the prototype style.
	"luna_star_bloom": [6, 37.5, Vector2(128, 128), true, SKILL_DIR],
	"luna_moon_ring": [6, 25.0, Vector2(160, 160), true, SKILL_DIR],
	"luna_brave_aura": [6, 10.0, Vector2(64, 64), true, SKILL_DIR],
	"luna_comet_trail": [4, 40.0, Vector2(24, 24), true, SKILL_DIR],
	"luna_comet_burst": [6, 42.857, Vector2(112, 112), true, SKILL_DIR],
	"nova_gravity_burst": [6, 42.857, Vector2(256, 256), false, SKILL_DIR],
	"nova_momentum_trail": [4, 40.0, Vector2(32, 16), true, SKILL_DIR],
	"nova_vector_streak": [4, 33.333, Vector2(96, 24), true, SKILL_DIR],
	"nova_shift_dash": [4, 18.182, Vector2(48, 20), true, SKILL_DIR],
	"nova_shift_ready": [5, 35.714, Vector2(64, 64), true, SKILL_DIR],
	"nova_impact_star": [6, 40.0, Vector2(256, 256), true, SKILL_DIR],
	"nova_launch_flash": [5, 31.25, Vector2(128, 32), true, SKILL_DIR],
	"rio_rune_guard": [6, 12.0, Vector2(64, 64), true, SKILL_DIR],
	"rio_rune_burst": [6, 37.5, Vector2(160, 160), true, SKILL_DIR],
	"rio_blink_trail": [5, 31.25, Vector2(128, 32), true, SKILL_DIR],
	# CODEX-VFX-01 candidate a (user 2026-10-29): Rio's extra air jump, a mana step plate under the
	# soles; the anchor is the plate's top centre. `_last` is the brighter one for the last jump.
	"rio_air_step": [5, 40.0, Vector2(32, 3), false, SKILL_DIR],
	"rio_air_step_last": [5, 40.0, Vector2(32, 3), false, SKILL_DIR],
	# CODEX-VFX-03 picks (user 2026-11-03), Frey: the wings (a; drawn at 2x, shown at half size,
	# the anchor on her feet), the K sword wave (b, flies with the projectile), the descent light (b).
	"frey_wings": [6, 20.0, Vector2(128, 240), true, SKILL_DIR],
	"frey_wave": [4, 16.0, Vector2(64, 64), false, EFFECTS_DIR],
	"frey_ult_light": [6, 13.3, Vector2(168, 168), true],
	# CODEX-VFX-04 picks (user 2026-11-03), Luna: the barrier and its break (b), the cyclone around
	# her (b) and fired (a), the warp burst (b), the J stars. All shown at 1x on screen.
	"luna_barrier": [6, 10.0, Vector2(128, 128), true, SKILL_DIR],
	"luna_barrier_break": [6, 24.0, Vector2(128, 128), true, SKILL_DIR],
	"luna_cyclone": [6, 20.0, Vector2(96, 96), true, SKILL_DIR],
	"luna_cyclone_shot": [6, 20.0, Vector2(96, 96), true, SKILL_DIR],
	"luna_warp": [6, 24.0, Vector2(128, 128), true, SKILL_DIR],
	"luna_star_shot": [4, 16.0, Vector2(24, 24), false, EFFECTS_DIR],
	"luna_star_big": [4, 16.0, Vector2(48, 48), false, EFFECTS_DIR],
	# CODEX-VFX-05 picks (user 2026-11-03), Nova: the chain ring under a rooted fighter (b), the K
	# orb (a), the L field (b, its rim at 300 px at 1x), the I sphere (a; normal blend, the core is
	# black, drawn behind the fighters it swings).
	"nova_gravity_root": [6, 10.0, Vector2(48, 16), true, SKILL_DIR],
	"nova_orb": [4, 16.0, Vector2(32, 32), true, EFFECTS_DIR],
	"nova_field": [6, 8.0, Vector2(320, 320), true, SKILL_DIR],
	"nova_sphere": [6, 12.0, Vector2(160, 160), false],
	# CODEX-VFX-06 a (user 2026-11-03): the beam's curved-tendril tip, and on a hit the tip splitting
	# round the foe, then binding it while it is dragged (drawn with the cord from the left).
	"nova_beam_head": [4, 16.0, Vector2(24, 24), true, EFFECTS_DIR],
	"nova_beam_split": [4, 40.0, Vector2(80, 80), true, SKILL_DIR],
	"nova_beam_bind": [4, 12.0, Vector2(80, 80), true, SKILL_DIR],
	# pixelfx motion effects (user 2026-11-04: "현재 테스트로 만든 것들 전부 게임에 넣어볼 것"; comparisons
	# in reports/pixelfx-eval-2026-11-03/): Luna's idle stars, looped over her body (anchor on the feet;
	# v3, nothing round her head or face); her landing stardust; Frey's step dust behind the landing foot;
	# the sparks and gold glints after each J cut, from the body centre like frey_slash. The dust and the
	# stardust are soft-edged (normal blend, translucent); the others add.
	"luna_idle_stars": [16, 12.0, Vector2(64, 120), true, MOTION_DIR],
	"luna_land_stardust": [17, 20.0, Vector2(104, 72), false, MOTION_DIR],
	# The earlier, smaller stardust (v1) for small jumps (user 2026-11-04). The step dust starts on the
	# puff (v2 without its empty first and last drawings); its pace is set per step by the caller.
	"luna_land_stardust_small": [10, 20.0, Vector2(88, 56), false, MOTION_DIR],
	"frey_step_dust": [9, 16.0, Vector2(70, 34), false, MOTION_DIR],
	"frey_slash_sparks_1": [19, 20.0, Vector2(20, 64), true, MOTION_DIR],
	"frey_slash_sparks_2": [19, 20.0, Vector2(20, 64), true, MOTION_DIR],
	"frey_slash_sparks_3": [19, 20.0, Vector2(20, 64), true, MOTION_DIR],
	# The Frey pilot picks (pick cup 2026-11-04-frey, D49): the follow-through after her up, down and air J
	# from the body centre with the move's angle drawn in, the ground and air versions apart (candidate A, the
	# lead's pixelfx: the user's re-pick in round 2026-11-24; the 11-04 clip bug had put Codex's B in); the
	# afterglow her melee hits leave on the struck body (candidate A, the lead, kept by the same re-pick).
	"frey_jfx_up": [19, 20.0, Vector2(80, 210), true, MOTION_DIR],
	"frey_jfx_up_air": [19, 20.0, Vector2(80, 210), true, MOTION_DIR],
	"frey_jfx_down": [19, 20.0, Vector2(20, 80), true, MOTION_DIR],
	"frey_jfx_down_air": [19, 20.0, Vector2(60, 60), true, MOTION_DIR],
	"frey_jfx_side_air": [19, 20.0, Vector2(20, 70), true, MOTION_DIR],
	"frey_hit_after": [10, 20.0, Vector2(64, 56), true, MOTION_DIR],
	"frey_hit_after_big": [14, 20.0, Vector2(96, 80), true, MOTION_DIR],
	# The pick cup round 2026-11-19 winners (D49; candidates by Codex CODEX-VFX-08/09, A "the sharp moment",
	# B "the directional linger"). Frey's take-off and landing (A), at the feet; normal Luna's take-off and
	# steps (A); her J star's launch flash and the tail riding the star (A, turned to the aim; the tails
	# loop); the afterglow a landed star leaves (B). Brave Luna's J follow-through, one strip per move with
	# its angle and reach drawn in, from the body centre like luna_brave_slash (B; anchors left of or above
	# the frame put the strip ahead of her), and her melee hit afterglow (B).
	"frey_jump": [8, 24.0, Vector2(62, 9), true, MOTION_DIR],
	"frey_air_jump": [10, 30.0, Vector2(68, 9), true, MOTION_DIR],
	"frey_land": [8, 30.0, Vector2(62, 22), true, MOTION_DIR],
	"frey_land_big": [12, 30.0, Vector2(89, 34), true, MOTION_DIR],
	"luna_jump": [9, 30.0, Vector2(58, 9), true, MOTION_DIR],
	"luna_air_jump": [10, 30.0, Vector2(79, -1), true, MOTION_DIR],
	"luna_step": [7, 20.0, Vector2(52, 20), true, MOTION_DIR],
	"luna_star_launch": [6, 30.0, Vector2(1, 26), true, MOTION_DIR],
	"luna_star_launch_big": [7, 30.0, Vector2(1, 39), true, MOTION_DIR],
	"luna_star_trail": [8, 40.0, Vector2(90, 14), true, MOTION_DIR],
	"luna_star_trail_big": [10, 40.0, Vector2(128, 20), true, MOTION_DIR],
	"luna_hit_after": [12, 20.0, Vector2(76, 40), true, MOTION_DIR],
	"luna_hit_after_big": [16, 20.0, Vector2(96, 44), true, MOTION_DIR],
	"brave_rush_1": [10, 20.0, Vector2(-54, 23), true, MOTION_DIR],
	"brave_rush_2": [12, 20.0, Vector2(-61, 27), true, MOTION_DIR],
	"brave_rush_3": [14, 20.0, Vector2(-52, 85), true, MOTION_DIR],
	"brave_up": [14, 20.0, Vector2(-50, 146), true, MOTION_DIR],
	"brave_low": [12, 20.0, Vector2(-65, -13), true, MOTION_DIR],
	"brave_side_air": [12, 20.0, Vector2(-70, 38), true, MOTION_DIR],
	"brave_down_air": [16, 20.0, Vector2(8, -84), true, MOTION_DIR],
	"brave_hit_after": [12, 20.0, Vector2(73, 12), true, MOTION_DIR],
	"brave_hit_after_big": [16, 20.0, Vector2(102, 12), true, MOTION_DIR],
	"yuki_grand_ward": [8, 12.0, Vector2(320, 320), false, SKILL_DIR],
	"guard_bubble": [3, 1.0, Vector2(64, 64), false, SKILL_DIR],
	"attack_afterimage": [4, 57.143, Vector2(80, 32), true, SKILL_DIR],
	# Realm-state art and the animated shared portal (CODEX-ART-24).
	"portal_anim": [6, 8.0, Vector2(48, 48), false, REALM_CENTER_DIR],
	"seal_barrier": [6, 6.0, Vector2(128, 128), false, REALM_EFFECTS_DIR],
	"collapse_cracks": [6, 5.0, Vector2(160, 64), false, REALM_EFFECTS_DIR],
	"warning_edge": [6, 8.0, Vector2(160, 24), true, REALM_EFFECTS_DIR],
	# Xion's effects (CODEX-VFX-10, pick cup 2026-11-24): blast B, recoil B, the double's entrance A, dive trail A.
	# The tracer and the point-blank burst keep her code drawings (the user picked "now"; see CODE_DRAWN).
	"xion_blast": [6, 30.0, Vector2(8, 64), true, EFFECTS_DIR],
	"xion_bullet": [2, 20.0, Vector2(12, 4), true, EFFECTS_DIR],
	"xion_recoil_blast": [6, 30.0, Vector2(96, 16), true, SKILL_DIR],
	"xion_point_blank": [5, 36.0, Vector2(56, 56), true, SKILL_DIR],
	"xion_double_in": [6, 24.0, Vector2(64, 160), true, SKILL_DIR],
	"xion_dive_trail": [5, 31.0, Vector2(128, 24), true, SKILL_DIR],
	# Rio's kit v3 effects (CODEX-VFX-11, the user's picks in pick cup round 2026-11-27-rio): the sword B
	# (flying and stuck), backstab A, shadow blink B, counter stance A, decoy burst A. All additive, as the
	# clips the user judged showed them (four were drawn for normal blending).
	"rio_mana_sword": [4, 20.0, Vector2(48, 16), true, EFFECTS_DIR],
	"rio_mana_sword_stuck": [4, 8.0, Vector2(48, 16), true, EFFECTS_DIR],
	"rio_backstab": [5, 36.0, Vector2(48, 48), true, SKILL_DIR],
	"rio_shadow_blink": [6, 30.0, Vector2(64, 144), true, SKILL_DIR],
	"rio_counter_stance": [6, 15.0, Vector2(96, 152), true, SKILL_DIR],
	"rio_decoy_burst": [6, 30.0, Vector2(80, 80), true, SKILL_DIR],
}

## Frame widths the anchors and callers' scales were written for. A strip redrawn bigger
## (CODEX-ART-14/16: frames twice as large at 1x density) is drawn smaller by the ratio, so
## the same call shows it at the same size with finer pixels.
const AUTHORED_WIDTH := {
	"frey_ult_charge": 128, "frey_ult_wave": 256, "yuki_ult_seal": 256, "yuki_ult_burst": 256,
	"luna_ult_transform": 192, "luna_ult_laser": 128, "luna_ult_laser_head": 96, "nova_ult_core": 128,
	"nova_ult_burst": 256, "rio_ult_circle": 192, "rio_ult_impact": 64,
	"frey_slash": 192, "frey_k": 224, "frey_l": 128, "yuki_slash": 192, "yuki_k": 128, "yuki_l": 192,
	"luna_slash": 192, "luna_k": 160, "luna_l": 192, "luna_brave_slash": 224, "nova_slash": 160,
	"nova_k": 224, "nova_l": 192, "rio_slash": 192, "rio_k": 256, "rio_l": 128,
	"luna_star_bloom": 256, "luna_moon_ring": 320, "luna_brave_aura": 128,
	"luna_comet_trail": 48, "luna_comet_burst": 224, "nova_gravity_burst": 512,
	"nova_momentum_trail": 64, "nova_vector_streak": 192, "nova_shift_dash": 96,
	"nova_shift_ready": 128, "nova_impact_star": 512, "nova_launch_flash": 256,
	"rio_rune_guard": 128, "rio_rune_burst": 320, "rio_blink_trail": 256,
	"yuki_grand_ward": 640, "guard_bubble": 128, "attack_afterimage": 160,
	"portal_anim": 96, "seal_barrier": 256, "collapse_cracks": 320, "warning_edge": 320,
}

## Effects with a contract but no strip, because the user picked the code drawing over the candidates (Xion,
## pick cup 2026-11-24): spawn() returns null for them and the caller draws its own. A strip put in the folder
## later takes over; then drop the name here.
const CODE_DRAWN := ["xion_bullet", "xion_point_blank"]

## Effects whose contract is set but whose art is not picked yet (Rio's kit v3, CODEX-VFX-11): spawn() returns
## null for them and his code draws its stand-ins, until the picked file is in its folder; then drop the name.
const PENDING_ART := []

static var _cache: Dictionary = {}
static var _additive: CanvasItemMaterial

## local = true places the effect at `at` in the parent's space (it follows a moving parent).
static func spawn(parent: Node, effect: String, at: Vector2, scale := Vector2.ONE, loop := false, z := 4, tint := Color.WHITE, local := false) -> AnimatedSprite2D:
	var frames := _frames(effect, loop)
	if frames == null or parent == null:
		return null
	var spec: Array = SPECS[effect]
	var ratio := size_ratio(effect)
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Vfx_%s" % effect
	sprite.add_to_group("vfx")
	sprite.sprite_frames = frames
	sprite.centered = false
	sprite.offset = -spec[2] * ratio
	sprite.scale = scale / ratio
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = z
	sprite.modulate = tint
	if bool(spec[3]):
		sprite.material = _additive_material()
	parent.add_child(sprite)
	if local:
		sprite.position = at
	else:
		sprite.global_position = at
	sprite.play(&"play")
	if not loop:
		sprite.animation_finished.connect(sprite.queue_free)
	return sprite

## True when the effect art will draw (art present and the original style on).
static func available(effect: String) -> bool:
	return _frames(effect, false) != null

## The strip's frames as separate textures (for tiling a beam), or an empty array.
static func frame_textures(effect: String) -> Array[Texture2D]:
	var key := "%s/textures" % effect
	if not ART_SETTINGS.use_original():
		return [] as Array[Texture2D]
	if _cache.has(key):
		return _cache[key]
	var result: Array[Texture2D] = []
	var texture := ART_SETTINGS.original_texture(_path(effect))
	if texture != null:
		var image := texture.get_image()
		var count := int(SPECS[effect][0])
		var width := image.get_width() / count
		for index in count:
			result.append(ImageTexture.create_from_image(image.get_region(Rect2i(index * width, 0, width, image.get_height()))))
	_cache[key] = result
	return result

static func fps(effect: String) -> float:
	return float(SPECS[effect][1])

static func _frames(effect: String, loop: bool) -> SpriteFrames:
	if not SPECS.has(effect):
		push_warning("Unknown effect %s" % effect)
		return null
	var key := "%s/%s" % [effect, loop]
	# The style can change at runtime (F2), so it is checked before the cache.
	if not ART_SETTINGS.use_original():
		return null
	if _cache.has(key):
		return _cache[key]
	var texture := ART_SETTINGS.original_texture(_path(effect))
	if texture == null:
		return null
	var spec: Array = SPECS[effect]
	var count := int(spec[0])
	var size := Vector2i(texture.get_width() / count, texture.get_height())
	var frames := SpriteFrames.new()
	frames.clear_all()
	frames.add_animation(&"play")
	frames.set_animation_speed(&"play", float(spec[1]))
	frames.set_animation_loop(&"play", loop)
	for index in count:
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(index * size.x, 0, size.x, size.y)
		frames.add_frame(&"play", frame)
	_cache[key] = frames
	return frames

static func _path(effect: String) -> String:
	var spec: Array = SPECS[effect]
	return (spec[4] if spec.size() > 4 else DIR) % effect

## Frame width of an effect strip as callers measure it (the authored width; 0 when the art
## is missing). spawn() turns that into the file's real size.
static func frame_width(effect: String) -> float:
	var frames := _frames(effect, false)
	if frames == null:
		return 0.0
	return float(AUTHORED_WIDTH.get(effect, frames.get_frame_texture(&"play", 0).get_width()))

## Real frame width over the authored one (2 for a strip redrawn twice as large).
static func size_ratio(effect: String) -> float:
	var frames := _frames(effect, false)
	if frames == null or not AUTHORED_WIDTH.has(effect):
		return 1.0
	return float(frames.get_frame_texture(&"play", 0).get_width()) / float(AUTHORED_WIDTH[effect])

static func _additive_material() -> CanvasItemMaterial:
	if _additive == null:
		_additive = CanvasItemMaterial.new()
		_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _additive
