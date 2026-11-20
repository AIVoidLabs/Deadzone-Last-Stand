extends GutTest


func test_matching_speed_gives_one() -> void:
	assert_almost_eq(ZombieClipRules.walk_speed_scale(2.6, 2.6, 1.0, 0.3, 1.8), 1.0, 0.0001)


func test_bigger_instance_needs_more_speed() -> void:
	assert_almost_eq(ZombieClipRules.walk_speed_scale(2.6, 2.6, 1.08, 0.3, 1.8), 1.0 / 1.08, 0.0001)


func test_proportional_and_clamped() -> void:
	assert_almost_eq(ZombieClipRules.walk_speed_scale(1.3, 2.6, 1.0, 0.3, 1.8), 0.5, 0.0001)
	assert_eq(ZombieClipRules.walk_speed_scale(0.0, 2.6, 1.0, 0.3, 1.8), 0.3)
	assert_eq(ZombieClipRules.walk_speed_scale(20.0, 2.6, 1.0, 0.3, 1.8), 1.8)


func test_zero_ref_does_not_crash() -> void:
	assert_eq(ZombieClipRules.walk_speed_scale(2.0, 0.0, 1.0, 0.3, 1.8), 1.8)
