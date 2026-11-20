class_name LobRules
extends RefCounted
## Yay atışı kuralları (saf): tükürücünün asit topu ve taş fırlatanın kayası. Hedef noktası askerin önünden alınır,
## hazırlığın sonunda kilitlenir; asker iniş halkasından çıkarak ya da dash'in dokunulmazlığıyla kurtulur.


## from'dan atan zombinin target'ı (hızı target_vel) lead sn sonra bulacağı yer; max_range'e (zombiden) ve arenaya kırpılır.
static func target_point(from: Vector2, target: Vector2, target_vel: Vector2, lead: float, max_range: float, half: float) -> Vector2:
	var aim: Vector2 = target + target_vel * lead
	var offset: Vector2 = aim - from
	if offset.length() > max_range:
		aim = from + offset.normalized() * max_range
	return aim.clamp(Vector2(-half, -half), Vector2(half, half))


## Yayın t (0..1) anındaki konum: x/z doğrusal, y bırakış yüksekliğinden yere inerken tepe arc kadar kabarır.
static func position_at(from: Vector2, dest: Vector2, t: float, arc: float, release_height: float) -> Vector3:
	var u: float = clampf(t, 0.0, 1.0)
	var flat: Vector2 = from.lerp(dest, u)
	return Vector3(flat.x, lerpf(release_height, 0.0, u) + JumpRules.height_at(u, arc), flat.y)


## Uçuşun ilerleme oranı (0..1).
static func progress(elapsed: float, flight: float) -> float:
	return clampf(elapsed / maxf(flight, 0.001), 0.0, 1.0)


## İniş (kaya) askeri kapsıyor mu.
static func hits(player_pos: Vector2, dest: Vector2, radius: float, player_radius: float) -> bool:
	return JumpRules.lands_on(player_pos, dest, radius, player_radius)


## Asit havuzunun içinde mi (askerin merkezi havuz dairesinde).
static func in_pool(player_pos: Vector2, center: Vector2, radius: float) -> bool:
	return player_pos.distance_to(center) <= radius


## Tik birikimi: acc + delta içinden kaç tam interval çıktığı (y) ve kalan birikim (x).
static func advance_tick(acc: float, delta: float, interval: float) -> Vector2:
	var total: float = acc + delta
	var ticks: float = floorf(total / maxf(interval, 0.001))
	return Vector2(total - ticks * interval, ticks)


## Taş fırlatan yakın vuruşa mı geçer: asker temas + melee_range içinde.
static func wants_swat(distance: float, contact: float, melee_range: float) -> bool:
	return distance <= contact + melee_range
