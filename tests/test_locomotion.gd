extends GutTest

const STEP: float = 1.0 / 60.0


func _run(velocity: Vector2, input: Vector2, seconds: float) -> Vector2:
	var steps: int = roundi(seconds / STEP)
	for _i in steps:
		velocity = Locomotion.step(velocity, input, Tuning.PLAYER_SPEED, Tuning.PLAYER_ACCEL, Tuning.PLAYER_FRICTION, STEP)
	return velocity


func test_reaches_max_speed_and_stays() -> void:
	var time_to_max: float = Tuning.PLAYER_SPEED / Tuning.PLAYER_ACCEL
	var velocity: Vector2 = _run(Vector2.ZERO, Vector2.RIGHT, time_to_max * 3.0)
	assert_almost_eq(velocity.length(), Tuning.PLAYER_SPEED, 0.001)
	assert_almost_eq(velocity.y, 0.0, 0.001)


func test_stops_by_friction() -> void:
	var time_to_stop: float = Tuning.PLAYER_SPEED / Tuning.PLAYER_FRICTION
	var velocity: Vector2 = _run(Vector2.RIGHT * Tuning.PLAYER_SPEED, Vector2.ZERO, time_to_stop * 1.5)
	assert_eq(velocity, Vector2.ZERO)


func test_diagonal_input_is_not_faster() -> void:
	var velocity: Vector2 = _run(Vector2.ZERO, Vector2(1.0, 1.0), 2.0)
	assert_almost_eq(velocity.length(), Tuning.PLAYER_SPEED, 0.001)


func test_one_step_accelerates_by_accel() -> void:
	var velocity: Vector2 = Locomotion.step(Vector2.ZERO, Vector2.UP, Tuning.PLAYER_SPEED, Tuning.PLAYER_ACCEL, Tuning.PLAYER_FRICTION, STEP)
	assert_almost_eq(velocity.length(), minf(Tuning.PLAYER_ACCEL * STEP, Tuning.PLAYER_SPEED), 0.0001)


func test_forward_lean_scales_with_speed() -> void:
	var max_angle: float = deg_to_rad(Tuning.PLAYER_LEAN_FORWARD_DEG)
	assert_eq(Locomotion.forward_lean(0.0, Tuning.PLAYER_SPEED, max_angle), 0.0)
	assert_almost_eq(Locomotion.forward_lean(Tuning.PLAYER_SPEED * 0.5, Tuning.PLAYER_SPEED, max_angle), max_angle * 0.5, 0.0001)
	assert_almost_eq(Locomotion.forward_lean(Tuning.PLAYER_SPEED * 3.0, Tuning.PLAYER_SPEED, max_angle), max_angle, 0.0001)


func test_turn_lean_is_clamped_and_signed() -> void:
	var max_angle: float = deg_to_rad(Tuning.PLAYER_LEAN_TURN_DEG)
	assert_almost_eq(Locomotion.turn_lean(PI, Tuning.PLAYER_LEAN_TURN_GAIN, max_angle), max_angle, 0.0001)
	assert_almost_eq(Locomotion.turn_lean(-PI, Tuning.PLAYER_LEAN_TURN_GAIN, max_angle), -max_angle, 0.0001)
	assert_eq(Locomotion.turn_lean(0.0, Tuning.PLAYER_LEAN_TURN_GAIN, max_angle), 0.0)
