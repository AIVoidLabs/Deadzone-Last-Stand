class_name SpawnRules
extends RefCounted
## Zombi doğma zamanlaması ve yeri. Aşama 2'de dalga tablosuna bağlanacak.


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
