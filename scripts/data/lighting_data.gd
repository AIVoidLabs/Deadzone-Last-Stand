class_name LightingData
extends RefCounted
## Işık ve zemin ön ayarları (5.7). Etkin olan Tuning.LIGHTING_PRESET; debug yapıda --lighting=<ad> ile denenir.
## Arena 8.1'de şehir sokağına dönünce zemin alanları oraya taşınır, ışık alanları kalır.

const TABLE: Dictionary = {
	# Aşama 1'den beri kullanılan: açık gri ızgara, filmic, renkler biraz soluk.
	&"classic": {
		"background": Color(0.09, 0.1, 0.12),
		"ambient_color": Color(0.55, 0.6, 0.7), "ambient_energy": 0.6,
		"sun_color": Color(1.0, 1.0, 1.0), "sun_energy": 1.2, "sun_rotation_deg": Vector3(-55.0, -35.0, 0.0),
		"tonemap": Environment.TONE_MAPPER_FILMIC, "exposure": 1.0, "saturation": 1.0, "contrast": 1.0,
		"ground_base": Color(0.24, 0.25, 0.27), "ground_line": Color(0.31, 0.32, 0.35), "ground_outside": Color(0.14, 0.14, 0.16),
		"ground_stains": 0.0, "fog_density": 0.0, "fog_color": Color(0.0, 0.0, 0.0),
	},
	# Akşam sokağı: koyu asfalt, sıcak alçak güneş, soğuk gölgeler; karakterler zeminden ayrışır.
	&"dusk": {
		"background": Color(0.05, 0.055, 0.07),
		"ambient_color": Color(0.5, 0.58, 0.8), "ambient_energy": 0.75,
		"sun_color": Color(1.0, 0.88, 0.74), "sun_energy": 2.4, "sun_rotation_deg": Vector3(-42.0, -40.0, 0.0),
		"tonemap": Environment.TONE_MAPPER_AGX, "exposure": 1.25, "saturation": 1.2, "contrast": 1.05,
		"ground_base": Color(0.15, 0.16, 0.18), "ground_line": Color(0.2, 0.21, 0.235), "ground_outside": Color(0.06, 0.06, 0.07),
		"ground_stains": 0.35, "fog_density": 0.005, "fog_color": Color(0.2, 0.24, 0.34),
	},
	# Bulutlu gündüz: yumuşak, nötr ışık; orta tonda beton, renkler doygun ama sakin.
	&"overcast": {
		"background": Color(0.1, 0.11, 0.12),
		"ambient_color": Color(0.72, 0.75, 0.8), "ambient_energy": 1.0,
		"sun_color": Color(0.95, 0.97, 1.0), "sun_energy": 1.5, "sun_rotation_deg": Vector3(-65.0, -25.0, 0.0),
		"tonemap": Environment.TONE_MAPPER_AGX, "exposure": 1.4, "saturation": 1.25, "contrast": 1.0,
		"ground_base": Color(0.24, 0.235, 0.225), "ground_line": Color(0.29, 0.285, 0.275), "ground_outside": Color(0.1, 0.1, 0.1),
		"ground_stains": 0.25, "fog_density": 0.0, "fog_color": Color(0.0, 0.0, 0.0),
	},
}


static func get_preset(id: StringName) -> Dictionary:
	assert(TABLE.has(id), "Bilinmeyen ışık ön ayarı: %s" % id)
	return TABLE[id]
