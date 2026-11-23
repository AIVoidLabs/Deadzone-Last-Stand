class_name QualityProfiles
extends RefCounted
## Platforma bağlı her değer burada. Oyun kodu yalnız aktif profili okur.
## max_enemies: Aşama 2.5 ölçümünde animasyonlu mankenle (2.5 bin üçgen, 25 kemik) 60 FPS tavanı
## ~500, 350'de ~96 FPS (RTX 3050 Ti Laptop). Efektlere pay kalsın diye yüksek profil 350.
## Karışık türlerle Aşama 7.5'te yeniden ölçülür.

const LOW: StringName = &"low"
const MEDIUM: StringName = &"medium"
const HIGH: StringName = &"high"

const ORDER: Array[StringName] = [&"low", &"medium", &"high"]

const TABLE: Dictionary = {
	# spark_amount: isabet başına kıvılcım. muzzle_light: atışta kısa nokta ışığı. bag_light: ödül çantasının nokta ışığı.
	# omni_lights: şehir greybox omni ışık üst sınırı; fire_shadows: ateş ışıklarında gölge.
	# ssr, volumetric_fog, glow, vignette: 8.3a atmosfer. ground_dressing: yer dekoru adet çarpanı (8.3d).
	# city_fx: şehir efekt seviyesi 0/1/2 (adetler Tuning.CITY_FX_*; 0'da duman, kül, lamba konisi kapalı).
	# blood_amount: isabet başına kan damlası (ölümde katlanır). decal_max: yerde aynı anda en çok leke.
	&"low": {"max_enemies": 150, "shadows": false, "msaa": 0, "spark_amount": 4, "muzzle_light": false, "bag_light": false, "blood_amount": 4, "decal_max": 48, "omni_lights": 4, "fire_shadows": false, "ssr": false, "volumetric_fog": false, "glow": false, "vignette": false, "city_fx": 0, "ground_dressing": 0.5},
	&"medium": {"max_enemies": 250, "shadows": true, "msaa": 1, "spark_amount": 6, "muzzle_light": true, "bag_light": true, "blood_amount": 6, "decal_max": 128, "omni_lights": 8, "fire_shadows": false, "ssr": false, "volumetric_fog": false, "glow": true, "vignette": true, "city_fx": 1, "ground_dressing": 1.0},
	&"high": {"max_enemies": 350, "shadows": true, "msaa": 2, "spark_amount": 10, "muzzle_light": true, "bag_light": true, "blood_amount": 9, "decal_max": 256, "omni_lights": 8, "fire_shadows": true, "ssr": true, "volumetric_fog": true, "glow": true, "vignette": true, "city_fx": 2, "ground_dressing": 1.0},
}


static func get_profile(id: StringName) -> Dictionary:
	assert(TABLE.has(id), "Bilinmeyen kalite profili: %s" % id)
	return TABLE[id]


## Platform yalnız varsayılanı seçer.
static func default_for(is_web: bool) -> StringName:
	return LOW if is_web else HIGH


static func next_after(id: StringName) -> StringName:
	var i: int = ORDER.find(id)
	return ORDER[(i + 1) % ORDER.size()]
