extends GutTest
## AmbienceScheduler: aralık sınırları, ağırlıklı seçim, tekrar yasağı, yön, tohumla tekrarlanabilirlik.


func _make(seed_value: int = 5) -> AmbienceScheduler:
	return AmbienceScheduler.new(AmbienceData.distant_weights(), Tuning.AMBIENCE_DISTANT_INTERVAL_MIN, Tuning.AMBIENCE_DISTANT_INTERVAL_MAX, seed_value)


## Sonraki olay gelene dek ilerler; (geçen süre, indeks) döndürür.
func _run_to_event(s: AmbienceScheduler) -> Array:
	var t: float = 0.0
	var dt: float = 0.1
	while t < Tuning.AMBIENCE_DISTANT_INTERVAL_MAX + 5.0:
		t += dt
		var idx: int = s.step(dt)
		if idx >= 0:
			return [t, idx]
	return [t, -1]


func test_first_interval_within_bounds() -> void:
	var s: AmbienceScheduler = _make()
	assert_between(s.time_left(), Tuning.AMBIENCE_DISTANT_INTERVAL_MIN, Tuning.AMBIENCE_DISTANT_INTERVAL_MAX)


func test_no_event_before_min_interval() -> void:
	var s: AmbienceScheduler = _make()
	assert_eq(s.step(Tuning.AMBIENCE_DISTANT_INTERVAL_MIN - 0.5), -1)


func test_event_fires_within_max_interval() -> void:
	for seed_value: int in 20:
		var r: Array = _run_to_event(_make(seed_value))
		assert_ne(r[1], -1, "olay gelmeli")
		assert_between(float(r[0]), Tuning.AMBIENCE_DISTANT_INTERVAL_MIN - 0.01, Tuning.AMBIENCE_DISTANT_INTERVAL_MAX + 0.11)


func test_index_in_range_and_no_immediate_repeat() -> void:
	var s: AmbienceScheduler = _make(11)
	var prev: int = -1
	for i: int in 200:
		var idx: int = s.step(Tuning.AMBIENCE_DISTANT_INTERVAL_MAX)
		assert_between(idx, 0, AmbienceData.DISTANT.size() - 1)
		assert_ne(idx, prev, "art arda aynı ses yok")
		prev = idx


func test_every_row_eventually_picked() -> void:
	var s: AmbienceScheduler = _make(3)
	var seen: Dictionary = {}
	for i: int in 200:
		seen[s.step(Tuning.AMBIENCE_DISTANT_INTERVAL_MAX)] = true
	assert_eq(seen.size(), AmbienceData.DISTANT.size())


func test_zero_weight_never_picked() -> void:
	var s: AmbienceScheduler = AmbienceScheduler.new([1.0, 0.0, 1.0] as Array[float], 1.0, 2.0, 9)
	for i: int in 100:
		assert_ne(s.step(10.0), 1)


func test_single_row_repeats() -> void:
	var s: AmbienceScheduler = AmbienceScheduler.new([1.0] as Array[float], 1.0, 2.0, 9)
	assert_eq(s.step(10.0), 0)
	assert_eq(s.step(10.0), 0)


func test_empty_weights_never_fire() -> void:
	var s: AmbienceScheduler = AmbienceScheduler.new([] as Array[float], 1.0, 2.0, 9)
	assert_eq(s.step(100.0), -1)


func test_angle_in_circle() -> void:
	var s: AmbienceScheduler = _make(2)
	for i: int in 50:
		s.step(Tuning.AMBIENCE_DISTANT_INTERVAL_MAX)
		assert_between(s.last_angle, 0.0, TAU)


func test_same_seed_same_sequence() -> void:
	var a: AmbienceScheduler = _make(77)
	var b: AmbienceScheduler = _make(77)
	for i: int in 30:
		assert_eq(a.step(Tuning.AMBIENCE_DISTANT_INTERVAL_MAX), b.step(Tuning.AMBIENCE_DISTANT_INTERVAL_MAX))
		assert_eq(a.last_angle, b.last_angle)


func test_min_greater_than_max_is_clamped() -> void:
	var s: AmbienceScheduler = AmbienceScheduler.new([1.0] as Array[float], 5.0, 2.0, 1)
	assert_eq(s.interval_max, 5.0)
