extends GutTest


func test_final_second_only_in_last_window() -> void:
	assert_eq(HudRules.final_second(0.0), 0)
	assert_eq(HudRules.final_second(-1.0), 0)
	assert_eq(HudRules.final_second(float(HudRules.FINAL_SECONDS) + 0.1), 0)
	assert_eq(HudRules.final_second(float(HudRules.FINAL_SECONDS)), HudRules.FINAL_SECONDS)
	assert_eq(HudRules.final_second(0.2), 1)


func test_clock_seconds_rounds_up_never_negative() -> void:
	assert_eq(HudRules.clock_seconds(12.01), 13)
	assert_eq(HudRules.clock_seconds(12.0), 12)
	assert_eq(HudRules.clock_seconds(-3.0), 0)


func test_pulse_range() -> void:
	for i: int in 20:
		var p: float = HudRules.pulse(float(i) * 0.13, 1.8)
		assert_between(p, 0.0, 1.0)


func test_decay_stops_at_zero() -> void:
	assert_eq(HudRules.decay(0.1, 1.0, 5.0), 0.0)
	assert_almost_eq(HudRules.decay(1.0, 0.1, 5.0), 0.5, 0.0001)


func test_clock_key_changes_with_every_part() -> void:
	var base: int = HudRules.clock_key(2, 5, false, 30, 0, false)
	assert_eq(HudRules.clock_key(2, 5, false, 30, 0, false), base, "aynı değer aynı anahtar")
	for other: int in [
		HudRules.clock_key(3, 5, false, 30, 0, false), HudRules.clock_key(2, 6, false, 30, 0, false),
		HudRules.clock_key(2, 5, true, 30, 0, false), HudRules.clock_key(2, 5, false, 29, 0, false),
		HudRules.clock_key(2, 5, false, 30, 3, false), HudRules.clock_key(2, 5, false, 30, 0, true),
	]:
		assert_ne(other, base)
