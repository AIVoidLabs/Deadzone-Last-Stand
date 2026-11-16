extends GutTest

const STEP: float = 1.0 / 60.0


func _new_dash() -> Dash:
	return Dash.new(Tuning.DASH_DURATION, Tuning.DASH_COOLDOWN)


func test_starts_ready() -> void:
	var dash: Dash = _new_dash()
	assert_true(dash.can_start())
	assert_almost_eq(dash.readiness(), 1.0, 0.0001)


func test_start_activates_and_blocks_restart() -> void:
	var dash: Dash = _new_dash()
	assert_true(dash.start())
	assert_true(dash.is_active())
	assert_false(dash.start())
	assert_almost_eq(dash.readiness(), 0.0, 0.0001)


func test_ends_after_duration_and_reports_once() -> void:
	var dash: Dash = _new_dash()
	dash.start()
	var end_reports: int = 0
	var elapsed: float = 0.0
	while elapsed < Tuning.DASH_DURATION + 0.5:
		if dash.tick(STEP):
			end_reports += 1
			assert_almost_eq(elapsed + STEP, Tuning.DASH_DURATION, STEP)
		elapsed += STEP
	assert_eq(end_reports, 1)
	assert_false(dash.is_active())


func test_cooldown_blocks_until_elapsed() -> void:
	var dash: Dash = _new_dash()
	dash.start()
	dash.tick(Tuning.DASH_COOLDOWN - 0.01)
	assert_false(dash.can_start())
	dash.tick(0.02)
	assert_true(dash.can_start())
	assert_true(dash.start())


func test_readiness_grows_with_time() -> void:
	var dash: Dash = _new_dash()
	dash.start()
	dash.tick(Tuning.DASH_COOLDOWN * 0.5)
	assert_almost_eq(dash.readiness(), 0.5, 0.0001)
