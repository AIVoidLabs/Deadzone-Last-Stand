class_name SpawnRules
extends RefCounted
## Zombi doğma zamanlaması ve yeri: sonsuz artış (dalgalar kapalıyken) ya da dalga satırından.


## Geçen süreye göre iki doğma arasındaki süre.
static func interval_at(elapsed: float) -> float:
	if not Tuning.FEATURE_SPAWN_RAMP:
		return Tuning.SPAWN_INTERVAL_START
	return maxf(Tuning.SPAWN_INTERVAL_MIN, Tuning.SPAWN_INTERVAL_START - elapsed * Tuning.SPAWN_INTERVAL_RAMP)


## Geçen süreye göre bir seferde doğan zombi sayısı.
static func batch_at(elapsed: float) -> int:
	if not Tuning.FEATURE_SPAWN_RAMP:
		return Tuning.SPAWN_BATCH_START
	return Tuning.SPAWN_BATCH_START + floori(elapsed / Tuning.SPAWN_BATCH_GROWTH_SEC)


## Arena kenarında, askerden en az min_dist uzakta bir nokta.
## Denemeler tutmazsa askerin karşı köşesi seçilir.
static func pick_edge_point(rng: RandomNumberGenerator, half_extent: float, player: Vector2, min_dist: float, tries: int) -> Vector2:
	for _i in tries:
		var along: float = rng.randf_range(-half_extent, half_extent)
		var p: Vector2
		match rng.randi_range(0, 3):
			0: p = Vector2(along, -half_extent)
			1: p = Vector2(along, half_extent)
			2: p = Vector2(-half_extent, along)
			_: p = Vector2(half_extent, along)
		if p.distance_to(player) >= min_dist:
			return p
	var sx: float = -1.0 if player.x >= 0.0 else 1.0
	var sy: float = -1.0 if player.y >= 0.0 else 1.0
	return Vector2(sx * half_extent, sy * half_extent)


## Dalga satırına göre iki doğma arasındaki süre; t: dalganın geçen oranı (0..1).
static func wave_interval(row: Dictionary, t: float) -> float:
	return lerpf(row["interval_start"], row["interval_end"], clampf(t, 0.0, 1.0))


## Dalga satırına göre bir seferde doğan zombi sayısı.
static func wave_batch(row: Dictionary, t: float) -> int:
	return roundi(lerpf(row["batch_start"], row["batch_end"], clampf(t, 0.0, 1.0)))


## Ağırlıklı tür seçimi. mix: tür → ağırlık.
static func pick_kind(rng: RandomNumberGenerator, mix: Dictionary) -> StringName:
	var total: float = 0.0
	for kind: StringName in mix:
		total += maxf(0.0, mix[kind])
	var roll: float = rng.randf() * total
	var chosen: StringName = &""
	for kind: StringName in mix:
		var weight: float = maxf(0.0, mix[kind])
		if weight <= 0.0:
			continue
		chosen = kind
		roll -= weight
		if roll < 0.0:
			break
	assert(chosen != &"", "Dalga türü karışımı boş")
	return chosen


## pick_kind ama sınırdaki türler (caps: tür → en çok canlı, alive: tür → şu anki canlı) seçimden çıkarılır.
## Karışımda sınırsız tür (yürüyen) her zaman kalır.
static func pick_kind_capped(rng: RandomNumberGenerator, mix: Dictionary, caps: Dictionary, alive: Dictionary) -> StringName:
	var allowed: Dictionary = mix
	for kind: StringName in caps:
		if allowed.has(kind) and int(alive.get(kind, 0)) >= int(caps[kind]):
			if allowed == mix:
				allowed = mix.duplicate()
			allowed.erase(kind)
	return pick_kind(rng, allowed)


## Sabit açılı kameranın yerde gördüğü alanı, kameranın baktığı noktaya göre çevreleyen dikdörtgen.
## Kamera +Y (dünya +Z) tarafında durur: position.y uzak kenar (negatif), end.y yakın kenar.
static func ground_view_rect(pitch_deg: float, distance: float, fov_deg: float, aspect: float, min_ray_deg: float) -> Rect2:
	var pitch: float = deg_to_rad(pitch_deg)
	var half_v: float = deg_to_rad(fov_deg) * 0.5
	var height: float = distance * sin(pitch)
	var back: float = distance * cos(pitch)
	var far_ray: float = maxf(pitch - half_v, deg_to_rad(min_ray_deg))
	var far: float = height / tan(far_ray) - back
	var near: float = back - height / tan(pitch + half_v)
	# Uzak kenardaki noktanın kamera derinliği; yatay yarı genişlik orada en büyük.
	var depth: float = height / sin(far_ray) * cos(half_v)
	var half_w: float = depth * tan(half_v) * aspect
	return Rect2(-half_w, -far, half_w * 2.0, far + near)


## Askerin çevresinde, görünür dikdörtgenin hemen dışında (margin kadar) bir nokta; arena içinde.
## Duvar yüzünden ekran içine düşerse yeniden dener; tutmazsa kenar noktasına döner.
static func pick_offscreen_point(rng: RandomNumberGenerator, half_extent: float, player: Vector2, view: Rect2, margin: float, tries: int) -> Vector2:
	var lim: Vector2 = Vector2(half_extent, half_extent)
	for _i in tries:
		var dir: Vector2 = Vector2.from_angle(rng.randf() * TAU)
		var p: Vector2 = (player + dir * (rect_exit_distance(view, dir) + margin)).clamp(-lim, lim)
		if not view.has_point(p - player):
			return p
	return pick_edge_point(rng, half_extent, player, view.size.length() * 0.5, tries)


## İçindeki orijinden dir yönünde gidilince dikdörtgenden çıkılan uzaklık.
static func rect_exit_distance(rect: Rect2, dir: Vector2) -> float:
	var best: float = INF
	if dir.x > 0.0:
		best = minf(best, rect.end.x / dir.x)
	elif dir.x < 0.0:
		best = minf(best, rect.position.x / dir.x)
	if dir.y > 0.0:
		best = minf(best, rect.end.y / dir.y)
	elif dir.y < 0.0:
		best = minf(best, rect.position.y / dir.y)
	return best
