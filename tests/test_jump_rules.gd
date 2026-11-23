extends GutTest


func test_landing_leads_a_moving_target() -> void:
	var p: Vector2 = JumpRules.landing_point(Vector2.ZERO, Vector2(5, 0), Vector2(0, 6), 1.0, 1.0, 20.0, 100.0)
	assert_almost_eq(p.x, 5.0, 0.001)
	assert_almost_eq(p.y, 6.0, 0.001)


func test_stationary_target_is_landed_on() -> void:
	var p: Vector2 = JumpRules.landing_point(Vector2.ZERO, Vector2(4, 3), Vector2.ZERO, 1.3, 0.9, 20.0, 100.0)
	assert_eq(p, Vector2(4, 3))


func test_landing_is_limited_by_range_and_arena() -> void:
	var far: Vector2 = JumpRules.landing_point(Vector2.ZERO, Vector2(30, 0), Vector2.ZERO, 1.0, 1.0, 9.0, 100.0)
	assert_almost_eq(far.length(), 9.0, 0.001)
	var edge: Vector2 = JumpRules.landing_point(Vector2.ZERO, Vector2(50, 0), Vector2(10, 0), 2.0, 1.0, 100.0, 40.0)
	assert_almost_eq(edge.x, 40.0, 0.001)


func test_height_is_parabolic() -> void:
	assert_almost_eq(JumpRules.height_at(0.0, 3.5), 0.0, 0.0001)
	assert_almost_eq(JumpRules.height_at(0.5, 3.5), 3.5, 0.0001)
	assert_almost_eq(JumpRules.height_at(1.0, 3.5), 0.0, 0.0001)
	assert_almost_eq(JumpRules.height_at(1.5, 3.5), 0.0, 0.0001)


func test_landing_hits_only_inside_radius() -> void:
	assert_true(JumpRules.lands_on(Vector2(1.0, 0), Vector2.ZERO, 1.5, 0.4))
	assert_true(JumpRules.lands_on(Vector2(1.9, 0), Vector2.ZERO, 1.5, 0.4))
	assert_false(JumpRules.lands_on(Vector2(2.0, 0), Vector2.ZERO, 1.5, 0.4))


func test_extra_hops_stay_within_chain_bounds() -> void:
	var lo: int = Tuning.JUMPER_CHAIN_MIN - 1
	var hi: int = Tuning.JUMPER_CHAIN_MAX - 1
	for roll in [0.0, 0.3, 0.5, 0.7, 0.9999, 1.0]:
		var extra: int = JumpRules.extra_hops(roll, Tuning.JUMPER_CHAIN_MIN, Tuning.JUMPER_CHAIN_MAX)
		assert_between(extra, lo, hi)
	assert_eq(JumpRules.extra_hops(0.0, Tuning.JUMPER_CHAIN_MIN, Tuning.JUMPER_CHAIN_MAX), lo)
	assert_eq(JumpRules.extra_hops(1.0, Tuning.JUMPER_CHAIN_MIN, Tuning.JUMPER_CHAIN_MAX), hi)
	assert_eq(JumpRules.extra_hops(0.5, 1, 1), 0, "tek zıplama")


func test_chain_pause_is_short_and_shows_marker_before_next_jump() -> void:
	var jumper: Dictionary = EnemyData.get_row(EnemyData.JUMPER)
	var pause: float = float(jumper["chain_pause"])
	assert_between(pause, 0.3, 0.5)
	assert_lt(pause, float(jumper["attack_windup"]))
