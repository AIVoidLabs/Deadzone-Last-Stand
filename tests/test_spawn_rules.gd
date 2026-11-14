extends GutTest

const HALF: float = Tuning.ARENA_SIZE * 0.5 - Tuning.SPAWN_EDGE_INSET


func test_interval_starts_at_start_value() -> void:
	assert_almost_eq(SpawnRules.interval_at(0.0), Tuning.SPAWN_INTERVAL_START, 0.0001)


func test_interval_shrinks_and_clamps() -> void:
	assert_lt(SpawnRules.interval_at(20.0), SpawnRules.interval_at(0.0))
	assert_almost_eq(SpawnRules.interval_at(100000.0), Tuning.SPAWN_INTERVAL_MIN, 0.0001)


func test_batch_grows_over_time() -> void:
	assert_eq(SpawnRules.batch_at(0.0), Tuning.SPAWN_BATCH_START)
	assert_eq(SpawnRules.batch_at(Tuning.SPAWN_BATCH_GROWTH_SEC * 2.0 + 0.1), Tuning.SPAWN_BATCH_START + 2)


func test_edge_points_are_on_edge_and_far_from_player() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var player: Vector2 = Vector2(5.0, -3.0)
	for _i in 200:
		var p: Vector2 = SpawnRules.pick_edge_point(rng, HALF, player, Tuning.SPAWN_MIN_PLAYER_DIST, Tuning.SPAWN_TRIES)
		var on_edge: bool = is_equal_approx(absf(p.x), HALF) or is_equal_approx(absf(p.y), HALF)
		assert_true(on_edge, "nokta kenarda olmalı: %s" % p)
		assert_lte(absf(p.x), HALF + 0.0001)
		assert_lte(absf(p.y), HALF + 0.0001)
		assert_gte(p.distance_to(player), Tuning.SPAWN_MIN_PLAYER_DIST - 0.0001)


func test_fallback_is_opposite_corner() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	# Ulaşılamaz mesafe → hep geri dönüş köşesi.
	var p: Vector2 = SpawnRules.pick_edge_point(rng, HALF, Vector2(10.0, 10.0), 9999.0, 3)
	assert_eq(p, Vector2(-HALF, -HALF))


func test_quality_profiles_share_keys_and_grow() -> void:
	var keys: Array = QualityProfiles.get_profile(QualityProfiles.LOW).keys()
	keys.sort()
	var previous: int = 0
	for id in QualityProfiles.ORDER:
		var profile: Dictionary = QualityProfiles.get_profile(id)
		var k: Array = profile.keys()
		k.sort()
		assert_eq(k, keys, "profil anahtarları aynı olmalı: %s" % id)
		var cap: int = profile["max_enemies"]
		assert_gt(cap, previous)
		previous = cap


func test_quality_cycle_wraps() -> void:
	assert_eq(QualityProfiles.next_after(QualityProfiles.HIGH), QualityProfiles.LOW)
	assert_eq(QualityProfiles.next_after(QualityProfiles.LOW), QualityProfiles.MEDIUM)
