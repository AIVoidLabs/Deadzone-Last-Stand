class_name BloatRules
extends RefCounted
## Patlayıcının patlama kuralları (saf). Askere hasar mesafeye göre azalır (merkezde tam, kenarda edge_factor);
## zombilere alan içinde sabit hasar; itme merkezden dışa.


## Askere hasar: distance merkez-asker uzaklığı; asker gövdesi (player_radius) alana değerse içindedir.
static func player_damage(distance: float, radius: float, full: float, edge_factor: float, player_radius: float) -> float:
	var reach: float = maxf(0.0, distance - player_radius)
	if reach > radius:
		return 0.0
	return full * lerpf(1.0, edge_factor, clampf(reach / maxf(radius, 0.001), 0.0, 1.0))


## Zombiye hasar: gövdesi alana değiyorsa sabit hasar, değilse 0.
static func zombie_damage(distance: float, radius: float, damage: float, zombie_radius: float) -> float:
	return damage if distance <= radius + zombie_radius else 0.0


## Merkezden hedefe itme yönü; üst üsteyse fallback.
static func push_direction(center: Vector2, target: Vector2, fallback: Vector2) -> Vector2:
	var away: Vector2 = target - center
	return away.normalized() if away.length_squared() > 0.0001 else fallback
