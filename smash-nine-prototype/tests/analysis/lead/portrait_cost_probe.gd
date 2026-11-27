extends SceneTree
## Quality track 4 (2026-11-27): what ArtSettings.character_portrait costs per call.
##   <godot> --headless --path . -s tests/analysis/lead/portrait_cost_probe.gd
## Main builds the bot panel's rows every 0.1 s and asks for each fighter's face. When nothing
## else holds the face (the panel hidden), the texture is freed after the refresh and the next
## call loads it from disk again. This times the call three ways, per character and body:
##   free:  nothing holds the result (as with the panel hidden)
##   held:  the first result is kept (as with the panel shown: its rows keep the faces)
##   exists: ResourceLoader.exists on a face path that is not there (the lookup tries it first)
## and prints PORTRAIT_RESULT {json}, microseconds per call.

const ART_SETTINGS := preload("res://scripts/ArtSettings.gd")
const CHARACTERS := ["frey", "luna", "nova", "rio", "xion", "yuki"]
const BODIES := ["male", "female"]
const CALLS := 40

func _initialize() -> void:
	var result := {}
	var free_all: Array = []
	var held_all: Array = []
	for character_id: String in CHARACTERS:
		for body: String in BODIES:
			var key := "%s/%s" % [character_id, body]
			# free: nothing keeps the texture between calls.
			var start := Time.get_ticks_usec()
			for i in CALLS:
				var texture: Texture2D = ART_SETTINGS.character_portrait(character_id, body)
				texture = null
			var free_us := float(Time.get_ticks_usec() - start) / CALLS
			# held: one reference stays, so load() finds it in the cache.
			var keep: Texture2D = ART_SETTINGS.character_portrait(character_id, body)
			start = Time.get_ticks_usec()
			for i in CALLS:
				var texture: Texture2D = ART_SETTINGS.character_portrait(character_id, body)
				texture = null
			var held_us := float(Time.get_ticks_usec() - start) / CALLS
			result[key] = {"free_us": snappedf(free_us, 0.1), "held_us": snappedf(held_us, 0.1),
				"path": keep.resource_path if keep != null else "", "size": keep.get_size() if keep != null else Vector2.ZERO}
			keep = null
			free_all.append(free_us)
			held_all.append(held_us)
	var missing := "res://assets/art/frey/frey_male_face.png"
	var start := Time.get_ticks_usec()
	for i in CALLS * 10:
		ResourceLoader.exists(missing)
	var exists_us := float(Time.get_ticks_usec() - start) / (CALLS * 10)
	var mean := func(values: Array) -> float:
		var total := 0.0
		for value in values:
			total += float(value)
		return snappedf(total / maxf(1.0, values.size()), 0.1)
	print("PORTRAIT_RESULT ", JSON.stringify({"per_face": result, "free_mean_us": mean.call(free_all),
		"held_mean_us": mean.call(held_all), "missing_exists_us": snappedf(exists_us, 0.1)}))
	quit()
