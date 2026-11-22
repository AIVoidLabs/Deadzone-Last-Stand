class_name AmbienceData
extends RefCounted
## Ortam ses tablosu. Dosya adı değişince (gerçek CC0 dosyalar gelince) yalnız burası değişir.
## Dosyalar assets/audio/ambience/ altında; üretim: tools/sfx/gen_ambience.py (yer tutucular diskte kalır: fire_crackle, city_rumble, distant_*; CC0 dosyalar *_cc0: tools/sfx/process_ambience.py).

const DIR: String = "res://assets/audio/ambience/%s.wav"
const BUS: StringName = &"Ambience"
## AudioStreamPlayer3D.attenuation_model: 0 ters mesafe, 1 ters kare, 2 logaritmik, 3 kapalı.
const ATT_INVERSE_DISTANCE: int = 0
const ATT_INVERSE_SQUARE: int = 1

## 3B döngü yayıcıları. unit_size: sesin düşmeye başladığı uzaklık, max_distance: bunun ötesi duyulmaz.
## pitch_variance: perde ± payı (yayıcılar birbirine faz kaymadan da farklı dursun).
const EMITTERS: Dictionary = {
	&"fire": {
		"file": "fire_cc0", "volume_db": -9.0, "unit_size": 2.5, "max_distance": 14.0,
		"attenuation": ATT_INVERSE_SQUARE, "pitch_variance": 0.06,
	},
	&"neon": {
		"file": "neon_buzz", "volume_db": -14.0, "unit_size": 2.5, "max_distance": 14.0,
		"attenuation": ATT_INVERSE_SQUARE, "pitch_variance": 0.02,
	},
	&"neon_broken": {
		"file": "neon_broken", "volume_db": -10.0, "unit_size": 2.5, "max_distance": 16.0,
		"attenuation": ATT_INVERSE_SQUARE, "pitch_variance": 0.02,
	},
	&"wire_hum": {
		"file": "wire_hum", "volume_db": -16.0, "unit_size": 3.0, "max_distance": 12.0,
		"attenuation": ATT_INVERSE_DISTANCE, "pitch_variance": 0.01,
	},
}

## Her zaman açık, konumsuz döngüler.
const BEDS: Array[Dictionary] = [
	{"file": "wind", "volume_db": -26.0},
	{"file": "city_bed_cc0", "volume_db": -13.0},
]

## Uzak tek seferlikler: weight = seçilme ağırlığı.
const DISTANT: Array[Dictionary] = [
	{"file": "distant_siren_cc0", "volume_db": -30.0, "weight": 0.4, "pitch_variance": 0.04},
	{"file": "distant_dog_cc0", "volume_db": -27.0, "weight": 1.0, "pitch_variance": 0.08},
	{"file": "distant_glass_cc0", "volume_db": -28.0, "weight": 0.7, "pitch_variance": 0.05},
]


static func path_of(file: String) -> String:
	return DIR % file


static func distant_weights() -> Array[float]:
	var out: Array[float] = []
	for row: Dictionary in DISTANT:
		out.append(float(row["weight"]))
	return out
