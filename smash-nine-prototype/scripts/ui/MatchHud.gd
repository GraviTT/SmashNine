extends CanvasLayer

## In-match overlay and the start / result screens.
##
## Match HUD (pick cup round 2026-11-25-ui, reports/ui-direction-2026-11-25): the fighter in focus
## is gathered at the bottom left (face, HP as a big number and a bar, souls toward the next card,
## the skill slots beside it); the clock and the survivor count sit top centre, the 3x3 realm map
## top right with the news stacked under it; a collapse warning is a red plate under the clock and
## the soul card offer a column at the bottom right. Flat plates on solid backs, and no HUD text
## under 16 px (MIN_FONT_SIZE).
## Test aids outside that layout: the live bot panel (F4, top left) and the debug text (F3). The
## bot panel shows other fighters' state for testing and leaves the game later (user 2026-11-25).
## Practice (PracticeSession) keeps the layout: the clock drops the survivors, the soul row counts
## the cards held, and practice's own lines stand at the bottom right over the control hints.

const AUDIO := preload("res://scripts/audio/AudioManager.gd")
const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
const LANGUAGE := preload("res://scripts/Language.gd")
const GAME_SPEED := preload("res://scripts/GameSpeed.gd")
const SOUL_CARDS := preload("res://scripts/match/SoulCards.gd")
const FRONTEND := preload("res://scripts/ui/StoryScreens.gd")
const ART_CREDITS := "Original art made for Smash Nine Realms (working title).  F2 switches realms and effects to the plain procedural look."
const TITLE_LOGO_ART := "res://assets/art/ui/title_logo.png"
const TITLE_BACKGROUND_ART := "res://assets/art/ui/title_bg.png"
const REALM_EMBLEM_ART := "res://assets/art/ui/realm_emblems/%s.png"
const HUD_FRAME_ART := "res://assets/art/ui/frames/%s.png"
const HUD_FRAME_MARGINS := {
	"skill_slot": 10,
	"hp_bar": 8,
	"card_panel": 14,
	"result_panel": 18,
	"menu_button": 10,
}
const CONTROLS_HINT := "A/D move  W jump  S+S drop  Space guard  J attack  K/L/U skills  I ultimate  Q portal  1-3 soul card  F3 debug  F4 bots"
## The other keys in one short line (user 2026-10-08: "화면 오른쪽 아래에 조작키를 간단히 표시하고,
## 스킬 아이콘도 간단하게"). The skill keys stand under their slots; this line sits in the bottom
## right corner and gives way to the soul card offer.
const CONTROLS_SHORT := "A/D move   W jump   S+S drop   Space guard   Q portal   F4 bots"
const SKILL_ICON_ART := "res://assets/art/skill_icons/%s.png"
const CARD_ICON_ART := "res://assets/art/ui/card_%s.png"
## U (the third skill, 2026-11-03 D47) shows only for a fighter that has one.
const SKILL_SLOTS: Array[String] = ["j", "k", "l", "u", "i"]
const SKILL_SLOT_SIZE := 56.0
const SKILL_SLOT_GAP := 10.0
## Under each slot: the key that uses it.
const SKILL_KEY_SIZE := Vector2(26, 20)
const SKILL_BAR_HEIGHT := 78.0
const SKILL_READY_COLOR := Color(1.0, 0.82, 0.35)
## Everything keeps this far from the screen edge.
const HUD_MARGIN := 16.0
## No HUD text is smaller than this (the audit of 2026-11-25 found nine kinds under 16 px, the
## minimap at 8). The test aids (bot panel, debug text) are the exception.
const MIN_FONT_SIZE := 16
## Places on the 1280x720 reference; _pin keeps each on its screen edge in any window shape.
const CLOCK_RECT := Rect2(405, 10, 470, 88)
const WARNING_RECT := Rect2(360, 106, 560, 60)
## Story mode: the rival's HP bar takes the place under the clock (StorySession, y 100-146).
const STORY_WARNING_Y := 158.0
const MINIMAP_RECT := Rect2(1078, 14, 186, 186)
const MINIMAP_CELL := Vector2(60, 43)
const MINIMAP_PITCH := Vector2(63, 46)
const FEED_RECT := Rect2(884, 214, 380, 150)
const PLAYER_RECT := Rect2(16, 596, 432, 112)
const SKILL_BAR_X := 464.0
## The soul card column fits right of a five-slot skill bar (it ends at x 784).
const CARD_WIDTH := 464.0
const CARD_HEAD := 34.0
const CARD_PADDING := 6.0
const CARD_ROW_MIN := 54.0
const CARD_ROW_GAP := 2.0
const CARD_TEXT_X := 110.0
## The control hints line in the bottom right corner, and practice's block over it.
const CONTROLS_HEIGHT := 28.0
const PRACTICE_WIDTH := 464.0
## Practice's clock capsule: the mode and the time, without the survivors.
const CLOCK_PRACTICE_WIDTH := 340.0
## Over the player's own fighter, from its feet.
const PLAYER_TAG_OFFSET := Vector2(0, -114)
## The words over a portal ("Q DOWN: ..." and its countdown, RealmWorld): the P1 tag rises over them.
const PORTAL_LABELS := "portal_labels"
const OFFSCREEN_BUBBLE := 36.0
## Live bot panel (F4, development aid 2026-10-08): on by default while the game is tested.
const BOT_PANEL_SHOWN_AT_START := true
const BOT_PANEL_WIDTH := 300.0
const BOT_ROW_FACE := 26.0
## A message stays this long under the map, the last part of it fading.
const MESSAGE_TIME := 4.0
const MESSAGE_FADE := 0.6
const MESSAGE_ROWS := 3
const PLATE := Color(0.047, 0.07, 0.125, 0.88)
const PLATE_SOLID := Color(0.047, 0.07, 0.125, 0.97)
const EDGE := Color(1, 1, 1, 0.16)
const GOLD := Color("f3cd7c")
const DIM := Color("b7c3d6")
const WHITE := Color("f5f8fc")
const INK := Color("101827")
const KEY_CAP := Color(0.93, 0.95, 0.98, 0.95)
const DANGER := Color("ff6a3d")
const DANGER_PLATE := Color(0.36, 0.05, 0.06, 0.92)
const HAZARD_PLATE := Color(0.34, 0.2, 0.03, 0.92)
const HP_LOW := Color("ee4a3a")
const HP_MID := Color("f2b632")
const HP_FULL := Color("3ecf6a")
const SOUL := Color("9a86ff")
const MINIMAP_STABLE := Color(0.12, 0.16, 0.23, 0.95)
## Soul card kinds by head colour: stat cards gold, action cards sky, a fighter's own cards pink
## (D54 adds the third kind; an unknown kind falls back to gold).
const CARD_KIND_COLOR := {"stat": Color("f3cd7c"), "action": Color("5fd0ff"), "exclusive": Color("ff7ab8"), "character": Color("ff7ab8")}
const PANEL_COLOR := Color(0.03, 0.03, 0.07, 0.78)
## The results table hides the match behind it (QA-15: the world showed through at 0.78).
const RESULTS_BACK_COLOR := Color(0.03, 0.03, 0.07, 0.92)
## Cut-in band heights: above the fighters when the caster is in the lower half of the screen,
## below them otherwise, so the band never covers the cast itself (Codex QA-12: at a fixed
## y 230 it hid Frey and the first wave). The low band stays clear of the player's plate.
const CUTIN_HIGH_Y := 172.0
const CUTIN_LOW_FROM_BOTTOM := 250.0
const CARD_COLOR := Color(0.1, 0.08, 0.2, 0.92)
const TEXT_DIM := Color(1.0, 1.0, 1.0, 0.7)
const REFERENCE_SIZE := Vector2(1280, 720)
const TOP_LEFT := Vector2(0.0, 0.0)
const TOP_CENTER := Vector2(0.5, 0.0)
const TOP_RIGHT := Vector2(1.0, 0.0)
const BOTTOM_LEFT := Vector2(0.0, 1.0)
const BOTTOM_CENTER := Vector2(0.5, 1.0)
const BOTTOM_RIGHT := Vector2(1.0, 1.0)

## The heavier cut of the UI font, for numbers and names.
var bold: FontVariation
## Every block of the match HUD sits in this box: it covers the view, never less than 1280x720
## of its own units, and on a smaller view it is drawn smaller as a whole (_fit_hud_root). The
## blocks are pinned to its edges, so they follow it when the view changes.
var hud_root: Control
## Clock: the phase (in story mode the stage and its objective), the match time, the survivors
## and the next timeline event under them.
var clock_root: Control
var clock_plate: Panel
var clock_label: Label
var time_label: Label
var clock_divider: Panel
var alive_caption: Label
var alive_label: Label
var alive_total: Label
var next_plate: Panel
var next_label: Label
var next_time: Label
var story_layout := false
var practice_layout := false
## 3x3 realm map: a colour per state and the fighters there as a number; the shown realm's name
## and its hazard under it. realm index -> {"back", "emblem", "count"}
var minimap_root: Control
var minimap_plate: Panel
var minimap_grid: Control
var minimap_cells: Dictionary = {}
var minimap_current := -1
var realm_label: Label
var hazard_label: Label
## Match messages under the map, newest last. info_label keeps the latest one's plain text.
var feed_root: Control
var feed_rows: Array[Dictionary] = []
var info_label: Label
var info_timer := 0.0
## The plate under the clock: a realm about to collapse (with its countdown) or a hazard.
var warning_root: Control
var warning_plate: Panel
var warning_label: Label
var warning_line: Label
var warning_number: Label
## The fighter in focus (P1, or the fighter being watched).
var player_root: Control
var focus_frame: Panel
var focus_accent: Panel
var focus_portrait: TextureRect
var focus_portrait_key := ""
var focus_name: Label
var kos_label: Label
var hp_label: Label
var hp_max_label: Label
var hp_bar: Control
var hp_fill: Panel
var soul_well: Panel
var soul_fill: Panel
var soul_label: Label
## Practice: the cards held, in the soul row (set_practice_status).
var status_label: Label
## Practice's own lines (build_practice_lines).
var practice_label: Label
var _gaps: RegEx
## "P1" over the player's own fighter.
var player_tag: Control
var skill_bar: Control
var controls_label: Label
var controls_height := CONTROLS_HEIGHT
## The hints and practice's lines as last laid out (_process lays out words written from outside).
var _controls_text_shown := ""
var _practice_text_shown := ""
## slot -> {"style", "icon", "glyph", "key", "shade", "time", "count", "count_back"}
var skill_slots: Dictionary = {}
var skill_icon_set := ""
var skill_pulse := 0.0
## Soul card offer: a time bar and one row per card.
var card_panel: Control
var card_head_plate: Panel
var card_title: Label
var card_hint: Label
var card_time: Label
var card_bar_back: Panel
var card_bar: Panel
var card_back: Panel
var card_frame: Control
var card_rows: Array[Dictionary] = []
var card_labels: Array[Label] = []
var card_icons: Array[TextureRect] = []
## The first letter of a card that has no icon yet, in its icon's place (D54: the new cards).
var card_letters: Array[Label] = []
var _card_signature := ""
var _card_full_time := 0.0
var _card_last_left := 0.0
## An offer runs on a clock; practice's card list does not (show_card_list).
var _card_timed := true
## Where the rows begin under the head (two header lines when the keys do not fit beside the title).
var _card_head := CARD_HEAD
var debug_label: Label
var results_grid: GridContainer
var overlay: Control
var overlay_back: ColorRect
var overlay_background_art: TextureRect
var result_panel_frame: Control
var menu_frame_root: Control
## The bot panel's on/off choice (F4), kept while screens hide the match HUD.
var bot_panel_wanted := BOT_PANEL_SHOWN_AT_START
var overlay_title: Label
var overlay_logo: TextureRect
var portrait_strip: Control
## Ultimate cut-in: a slanted band in the caster's colour with the face, name and ultimate name.
var cutin_root: Control
var cutin_band: Panel
var cutin_stripe: Panel
var cutin_face: TextureRect
var cutin_name: Label
var cutin_title: Label
var cutin_tween: Tween
var flash_rect: ColorRect
## Faces at the screen edge toward fighters in the shown realm who are off screen (realms are
## bigger than the view since 2026-10-08). Each: {"root", "arrow", "ring", "face"}
var offscreen_root: Control
var offscreen_markers: Array[Dictionary] = []
## Top-left list of every fighter: face, realm, HP and what its bot is trying to do. A test aid
## (F4), not part of the match HUD.
var bot_panel: PanelContainer
var bot_rows: VBoxContainer
var bot_row_nodes: Array = []
var flash_tween: Tween
var overlay_body: Label
var overlay_credits: Label
var frontend: FRONTEND
## The match HUD is on screen (the start, result and story screens hide it).
var _hud_shown := true
var _pulse := 0.0

func _init() -> void:
	LANGUAGE.load_saved()

func _ready() -> void:
	name = "UI"
	bold = FontVariation.new()
	bold.base_font = ThemeDB.fallback_font
	bold.variation_embolden = 0.7
	hud_root = Control.new()
	hud_root.name = "HudRoot"
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_root)
	_fit_hud_root()
	get_viewport().size_changed.connect(_fit_hud_root)
	_build_clock()
	_build_minimap()
	_build_feed()
	_build_warning()
	_build_player()
	_build_skill_bar()
	_build_controls()
	# Over the plates: the player's own mark and the off-screen faces are never hidden by one.
	_build_offscreen()
	_build_player_tag()
	_build_card_panel()
	_build_cutin()
	_build_bot_panel()
	debug_label = _label(Vector2(330, 180), Vector2(390, 360), 13, HORIZONTAL_ALIGNMENT_LEFT)
	debug_label.visible = false
	_pin(debug_label, TOP_LEFT)
	_build_overlay()

func _process(delta: float) -> void:
	_pulse += delta
	# The view can change without a size_changed the blocks hear (the web build at a 1.5 device
	# pixel ratio kept the HUD on 1280x720 places over an 853x480 view, 2026-11-27): checked here too.
	_fit_hud_root()
	# Words written straight into these labels from outside (the gamepad's) get their layout here.
	if controls_label.text != _controls_text_shown:
		set_control_hints(controls_label.text)
	if is_instance_valid(practice_label) and practice_label.text != _practice_text_shown:
		set_practice_lines(practice_label.text)

## The root box covers the view. It is never under 1280x720 of its own units: on a smaller view
## (the web build showed 853x480 at a 1.5 device pixel ratio) it is scaled down whole, so the
## blocks keep the places and room they have at 1280x720 instead of crowding. Setting its size
## moves every block pinned to its edges.
func _fit_hud_root() -> void:
	var view := get_viewport().get_visible_rect().size
	if view.x <= 0.0 or view.y <= 0.0:
		return
	var fit := minf(1.0, minf(view.x / REFERENCE_SIZE.x, view.y / REFERENCE_SIZE.y))
	var layout := view / fit
	if hud_root.size.is_equal_approx(layout) and is_equal_approx(hud_root.scale.x, fit):
		return
	hud_root.position = Vector2.ZERO
	hud_root.scale = Vector2(fit, fit)
	hud_root.size = layout

# --- Small builders ---

## Re-expresses a control laid out on the 1280x720 reference as an offset from an
## anchor point, e.g. (0.5, 1) = bottom centre.
func _pin(control: Control, anchor: Vector2) -> void:
	var position := control.position
	var size := control.size
	control.anchor_left = anchor.x
	control.anchor_right = anchor.x
	control.anchor_top = anchor.y
	control.anchor_bottom = anchor.y
	control.offset_left = position.x - anchor.x * REFERENCE_SIZE.x
	control.offset_top = position.y - anchor.y * REFERENCE_SIZE.y
	control.offset_right = control.offset_left + size.x
	control.offset_bottom = control.offset_top + size.y

## A block of the HUD: an empty control at `rect` of the reference, kept on `anchor`'s edge.
func _root(node_name: String, rect: Rect2, anchor: Vector2) -> Control:
	var control := Control.new()
	control.name = node_name
	control.position = rect.position
	control.size = rect.size
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(control)
	_pin(control, anchor)
	return control

func _box(color: Color, border := Color.TRANSPARENT, width := 0, radius := 4, skew := 0.0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.skew = Vector2(skew, 0)
	box.anti_aliasing = true
	return box

func _plate(parent: Node, rect: Rect2, box: StyleBoxFlat) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", box)
	parent.add_child(panel)
	return panel

func _text(parent: Node, text: String, rect: Rect2, font_size: int, color := WHITE, heavy := false, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	# Clip first: a Label's size is clamped up to its text's width unless it clips.
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	label.add_theme_constant_override("outline_size", 3)
	if heavy:
		label.add_theme_font_override("font", bold)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _picture(parent: Node, texture: Texture2D, rect: Rect2, pixel := true) -> TextureRect:
	var picture := TextureRect.new()
	# Before the size: a TextureRect is otherwise held at its texture's own size.
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture = texture
	picture.position = rect.position
	picture.size = rect.size
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if pixel else CanvasItem.TEXTURE_FILTER_LINEAR
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(picture)
	return picture

## Korean wraps between any two syllables, so a line could end inside a word ("착 / 지"). A word
## joiner (U+2060) between the letters of each word keeps the breaks at the spaces.
func _keep_words(text: String) -> String:
	var words: PackedStringArray = []
	for word in text.split(" "):
		words.append("⁠".join(word.split("")))
	return " ".join(words)

## A label for the test aids: outlined text straight on the screen.
func _label(position: Vector2, size: Vector2, font_size: int, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.position = position
	label.size = size
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 4)
	hud_root.add_child(label)
	return label

## Loads an authored 9-slice in original-art mode. The returned ColorRect preserves the
## exact previous block-colour presentation for F2 prototype mode and missing files.
func _hud_frame(frame_id: String, frame_size: Vector2, fallback_color: Color, node_name: String) -> Control:
	var texture := ART_SETTINGS.original_texture(HUD_FRAME_ART % frame_id)
	if texture == null:
		var fallback := ColorRect.new()
		fallback.name = node_name
		fallback.size = frame_size
		fallback.color = fallback_color
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return fallback
	var frame := NinePatchRect.new()
	frame.name = node_name
	frame.size = frame_size
	frame.texture = texture
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var margin: int = int(HUD_FRAME_MARGINS.get(frame_id, 8))
	frame.patch_margin_left = margin
	frame.patch_margin_top = margin
	frame.patch_margin_right = margin
	frame.patch_margin_bottom = margin
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return frame

## A portrait slot: painted faces scale smoothly, pixel portraits stay crisp.
func _portrait_rect(position: Vector2, size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.position = position
	rect.size = size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

func _set_portrait(rect: TextureRect, texture: Texture2D) -> void:
	rect.texture = texture
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if ART_SETTINGS.is_painted_portrait(texture) else CanvasItem.TEXTURE_FILTER_NEAREST

func _format_time(seconds: float) -> String:
	var whole := maxi(0, int(seconds))
	return "%d:%02d" % [whole / 60, whole % 60]

## A countdown shows the second it is in: 28.4 s left reads 0:29, as the warning plate's seconds
## do (MatchDirector.get_warning_seconds_left). The clock used to say 0:28 beside the plate's 29.
func _format_countdown(seconds: float) -> String:
	return _format_time(ceilf(maxf(seconds, 0.0)))

# --- Clock, survivors, next event ---

func _build_clock() -> void:
	clock_root = _root("Clock", CLOCK_RECT, TOP_CENTER)
	clock_plate = _plate(clock_root, Rect2(0, 0, 470, 50), _box(PLATE_SOLID, EDGE, 1, 4, 0.22))
	clock_label = _text(clock_root, "", Rect2(22, 0, 196, 50), MIN_FONT_SIZE, DIM)
	time_label = _text(clock_root, "", Rect2(218, 0, 100, 50), 30, WHITE, true, HORIZONTAL_ALIGNMENT_RIGHT)
	clock_divider = _plate(clock_root, Rect2(334, 10, 1, 30), _box(EDGE, Color.TRANSPARENT, 0, 0))
	alive_caption = _text(clock_root, tr("Alive"), Rect2(348, 0, 46, 50), MIN_FONT_SIZE, DIM)
	alive_label = _text(clock_root, "", Rect2(392, 0, 34, 50), 24, WHITE, true, HORIZONTAL_ALIGNMENT_RIGHT)
	alive_total = _text(clock_root, "", Rect2(430, 2, 36, 50), MIN_FONT_SIZE, DIM)
	next_plate = _plate(clock_root, Rect2(95, 56, 280, 32), _box(Color(PLATE, 0.84), Color.TRANSPARENT, 0, 4, 0.22))
	next_label = _text(next_plate, "", Rect2(14, 0, 170, 32), MIN_FONT_SIZE, DIM)
	next_time = _text(next_plate, "", Rect2(184, 0, 82, 32), 20, GOLD, true, HORIZONTAL_ALIGNMENT_RIGHT)
	next_plate.visible = false

func set_clock(phase: String, elapsed: float, next_name: String, next_in: float) -> void:
	if story_layout:
		# StorySession writes the stage and its objective (set_story_objective).
		return
	clock_label.text = phase
	time_label.text = _format_time(elapsed)
	next_plate.visible = next_name != ""
	next_label.text = tr(next_name)
	next_time.text = _format_countdown(next_in)

## Story mode: the clock plate carries the stage and its objective in place of the phase, the
## time and the survivors, and warnings sit under the rival's HP bar.
func set_story_layout(enabled: bool) -> void:
	story_layout = enabled
	for node: Control in [time_label, clock_divider, alive_caption, alive_label, alive_total]:
		node.visible = not enabled
	if enabled:
		next_plate.visible = false
	clock_label.size.x = 426.0 if enabled else 196.0
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if enabled else HORIZONTAL_ALIGNMENT_LEFT
	clock_label.add_theme_font_size_override("font_size", 18 if enabled else MIN_FONT_SIZE)
	clock_label.add_theme_color_override("font_color", WHITE if enabled else DIM)
	if enabled:
		clock_label.add_theme_font_override("font", bold)
	else:
		clock_label.remove_theme_font_override("font")
	var top := STORY_WARNING_Y if enabled else WARNING_RECT.position.y
	warning_root.offset_top = top
	warning_root.offset_bottom = top + WARNING_RECT.size.y

func set_story_objective(stage: String, objective: String, shown: bool) -> void:
	clock_label.text = stage + "   |   " + objective
	clock_label.visible = shown
	clock_root.visible = shown

# --- Minimap ---

func _build_minimap() -> void:
	minimap_root = _root("RealmMinimap", MINIMAP_RECT, TOP_RIGHT)
	minimap_plate = _plate(minimap_root, Rect2(-6, -6, 198, 176), _box(Color(PLATE, 0.66), Color.TRANSPARENT, 0, 6))
	minimap_grid = Control.new()
	minimap_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap_root.add_child(minimap_grid)
	realm_label = _text(minimap_root, "", Rect2(-6, 140, 198, 26), MIN_FONT_SIZE, WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	hazard_label = _text(minimap_root, "", Rect2(-6, 162, 198, 24), MIN_FONT_SIZE, DIM, false, HORIZONTAL_ALIGNMENT_CENTER)

func rebuild_minimap(layout: RefCounted, director: Node, current_index: int) -> void:
	for child in minimap_grid.get_children():
		child.queue_free()
	minimap_cells.clear()
	minimap_current = current_index
	for i in layout.realm_count():
		var realm: Dictionary = layout.get_realm(i)
		var grid: Vector2i = realm.grid
		var cell := Control.new()
		cell.position = Vector2(grid.x * MINIMAP_PITCH.x, grid.y * MINIMAP_PITCH.y)
		cell.size = MINIMAP_CELL
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		minimap_grid.add_child(cell)
		var back := _plate(cell, Rect2(Vector2.ZERO, MINIMAP_CELL), _box(MINIMAP_STABLE, Color.TRANSPARENT, 0, 4))
		var realm_name := str(realm.name)
		var emblem_texture := _realm_emblem_texture(realm_name)
		var emblem: Control
		if emblem_texture != null:
			emblem = _picture(cell, emblem_texture, Rect2(3, 5, 32, 32))
		else:
			# Without the emblems (F2): the first letters of the realm's name.
			emblem = _text(cell, tr(realm_name).left(2), Rect2(3, 0, 30, MINIMAP_CELL.y), MIN_FONT_SIZE, DIM)
		var count := _text(cell, "", Rect2(30, 0, 30, MINIMAP_CELL.y), 21, WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
		minimap_cells[i] = {"back": back, "emblem": emblem, "count": count}
	update_minimap_labels(director, {})

func _realm_emblem_texture(realm_name: String) -> Texture2D:
	var key := realm_name.to_lower().replace(" ", "_")
	return ART_SETTINGS.original_texture(REALM_EMBLEM_ART % key)

## counts: realm_index -> living combatants there. A realm's state is its cell's colour (about to
## collapse: pulsing orange; collapsed: black with a cross; sealed: grey) and the fighters there
## its number; the shown realm has the gold edge.
func update_minimap_labels(director: Node, counts: Dictionary) -> void:
	for i: int in minimap_cells:
		var nodes: Dictionary = minimap_cells[i]
		var back: Panel = nodes.back
		if not is_instance_valid(back):
			continue
		var state: String = director.get_state(i)
		var box: StyleBoxFlat = back.get_theme_stylebox("panel")
		var count: Label = nodes.count
		var emblem: Control = nodes.emblem
		var here := int(counts.get(i, 0))
		count.text = str(here) if here > 0 and (state == "stable" or state == "warning") else ""
		count.add_theme_color_override("font_color", WHITE)
		emblem.modulate = Color.WHITE
		match state:
			"warning":
				box.bg_color = Color(0.78, 0.2, 0.08, 0.96).lerp(Color(1.0, 0.42, 0.16, 0.96), 0.5 + 0.5 * sin(_pulse * 7.0))
			"collapsed":
				box.bg_color = Color(0.02, 0.02, 0.03, 0.9)
				emblem.modulate = Color(1, 1, 1, 0.16)
				count.text = "×"
				count.add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
			"locked":
				box.bg_color = Color(0.2, 0.2, 0.25, 0.9)
				emblem.modulate = Color(1, 1, 1, 0.45)
			_:
				box.bg_color = MINIMAP_STABLE
		box.border_color = GOLD if i == minimap_current else Color.TRANSPARENT
		box.set_border_width_all(3 if i == minimap_current else 0)

## text: "<realm>  -  <subtitle>" from Main; the map shows the realm's name and, under it, the
## name of its hazard.
func set_realm_title(text: String, _accent: Color, hazard_text := "") -> void:
	realm_label.text = text.get_slice("  -  ", 0)
	hazard_label.text = hazard_text
	minimap_plate.size.y = 198.0 if hazard_text != "" else 176.0

# --- Messages ---

## info_label draws nothing: it keeps the newest message's text, and its visible flag says whether
## that message is still up, as the one message line of the old HUD did (practice and the tests
## read both; hiding it takes the messages down at the next tick).
func _build_feed() -> void:
	feed_root = _root("Messages", FEED_RECT, TOP_RIGHT)
	info_label = Label.new()
	info_label.name = "LastMessage"
	info_label.clip_text = true
	info_label.size = Vector2.ZERO
	info_label.self_modulate = Color(1, 1, 1, 0)
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_label.visible = false
	hud_root.add_child(info_label)

func show_message(text: String) -> void:
	info_label.text = text
	info_label.visible = _hud_shown
	info_timer = MESSAGE_TIME
	if not _hud_shown:
		return
	var needed := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, MIN_FONT_SIZE).x + 30.0
	var width := minf(needed, FEED_RECT.size.x)
	var wraps := needed > FEED_RECT.size.x
	var row := Control.new()
	row.size = Vector2(FEED_RECT.size.x, 30.0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feed_root.add_child(row)
	var x := FEED_RECT.size.x - width
	var plate := _plate(row, Rect2(x, 0, width, 30.0), _box(PLATE, Color.TRANSPARENT, 0, 4))
	var stripe := _plate(row, Rect2(x, 0, 5, 30.0), _box(_message_color(text), Color.TRANSPARENT, 0, 2))
	var line := _text(row, _keep_words(text) if wraps else text, Rect2(x + 14, 0, width - 22, 30.0), MIN_FONT_SIZE)
	var height := 30.0
	if wraps:
		# Up to three lines, as many as the words take: a collapse warning naming four realms
		# lost its "move to a safe realm" at two (capture 2026-11-26).
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_theme_constant_override("line_spacing", -2)
		var advance := line.get_line_height() - 2.0
		line.size.y = advance * 4.0
		var lines := clampi(line.get_line_count(), 2, 3)
		line.max_lines_visible = lines
		height = lines * advance + 10.0
		line.size.y = height
		row.size.y = height
		plate.size.y = height
		stripe.size.y = height
	feed_rows.append({"row": row, "time": MESSAGE_TIME, "height": height})
	while feed_rows.size() > MESSAGE_ROWS:
		feed_rows[0].row.queue_free()
		feed_rows.remove_at(0)
	_place_feed_rows()

## The stripe beside a message says what kind of news it is: someone is out (red), a collapse
## (orange), a soul card (violet), an elite monster (gold). Read from the words of the message,
## as every message arrives as finished text.
func _message_color(text: String) -> Color:
	for word in ["탈락", "eliminated"]:
		if text.contains(word):
			return HP_LOW
	for word in ["붕괴", "서든데스", "ollaps", "Sudden death"]:
		if text.contains(word):
			return DANGER
	for word in ["소울 카드", "Soul card", "soul card"]:
		if text.contains(word):
			return SOUL
	for word in ["정예", "Elite"]:
		if text.contains(word):
			return GOLD
	return DIM

func _place_feed_rows() -> void:
	var y := 0.0
	for entry in feed_rows:
		entry.row.position.y = y
		y += float(entry.height) + 5.0

func _clear_feed() -> void:
	for entry in feed_rows:
		entry.row.queue_free()
	feed_rows.clear()
	info_label.visible = false

## Takes every message down at once (practice: the note about growth goes with its card list).
func clear_messages() -> void:
	_clear_feed()
	info_timer = 0.0

## Counts the messages down; each fades out when its time is up.
func tick_info(delta: float) -> void:
	info_timer = maxf(info_timer - delta, 0.0)
	if feed_rows.is_empty():
		return
	if not info_label.visible:
		# Someone took the message down (the old HUD's one line was hidden that way).
		clear_messages()
		return
	for entry in feed_rows.duplicate():
		entry.time = float(entry.time) - delta
		entry.row.modulate.a = clampf(float(entry.time) / MESSAGE_FADE, 0.0, 1.0)
		if float(entry.time) <= 0.0:
			entry.row.queue_free()
			feed_rows.erase(entry)
	if feed_rows.is_empty():
		info_label.visible = false
	_place_feed_rows()

# --- Warnings ---

func _build_warning() -> void:
	warning_root = _root("Warning", WARNING_RECT, TOP_CENTER)
	warning_plate = _plate(warning_root, Rect2(Vector2.ZERO, WARNING_RECT.size), _box(DANGER_PLATE, DANGER, 2, 6))
	warning_label = _text(warning_root, "", Rect2(18, 4, 410, 26), 19, Color("ffd9c8"), true)
	warning_line = _text(warning_root, "", Rect2(18, 30, 410, 26), MIN_FONT_SIZE)
	warning_number = _text(warning_root, "", Rect2(430, 0, 116, 60), 40, Color("ffe07a"), true, HORIZONTAL_ALIGNMENT_RIGHT)
	_set_warning_visible(false)

## The label's own flag follows the plate: the collapse sound and the tests read it.
func _set_warning_visible(shown: bool) -> void:
	warning_root.visible = shown
	warning_label.visible = shown

## seconds < 0 hides the countdown.
## Collapse countdown (seconds >= 0) wins over a realm hazard warning; both empty hides the plate.
func set_warning_banner(seconds: int, hazard_warning := "") -> void:
	AUDIO.collapse(self, seconds if _hud_shown else -1, warning_label)
	if seconds >= 0:
		set_warning_text(tr("This realm is collapsing"), tr("Press Q on a portal to reach a safe realm"), seconds)
	elif hazard_warning != "":
		set_warning_text(tr(hazard_warning), "", -1)
	else:
		_set_warning_visible(false)

## The plate under the clock: a title, an optional second line and, with seconds >= 0, a big
## countdown (red). Without a countdown it is the amber plate of a realm hazard.
func set_warning_text(title: String, line: String, seconds: int) -> void:
	if not _hud_shown:
		_set_warning_visible(false)
		return
	var countdown := seconds >= 0
	var tall := line != ""
	warning_label.text = title
	warning_line.text = line
	warning_line.visible = tall
	warning_number.text = str(seconds) if countdown else ""
	warning_plate.size.y = WARNING_RECT.size.y if tall else 38.0
	warning_label.position.y = 4.0 if tall else 0.0
	warning_label.size = Vector2(410.0 if countdown else 524.0, 26.0 if tall else 38.0)
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if tall else HORIZONTAL_ALIGNMENT_CENTER
	warning_label.add_theme_font_size_override("font_size", 19 if tall else 17)
	warning_label.add_theme_color_override("font_color", Color("ffd9c8") if countdown else WHITE)
	warning_number.size.y = warning_plate.size.y
	var box: StyleBoxFlat = warning_plate.get_theme_stylebox("panel")
	box.bg_color = DANGER_PLATE if countdown else HAZARD_PLATE
	box.border_color = DANGER if countdown else GOLD
	_set_warning_visible(true)

# --- The fighter in focus ---

func _build_player() -> void:
	player_root = _root("PlayerPlate", PLAYER_RECT, BOTTOM_LEFT)
	_plate(player_root, Rect2(54, 14, 378, 92), _box(PLATE_SOLID, EDGE, 1, 4, 0.18))
	focus_accent = _plate(player_root, Rect2(60, 14, 10, 92), _box(Color.WHITE, Color.TRANSPARENT, 0, 2, 0.18))
	focus_frame = _plate(player_root, Rect2(0, 4, 108, 108), _box(Color.WHITE, Color.TRANSPARENT, 0, 6))
	focus_portrait = _picture(player_root, null, Rect2(3, 7, 102, 102), false)
	focus_name = _text(player_root, "", Rect2(124, 16, 172, 26), 18, WHITE, true)
	kos_label = _text(player_root, "", Rect2(300, 16, 116, 26), MIN_FONT_SIZE, DIM, false, HORIZONTAL_ALIGNMENT_RIGHT)
	hp_label = _text(player_root, "", Rect2(122, 38, 84, 40), 34, WHITE, true)
	hp_max_label = _text(player_root, "", Rect2(196, 50, 60, 26), 17, DIM)
	hp_bar = Control.new()
	hp_bar.name = "HpBar"
	hp_bar.position = Vector2(252, 48)
	hp_bar.size = Vector2(164, 22)
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_root.add_child(hp_bar)
	_plate(hp_bar, Rect2(0, 0, 164, 22), _box(Color(0, 0, 0, 0.62), Color.TRANSPARENT, 0, 4)).name = "HpWell"
	hp_fill = _plate(hp_bar, Rect2(2, 2, 160, 18), _box(HP_FULL, Color.TRANSPARENT, 0, 3))
	hp_fill.name = "HpFill"
	_text(player_root, tr("Souls"), Rect2(124, 76, 46, 26), MIN_FONT_SIZE, SOUL.lightened(0.35))
	soul_well = _plate(player_root, Rect2(172, 84, 148, 10), _box(Color(0, 0, 0, 0.62), Color.TRANSPARENT, 0, 5))
	soul_fill = _plate(player_root, Rect2(173, 85, 146, 8), _box(SOUL, Color.TRANSPARENT, 0, 4))
	soul_label = _text(player_root, "", Rect2(326, 76, 90, 26), MIN_FONT_SIZE, WHITE, false, HORIZONTAL_ALIGNMENT_RIGHT)
	status_label = _text(player_root, "", Rect2(236, 76, 180, 26), MIN_FONT_SIZE, GOLD, false, HORIZONTAL_ALIGNMENT_RIGHT)
	status_label.name = "PracticeCards"
	status_label.visible = false

func set_status(alive: int, total: int, focus: Node) -> void:
	alive_label.text = str(alive)
	alive_total.text = "/ %d" % total
	_fill_focus(focus)

## The plate of the fighter in focus: face, name, KOs, HP and the souls.
func _fill_focus(focus: Node) -> void:
	# Only while the match HUD shows: Main keeps calling this behind the result screen.
	var shown := _hud_shown and is_instance_valid(focus)
	player_root.visible = shown
	hp_bar.visible = shown
	_show_focus_portrait(focus)
	_place_player_tag(focus if shown else null)
	if not is_instance_valid(focus):
		return
	var watching := not bool(focus.is_human)
	focus_name.text = (tr("Spectating") + "  " if watching else "") + tr(str(focus.display_name))
	focus_name.add_theme_color_override("font_color", DIM if watching else WHITE)
	kos_label.text = tr("KOs %d") % int(focus.score)
	var ratio := clampf(float(focus.hp) / maxf(float(focus.max_hp), 1.0), 0.0, 1.0)
	var low := ratio <= 0.3
	var hp_color := HP_LOW if low else (HP_MID if ratio <= 0.55 else HP_FULL)
	hp_label.text = str(ceili(float(focus.hp)))
	hp_label.add_theme_color_override("font_color", HP_LOW.lightened(0.3) if low else WHITE)
	hp_max_label.text = "/ %d" % ceili(float(focus.max_hp))
	hp_max_label.position.x = 124.0 + bold.get_string_size(hp_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x + 8.0
	hp_fill.size.x = 160.0 * ratio
	# Low HP: the bar blinks.
	(hp_fill.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = hp_color.lerp(Color.WHITE, 0.25 + 0.25 * sin(_pulse * 9.0)) if low else hp_color
	# Souls toward the next card; in practice no offer opens, so the souls alone.
	var next_threshold: int = focus.get_next_soul_threshold()
	if practice_layout:
		soul_label.text = str(int(focus.souls))
	elif next_threshold > 0:
		var previous := 0
		for threshold: int in focus.SOUL_THRESHOLDS:
			if threshold < next_threshold:
				previous = threshold
		soul_fill.size.x = 146.0 * clampf(float(int(focus.souls) - previous) / maxf(float(next_threshold - previous), 1.0), 0.0, 1.0)
		soul_label.text = "%d / %d" % [int(focus.souls), next_threshold]
	else:
		soul_fill.size.x = 146.0
		soul_label.text = tr("All cards")

func _show_focus_portrait(focus: Node) -> void:
	var key := "" if not is_instance_valid(focus) else "%s/%s" % [focus.character_id, focus.body_type]
	if key == focus_portrait_key:
		return
	focus_portrait_key = key
	var texture: Texture2D = null if key == "" else ART_SETTINGS.character_portrait(focus.character_id, focus.body_type)
	_set_portrait(focus_portrait, texture)
	if is_instance_valid(focus):
		(focus_frame.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = focus.body_color
		(focus_accent.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = focus.body_color

func _build_player_tag() -> void:
	player_tag = Control.new()
	player_tag.name = "PlayerTag"
	player_tag.size = Vector2(44, 34)
	player_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_tag.visible = false
	add_child(player_tag)
	var pointer := Polygon2D.new()
	pointer.polygon = PackedVector2Array([Vector2(14, 22), Vector2(30, 22), Vector2(22, 33)])
	pointer.color = GOLD
	player_tag.add_child(pointer)
	_plate(player_tag, Rect2(0, 0, 44, 24), _box(GOLD, INK, 2, 5))
	_text(player_tag, "P1", Rect2(0, 0, 44, 24), MIN_FONT_SIZE, INK, true, HORIZONTAL_ALIGNMENT_CENTER).add_theme_constant_override("outline_size", 0)

## "P1" follows the player's own fighter; a fighter that is only watched gets none.
func _place_player_tag(focus: Node) -> void:
	var mine := is_instance_valid(focus) and focus is CanvasItem and bool(focus.is_human) and not bool(focus.is_defeated)
	player_tag.visible = mine
	if not mine:
		return
	# The small gold name over the head says the same; the tag takes its place.
	var world_name := focus.get_node_or_null("NameLabel") as CanvasItem
	if world_name != null:
		world_name.visible = false
	var head: Vector2 = (focus as CanvasItem).get_global_transform_with_canvas() * PLAYER_TAG_OFFSET
	var tag := Rect2(head - Vector2(player_tag.size.x * 0.5, player_tag.size.y), player_tag.size)
	# A portal's words stay readable while the fighter stands at it: the tag rises over them (its
	# tail covered "Q DOWN: ..." in the HUD capture of 2026-11-25). The countdown sits over the words.
	var words := _portal_words()
	for attempt in 3:
		var raised := false
		for rect: Rect2 in words:
			if tag.intersects(rect):
				tag.position.y = rect.position.y - tag.size.y - 2.0
				raised = true
		if not raised:
			break
	player_tag.position = tag.position

## The screen rects of the words over the portals on show.
func _portal_words() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for node in get_tree().get_nodes_in_group(PORTAL_LABELS):
		var label := node as Label
		if label == null or label.text == "" or not label.is_visible_in_tree():
			continue
		var xform := label.get_global_transform_with_canvas()
		rects.append(Rect2(xform.origin, label.size * xform.get_scale()))
	return rects

# --- Skill slots ---

func _build_skill_bar() -> void:
	skill_bar = _root("SkillBar", Rect2(SKILL_BAR_X, 720.0 - HUD_MARGIN - 82.0, 10, SKILL_BAR_HEIGHT), BOTTOM_LEFT)
	var key_x := (SKILL_SLOT_SIZE - SKILL_KEY_SIZE.x) * 0.5
	var key_rect := Rect2(Vector2(key_x, SKILL_SLOT_SIZE + 2.0), SKILL_KEY_SIZE)
	var slot_rect := Rect2(0, 0, SKILL_SLOT_SIZE, SKILL_SLOT_SIZE)
	for slot in SKILL_SLOTS:
		var panel := Control.new()
		panel.name = "SkillSlot%s" % slot.to_upper()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.size = Vector2(SKILL_SLOT_SIZE, SKILL_BAR_HEIGHT)
		skill_bar.add_child(panel)
		var style := _box(PLATE_SOLID, EDGE, 2, 4)
		_plate(panel, slot_rect, style).name = "SkillSlotBack%s" % slot.to_upper()
		# The icon (CODEX-ART-18, 40 px at 1:1), or the key letter when there is none (F2).
		var icon := _picture(panel, null, Rect2(8, 8, 40, 40))
		var glyph := _text(panel, slot.to_upper(), slot_rect, 26, WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
		# Cooldown: a shade from the top for the share still to wait, and the seconds.
		var shade := ColorRect.new()
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade.color = Color(0.0, 0.0, 0.0, 0.7)
		shade.size = Vector2(SKILL_SLOT_SIZE, 0.0)
		panel.add_child(shade)
		var time := _text(panel, "", slot_rect, 26, WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
		# A short count on the top corner (Xion's rounds on J, 2026-11-18): only while the fighter
		# shown on the bar has one.
		var count_back := _plate(panel, Rect2(-4, -6, 30, 22), _box(Color(0, 0, 0, 0.82), Color.TRANSPARENT, 0, 4))
		var count := _text(panel, "", Rect2(-4, -6, 30, 22), MIN_FONT_SIZE, GOLD, true, HORIZONTAL_ALIGNMENT_CENTER)
		count.name = "Count"
		_plate(panel, key_rect, _box(KEY_CAP, Color.TRANSPARENT, 0, 4))
		var key := _text(panel, slot.to_upper(), key_rect, MIN_FONT_SIZE, INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		key.add_theme_constant_override("outline_size", 0)
		skill_slots[slot] = {"style": style, "icon": icon, "glyph": glyph, "key": key, "shade": shade, "time": time, "count": count, "count_back": count_back}
	_layout_skill_bar(false)

## The slots in a row beside the player's plate; U only when the fighter has a third skill.
func _layout_skill_bar(show_third: bool) -> void:
	var shown := SKILL_SLOTS.filter(func(slot: String) -> bool: return slot != "u" or show_third)
	var width := shown.size() * SKILL_SLOT_SIZE + (shown.size() - 1) * SKILL_SLOT_GAP
	skill_bar.offset_right = skill_bar.offset_left + width
	for slot in SKILL_SLOTS:
		var panel := skill_bar.get_node("SkillSlot%s" % slot.to_upper()) as Control
		panel.visible = shown.has(slot)
		if panel.visible:
			panel.position.x = shown.find(slot) * (SKILL_SLOT_SIZE + SKILL_SLOT_GAP)

## The focused fighter's moves: icons by character (Brave Luna's set while she is transformed),
## a shade and seconds while a move cools down, a gold edge when the ultimate is ready.
func update_skill_bar(fighter: Node, delta: float) -> void:
	if not skill_bar.visible:
		return
	if not is_instance_valid(fighter):
		skill_bar.modulate.a = 0.0
		return
	skill_bar.modulate.a = 0.55 if bool(fighter.get("is_defeated")) else 1.0
	var character_id := str(fighter.get("character_id"))
	var icon_set := "%s%s|%s" % [character_id, "_brave" if fighter.get("transformed") == true else "", ART_SETTINGS.use_original()]
	if icon_set != skill_icon_set:
		skill_icon_set = icon_set
		_layout_skill_bar(fighter.has_method("has_skill_three") and fighter.has_skill_three())
		var accent: Color = fighter.get("body_color") if fighter.get("body_color") is Color else Color.WHITE
		for slot in SKILL_SLOTS:
			var nodes: Dictionary = skill_slots[slot]
			nodes.icon.texture = ART_SETTINGS.original_texture(SKILL_ICON_ART % ("%s_%s" % [icon_set.get_slice("|", 0), slot]))
			nodes.glyph.add_theme_color_override("font_color", accent.lerp(Color.WHITE, 0.35))
	skill_pulse += delta
	for slot in SKILL_SLOTS:
		var nodes: Dictionary = skill_slots[slot]
		var cooldown: Vector2 = fighter.skill_cooldown(slot) if fighter.has_method("skill_cooldown") else Vector2.ZERO
		var waiting: float = clampf(cooldown.x / cooldown.y, 0.0, 1.0) if cooldown.y > 0.0 else 0.0
		nodes.shade.size = Vector2(SKILL_SLOT_SIZE, SKILL_SLOT_SIZE * waiting)
		nodes.time.text = "%d" % ceili(cooldown.x) if cooldown.x > 0.0 else ""
		var counter: String = fighter.skill_counter(slot) if fighter.has_method("skill_counter") else ""
		nodes.count.text = counter
		nodes.count_back.visible = counter != ""
		# Without an icon the key letter fills the slot; the seconds take its place while waiting.
		nodes.glyph.visible = nodes.icon.texture == null and cooldown.x <= 0.0
		nodes.icon.modulate = Color(1, 1, 1, 0.45) if cooldown.x > 0.0 else Color.WHITE
		var style: StyleBoxFlat = nodes.style
		if slot == "i" and cooldown.x <= 0.0:
			style.border_color = SKILL_READY_COLOR.lerp(Color.WHITE, 0.25 + 0.25 * sin(skill_pulse * 6.0))
			style.set_border_width_all(3)
		else:
			style.border_color = EDGE
			style.set_border_width_all(2)

func _build_controls() -> void:
	controls_label = _text(hud_root, "", Rect2(1280.0 - HUD_MARGIN - 10.0, 720.0 - HUD_MARGIN - CONTROLS_HEIGHT, 10, CONTROLS_HEIGHT), MIN_FONT_SIZE, DIM, false, HORIZONTAL_ALIGNMENT_CENTER)
	controls_label.name = "Controls"
	controls_label.add_theme_stylebox_override("normal", _box(Color(PLATE, 0.7), Color.TRANSPARENT, 0, 4))
	_pin(controls_label, BOTTOM_RIGHT)
	set_control_hints(tr(CONTROLS_SHORT))

## The hints keep to the card column's width, which fits right of a five-slot skill bar: a longer
## line breaks at its wide gaps (three spaces) into lines of even width. The English line did not
## fit one (487 px over Rio's bar, test_hud_layout 2026-11-26); the Korean one does. Other words
## (the gamepad's, scripts/input/PadGlyphs.gd) come here too: written straight into
## controls_label.text, they are laid out the same way at the HUD's next frame.
func set_control_hints(text: String) -> void:
	var font: Font = controls_label.get_theme_font("font")
	controls_label.text = _fit_items(text, font, MIN_FONT_SIZE, CARD_WIDTH - 22.0, true)
	_controls_text_shown = controls_label.text
	var lines := controls_label.text.split("\n")
	var width := 0.0
	for line in lines:
		width = maxf(width, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, MIN_FONT_SIZE).x + 22.0)
	var advance := controls_label.get_line_height() + controls_label.get_theme_constant("line_spacing")
	controls_height = CONTROLS_HEIGHT if lines.size() == 1 else lines.size() * advance + 8.0
	controls_label.offset_left = -HUD_MARGIN - width
	controls_label.offset_right = -HUD_MARGIN
	controls_label.offset_top = -HUD_MARGIN - controls_height
	controls_label.offset_bottom = -HUD_MARGIN
	if is_instance_valid(practice_label):
		_place_practice_lines()

## The hints' width on screen (one line, or the longer of two).
func controls_label_width() -> float:
	return controls_label.size.x

# --- Fighters outside the view ---

func _build_offscreen() -> void:
	offscreen_root = Control.new()
	offscreen_root.name = "OffscreenMarkers"
	offscreen_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	offscreen_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(offscreen_root)

## markers: [{"position": screen point near the edge, "angle": radians, "color": Color,
## "face": Texture2D (optional)}]. Each is the fighter's face in a ring of its colour with an
## arrow toward it. A face slides along its edge off the HUD's plates (it sat on the map in the
## capture of 2026-11-25) and off the faces placed before it; on the bottom edge, which the HUD
## fills, it stands above the plates.
func set_offscreen_markers(markers: Array) -> void:
	var half := OFFSCREEN_BUBBLE * 0.5
	while offscreen_markers.size() < markers.size():
		var bubble := Control.new()
		bubble.size = Vector2(OFFSCREEN_BUBBLE, OFFSCREEN_BUBBLE)
		bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
		offscreen_root.add_child(bubble)
		var arrow := Polygon2D.new()
		arrow.polygon = PackedVector2Array([Vector2(half + 13, 0), Vector2(half - 1, -10), Vector2(half - 1, 10)])
		arrow.position = Vector2(half, half)
		bubble.add_child(arrow)
		var ring := _plate(bubble, Rect2(0, 0, OFFSCREEN_BUBBLE, OFFSCREEN_BUBBLE), _box(Color.WHITE, Color(0.03, 0.05, 0.1), 2, int(half)))
		var face := _picture(bubble, null, Rect2(3, 3, OFFSCREEN_BUBBLE - 6, OFFSCREEN_BUBBLE - 6), false)
		offscreen_markers.append({"root": bubble, "arrow": arrow, "ring": ring, "face": face})
	var view := get_viewport().get_visible_rect().size
	var blocks: Array[Rect2] = []
	if not markers.is_empty():
		blocks = _marker_blocks()
	var placed: Array[Rect2] = []
	for index in offscreen_markers.size():
		var nodes: Dictionary = offscreen_markers[index]
		var bubble: Control = nodes.root
		bubble.visible = index < markers.size()
		if not bubble.visible:
			continue
		var marker: Dictionary = markers[index]
		var at := _clear_marker_point(marker.position, blocks, placed, view)
		var angle := float(marker.angle)
		# The next face keeps a face's width and a gap from this one.
		var room := OFFSCREEN_BUBBLE + 4.0
		placed.append(Rect2(at - Vector2(room, room), Vector2(room, room) * 2.0))
		var color: Color = marker.color
		bubble.position = at - Vector2(half, half)
		(nodes.arrow as Polygon2D).rotation = angle
		(nodes.arrow as Polygon2D).color = color.lightened(0.2)
		((nodes.ring as Panel).get_theme_stylebox("panel") as StyleBoxFlat).bg_color = color
		_set_portrait(nodes.face, marker.get("face"))

## The HUD's plates on screen, each grown by half a face and a gap: no face's centre goes there.
func _marker_blocks() -> Array[Rect2]:
	var nodes: Array[Control] = [minimap_plate, clock_plate, next_plate, warning_plate, player_root, skill_bar, controls_label, card_panel, bot_panel]
	if is_instance_valid(practice_label):
		nodes.append(practice_label)
	for entry in feed_rows:
		# The row's plate (its first child), as wide as its words.
		nodes.append(entry.row.get_child(0) as Control)
	var blocks: Array[Rect2] = []
	for node in nodes:
		if is_instance_valid(node) and node.is_visible_in_tree():
			blocks.append(node.get_global_rect().grow(OFFSCREEN_BUBBLE * 0.5 + 4.0))
	return blocks

## Moves a face's centre off every block and earlier face, the shorter way that stays on screen:
## along a side edge up or down, along the top edge left or right, and up from the bottom edge
## (the HUD's plates fill it). With no clear place the face stays where it was.
func _clear_marker_point(start: Vector2, blocks: Array[Rect2], placed: Array[Rect2], view: Vector2) -> Vector2:
	var taken: Array[Rect2] = []
	taken.append_array(blocks)
	taken.append_array(placed)
	if not _marker_hit(start, taken).has_area():
		return start
	var edge := OFFSCREEN_BUBBLE * 0.5 + 4.0
	var on_side := minf(start.x, view.x - start.x) <= minf(start.y, view.y - start.y)
	var on_top := not on_side and start.y < view.y * 0.5
	var along_x := on_top
	var limit := (view.x if along_x else view.y) - edge
	var best := start
	var best_shift := INF
	for direction: float in ([-1.0, 1.0] if on_side or on_top else [-1.0]):
		var at := start
		for attempt in 16:
			var hit := _marker_hit(at, taken)
			if not hit.has_area():
				break
			if along_x:
				at.x = hit.position.x - 0.5 if direction < 0.0 else hit.end.x + 0.5
			else:
				at.y = hit.position.y - 0.5 if direction < 0.0 else hit.end.y + 0.5
		var value := at.x if along_x else at.y
		if _marker_hit(at, taken).has_area() or value < edge or value > limit:
			continue
		if at.distance_to(start) < best_shift:
			best = at
			best_shift = at.distance_to(start)
	return best

func _marker_hit(at: Vector2, rects: Array[Rect2]) -> Rect2:
	for rect in rects:
		if rect.has_point(at):
			return rect
	return Rect2()

# --- Soul card offer ---

func _build_card_panel() -> void:
	card_panel = _root("SoulCards", Rect2(1280.0 - HUD_MARGIN - CARD_WIDTH, 400, CARD_WIDTH, 304), BOTTOM_RIGHT)
	card_panel.visible = false
	card_head_plate = _plate(card_panel, Rect2(0, 0, CARD_WIDTH, 27), _box(PLATE_SOLID, Color.TRANSPARENT, 0, 4))
	card_title = _text(card_panel, "", Rect2(12, 0, 200, 26), MIN_FONT_SIZE, WHITE, true)
	card_hint = _text(card_panel, "", Rect2(220, 0, 200, 26), MIN_FONT_SIZE, DIM)
	card_time = _text(card_panel, "", Rect2(CARD_WIDTH - 92, 0, 80, 26), 18, GOLD, true, HORIZONTAL_ALIGNMENT_RIGHT)
	# The time left, as a bar that runs out.
	card_bar_back = _plate(card_panel, Rect2(0, 26, CARD_WIDTH, 5), _box(Color(0, 0, 0, 0.75), Color.TRANSPARENT, 0, 2))
	card_bar = _plate(card_panel, Rect2(0, 26, CARD_WIDTH, 5), _box(GOLD, Color.TRANSPARENT, 0, 2))
	# A solid back under the authored card frame: the frame's centre is empty, and the text used to
	# sit straight on the arena (UI audit 2026-11-25). One frame holds the three cards: as a column
	# beside the player's plate they are rows, too low for a frame each.
	card_back = _plate(card_panel, Rect2(0, CARD_HEAD, CARD_WIDTH, 100), _box(PLATE_SOLID, Color.TRANSPARENT, 0, 2))
	card_frame = _hud_frame("card_panel", Vector2(CARD_WIDTH + 8.0, 108), CARD_COLOR, "CardPanelFrame")
	card_frame.position = Vector2(-4, CARD_HEAD - 4.0)
	card_panel.add_child(card_frame)
	for index in 3:
		var row := Control.new()
		row.name = "CardRow%d" % (index + 1)
		row.size = Vector2(CARD_WIDTH, CARD_ROW_MIN)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_panel.add_child(row)
		var rule := _plate(row, Rect2(12, -1, CARD_WIDTH - 24.0, 1), _box(EDGE, Color.TRANSPARENT, 0, 0))
		rule.visible = index > 0
		# The key that picks the card, on a tab in the colour of its kind.
		var tab := _plate(row, Rect2(12, 6, 30, CARD_ROW_MIN - 12.0), _box(GOLD, Color.TRANSPARENT, 0, 3))
		var number := _text(row, str(index + 1), Rect2(12, 6, 30, CARD_ROW_MIN - 12.0), 20, INK, true, HORIZONTAL_ALIGNMENT_CENTER)
		number.add_theme_constant_override("outline_size", 0)
		# A card without art yet shows its title's first letter in its kind's colour on a tile
		# (D54: the new cards start that way).
		var tile := _plate(row, Rect2(52, 3, 48, 48), _box(Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.35), 2, 6))
		var letter := _text(row, "", Rect2(52, 3, 48, 48), 26, WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
		card_letters.append(letter)
		var icon := _picture(row, null, Rect2(52, 3, 48, 48))
		card_icons.append(icon)
		var title := _text(row, "", Rect2(CARD_TEXT_X, 3, 200, 26), 19, WHITE, true)
		var kind := _text(row, "", Rect2(CARD_WIDTH - 14.0 - 150.0, 5, 150, 22), MIN_FONT_SIZE, GOLD, false, HORIZONTAL_ALIGNMENT_RIGHT)
		var text := _text(row, "", Rect2(CARD_TEXT_X, 28, CARD_WIDTH - CARD_TEXT_X - 14.0, 22), MIN_FONT_SIZE, Color("dfe6f1"))
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		text.max_lines_visible = 3
		card_labels.append(text)
		card_rows.append({"row": row, "tab": tab, "number": number, "tile": tile, "letter": letter, "icon": icon, "title": title, "kind": kind})
	_set_card_header(tr("Choose a soul card"), tr("Press 1 · 2 · 3"), true)

## Called every frame while P1 has an offer. The bar is the share of the choice time left:
## seconds_total is the choice's full time (SoulGrowth's time_total); without it, the first value
## an offer comes with stands for it.
func show_card_offer(cards: Array, seconds_left: float, seconds_total := 0.0) -> void:
	AUDIO.card_offer(self, card_panel.visible)
	var signature := _card_ids(cards)
	var fresh := not card_panel.visible or not _card_timed or signature != _card_signature
	if fresh or seconds_left > _card_last_left + 0.25:
		_card_full_time = seconds_left
	if seconds_total > 0.0:
		_card_full_time = seconds_total
	if fresh:
		_card_timed = true
		_card_signature = signature
		_set_card_header(tr("Choose a soul card"), tr("Press 1 · 2 · 3"), true)
		_fill_cards(cards)
	_card_last_left = seconds_left
	_open_card_panel()
	card_time.text = tr("%ds") % ceili(seconds_left)
	card_bar.size.x = CARD_WIDTH * clampf(seconds_left / maxf(_card_full_time, 0.1), 0.0, 1.0)
	(card_bar.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = GOLD if seconds_left > 2.0 else DANGER

## The same column without a clock: practice's card list (PracticeSession). header is one line:
## up to its first wide gap (four spaces) it names the list, the rest gives the keys, set under
## the name when both do not fit one line.
func show_card_list(cards: Array, header: String) -> void:
	AUDIO.card_offer(self, card_panel.visible)
	var parts := header.split("    ", true, 1)
	_card_timed = false
	_card_signature = _card_ids(cards)
	_set_card_header(parts[0].strip_edges(), parts[1].strip_edges() if parts.size() > 1 else "", false)
	_fill_cards(cards)
	_open_card_panel()

## A card's kind as its row shows it, in another wording (practice adds how many are held).
func set_card_kind_text(index: int, text: String) -> void:
	var nodes: Dictionary = card_rows[index]
	nodes.kind.text = text
	_fit_title_row(nodes)

## A card row's words as one text (title, description, kind), for tests and tools.
func card_row_text(index: int) -> String:
	var nodes: Dictionary = card_rows[index]
	return "%s\n%s\n%s" % [nodes.title.text, card_labels[index].text.replace(String.chr(0x2060), ""), nodes.kind.text]

func _card_ids(cards: Array) -> String:
	var ids: Array[String] = []
	for card: Dictionary in cards:
		ids.append(str(card.id))
	return ",".join(ids)

func _open_card_panel() -> void:
	card_panel.visible = true
	# The corner belongs to the cards while they are open.
	controls_label.visible = false

## The column's head: the title, the keys beside it (or under it, when both do not fit one line)
## and, for an offer, the seconds at the right with the time bar under the head.
func _set_card_header(title: String, hint: String, timed: bool) -> void:
	var title_font: Font = card_title.get_theme_font("font")
	var hint_font: Font = card_hint.get_theme_font("font")
	var title_width := title_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, MIN_FONT_SIZE).x + 6.0
	var hint_width := hint_font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, MIN_FONT_SIZE).x + 6.0
	var right := CARD_WIDTH - 12.0 - (88.0 if timed else 0.0)
	var one_line := hint == "" or 24.0 + title_width + hint_width <= right
	card_title.text = title
	card_title.size = Vector2(minf(title_width, right - 12.0), 26)
	card_hint.text = hint
	if one_line:
		card_hint.position = Vector2(24.0 + title_width, 0)
		card_hint.size = Vector2(maxf(right - card_hint.position.x, 0.0), 26)
	else:
		card_hint.position = Vector2(12, 24)
		card_hint.size = Vector2(CARD_WIDTH - 24.0, 26)
	var head := 27.0 if one_line else 51.0
	card_head_plate.size.y = head
	card_time.visible = timed
	card_bar_back.visible = timed
	card_bar.visible = timed
	card_bar_back.position.y = head - 1.0
	card_bar.position.y = head - 1.0
	_card_head = head + CARD_HEAD - 27.0

## One row per card: as tall as its text (one line, or up to three wrapped at the spaces).
func _fill_cards(cards: Array) -> void:
	var text_width := CARD_WIDTH - CARD_TEXT_X - 14.0
	var y := _card_head + CARD_PADDING
	for index in card_rows.size():
		var nodes: Dictionary = card_rows[index]
		var row: Control = nodes.row
		var label := card_labels[index]
		row.visible = index < cards.size()
		if not row.visible:
			label.text = ""
			card_icons[index].texture = null
			card_letters[index].text = ""
			continue
		var card: Dictionary = cards[index]
		var color: Color = CARD_KIND_COLOR.get(str(card.kind), GOLD)
		var title_text := tr(str(card.title))
		var body := tr(str(card.text))
		nodes.title.text = title_text
		nodes.kind.text = tr(str(card.kind))
		nodes.kind.add_theme_color_override("font_color", color)
		_fit_title_row(nodes)
		(nodes.tab.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = color
		# Original card icon (assets/art/ui/card_<id>.png); none in the prototype style, and none
		# yet for the cards of D54: the title's first letter in the colour of the card's kind.
		var icon := ART_SETTINGS.original_texture(CARD_ICON_ART % card.id)
		card_icons[index].texture = icon
		nodes.tile.visible = icon == null
		nodes.letter.text = "" if icon != null else title_text.left(1)
		nodes.letter.add_theme_color_override("font_color", color)
		(nodes.tile.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Color(color, 0.55)
		var font: Font = label.get_theme_font("font")
		var one_line := font.get_string_size(body, HORIZONTAL_ALIGNMENT_LEFT, -1, MIN_FONT_SIZE).x <= text_width
		label.text = body if one_line else _keep_words(body)
		# A line takes its height and the label's line spacing: without the spacing a second line
		# did not fit, and the first ended in "..." (English Chaser, capture 2026-11-26).
		var advance := label.get_line_height() + label.get_theme_constant("line_spacing")
		label.size = Vector2(text_width, advance * 3.0)
		var lines := 1 if one_line else clampi(label.get_line_count(), 2, 3)
		label.size.y = lines * advance + 2.0
		var height := maxf(CARD_ROW_MIN, 28.0 + lines * advance + 6.0)
		row.position = Vector2(0, y)
		row.size.y = height
		nodes.tab.size.y = height - 12.0
		nodes.number.size.y = height - 12.0
		y += height + CARD_ROW_GAP
	var list_height := y - CARD_ROW_GAP + CARD_PADDING - _card_head
	card_back.position.y = _card_head
	card_back.size.y = list_height
	card_frame.position.y = _card_head - 4.0
	card_frame.size.y = list_height + 8.0
	# The column stands on the bottom margin, as tall as its cards.
	card_panel.offset_top = -HUD_MARGIN - (_card_head + list_height)
	card_panel.offset_bottom = -HUD_MARGIN

## The kind stands at the right of the title line as wide as its words; the title has the rest.
func _fit_title_row(nodes: Dictionary) -> void:
	var kind: Label = nodes.kind
	var title: Label = nodes.title
	var width := kind.get_theme_font("font").get_string_size(kind.text, HORIZONTAL_ALIGNMENT_LEFT, -1, MIN_FONT_SIZE).x + 6.0
	width = clampf(width, 40.0, CARD_WIDTH - CARD_TEXT_X - 14.0 - 120.0)
	kind.position.x = CARD_WIDTH - 14.0 - width
	kind.size.x = width
	title.size.x = kind.position.x - 10.0 - CARD_TEXT_X

func hide_card_offer() -> void:
	card_panel.visible = false
	controls_label.visible = _hud_shown

# --- Practice (scripts/practice/PracticeSession.gd) ---

## Practice has no survivors and no card offers: the clock keeps the mode and the time, and the
## soul row of the player's plate shows the souls and the cards held (set_practice_status).
func set_practice_layout() -> void:
	practice_layout = true
	for node: Control in [clock_divider, alive_caption, alive_label, alive_total, soul_well, soul_fill]:
		node.visible = false
	# The capsule closes round the mode and the time, still in the middle of the top edge.
	var shift := (CLOCK_RECT.size.x - CLOCK_PRACTICE_WIDTH) * 0.5
	clock_plate.position.x = shift
	clock_plate.size.x = CLOCK_PRACTICE_WIDTH
	clock_label.position.x = 22.0 + shift
	time_label.position.x = 218.0 + shift
	soul_label.position.x = 172.0
	soul_label.size.x = 60.0
	soul_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	status_label.visible = true

## Practice writes this every frame, and while its lists hold the game (Main draws nothing then):
## the cards held, and the plate again, so HP a card changed shows at once.
func set_practice_status(cards_held: int, focus: Node) -> void:
	status_label.text = tr("Cards held %d") % cards_held
	_fill_focus(focus)

## Practice's own lines (its target and the damage, then its keys): a block at the bottom right,
## over the control hints.
func build_practice_lines() -> Label:
	practice_label = _text(hud_root, "", Rect2(1280.0 - HUD_MARGIN - PRACTICE_WIDTH, 560, PRACTICE_WIDTH, 100), MIN_FONT_SIZE, WHITE)
	practice_label.name = "PracticeInfo"
	practice_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	practice_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var box := _box(Color(PLATE, 0.8), Color.TRANSPARENT, 0, 4)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	practice_label.add_theme_stylebox_override("normal", box)
	_pin(practice_label, BOTTOM_RIGHT)
	return practice_label

## Sets practice's lines, broken at the wide gaps between their items so each line fits the block,
## which stands on the control hints and grows upward. Lines written straight into the label (the
## gamepad's help, PracticeSession.show_pad_help) are laid out the same way at the next frame.
func set_practice_lines(text: String) -> void:
	var font: Font = practice_label.get_theme_font("font")
	var room := PRACTICE_WIDTH - 24.0
	var fitted := _fit_items(text, font, MIN_FONT_SIZE, room)
	_practice_text_shown = fitted
	if fitted == practice_label.text:
		return
	practice_label.text = fitted
	_place_practice_lines()

func _place_practice_lines() -> void:
	# The label's own measure of its lines and margins; it grows upward if ever taller.
	var height := practice_label.get_minimum_size().y
	var bottom := -HUD_MARGIN - controls_height - 8.0
	practice_label.offset_bottom = bottom
	practice_label.offset_top = bottom - height

## Lays text out in lines no wider than width, breaking only at its wide gaps (three spaces or
## more, which set the hints' and practice's items apart); each item stays whole. balanced: the
## same number of lines, but as even as they go ("... Q portal / F4 bots" left one item alone).
func _fit_items(text: String, font: Font, font_size: int, width: float, balanced := false) -> String:
	var fitted := _wrap_items(text, font, font_size, width)
	if not balanced:
		return fitted
	var count := fitted.split("\n").size()
	var narrow := width
	while narrow > 40.0:
		var tighter := _wrap_items(text, font, font_size, narrow - 8.0)
		if tighter.split("\n").size() > count:
			break
		fitted = tighter
		narrow -= 8.0
	return fitted

func _wrap_items(text: String, font: Font, font_size: int, width: float) -> String:
	if _gaps == null:
		_gaps = RegEx.create_from_string(" {3,}")
	var lines: PackedStringArray = []
	for source in text.split("\n"):
		var line := ""
		for item in _gaps.sub(source, "\u001f", true).split("\u001f"):
			var joined := item if line == "" else line + "   " + item
			if line != "" and font.get_string_size(joined, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
				lines.append(line)
				line = item
			else:
				line = joined
		lines.append(line)
	return "\n".join(lines)

# --- Ultimate cut-in ---

func _build_cutin() -> void:
	flash_rect = ColorRect.new()
	flash_rect.name = "UltimateFlash"
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.color = Color(1, 1, 1, 0)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash_rect)
	cutin_root = Control.new()
	cutin_root.name = "UltimateCutin"
	cutin_root.position = Vector2(-40, CUTIN_HIGH_Y)
	cutin_root.size = Vector2(640, 104)
	cutin_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cutin_root.visible = false
	hud_root.add_child(cutin_root)
	cutin_band = _plate(cutin_root, Rect2(0, 0, 620, 104), _box(Color.WHITE, Color.TRANSPARENT, 0, 2, 0.3))
	cutin_stripe = _plate(cutin_root, Rect2(0, 90, 600, 8), _box(Color.WHITE, Color.TRANSPARENT, 0, 2, 0.3))
	cutin_face = _picture(cutin_root, null, Rect2(70, 0, 104, 104), false)
	cutin_name = _text(cutin_root, "", Rect2(190, 12, 400, 28), 19, WHITE, true)
	cutin_title = _text(cutin_root, "", Rect2(190, 40, 400, 50), 36, WHITE, true)

## Slides a band in the caster's colour in from the left for about 0.9 s and flashes the screen.
func show_ultimate_cutin(player: Node) -> void:
	# In the root box's own units (it is scaled down on a view under 1280x720).
	var view_height := hud_root.size.y
	var caster_y := view_height * 0.5
	if player is CanvasItem:
		caster_y = (player as CanvasItem).get_global_transform_with_canvas().origin.y / hud_root.scale.y
	cutin_root.position.y = CUTIN_HIGH_Y if caster_y > view_height * 0.5 else view_height - CUTIN_LOW_FROM_BOTTOM
	_set_portrait(cutin_face, ART_SETTINGS.character_portrait(player.character_id, player.body_type))
	(cutin_band.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Color(player.body_color.darkened(0.42), 1.0)
	(cutin_stripe.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Color(player.body_color.lightened(0.45), 0.9)
	cutin_name.text = ("P1  " if player.is_human else "") + tr(str(player.display_name))
	cutin_title.text = tr(str(player.ultimate_name)).to_upper()
	cutin_root.visible = true
	cutin_root.modulate.a = 1.0
	if cutin_tween != null and cutin_tween.is_valid():
		cutin_tween.kill()
	cutin_root.position.x = -700.0
	cutin_tween = create_tween()
	cutin_tween.tween_property(cutin_root, "position:x", -40.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	cutin_tween.tween_interval(0.62)
	cutin_tween.tween_property(cutin_root, "modulate:a", 0.0, 0.18)
	cutin_tween.tween_callback(func() -> void: cutin_root.visible = false)
	if flash_tween != null and flash_tween.is_valid():
		flash_tween.kill()
	flash_rect.color = Color(1, 1, 1, 0.24)
	flash_tween = create_tween()
	flash_tween.tween_property(flash_rect, "color:a", 0.0, 0.2)

# --- Test aids: the live bot panel (F4) and the debug text (F3) ---

func set_debug_text(text: String) -> void:
	debug_label.text = text

func toggle_debug() -> void:
	debug_label.visible = not debug_label.visible

func toggle_bot_panel() -> void:
	if not _hud_shown:
		bot_panel_wanted = not bot_panel_wanted
		return
	bot_panel.visible = not bot_panel.visible

## Not part of the match HUD: it shows what every fighter and its bot are doing, for testing, in
## the corner the HUD leaves empty.
func _build_bot_panel() -> void:
	bot_panel = PanelContainer.new()
	bot_panel.name = "BotPanel"
	bot_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.03, 0.06, 0.55)
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	bot_panel.add_theme_stylebox_override("panel", style)
	bot_panel.position = Vector2(6.0, 6.0)
	bot_panel.size = Vector2(BOT_PANEL_WIDTH, 0.0)
	bot_panel.visible = BOT_PANEL_SHOWN_AT_START
	hud_root.add_child(bot_panel)
	_pin(bot_panel, TOP_LEFT)
	bot_rows = VBoxContainer.new()
	bot_rows.add_theme_constant_override("separation", 3)
	bot_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bot_panel.add_child(bot_rows)

## rows: [{"face": Texture2D or null, "color": Color, "title": String, "lines": String,
## "dim": bool}], one per fighter, in a stable order.
func update_bot_panel(rows: Array) -> void:
	if not bot_panel.visible:
		return
	while bot_row_nodes.size() < rows.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var face := TextureRect.new()
		face.custom_minimum_size = Vector2(BOT_ROW_FACE, BOT_ROW_FACE)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(face)
		var text := Label.new()
		text.add_theme_font_size_override("font_size", 10)
		text.add_theme_constant_override("line_spacing", -2)
		text.custom_minimum_size = Vector2(BOT_PANEL_WIDTH - BOT_ROW_FACE - 18.0, 0.0)
		text.autowrap_mode = TextServer.AUTOWRAP_OFF
		text.clip_text = true
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(text)
		bot_rows.add_child(row)
		bot_row_nodes.append({"row": row, "face": face, "text": text})
	for index in bot_row_nodes.size():
		var nodes: Dictionary = bot_row_nodes[index]
		var row: HBoxContainer = nodes.row
		row.visible = index < rows.size()
		if not row.visible:
			continue
		var data: Dictionary = rows[index]
		var face: TextureRect = nodes.face
		face.texture = data.get("face")
		var text: Label = nodes.text
		text.text = "%s\n%s" % [data.title, data.lines]
		var color: Color = data.color
		text.add_theme_color_override("font_color", color.lerp(Color.WHITE, 0.55))
		row.modulate = Color(1, 1, 1, 0.5 if bool(data.get("dim", false)) else 1.0)

# --- Start and result screens ---

func _build_overlay() -> void:
	overlay = Control.new()
	overlay.name = "Overlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	overlay_back = ColorRect.new()
	overlay_back.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_back.color = PANEL_COLOR
	overlay_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(overlay_back)
	overlay_background_art = TextureRect.new()
	overlay_background_art.name = "TitleBackgroundArt"
	overlay_background_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_background_art.texture = ART_SETTINGS.original_texture(TITLE_BACKGROUND_ART)
	overlay_background_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay_background_art.stretch_mode = TextureRect.STRETCH_SCALE
	overlay_background_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	overlay_background_art.modulate = Color(0.62, 0.62, 0.72, 0.92)
	overlay_background_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_background_art.visible = overlay_background_art.texture != null
	overlay.add_child(overlay_background_art)
	var art_scrim := ColorRect.new()
	art_scrim.name = "TitleBackgroundScrim"
	art_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	art_scrim.color = Color(0.01, 0.015, 0.04, 0.28 if overlay_background_art.texture != null else 0.0)
	art_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(art_scrim)
	result_panel_frame = _hud_frame("result_panel", Vector2(960, 520), RESULTS_BACK_COLOR, "ResultPanelFrame")
	result_panel_frame.position = Vector2(160, 180)
	result_panel_frame.visible = false
	overlay.add_child(result_panel_frame)
	menu_frame_root = Control.new()
	menu_frame_root.name = "MenuButtonFrames"
	menu_frame_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_frame_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(menu_frame_root)
	overlay_title = Label.new()
	overlay_title.position = Vector2(0, 110)
	overlay_title.size = Vector2(1280, 70)
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_title.add_theme_font_size_override("font_size", 48)
	overlay_title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.4))
	overlay.add_child(overlay_title)
	_pin(overlay_title, TOP_CENTER)
	# Original title logo (CODEX-ART-06) drawn at half size in place of the title text.
	overlay_logo = TextureRect.new()
	overlay_logo.position = Vector2(480, 92)
	overlay_logo.size = Vector2(320, 100)
	overlay_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	overlay_logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	overlay_logo.texture = ART_SETTINGS.original_texture(TITLE_LOGO_ART)
	overlay_logo.visible = false
	overlay_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(overlay_logo)
	_pin(overlay_logo, TOP_CENTER)
	overlay_body = Label.new()
	overlay_body.position = Vector2(240, 200)
	overlay_body.size = Vector2(800, 480)
	overlay_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_body.add_theme_font_size_override("font_size", 19)
	overlay.add_child(overlay_body)
	_pin(overlay_body, TOP_CENTER)
	overlay_credits = Label.new()
	overlay_credits.position = Vector2(40, 650)
	overlay_credits.size = Vector2(1200, 50)
	overlay_credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_credits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_credits.add_theme_font_size_override("font_size", 12)
	overlay_credits.modulate = TEXT_DIM
	overlay_credits.text = tr(ART_CREDITS)
	overlay.add_child(overlay_credits)
	_pin(overlay_credits, BOTTOM_CENTER)
	frontend = FRONTEND.new()
	overlay.add_child(frontend)

## A column of fighter portraits left of the menu (original style only); characters drawn
## in two bodies show the body P1 picked with V.
func _show_portraits(characters: Array[Dictionary], body: String) -> void:
	if is_instance_valid(portrait_strip):
		portrait_strip.queue_free()
	portrait_strip = Control.new()
	portrait_strip.name = "Portraits"
	portrait_strip.position = Vector2(150, 200)
	portrait_strip.size = Vector2(160, characters.size() * 76)
	portrait_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(portrait_strip)
	_pin(portrait_strip, TOP_CENTER)
	for index in characters.size():
		var data: Dictionary = characters[index]
		var portrait := ART_SETTINGS.character_portrait(str(data.id), body if data.get("bodies", []).size() > 1 else "")
		if portrait == null:
			continue
		var frame := ColorRect.new()
		frame.position = Vector2(40, index * 76)
		frame.size = Vector2(68, 68)
		frame.color = Color(data.color, 0.35)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_strip.add_child(frame)
		var picture := _portrait_rect(frame.position + Vector2(2, 2), Vector2(64, 64))
		_set_portrait(picture, portrait)
		portrait_strip.add_child(picture)
		var key := Label.new()
		key.position = Vector2(0, index * 76 + 20)
		key.size = Vector2(36, 28)
		key.text = "[%d]" % (index + 1)
		key.add_theme_font_size_override("font_size", 17)
		portrait_strip.add_child(key)
	_build_menu_frames(characters.size())

func _build_menu_frames(character_count: int) -> void:
	for child in menu_frame_root.get_children():
		child.queue_free()
	# The unified body label remains the text owner. These shallow frames sit behind its
	# character choices and the B/F2 actions, improving scanning without changing inputs.
	for index in character_count:
		var frame := _hud_frame("menu_button", Vector2(360, 24), Color(0.08, 0.09, 0.14, 0.72), "MenuButtonFrame%d" % (index + 1))
		frame.position = Vector2(460, 292 + index * 24)
		menu_frame_root.add_child(frame)
	for index in 2:
		var action := _hud_frame("menu_button", Vector2(360, 24), Color(0.08, 0.09, 0.14, 0.72), "MenuActionFrame%d" % (index + 1))
		action.position = Vector2(460, 340 + character_count * 24 + index * 24)
		menu_frame_root.add_child(action)

func show_start_screen(characters: Array[Dictionary], body := "male") -> void:
	# Keep the existing authored frame nodes for the HUD art contract.
	_build_menu_frames(characters.size())
	_set_match_hud_visible(false)
	_hide_legacy_overlay_text()
	frontend.body = body
	frontend.show_title()
	overlay_back.color = PANEL_COLOR
	overlay_background_art.visible = overlay_background_art.texture != null
	overlay.visible = true

func _hide_legacy_overlay_text() -> void:
	for node in [overlay_title, overlay_logo, overlay_body, overlay_credits, result_panel_frame, menu_frame_root]:
		node.visible = false
	if is_instance_valid(portrait_strip):
		portrait_strip.visible = false
	if is_instance_valid(results_grid):
		results_grid.visible = false

## survival: combatant -> seconds survived (MatchDirector.get_survival_time).
func show_results(winner: Node, reason: String, standings: Array[Node], human: Node, survival: Dictionary = {}) -> void:
	_set_match_hud_visible(false)
	_hide_legacy_overlay_text()
	overlay_title.text = tr("%s WINS") % tr(str(winner.display_name)).to_upper() if is_instance_valid(winner) else tr("DRAW")
	overlay_back.color = RESULTS_BACK_COLOR
	frontend.show_results(winner, reason, standings, human, survival)
	overlay.visible = true

## Display names for picked card ids (results showed "sky_step", "last_stand").
func _card_names(ids: Array) -> Array[String]:
	var names: Array[String] = []
	for id in ids:
		var card: Dictionary = SOUL_CARDS.find(str(id))
		names.append(tr(str(card.get("title", str(id).replace("_", " ").capitalize()))))
	return names

func _add_result_cell(text: String, color: Color) -> void:
	var cell := Label.new()
	cell.text = text
	cell.add_theme_font_size_override("font_size", 18)
	cell.add_theme_color_override("font_color", color)
	results_grid.add_child(cell)

func hide_overlay() -> void:
	_set_match_hud_visible(true)
	overlay.visible = false

## The in-match HUD hides behind the start, result and story screens so it does not show
## through them.
func _set_match_hud_visible(visible_now: bool) -> void:
	if not visible_now and _hud_shown:
		bot_panel_wanted = bot_panel.visible
	_hud_shown = visible_now
	for node: CanvasItem in [clock_root, clock_label, minimap_root, hazard_label, skill_bar, controls_label, feed_root, offscreen_root]:
		node.visible = visible_now
	# The bot panel belongs to the match too (it showed through the results table, QA-15).
	bot_panel.visible = visible_now and bot_panel_wanted
	if visible_now:
		# set_status brings the player's plate and the P1 tag back with the next frame.
		return
	player_root.visible = false
	hp_bar.visible = false
	player_tag.visible = false
	# A fresh screen starts without an old message.
	_clear_feed()
	info_timer = 0.0
	_set_warning_visible(false)
	card_panel.visible = false
	# An ultimate cut-in or flash still playing ends with the match view: it stayed 0.85 s
	# over the story dialogue after a fight (QA-21 S1).
	if cutin_tween != null and cutin_tween.is_valid():
		cutin_tween.kill()
	if flash_tween != null and flash_tween.is_valid():
		flash_tween.kill()
	cutin_root.visible = false
	flash_rect.color.a = 0.0
