extends SceneTree
## Animasyon kütüphanelerindeki kliplerin süresini ve döngü bilgisini yazar.
## Çalıştırma: godot --headless --path . -s res://tools/godot/clip_info.gd

const LIBRARIES: Dictionary = {
	"ual1": "res://assets/models/anim/ual1.glb",
	"ual2": "res://assets/models/anim/ual2.glb",
}


func _init() -> void:
	for library_name: String in LIBRARIES:
		var library: AnimationLibrary = load(LIBRARIES[library_name]) as AnimationLibrary
		for clip: StringName in library.get_animation_list():
			var animation: Animation = library.get_animation(clip)
			print("CLIP %s/%s  %.2f sn  %s" % [library_name, clip, animation.length, "döngü" if animation.loop_mode != Animation.LOOP_NONE else "tek"])
	quit()
