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


func _view() -> Rect2:
	return SpawnRules.ground_view_rect(Tuning.CAMERA_PITCH_DEG, Tuning.CAMERA_DISTANCE, Tuning.CAMERA_FOV, 16.0 / 9.0, Tuning.SPAWN_VIEW_MIN_RAY_DEG)


func test_wave_interval_and_batch_follow_row() -> void:
	var row: Dictionary = WaveData.WAVES[WaveData.WAVES.size() - 1]
	assert_almost_eq(SpawnRules.wave_interval(row, 0.0), row["interval_start"], 0.0001)
	assert_almost_eq(SpawnRules.wave_interval(row, 1.0), row["interval_end"], 0.0001)
	assert_almost_eq(SpawnRules.wave_interval(row, 5.0), row["interval_end"], 0.0001, "oran kırpılır")
	assert_eq(SpawnRules.wave_batch(row, 0.0), row["batch_start"])
	assert_eq(SpawnRules.wave_batch(row, 1.0), row["batch_end"])


func test_pick_kind_respects_weights() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 3
	var mix: Dictionary = {&"a": 0.0, &"b": 1.0}
	for _i in 100:
		assert_eq(SpawnRules.pick_kind(rng, mix), &"b")
	var even: Dictionary = {&"a": 1.0, &"b": 1.0}
	var count_a: int = 0
	for _i in 1000:
		if SpawnRules.pick_kind(rng, even) == &"a":
			count_a += 1
	assert_between(count_a, 400, 600)


func test_view_rect_sees_further_ahead_than_behind() -> void:
	var view: Rect2 = _view()
	assert_true(view.has_point(Vector2.ZERO), "asker görünür alanın içinde")
	assert_gt(-view.position.y, view.end.y, "kameranın baktığı yön daha uzun")
	var wide: Rect2 = SpawnRules.ground_view_rect(Tuning.CAMERA_PITCH_DEG, Tuning.CAMERA_DISTANCE, Tuning.CAMERA_FOV, 21.0 / 9.0, Tuning.SPAWN_VIEW_MIN_RAY_DEG)
	assert_gt(wide.size.x, view.size.x, "geniş ekran daha geniş görür")


func test_rect_exit_distance() -> void:
	var rect: Rect2 = Rect2(-4.0, -10.0, 8.0, 12.0)
	assert_almost_eq(SpawnRules.rect_exit_distance(rect, Vector2.RIGHT), 4.0, 0.0001)
	assert_almost_eq(SpawnRules.rect_exit_distance(rect, Vector2.UP), 10.0, 0.0001)
	assert_almost_eq(SpawnRules.rect_exit_distance(rect, Vector2.DOWN), 2.0, 0.0001)


func test_offscreen_points_are_outside_view_and_inside_arena() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 11
	var view: Rect2 = _view()
	# Ortada ve duvara yakın iki konum.
	for player: Vector2 in [Vector2.ZERO, Vector2(HALF - 3.0, 4.0)]:
		for _i in 200:
			var p: Vector2 = SpawnRules.pick_offscreen_point(rng, HALF, player, view, Tuning.SPAWN_OFFSCREEN_MARGIN, Tuning.SPAWN_TRIES)
			assert_false(view.has_point(p - player), "nokta ekranda: %s" % p)
			assert_lte(absf(p.x), HALF + 0.0001)
			assert_lte(absf(p.y), HALF + 0.0001)
