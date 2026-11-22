class_name CityConePlacement
extends RefCounted
## 8.3j: koni yerlesimi. Cesede (corpse_gap) ya da carpismali prope (clearance) yakin koni, ayni yonde
## halka seklinde aranan en yakin uygun noktaya tasinir; RNG kullanmaz, uygun koniye dokunmaz.
## Kapatma: Tuning.FEATURE_CITY_CONE_CLEAR.

const RING_STEP: float = 0.5
const RING_MAX: int = 14
const ANGLE_STEP: float = 0.7   # tam dairede asal-ish aralik: her halkada farkli aci dizisi


## street_half: sokak yarim eni (koni bu seridin icinde kalir; bina bloklari disinda).
static func is_clear(p: Vector3, corpses: Array[Vector3], blocked: Array[Vector2], corpse_gap: float, clearance: float) -> bool:
	var flat: Vector2 = Vector2(p.x, p.z)
	for c: Vector3 in corpses:
		if flat.distance_to(Vector2(c.x, c.z)) < corpse_gap:
			return false
	for b: Vector2 in blocked:
		if flat.distance_to(b) < clearance:
			return false
	return true


static func on_street(p: Vector3, street_half: float) -> bool:
	return minf(absf(p.x), absf(p.z)) <= street_half


static func pick_spot(p: Vector3, corpses: Array[Vector3], blocked: Array[Vector2], corpse_gap: float, clearance: float, street_half: float) -> Vector3:
	if is_clear(p, corpses, blocked, corpse_gap, clearance):
		return p
	for ring: int in range(1, RING_MAX + 1):
		var dist: float = corpse_gap + RING_STEP * float(ring - 1)
		for k: int in 12:
			var ang: float = ANGLE_STEP * float(k + ring) + TAU * float(k) / 12.0
			var q: Vector3 = Vector3(p.x + cos(ang) * dist, p.y, p.z + sin(ang) * dist)
			if on_street(q, street_half) and is_clear(q, corpses, blocked, corpse_gap, clearance):
				return q
	return p
