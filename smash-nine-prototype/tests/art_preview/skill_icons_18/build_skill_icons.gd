extends SceneTree

const OUT := "res://assets/art/skill_icons"
const REPORT := "res://../reports/codex-art-18"
const SIZE := 40
const N := Color("#101522")
const WHITE := Color("#f7fbff")
const GOLD := Color("#ffc84a")
const GOLD2 := Color("#fff09a")
const STEEL := Color("#6ea4c8")
const ICE := Color("#58d8f5")
const ICE2 := Color("#c9f8ff")
const RED := Color("#ef4f5f")
const PINK := Color("#ff5fb8")
const PINK2 := Color("#ffb4df")
const CYAN := Color("#45e5f5")
const VIOLET := Color("#8062ec")
const VIOLET2 := Color("#c2a8ff")
const BLUE := Color("#39aef0")
const BLUE2 := Color("#a9eaff")

const FILES := [
	"frey_j", "frey_k", "frey_l", "frey_i",
	"yuki_j", "yuki_k", "yuki_l", "yuki_i",
	"luna_j", "luna_k", "luna_l", "luna_i",
	"luna_brave_j", "luna_brave_k", "luna_brave_l", "luna_brave_i",
	"nova_j", "nova_k", "nova_l", "nova_i",
	"rio_j", "rio_k", "rio_l", "rio_i",
]

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT))
	var icons: Array[Image] = []
	for icon_name in FILES:
		var icon := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
		icon.fill(Color.TRANSPARENT)
		_draw_icon(icon, icon_name)
		icon.save_png("%s/%s.png" % [OUT, icon_name])
		icons.append(icon)
	_build_contacts(icons)
	_audit(icons)
	print("[skill_icons_18] wrote %d icons and contact sheets" % icons.size())
	quit()

func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)

func _dot(img: Image, p: Vector2i, c: Color, r: int = 1) -> void:
	for y in range(p.y - r, p.y + r + 1):
		for x in range(p.x - r, p.x + r + 1):
			_px(img, x, y, c)

func _line(img: Image, a: Vector2i, b: Vector2i, c: Color, width: int = 1) -> void:
	var x0 := a.x
	var y0 := a.y
	var dx := absi(b.x - x0)
	var sx := 1 if x0 < b.x else -1
	var dy := -absi(b.y - y0)
	var sy := 1 if y0 < b.y else -1
	var err := dx + dy
	while true:
		_dot(img, Vector2i(x0, y0), c, width / 2)
		if x0 == b.x and y0 == b.y:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

func _poly(img: Image, pts: PackedVector2Array, c: Color) -> void:
	var min_y := SIZE
	var max_y := 0
	for p in pts:
		min_y = mini(min_y, floori(p.y))
		max_y = maxi(max_y, ceili(p.y))
	for y in range(min_y, max_y + 1):
		var hits: Array[float] = []
		for i in range(pts.size()):
			var p1 := pts[i]
			var p2 := pts[(i + 1) % pts.size()]
			if (p1.y <= y and p2.y > y) or (p2.y <= y and p1.y > y):
				hits.append(p1.x + (float(y) - p1.y) * (p2.x - p1.x) / (p2.y - p1.y))
		hits.sort()
		for i in range(0, hits.size() - 1, 2):
			for x in range(ceili(hits[i]), floori(hits[i + 1]) + 1):
				_px(img, x, y, c)

func _circle(img: Image, center: Vector2i, radius: int, c: Color) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if Vector2i(x, y).distance_squared_to(center) <= radius * radius:
				_px(img, x, y, c)

func _ring(img: Image, center: Vector2i, radius: int, thickness: int, c: Color) -> void:
	var inner := (radius - thickness) * (radius - thickness)
	var outer := radius * radius
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var d := Vector2i(x, y).distance_squared_to(center)
			if d <= outer and d >= inner:
				_px(img, x, y, c)

func _star(img: Image, p: Vector2i, radius: int, c: Color) -> void:
	_poly(img, PackedVector2Array([
		p + Vector2i(0, -radius), p + Vector2i(2, -2), p + Vector2i(radius, 0),
		p + Vector2i(2, 2), p + Vector2i(0, radius), p + Vector2i(-2, 2),
		p + Vector2i(-radius, 0), p + Vector2i(-2, -2),
	]), c)

func _spark(img: Image, p: Vector2i, c: Color, radius: int = 3) -> void:
	_line(img, p + Vector2i(-radius, 0), p + Vector2i(radius, 0), N, 3)
	_line(img, p + Vector2i(0, -radius), p + Vector2i(0, radius), N, 3)
	_line(img, p + Vector2i(-radius, 0), p + Vector2i(radius, 0), c, 1)
	_line(img, p + Vector2i(0, -radius), p + Vector2i(0, radius), c, 1)

func _blade(img: Image, a: Vector2i, b: Vector2i, main: Color, glow: Color = WHITE) -> void:
	_line(img, a, b, N, 7)
	_line(img, a, b, main, 5)
	_line(img, a + Vector2i(0, -1), b + Vector2i(0, -1), glow, 1)
	var d := Vector2(b - a).normalized()
	var n := Vector2(-d.y, d.x)
	var guard := Vector2(a) + d * 5.0
	_line(img, Vector2i(guard + n * 5.0), Vector2i(guard - n * 5.0), N, 5)
	_line(img, Vector2i(guard + n * 4.0), Vector2i(guard - n * 4.0), GOLD, 2)

func _talisman(img: Image, center: Vector2i, main: Color = ICE2) -> void:
	var r := Rect2i(center.x - 5, center.y - 9, 10, 18)
	for y in range(r.position.y - 1, r.end.y + 1):
		for x in range(r.position.x - 1, r.end.x + 1):
			_px(img, x, y, N)
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_px(img, x, y, main)
	_line(img, center + Vector2i(-2, -5), center + Vector2i(2, -1), RED, 2)
	_line(img, center + Vector2i(2, -1), center + Vector2i(-2, 4), RED, 2)
	_line(img, center + Vector2i(-2, 4), center + Vector2i(2, 6), RED, 2)

func _mini_talisman(img: Image, center: Vector2i) -> void:
	for y in range(center.y - 6, center.y + 7):
		for x in range(center.x - 4, center.x + 5):
			_px(img, x, y, N)
	for y in range(center.y - 5, center.y + 6):
		for x in range(center.x - 3, center.x + 4):
			_px(img, x, y, ICE2)
	_line(img, center + Vector2i(-1, -3), center + Vector2i(1, 3), RED, 2)

func _heart(img: Image, p: Vector2i, scale: int, c: Color) -> void:
	_circle(img, p + Vector2i(-scale, -scale), scale + 1, N)
	_circle(img, p + Vector2i(scale, -scale), scale + 1, N)
	_poly(img, PackedVector2Array([p + Vector2i(-2 * scale - 1, -scale), p + Vector2i(2 * scale + 1, -scale), p + Vector2i(0, 3 * scale)]), N)
	_circle(img, p + Vector2i(-scale, -scale), scale, c)
	_circle(img, p + Vector2i(scale, -scale), scale, c)
	_poly(img, PackedVector2Array([p + Vector2i(-2 * scale, -scale), p + Vector2i(2 * scale, -scale), p + Vector2i(0, 3 * scale - 1)]), c)

func _arrow(img: Image, a: Vector2i, b: Vector2i, c: Color) -> void:
	_line(img, a, b, N, 7)
	_line(img, a, b, c, 4)
	var d := Vector2(b - a).normalized()
	var n := Vector2(-d.y, d.x)
	_poly(img, PackedVector2Array([Vector2(b + Vector2i(d * 5.0)), Vector2(b) + n * 8.0 - d * 7.0, Vector2(b) - n * 8.0 - d * 7.0]), N)
	_poly(img, PackedVector2Array([Vector2(b + Vector2i(d * 2.0)), Vector2(b) + n * 5.0 - d * 5.0, Vector2(b) - n * 5.0 - d * 5.0]), c)

func _draw_icon(img: Image, id: String) -> void:
	match id:
		"frey_j":
			_blade(img, Vector2i(9, 31), Vector2i(29, 9), STEEL)
			for p in [Vector2i(7, 12), Vector2i(12, 7), Vector2i(30, 27), Vector2i(34, 22)]: _circle(img, p, 2, GOLD)
		"frey_k":
			_blade(img, Vector2i(8, 29), Vector2i(28, 11), STEEL)
			for y in [13, 19, 25]: _line(img, Vector2i(4, y + 6), Vector2i(16, y - 3), GOLD, 2)
		"frey_l":
			_blade(img, Vector2i(14, 33), Vector2i(23, 9), STEEL)
			_line(img, Vector2i(8, 29), Vector2i(7, 15), N, 5); _line(img, Vector2i(8, 29), Vector2i(7, 15), GOLD, 2)
			_line(img, Vector2i(7, 15), Vector2i(14, 7), GOLD2, 2); _spark(img, Vector2i(29, 10), GOLD2)
		"frey_i":
			_blade(img, Vector2i(20, 7), Vector2i(20, 28), STEEL)
			_poly(img, PackedVector2Array([Vector2(3, 31), Vector2(13, 26), Vector2(20, 34), Vector2(27, 26), Vector2(37, 31), Vector2(29, 36), Vector2(11, 36)]), N)
			_line(img, Vector2i(5, 31), Vector2i(14, 29), GOLD, 3); _line(img, Vector2i(26, 29), Vector2i(35, 31), GOLD, 3)
		"yuki_j":
			_talisman(img, Vector2i(22, 20)); _line(img, Vector2i(4, 25), Vector2i(14, 20), ICE, 3); _line(img, Vector2i(6, 31), Vector2i(15, 26), ICE2, 2); _spark(img, Vector2i(33, 9), ICE2)
		"yuki_k":
			_talisman(img, Vector2i(20, 20)); _line(img, Vector2i(6, 10), Vector2i(6, 30), ICE, 3); _line(img, Vector2i(34, 10), Vector2i(34, 30), ICE, 3); _line(img, Vector2i(6, 10), Vector2i(12, 6), ICE2, 2); _line(img, Vector2i(34, 10), Vector2i(28, 6), ICE2, 2)
		"yuki_l":
			for p in [Vector2i(20, 6), Vector2i(34, 20), Vector2i(20, 34), Vector2i(6, 20)]: _line(img, Vector2i(20, 20), p, ICE, 4)
			_ring(img, Vector2i(20, 20), 10, 3, N); _ring(img, Vector2i(20, 20), 9, 2, ICE2); _star(img, Vector2i(20, 20), 6, WHITE)
		"yuki_i":
			_ring(img, Vector2i(20, 20), 13, 3, N); _ring(img, Vector2i(20, 20), 12, 2, ICE)
			for p in [Vector2i(20, 8), Vector2i(32, 20), Vector2i(20, 32), Vector2i(8, 20)]: _mini_talisman(img, p)
			_star(img, Vector2i(20, 20), 7, WHITE)
		"luna_j":
			_ring(img, Vector2i(20, 20), 11, 3, N); _ring(img, Vector2i(20, 20), 10, 2, PINK); _star(img, Vector2i(20, 20), 8, GOLD2); _spark(img, Vector2i(32, 8), GOLD)
		"luna_k":
			_poly(img, PackedVector2Array([Vector2(4, 29), Vector2(12, 17), Vector2(25, 13), Vector2(35, 20), Vector2(23, 27)]), N)
			_line(img, Vector2i(6, 27), Vector2i(25, 17), PINK, 6); _star(img, Vector2i(29, 18), 7, GOLD2); _spark(img, Vector2i(11, 11), CYAN)
		"luna_l":
			_ring(img, Vector2i(20, 20), 14, 5, N); _ring(img, Vector2i(20, 20), 13, 3, PINK); _ring(img, Vector2i(20, 20), 9, 2, CYAN); _star(img, Vector2i(20, 20), 6, GOLD2)
		"luna_i":
			_star(img, Vector2i(20, 20), 15, N); _star(img, Vector2i(20, 20), 13, PINK); _star(img, Vector2i(20, 20), 8, GOLD2); _heart(img, Vector2i(20, 8), 2, PINK2)
		"luna_brave_j":
			_line(img, Vector2i(4, 28), Vector2i(24, 19), N, 7); _line(img, Vector2i(4, 28), Vector2i(24, 19), CYAN, 4); _heart(img, Vector2i(29, 18), 3, PINK); _spark(img, Vector2i(11, 11), GOLD2)
		"luna_brave_k":
			_ring(img, Vector2i(21, 21), 14, 4, N); _ring(img, Vector2i(21, 21), 13, 2, CYAN); _heart(img, Vector2i(22, 19), 4, PINK2); _line(img, Vector2i(4, 31), Vector2i(14, 25), GOLD, 3)
		"luna_brave_l":
			_line(img, Vector2i(7, 31), Vector2i(30, 10), N, 9); _line(img, Vector2i(7, 31), Vector2i(30, 10), PINK, 6); _line(img, Vector2i(10, 29), Vector2i(30, 12), WHITE, 2); _heart(img, Vector2i(11, 10), 2, PINK2); _spark(img, Vector2i(32, 29), GOLD2)
		"luna_brave_i":
			_heart(img, Vector2i(11, 19), 4, PINK); _line(img, Vector2i(18, 21), Vector2i(34, 21), N, 9); _line(img, Vector2i(18, 21), Vector2i(34, 21), WHITE, 5); _line(img, Vector2i(18, 21), Vector2i(34, 21), PINK2, 2); _spark(img, Vector2i(34, 21), GOLD2, 3); _spark(img, Vector2i(19, 9), CYAN, 3)
		"nova_j":
			_arrow(img, Vector2i(5, 27), Vector2i(32, 13), CYAN); _line(img, Vector2i(7, 33), Vector2i(20, 27), VIOLET, 3)
		"nova_k":
			_arrow(img, Vector2i(5, 20), Vector2i(31, 20), CYAN); _line(img, Vector2i(7, 12), Vector2i(19, 12), VIOLET, 3); _line(img, Vector2i(7, 28), Vector2i(19, 28), VIOLET2, 3)
		"nova_l":
			_poly(img, PackedVector2Array([Vector2(20, 5), Vector2(32, 11), Vector2(35, 25), Vector2(28, 34), Vector2(12, 34), Vector2(5, 25), Vector2(8, 11)]), N)
			_poly(img, PackedVector2Array([Vector2(20, 8), Vector2(30, 13), Vector2(32, 24), Vector2(26, 31), Vector2(14, 31), Vector2(8, 24), Vector2(10, 13)]), VIOLET)
			for x in [14, 20, 26]: _line(img, Vector2i(x, 12), Vector2i(x, 28), CYAN, 2)
		"nova_i":
			_circle(img, Vector2i(20, 20), 8, N); _circle(img, Vector2i(20, 20), 5, Color("#080612")); _ring(img, Vector2i(20, 20), 15, 3, N); _ring(img, Vector2i(20, 20), 14, 2, VIOLET)
			_line(img, Vector2i(4, 27), Vector2i(15, 29), CYAN, 3); _arrow(img, Vector2i(24, 11), Vector2i(31, 16), CYAN); _spark(img, Vector2i(8, 9), VIOLET2)
		"rio_j":
			_blade(img, Vector2i(8, 31), Vector2i(27, 10), BLUE)
			_line(img, Vector2i(6, 24), Vector2i(31, 9), N, 7); _line(img, Vector2i(6, 24), Vector2i(31, 9), CYAN, 3)
		"rio_k":
			_line(img, Vector2i(5, 20), Vector2i(35, 20), N, 7); _line(img, Vector2i(5, 20), Vector2i(35, 20), WHITE, 2)
			_ring(img, Vector2i(20, 20), 13, 4, N); _line(img, Vector2i(10, 29), Vector2i(30, 10), VIOLET, 3); _spark(img, Vector2i(20, 20), CYAN, 5)
		"rio_l":
			_ring(img, Vector2i(20, 20), 14, 5, N); _ring(img, Vector2i(20, 20), 13, 3, BLUE); _star(img, Vector2i(20, 20), 8, BLUE2)
			for p in [Vector2i(20, 6), Vector2i(34, 20), Vector2i(20, 34), Vector2i(6, 20)]: _circle(img, p, 2, VIOLET2)
		"rio_i":
			_ring(img, Vector2i(20, 20), 11, 3, N); _ring(img, Vector2i(20, 20), 10, 2, BLUE); _star(img, Vector2i(20, 20), 6, WHITE)
			var gems := [Color("#ff675f"), GOLD, Color("#67e875"), CYAN, VIOLET2, PINK]
			for i in range(6):
				var ang := -PI / 2.0 + TAU * i / 6.0
				var p := Vector2i(20, 20) + Vector2i(roundi(cos(ang) * 15), roundi(sin(ang) * 15))
				_poly(img, PackedVector2Array([p + Vector2i(0, -4), p + Vector2i(3, 0), p + Vector2i(0, 4), p + Vector2i(-3, 0)]), N)
				_poly(img, PackedVector2Array([p + Vector2i(0, -3), p + Vector2i(2, 0), p + Vector2i(0, 3), p + Vector2i(-2, 0)]), gems[i])

func _build_contacts(icons: Array[Image]) -> void:
	var board := Image.create_empty(416, 312, false, Image.FORMAT_RGBA8)
	board.fill(Color("#0a0d14"))
	for panel in range(2):
		var bg := Color("#141824") if panel == 0 else Color("#d9dde3")
		var ox := 8 + panel * 208
		for i in range(icons.size()):
			var x := ox + (i % 4) * 48
			var y := 12 + (i / 4) * 48
			for py in range(y, y + 48):
				for px in range(x, x + 48): board.set_pixel(px, py, bg)
			board.blend_rect(icons[i], Rect2i(0, 0, 40, 40), Vector2i(x + 4, y + 4))
	board.save_png("%s/contact_sheet_1x.png" % REPORT)
	var large := board.duplicate()
	large.resize(board.get_width() * 4, board.get_height() * 4, Image.INTERPOLATE_NEAREST)
	large.save_png("%s/contact_sheet_4x.png" % REPORT)

func _audit(icons: Array[Image]) -> void:
	var csv := "file,width,height,format,visible_pixels,border_pixels,min_x,min_y,max_x,max_y\n"
	var failures: Array[String] = []
	for i in range(icons.size()):
		var img := icons[i]
		var count := 0
		var border := 0
		var min_x := SIZE
		var min_y := SIZE
		var max_x := -1
		var max_y := -1
		for y in range(SIZE):
			for x in range(SIZE):
				if img.get_pixel(x, y).a > 0.01:
					count += 1
					min_x = mini(min_x, x); min_y = mini(min_y, y); max_x = maxi(max_x, x); max_y = maxi(max_y, y)
					if x == 0 or y == 0 or x == SIZE - 1 or y == SIZE - 1: border += 1
		csv += "%s.png,%d,%d,RGBA8,%d,%d,%d,%d,%d,%d\n" % [FILES[i], img.get_width(), img.get_height(), count, border, min_x, min_y, max_x, max_y]
		if img.get_width() != SIZE or img.get_height() != SIZE or border > 0 or count < 50:
			failures.append(FILES[i])
	var f := FileAccess.open("%s/measurements.csv" % REPORT, FileAccess.WRITE)
	f.store_string(csv)
	var v := FileAccess.open("%s/verification.txt" % REPORT, FileAccess.WRITE)
	v.store_string("icons=%d\nsize=40x40\nformat=RGBA8\ntransparent_background=true\nborder_pixels=0 required\nfailures=%s\n" % [icons.size(), ",".join(failures)])
	if not failures.is_empty():
		push_error("Audit failed: %s" % ", ".join(failures))
