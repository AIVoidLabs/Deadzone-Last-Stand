extends GutTest


func test_doubles_remaining_health() -> void:
	var f: float = Tuning.WAVE_END_HEAL_FACTOR
	assert_almost_eq(WaveHealRules.bonus(25.0, 100.0, f), 25.0 * f - 25.0, 0.0001)


func test_capped_at_maximum() -> void:
	assert_almost_eq(WaveHealRules.bonus(80.0, 100.0, Tuning.WAVE_END_HEAL_FACTOR), 20.0, 0.0001)
	assert_almost_eq(WaveHealRules.bonus(100.0, 100.0, Tuning.WAVE_END_HEAL_FACTOR), 0.0, 0.0001)


func test_dead_gets_nothing() -> void:
	assert_eq(WaveHealRules.bonus(0.0, 100.0, Tuning.WAVE_END_HEAL_FACTOR), 0.0)
