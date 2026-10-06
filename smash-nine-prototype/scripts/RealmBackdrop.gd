extends Node2D
## Procedural realm background. Theme drawings are authored on a 1280x720 tile and
## scaled to each tile of the realm; `margin` extends the base colour past the edges.

const AUTHORED_TILE := Vector2(1280, 720)

var realm_size := Vector2(1280, 720)
var tile_size := Vector2(1280, 720)
var theme := "valkyrie_gate"
var theme_index := 0
var base_color := Color(0.02, 0.04, 0.08)
var accent_color := Color(1.0, 0.72, 0.34)
var margin := 0.0

func configure(new_realm_size: Vector2, new_tile_size: Vector2, new_theme: String, new_base: Color, new_accent: Color, new_margin := 0.0) -> void:
	realm_size = new_realm_size
	tile_size = new_tile_size
	theme = new_theme
	theme_index = new_theme.hash() % 97
	base_color = new_base
	accent_color = new_accent
	margin = new_margin
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-Vector2.ONE * margin, realm_size + Vector2.ONE * margin * 2.0), base_color.darkened(0.35))
	draw_rect(Rect2(Vector2.ZERO, realm_size), base_color)
	var tiles_x := maxi(1, roundi(realm_size.x / tile_size.x))
	var tiles_y := maxi(1, roundi(realm_size.y / tile_size.y))
	var tile_scale := tile_size / AUTHORED_TILE
	for tile_y in tiles_y:
		for tile_x in tiles_x:
			draw_set_transform(Vector2(tile_x * tile_size.x, tile_y * tile_size.y), 0.0, tile_scale)
			_draw_realm_tile(Vector2.ZERO, tile_x + tile_y * tiles_x)
	draw_set_transform(Vector2.ZERO)

func _draw_realm_tile(origin: Vector2, variation: int) -> void:
	_draw_depth_bands(origin)
	_draw_sky_specks(origin, variation)
	match theme:
		"valkyrie_gate":
			_draw_valkyrie_gate(origin)
		"moon_bridge":
			_draw_moon_bridge(origin)
		"sunken_temple":
			_draw_sunken_temple(origin)
		"skyline_spires":
			_draw_skyline_spires(origin)
		"ember_ring":
			_draw_ember_ring(origin, variation)
		"frost_steps":
			_draw_frost_steps(origin, variation)
		"gravity_well":
			_draw_gravity_well(origin, variation)
		"market_rooftops":
			_draw_market_rooftops(origin)
		"starfall_shrine":
			_draw_starfall_shrine(origin, variation)

func _draw_depth_bands(origin: Vector2) -> void:
	var distant := base_color.lightened(0.055)
	var near := base_color.lightened(0.095)
	draw_rect(Rect2(origin + Vector2(0, AUTHORED_TILE.y * 0.48), Vector2(AUTHORED_TILE.x, AUTHORED_TILE.y * 0.52)), distant)
	var ridge := PackedVector2Array([
		origin + Vector2(0, 530), origin + Vector2(170, 440), origin + Vector2(340, 500),
		origin + Vector2(520, 390), origin + Vector2(720, 500), origin + Vector2(930, 410),
		origin + Vector2(1120, 485), origin + Vector2(1280, 430), origin + Vector2(1280, 720),
		origin + Vector2(0, 720)
	])
	draw_colored_polygon(ridge, near)

func _draw_sky_specks(origin: Vector2, variation: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1103 + theme_index * 97 + variation * 31
	for index in 24:
		var position := origin + Vector2(rng.randf_range(35, AUTHORED_TILE.x - 35), rng.randf_range(105, 390))
		var size := 2.0 if index % 5 else 4.0
		draw_rect(Rect2(position, Vector2(size, size)), Color(accent_color.r, accent_color.g, accent_color.b, 0.22 + float(index % 3) * 0.12))

func _draw_valkyrie_gate(origin: Vector2) -> void:
	var stone := Color(0.16, 0.19, 0.26, 0.92)
	var glow := Color(accent_color.r, accent_color.g, accent_color.b, 0.38)
	draw_rect(Rect2(origin + Vector2(470, 205), Vector2(62, 300)), stone)
	draw_rect(Rect2(origin + Vector2(748, 205), Vector2(62, 300)), stone)
	draw_rect(Rect2(origin + Vector2(445, 190), Vector2(390, 42)), stone.lightened(0.08))
	draw_arc(origin + Vector2(640, 250), 154, PI, TAU, 24, glow, 8)
	draw_line(origin + Vector2(640, 245), origin + Vector2(640, 470), glow, 3)

func _draw_moon_bridge(origin: Vector2) -> void:
	var moon := Color(0.78, 0.86, 1.0, 0.78)
	draw_circle(origin + Vector2(1010, 185), 92, moon)
	draw_circle(origin + Vector2(1042, 160), 92, base_color.lightened(0.025))
	for index in 4:
		draw_line(origin + Vector2(100, 400 + index * 32), origin + Vector2(1180, 400 + index * 32), Color(accent_color.r, accent_color.g, accent_color.b, 0.1), 3)
	draw_arc(origin + Vector2(640, 520), 460, PI + 0.22, TAU - 0.22, 36, Color(accent_color.r, accent_color.g, accent_color.b, 0.25), 4)

func _draw_sunken_temple(origin: Vector2) -> void:
	var ruin := Color(0.08, 0.2, 0.22, 0.92)
	for x in [170, 370, 850, 1050]:
		draw_rect(Rect2(origin + Vector2(x, 270), Vector2(58, 270)), ruin)
		draw_rect(Rect2(origin + Vector2(x - 18, 252), Vector2(94, 24)), ruin.lightened(0.08))
	draw_rect(Rect2(origin + Vector2(140, 520), Vector2(1000, 28)), ruin.lightened(0.04))
	for index in 8:
		draw_circle(origin + Vector2(95 + index * 151, 150 + (index % 3) * 42), 6 + index % 4, Color(accent_color.r, accent_color.g, accent_color.b, 0.18))

func _draw_skyline_spires(origin: Vector2) -> void:
	var tower := Color(0.06, 0.12, 0.22, 0.94)
	for index in 7:
		var width := 70.0 + float(index % 3) * 22.0
		var height := 170.0 + float((index * 53) % 230)
		var x := 65.0 + index * 182.0
		draw_rect(Rect2(origin + Vector2(x, 570 - height), Vector2(width, height)), tower.lightened(float(index % 2) * 0.035))
		draw_colored_polygon(PackedVector2Array([origin + Vector2(x, 570 - height), origin + Vector2(x + width * 0.5, 520 - height), origin + Vector2(x + width, 570 - height)]), tower.lightened(0.06))

func _draw_ember_ring(origin: Vector2, variation: int) -> void:
	var lava := Color(1.0, 0.18, 0.035, 0.34)
	draw_line(origin + Vector2(0, 560), origin + Vector2(1280, 540), lava, 22)
	draw_arc(origin + Vector2(640, 470), 285, PI + 0.2, TAU - 0.2, 30, Color(accent_color.r, accent_color.g, accent_color.b, 0.3), 9)
	for index in 16:
		var x := float((index * 83 + variation * 41) % 1200) + 40
		var y := 470.0 - float((index * 37) % 240)
		draw_rect(Rect2(origin + Vector2(x, y), Vector2(4, 10 + index % 4 * 4)), Color(accent_color.r, accent_color.g, accent_color.b, 0.35))

func _draw_frost_steps(origin: Vector2, variation: int) -> void:
	var ice := Color(0.42, 0.82, 0.96, 0.24)
	for index in 6:
		var x := float(index * 220 - 60)
		var peak := 300.0 + float((index + variation) % 3) * 65.0
		draw_colored_polygon(PackedVector2Array([origin + Vector2(x, 560), origin + Vector2(x + 150, peak), origin + Vector2(x + 310, 560)]), ice)
	for index in 30:
		var x := float((index * 47 + variation * 23) % 1240) + 20
		var y := float((index * 71) % 390) + 95
		draw_rect(Rect2(origin + Vector2(x, y), Vector2(3, 8)), Color(0.85, 0.97, 1.0, 0.42))

func _draw_gravity_well(origin: Vector2, variation: int) -> void:
	var center := origin + Vector2(640, 365)
	for radius in [80, 150, 235, 330]:
		draw_arc(center, radius, 0.15 + variation * 0.08, TAU - 0.45, 40, Color(accent_color.r, accent_color.g, accent_color.b, 0.14), 4)
	draw_circle(center, 42, Color(0.01, 0.005, 0.03, 0.88))
	draw_arc(center, 48, 0, TAU, 30, Color(accent_color.r, accent_color.g, accent_color.b, 0.6), 5)
	for index in 9:
		var point := center + Vector2.from_angle(float(index) * TAU / 9.0) * (120 + index % 3 * 75)
		draw_colored_polygon(PackedVector2Array([point + Vector2(-12, 4), point + Vector2(-2, -11), point + Vector2(15, -3), point + Vector2(8, 12)]), Color(0.25, 0.22, 0.42, 0.75))

func _draw_market_rooftops(origin: Vector2) -> void:
	var building := Color(0.17, 0.12, 0.1, 0.95)
	for index in 6:
		var x := float(index * 225 - 35)
		var height := 150.0 + float(index % 3) * 55.0
		draw_rect(Rect2(origin + Vector2(x, 590 - height), Vector2(205, height)), building.lightened(float(index % 2) * 0.035))
		draw_colored_polygon(PackedVector2Array([origin + Vector2(x - 20, 590 - height), origin + Vector2(x + 102, 535 - height), origin + Vector2(x + 225, 590 - height)]), Color(0.29, 0.15, 0.1, 0.95))
	for index in 10:
		var lamp := origin + Vector2(90 + index * 122, 260 + (index % 2) * 55)
		draw_line(lamp - Vector2(0, 38), lamp, Color(0.42, 0.31, 0.2, 0.55), 2)
		draw_rect(Rect2(lamp - Vector2(7, 0), Vector2(14, 20)), Color(accent_color.r, accent_color.g, accent_color.b, 0.68))

func _draw_starfall_shrine(origin: Vector2, variation: int) -> void:
	var shrine := Color(0.23, 0.08, 0.19, 0.93)
	draw_rect(Rect2(origin + Vector2(470, 260), Vector2(42, 300)), shrine)
	draw_rect(Rect2(origin + Vector2(768, 260), Vector2(42, 300)), shrine)
	draw_rect(Rect2(origin + Vector2(425, 235), Vector2(430, 42)), shrine.lightened(0.08))
	draw_rect(Rect2(origin + Vector2(485, 295), Vector2(310, 28)), shrine)
	for index in 8:
		var start := origin + Vector2(80 + index * 155, 120 + ((index + variation) % 3) * 55)
		draw_line(start, start + Vector2(38, 62), Color(accent_color.r, accent_color.g, accent_color.b, 0.46), 4)
		draw_rect(Rect2(start - Vector2(3, 3), Vector2(7, 7)), Color(1.0, 0.88, 1.0, 0.8))
