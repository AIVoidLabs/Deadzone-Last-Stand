extends GutTest


func test_dynamic_angle_zero_at_rest() -> void:
	assert_eq(FollowCamera.dynamic_angle(Vector3.ZERO, Tuning.PLAYER_SPEED, 7.0, 3.0), Vector2.ZERO)


func test_dynamic_angle_clamped_to_run_speed() -> void:
	var a: Vector2 = FollowCamera.dynamic_angle(Vector3(Tuning.PLAYER_SPEED * 3.0, 0.0, 0.0), Tuning.PLAYER_SPEED, 7.0, 3.0)
	assert_almost_eq(absf(a.x), 7.0, 0.001)
	assert_almost_eq(a.y, 0.0, 0.001)


func test_forward_pitch_sign() -> void:
	var a: Vector2 = FollowCamera.dynamic_angle(Vector3(0.0, 0.0, Tuning.PLAYER_SPEED), Tuning.PLAYER_SPEED, 7.0, 3.0)
	assert_almost_eq(a.y, 3.0, 0.001)


func test_orbit_offset_keeps_distance() -> void:
	assert_almost_eq(FollowCamera.orbit_offset(60.0, 7.0, 24.0).length(), 24.0, 0.001)
