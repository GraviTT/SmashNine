extends SceneTree

const SOURCES := [
	"res://assets/art/frey/frey_illustration_source.png",
	"res://assets/art/frey/frey_v2_source.png",
	"res://assets/art/nova/nova_male_illustration_source.png",
	"res://assets/art/nova/nova_male_v2_source.png",
	"res://assets/art/nova/nova_female_illustration_source.png",
	"res://assets/art/nova/nova_female_v2_source.png",
	"res://assets/art/yuki/yuki_illustration_source.png",
	"res://assets/art/yuki/yuki_v2_source.png",
]

func _initialize() -> void:
	for path: String in SOURCES:
		var image := Image.load_from_file(path)
		var alpha_min := 1.0
		var alpha_max := 0.0
		var transparent := 0
		for y: int in range(image.get_height()):
			for x: int in range(image.get_width()):
				var alpha := image.get_pixel(x, y).a
				alpha_min = minf(alpha_min, alpha)
				alpha_max = maxf(alpha_max, alpha)
				if alpha < 0.01:
					transparent += 1
		print("[source] %s %dx%d alpha=%.3f..%.3f transparent=%d/%d" % [path, image.get_width(), image.get_height(), alpha_min, alpha_max, transparent, image.get_width() * image.get_height()])
	quit()
