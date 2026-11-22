extends GutTest


func test_full_volume_inside_full_radius() -> void:
	assert_eq(SoundDistance.offset_db(Tuning.SFX_DISTANCE_FULL * 0.5, Tuning.SFX_DISTANCE_FULL, Tuning.SFX_DISTANCE_MAX, Tuning.SFX_DISTANCE_MIN_DB), 0.0)
	assert_eq(SoundDistance.offset_db(Tuning.SFX_DISTANCE_FULL, Tuning.SFX_DISTANCE_FULL, Tuning.SFX_DISTANCE_MAX, Tuning.SFX_DISTANCE_MIN_DB), 0.0)


func test_min_db_at_max_radius() -> void:
	assert_eq(SoundDistance.offset_db(Tuning.SFX_DISTANCE_MAX, Tuning.SFX_DISTANCE_FULL, Tuning.SFX_DISTANCE_MAX, Tuning.SFX_DISTANCE_MIN_DB), Tuning.SFX_DISTANCE_MIN_DB)


func test_linear_in_between() -> void:
	var mid: float = (Tuning.SFX_DISTANCE_FULL + Tuning.SFX_DISTANCE_MAX) * 0.5
	var db: float = SoundDistance.offset_db(mid, Tuning.SFX_DISTANCE_FULL, Tuning.SFX_DISTANCE_MAX, Tuning.SFX_DISTANCE_MIN_DB)
	assert_almost_eq(db, Tuning.SFX_DISTANCE_MIN_DB * 0.5, 0.0001)


func test_monotonic_falloff() -> void:
	var near: float = SoundDistance.offset_db(12.0, Tuning.SFX_DISTANCE_FULL, Tuning.SFX_DISTANCE_MAX, Tuning.SFX_DISTANCE_MIN_DB)
	var far: float = SoundDistance.offset_db(25.0, Tuning.SFX_DISTANCE_FULL, Tuning.SFX_DISTANCE_MAX, Tuning.SFX_DISTANCE_MIN_DB)
	assert_true(far < near)
	assert_true(near < 0.0)


func test_audible_cutoff() -> void:
	assert_true(SoundDistance.audible(Tuning.SFX_DISTANCE_MAX - 0.1, Tuning.SFX_DISTANCE_MAX))
	assert_false(SoundDistance.audible(Tuning.SFX_DISTANCE_MAX, Tuning.SFX_DISTANCE_MAX))
	assert_false(SoundDistance.audible(Tuning.SFX_DISTANCE_MAX + 5.0, Tuning.SFX_DISTANCE_MAX))


func test_flat_distance_ignores_height() -> void:
	assert_almost_eq(SoundDistance.flat_distance(Vector3(3.0, 9.0, 0.0), Vector3(0.0, 0.0, 4.0)), 5.0, 0.0001)
