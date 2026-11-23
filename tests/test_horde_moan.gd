extends GutTest

const EPSILON: float = 0.0001


func _interval(count: int, roll: float, jitter: float = 0.0) -> float:
	return HordeMoan.interval(count, Tuning.HORDE_MOAN_MIN_COUNT, Tuning.HORDE_GROAN_FULL_COUNT,
		Tuning.HORDE_MOAN_INTERVAL_SPARSE, Tuning.HORDE_MOAN_INTERVAL_DENSE, jitter, roll)


func test_inactive_below_min_count() -> void:
	assert_false(HordeMoan.active(Tuning.HORDE_MOAN_MIN_COUNT - 1, Tuning.HORDE_MOAN_MIN_COUNT))
	assert_true(HordeMoan.active(Tuning.HORDE_MOAN_MIN_COUNT, Tuning.HORDE_MOAN_MIN_COUNT))


func test_interval_sparse_at_min_and_dense_at_full() -> void:
	assert_almost_eq(_interval(Tuning.HORDE_MOAN_MIN_COUNT, 0.5), Tuning.HORDE_MOAN_INTERVAL_SPARSE, EPSILON)
	assert_almost_eq(_interval(Tuning.HORDE_GROAN_FULL_COUNT, 0.5), Tuning.HORDE_MOAN_INTERVAL_DENSE, EPSILON)
	assert_almost_eq(_interval(Tuning.HORDE_GROAN_FULL_COUNT * 3, 0.5), Tuning.HORDE_MOAN_INTERVAL_DENSE, EPSILON)


func test_interval_shrinks_as_horde_grows() -> void:
	@warning_ignore("integer_division")
	var mid: int = (Tuning.HORDE_MOAN_MIN_COUNT + Tuning.HORDE_GROAN_FULL_COUNT) / 2
	assert_lt(_interval(mid, 0.5), _interval(Tuning.HORDE_MOAN_MIN_COUNT, 0.5))
	assert_gt(_interval(mid, 0.5), _interval(Tuning.HORDE_GROAN_FULL_COUNT, 0.5))


func test_jitter_range_is_relative_and_positive() -> void:
	var base: float = _interval(Tuning.HORDE_MOAN_MIN_COUNT, 0.5)
	assert_almost_eq(_interval(Tuning.HORDE_MOAN_MIN_COUNT, 0.0, Tuning.HORDE_MOAN_JITTER), base * (1.0 - Tuning.HORDE_MOAN_JITTER), EPSILON)
	assert_almost_eq(_interval(Tuning.HORDE_MOAN_MIN_COUNT, 1.0, Tuning.HORDE_MOAN_JITTER), base * (1.0 + Tuning.HORDE_MOAN_JITTER), EPSILON)
	assert_gt(_interval(Tuning.HORDE_GROAN_FULL_COUNT, 0.0, Tuning.HORDE_MOAN_JITTER), 0.0)