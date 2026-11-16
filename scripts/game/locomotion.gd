class_name Locomotion
extends RefCounted
## Askerin XZ düzlemindeki hız kuralı ve gövde yatması. Sahneden bağımsız; değerler parametreyle gelir.


## Girdi varsa hedef hıza ivmelenir, yoksa sürtünmeyle durur. Yeni hızı döndürür.
static func step(velocity: Vector2, input: Vector2, max_speed: float, accel: float, friction: float, delta: float) -> Vector2:
	var wish: Vector2 = input.limit_length(1.0)
	var rate: float = accel if wish != Vector2.ZERO else friction
	return velocity.move_toward(wish * max_speed, rate * delta)


## Hıza göre öne yatma açısı (radyan): dururken 0, tam hızda max_angle.
static func forward_lean(speed: float, max_speed: float, max_angle: float) -> float:
	if max_speed <= 0.0:
		return 0.0
	return clampf(speed / max_speed, 0.0, 1.0) * max_angle


## Dönüşe doğru yana yatma açısı (radyan). yaw_error: hedef yön - şimdiki yön (radyan, işaretli).
static func turn_lean(yaw_error: float, gain: float, max_angle: float) -> float:
	return clampf(yaw_error * gain, -max_angle, max_angle)
