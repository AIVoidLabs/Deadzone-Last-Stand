class_name ScreamRules
extends RefCounted
## Çığlıkçının kuralları (saf): mesafe davranışı (yaklaş / dur / kaç), çağrı halkasındaki doğma noktaları, çağrı sınırı.


## Hareket vektörü (birim ya da sıfır): to_target askere yön. Mesafe keep_min'den yakınsa kaçar (-to_target),
## scream_range'den uzaksa yaklaşır, arada durur.
static func move_vector(distance: float, scream_range: float, keep_min: float, to_target: Vector2) -> Vector2:
	if distance < keep_min:
		return -to_target
	if distance > scream_range:
		return to_target
	return Vector2.ZERO


## center çevresinde radius yarıçaplı halkada eşit aralıklı count nokta (start_angle'dan), arenaya (±half) kırpılı.
static func ring_points(center: Vector2, radius: float, count: int, start_angle: float, half: float) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	for k in count:
		var point: Vector2 = center + Vector2.from_angle(start_angle + TAU * float(k) / float(maxi(count, 1))) * radius
		out.append(point.clamp(Vector2(-half, -half), Vector2(half, half)))
	return out


## Bu çığlıkta en çok kaç zombi çağrılır: istenen sayı, çağıranın kalan kotası ve genel üst sınırın kalanı ile sınırlı.
static func allowed_count(want: int, caller_alive: int, caller_max: int, total_alive: int, total_cap: int) -> int:
	return maxi(0, mini(want, mini(caller_max - caller_alive, total_cap - total_alive)))
