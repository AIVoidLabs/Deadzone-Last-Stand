class_name Knockback
extends RefCounted
## Vurulan zombinin geriye itilmesi: tek seferlik hız verilir, hız üstel olarak söner.
## Ragdoll ya da fizik motoru yok; kat edilen yol kapalı formülle bellidir.


## force: ağırlığı 1 olan hedefe verilen ilk hız (m/sn). Ağır hedef daha az itilir.
static func impulse(direction: Vector2, force: float, weight: float) -> Vector2:
	if direction == Vector2.ZERO or force <= 0.0:
		return Vector2.ZERO
	return direction.normalized() * (force / maxf(weight, 0.01))


static func decay(velocity: Vector2, damping: float, delta: float) -> Vector2:
	return velocity * exp(-damping * delta)


## İtmenin sonunda kat edilen toplam yol (m).
static func travel_distance(force: float, weight: float, damping: float) -> float:
	return force / maxf(weight, 0.01) / damping
