extends GutTest
## MeleeRules: savurma yayı ve yanma sayacı.

const ORIGIN: Vector2 = Vector2.ZERO
const FORWARD: Vector2 = Vector2(0.0, 1.0)


func test_target_in_front_is_hit() -> void:
	assert_true(MeleeRules.in_arc(ORIGIN, FORWARD, Vector2(0.0, 2.0), 0.4, 3.0, deg_to_rad(90.0)))


func test_target_beyond_reach_is_missed() -> void:
	assert_false(MeleeRules.in_arc(ORIGIN, FORWARD, Vector2(0.0, 4.0), 0.4, 3.0, deg_to_rad(90.0)))


func test_body_radius_extends_reach() -> void:
	assert_true(MeleeRules.in_arc(ORIGIN, FORWARD, Vector2(0.0, 3.3), 0.4, 3.0, deg_to_rad(90.0)))


func test_target_behind_is_missed_by_narrow_arc() -> void:
	assert_false(MeleeRules.in_arc(ORIGIN, FORWARD, Vector2(0.0, -2.0), 0.4, 3.0, deg_to_rad(120.0)))


func test_target_outside_angle_is_missed() -> void:
	assert_false(MeleeRules.in_arc(ORIGIN, FORWARD, Vector2(2.0, 0.2), 0.3, 3.0, deg_to_rad(90.0)))


func test_wide_arc_reaches_sideways() -> void:
	assert_true(MeleeRules.in_arc(ORIGIN, FORWARD, Vector2(2.0, 0.2), 0.3, 3.0, deg_to_rad(200.0)))


func test_overlapping_target_is_always_hit() -> void:
	assert_true(MeleeRules.in_arc(ORIGIN, FORWARD, Vector2(0.0, -0.2), 0.4, 3.0, deg_to_rad(10.0)))


func test_burn_ticks_accumulate() -> void:
	var step: Dictionary = MeleeRules.burn_step(3.0, 0.0, 0.3, 0.5)
	assert_eq(step["ticks"], 0)
	step = MeleeRules.burn_step(step["left"], step["acc"], 0.3, 0.5)
	assert_eq(step["ticks"], 1)
	assert_almost_eq(float(step["left"]), 2.4, 0.0001)


func test_burn_stops_when_time_runs_out() -> void:
	var step: Dictionary = MeleeRules.burn_step(0.2, 0.0, 1.0, 0.5)
	assert_eq(step["ticks"], 0)
	assert_eq(step["left"], 0.0)
	step = MeleeRules.burn_step(0.0, step["acc"], 1.0, 0.5)
	assert_eq(step["ticks"], 0)
