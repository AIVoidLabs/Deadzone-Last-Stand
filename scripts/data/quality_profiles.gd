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
	# spark_amount: isabet başına kıvılcım. muzzle_light: atışta kısa nokta ışığı.
	&"low": {"max_enemies": 150, "shadows": false, "msaa": 0, "spark_amount": 4, "muzzle_light": false},
	&"medium": {"max_enemies": 250, "shadows": true, "msaa": 1, "spark_amount": 6, "muzzle_light": true},
	&"high": {"max_enemies": 350, "shadows": true, "msaa": 2, "spark_amount": 10, "muzzle_light": true},
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
