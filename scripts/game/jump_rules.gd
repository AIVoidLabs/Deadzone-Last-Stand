class_name JumpRules
extends RefCounted
## Zıplayan zombinin kuralları (saf): iniş noktası, yay yüksekliği, iniş isabeti.
## İniş noktası rastgele değil: askerin o ana kadar gideceği yere önden nişan alınır, hazırlığın
## sonunda kilitlenir; asker halkadan çıkarak ya da dash'in dokunulmazlığıyla kurtulur.


## from'dan atlayan zombinin target'ı (hızı target_vel) time_ahead sn sonra bulacağı yer.
## max_range zıplama menzilini, half arena yarı boyunu sınırlar.
static func landing_point(from: Vector2, target: Vector2, target_vel: Vector2, time_ahead: float, lead: float, max_range: float, half: float) -> Vector2:
	var aim: Vector2 = target + target_vel * time_ahead * lead
	var offset: Vector2 = aim - from
	if offset.length() > max_range:
		aim = from + offset.normalized() * max_range
	return aim.clamp(Vector2(-half, -half), Vector2(half, half))


## Havadaki yükseklik: progress 0..1, tepe noktası peak (parabol).
static func height_at(progress: float, peak: float) -> float:
	var t: float = clampf(progress, 0.0, 1.0)
	return 4.0 * peak * t * (1.0 - t)


## Seri zıplamada ilk zıplamadan sonraki ek zıplama sayısı: toplam min_total..max_total'dan roll (0..1) ile seçilir.
static func extra_hops(roll: float, min_total: int, max_total: int) -> int:
	var lo: int = maxi(min_total, 1)
	var hi: int = maxi(max_total, lo)
	var total: int = lo + mini(int(clampf(roll, 0.0, 0.9999) * float(hi - lo + 1)), hi - lo)
	return total - 1


## İniş şoku askeri kapsıyor mu.
static func lands_on(player_pos: Vector2, land_point: Vector2, radius: float, player_radius: float) -> bool:
	return player_pos.distance_to(land_point) <= radius + player_radius
