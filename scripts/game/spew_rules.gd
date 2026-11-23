class_name SpewRules
extends RefCounted
## Boss kusmuk yağmuru kuralları (saf; sayılar EnemyDataBoss satırından gelir, rastgelelik rng parametresiyle):
## seçilebilir mesafe aralığı, uzaktan tehdit ağırlığı, top sayısı, iniş noktaları (yelpaze + mesafe payı), uçuş süresi
## ve kaçış boşluğu garantisi (askerin kaçabileceği en az bir yön açık kalır).

## Satır anahtarı: top boss kusmuğuna ait (LobAttack sayaçları ayırır, boss ölünce uçanlar iptal edilir; tükürücüde yok).
const BOSS_BALL_KEY: String = "boss_ball"
const _GAP_SAMPLES: int = 16
## Her top kendi yelpaze diliminde rastgele açıyla düşer; dilimin kenarlarından bu kadar (dilim oranı) içeride kalır
## (komşu toplar üst üste binmesin): açı payı = _SLICE_EDGE + _SLICE_SPAN * rastgele.
const _SLICE_EDGE: float = 0.15
const _SLICE_SPAN: float = 0.7


## Asker spew_min..spew_max arasında mı (saldırı yalnız burada seçilebilir).
static func in_band(dist: float, row: Dictionary) -> bool:
	return dist >= float(row["spew_min"]) and dist <= float(row["spew_max"])


## Seçim ağırlığı: asker spew_far_dist'ten uzaktaysa spew_far_mult katı.
static func weight(dist: float, base: float, row: Dictionary) -> float:
	return base * float(row["spew_far_mult"]) if dist > float(row["spew_far_dist"]) else base


## Atış başına top sayısı: öfkede spew_count_rage.
static func count(raged: bool, row: Dictionary) -> int:
	return int(row["spew_count_rage"]) if raged else int(row["spew_count"])


## Top uçuş süresi: mesafe / hız, [min, max] arasına kırpılır (uzak atış daha uzun uçar).
static func flight(dist: float, row: Dictionary) -> float:
	return clampf(dist / maxf(float(row["spew_ball_speed"]), 0.001), float(row["spew_flight_min"]), float(row["spew_flight_max"]))


## Yay tepe yüksekliği uçuş süresiyle orantılı.
static func arc(flight_time: float, row: Dictionary) -> float:
	return flight_time * float(row["spew_arc_per_sec"])


## LobAttack'ın asit topu satırı: havuz değerleri + doğrudan isabet hasarı (spew_hit_damage) ve yarıçapı.
static func acid_row(row: Dictionary) -> Dictionary:
	return {
		"attack_kind": &"spit", "acid_radius": row["spew_pool_radius"], "acid_time": row["spew_pool_life"],
		"acid_tick": row["spew_acid_tick"], "acid_damage": row["spew_acid_damage"], "spew_hit_damage": row["spew_damage"],
		BOSS_BALL_KEY: true,
	}


## from'dan target yönünde spread_deg'lik yelpazeye count top: her top kendi diliminde rastgele açıyla, askere uzaklığın
## [lo, hi] katı mesafeye (askerin etrafına yağar). Noktalar arenaya (±half) kırpılır.
static func landing_points(from: Vector2, target: Vector2, n: int, spread_deg: float, lo: float, hi: float, half: float, rng: RandomNumberGenerator) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var offset: Vector2 = target - from
	var dist: float = offset.length()
	var base: float = offset.angle() if dist > 0.0001 else 0.0
	var spread: float = deg_to_rad(spread_deg)
	for k in n:
		var t: float = (float(k) + _SLICE_EDGE + _SLICE_SPAN * rng.randf()) / float(maxi(n, 1))
		var angle: float = base + lerpf(-spread * 0.5, spread * 0.5, t)
		var reach: float = dist * rng.randf_range(lo, hi)
		out.append((from + Vector2.from_angle(angle) * reach).clamp(Vector2(-half, -half), Vector2(half, half)))
	return out


## Toplar bina/engele çarparsa engelin kenarına iner (LobAttack'taki atışla aynı kırpma): iniş noktaları kırpılmış hâlde döner.
## Boşluk hesabı bu noktalarla yapılmalı (havuz gerçekte kırpılmış yere düşer).
static func clip_points(from: Vector2, points: Array[Vector2], radius: float, margin: float, blocks: Array[Rect2]) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for p: Vector2 in points:
		var shot: Vector3 = CityLayout.clip_shot(from, p, radius, margin, blocks)
		out.append(Vector2(shot.x, shot.y))
	return out


## Askerin (target) çıkabileceği en az bir yön açık mı. Yön açık sayılır: soldan escape_len ilerleyince arenada (±half, asker
## yarıçapı payıyla) ve engele (blocks) çarpmadan kalır, havuza (pool_radius + player_radius) girmez.
## Havuz sınıfları: askerin gövdesi tamamen içinde (merkez uzaklığı <= pool_radius - player_radius) olan havuz dışlanır
## (asker zaten vurulur; her yön onu terk etmektir); gövdesine değen (merkez uzaklığı <= pool_radius + player_radius) havuz için
## yalnız yolun SONU havuzun dışında olmalı (içinden çıkılır ama içine/içinden geri girilmez); uzaktaki havuz yolu hiç kesmemeli.
static func has_gap(points: Array[Vector2], target: Vector2, pool_radius: float, player_radius: float, escape_len: float, half: float, blocks: Array[Rect2]) -> bool:
	for s in _GAP_SAMPLES:
		var dir: Vector2 = Vector2.from_angle(TAU * float(s) / float(_GAP_SAMPLES))
		if direction_open(points, target, dir, pool_radius, player_radius, escape_len, half, blocks):
			return true
	return false


## Tek yön için has_gap'in testi (bkz. has_gap).
static func direction_open(points: Array[Vector2], target: Vector2, dir: Vector2, pool_radius: float, player_radius: float, escape_len: float, half: float, blocks: Array[Rect2]) -> bool:
	var end: Vector2 = target + dir * escape_len
	var lim: float = half - player_radius
	if absf(end.x) > lim or absf(end.y) > lim:
		return false
	if CityLayout.first_hit(target, end, player_radius, blocks).x >= 0.0:
		return false
	var reach: float = pool_radius + player_radius
	for p: Vector2 in points:
		var start_dist: float = p.distance_to(target)
		if start_dist <= pool_radius - player_radius:
			continue
		if end.distance_to(p) <= reach:
			return false
		if start_dist > reach and Geometry2D.get_closest_point_to_segment(p, target, end).distance_to(p) <= reach:
			return false
	return true


## Kaçış yönü kalmadıysa askere en yakın topu çıkarır; yön açılana dek tekrarlar. Girdi değişmez.
## points kırpılmış (clip_points) iniş noktaları olmalı.
static func ensure_gap(points: Array[Vector2], target: Vector2, pool_radius: float, player_radius: float, escape_len: float, half: float, blocks: Array[Rect2]) -> Array[Vector2]:
	var out: Array[Vector2] = points.duplicate()
	while not out.is_empty() and not has_gap(out, target, pool_radius, player_radius, escape_len, half, blocks):
		var worst: int = 0
		for k in out.size():
			if out[k].distance_to(target) < out[worst].distance_to(target):
				worst = k
		out.remove_at(worst)
	return out
