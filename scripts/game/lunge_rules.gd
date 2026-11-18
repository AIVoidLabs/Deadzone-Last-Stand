class_name LungeRules
extends RefCounted
## Koşucunun atılma kuralları (saf). Rastgele değil: hedefin gideceği yere nişan alır (lead),
## hazırlığın sonunda yönü kilitler, atılırken sınırlı dönüşle hafifçe izler.


## from'dan target'a atılma yönü. target_vel hedefin hızı; lead 0 ise doğrudan, 1 ise tam önden kesme.
## Varış süresi mesafe / atılma hızı kabul edilir.
static func aim_direction(from: Vector2, target: Vector2, target_vel: Vector2, lunge_speed: float, lead: float) -> Vector2:
	var arrive: float = from.distance_to(target) / maxf(lunge_speed, 0.001)
	var predicted: Vector2 = target + target_vel * arrive * lead
	var dir: Vector2 = predicted - from
	if dir.length_squared() < 0.000001:
		dir = target - from
	return dir.normalized() if dir.length_squared() > 0.000001 else Vector2.DOWN


## current yönünü desired yönüne en çok max_turn radyan döndürür.
static func steer(current: Vector2, desired: Vector2, max_turn: float) -> Vector2:
	if current == Vector2.ZERO:
		return desired
	var angle: float = current.angle_to(desired)
	return current.rotated(clampf(angle, -max_turn, max_turn)).normalized()


## Hazırlığın son lock_time saniyesinde yön kilitlenir (oyuncuya tepki payı).
static func is_aim_locked(windup_left: float, lock_time: float) -> bool:
	return windup_left <= lock_time
