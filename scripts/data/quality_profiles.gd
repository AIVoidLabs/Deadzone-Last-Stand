class_name QualityProfiles
extends RefCounted
## Platforma bağlı her değer burada. Oyun kodu yalnız aktif profili okur.
## max_enemies: Aşama 1 ölçümünde kutu zombilerle 60 FPS tavanı ~1350 (RTX 3050 Ti Laptop).
## Yüksek profil bunun yaklaşık yarısında; iskeletli modeller (Aşama 5) gelince yeniden ölçülür.

const LOW: StringName = &"low"
const MEDIUM: StringName = &"medium"
const HIGH: StringName = &"high"

const ORDER: Array[StringName] = [&"low", &"medium", &"high"]

const TABLE: Dictionary = {
	&"low": {"max_enemies": 200, "shadows": false, "msaa": 0},
	&"medium": {"max_enemies": 350, "shadows": true, "msaa": 1},
	&"high": {"max_enemies": 600, "shadows": true, "msaa": 2},
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
