class_name CityWestLight
extends Node3D
## 8.3j: bati kolunun karanligini kapatan gorunur kaynaklar: sonmekte olan cop atesleri (CityFire) ve her birinin
## zemine sizan sicak sahte isigi. OmniLight yok (profil siniri bozulmaz). Kapatma: Tuning.FEATURE_CITY_WEST_LIGHT.

var _fires: Array[CityFire] = []


func _ready() -> void:
	name = "CityWestLight"
	for p: Vector3 in Tuning.CITY_WEST_FIRES:
		var fire: CityFire = CityFire.new(Tuning.CITY_WEST_FIRE_SCALE, Vector3(0.9, 0.05, 0.45) * Tuning.CITY_WEST_FIRE_SCALE, Tuning.CITY_FIRE_TRASH_HEIGHT)
		fire.position = p
		add_child(fire)
		AmbienceEmitter.attach(self, &"fire", p + Vector3(0.0, Tuning.AMBIENCE_EMITTER_HEIGHT, 0.0))
		_fires.append(fire)
		add_child(CityFxAssets.glow_quad(p, Tuning.CITY_WEST_GLOW_RADIUS, Tuning.CITY_WEST_GLOW_COLOR, Tuning.CITY_WEST_GLOW_ENERGY, Tuning.CITY_WEST_GLOW_FLICKER))
	_apply_quality(Quality.current)
	Quality.profile_changed.connect(_apply_quality)


func _apply_quality(_profile_id: StringName) -> void:
	var level: int = Quality.get_value("city_fx")
	for fire: CityFire in _fires:
		fire.apply_level(level)
