class_name SoundDistance
extends RefCounted
## Konumlu seslerin uzaklık kuralı (saf): yakında tam ses, uzaklaştıkça dB doğrusal düşer, ötesinde çalmaz.


## Yatay (XZ) uzaklık; yükseklik sayılmaz.
static func flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Ses bu uzaklıkta çalsın mı (max_radius ve ötesi: hayır).
static func audible(distance: float, max_radius: float) -> bool:
	return distance < max_radius


## Uzaklığa göre eklenecek dB: full_radius içinde 0, max_radius'ta min_db, arada doğrusal.
static func offset_db(distance: float, full_radius: float, max_radius: float, min_db: float) -> float:
	if distance <= full_radius:
		return 0.0
	if distance >= max_radius:
		return min_db
	return min_db * (distance - full_radius) / (max_radius - full_radius)
