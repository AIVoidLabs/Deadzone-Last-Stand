extends GutTest
## Düşük can kalp atışı kuralı: eşik, ilk atış, aralık, iyileşme ve ölümde sıfırlanma.

const T: float = Tuning.LOW_HEALTH_THRESHOLD
const I: float = Tuning.LOW_HEALTH_BEAT_INTERVAL


func test_is_low_bounds() -> void:
	assert_true(LowHealthRule.is_low(T, T))
	assert_false(LowHealthRule.is_low(T + 0.01, T))
	assert_false(LowHealthRule.is_low(0.0, T), "ölü: atış yok")


func test_healthy_never_beats() -> void:
	var rule: LowHealthRule = LowHealthRule.new()
	for i: int in 100:
		assert_false(rule.tick(0.1, 1.0, T, I))


func test_first_beat_immediate_then_interval() -> void:
	var rule: LowHealthRule = LowHealthRule.new()
	assert_true(rule.tick(0.016, T * 0.5, T, I))
	assert_false(rule.tick(I * 0.5, T * 0.5, T, I))
	assert_true(rule.tick(I * 0.6, T * 0.5, T, I))
	assert_false(rule.tick(0.016, T * 0.5, T, I))


func test_heal_and_death_reset() -> void:
	var rule: LowHealthRule = LowHealthRule.new()
	rule.tick(0.016, T * 0.5, T, I)
	assert_false(rule.tick(0.016, 1.0, T, I), "iyileşti")
	assert_true(rule.tick(0.016, T * 0.5, T, I), "tekrar düşünce hemen atar")
	assert_false(rule.tick(0.016, 0.0, T, I), "öldü")