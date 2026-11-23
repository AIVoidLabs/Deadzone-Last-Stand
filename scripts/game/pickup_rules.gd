class_name PickupRules
extends RefCounted
## Yerdeki kristallerin hareketi: düşerken sekme, askere çekilme. Sahneden bağımsız.


## Çekilen kristalin yeni hızı: ivmelenir, üst sınırda durur.
static func pull_speed(speed: float, accel: float, max_speed: float, delta: float) -> float:
	return minf(max_speed, speed + accel * delta)


## Çekilen kristalin yeni konumu: hedefe doğru step kadar, öteye geçmeden.
static func pull_step(pos: Vector2, target: Vector2, speed: float, delta: float) -> Vector2:
	return pos.move_toward(target, speed * delta)


## Sekme yüksekliği: 0'dan çıkıp t = duration/2'de height'a varan, duration'da yere inen parabol.
static func hop_height(t: float, duration: float, height: float) -> float:
	if duration <= 0.0:
		return 0.0
	var k: float = clampf(t / duration, 0.0, 1.0)
	return 4.0 * height * k * (1.0 - k)


## Ölen zombi kristal bırakır mı? chance 0..1; rastgelelik rng'den (test edilebilir).
static func should_drop(chance: float, rng: RandomNumberGenerator) -> bool:
	if chance >= 1.0:
		return true
	return rng.randf() < chance


## Askerin çekim menzilinde mi?
static func in_magnet(pos: Vector2, player: Vector2, radius: float) -> bool:
	return pos.distance_squared_to(player) <= radius * radius


## Kristalin görüntü boyu: değeri büyüdükçe (birleşince) biraz büyür.
static func value_scale(value: int, per_value: float, max_scale: float) -> float:
	return minf(max_scale, 1.0 + per_value * float(maxi(0, value - 1)))
