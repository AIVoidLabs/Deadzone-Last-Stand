extends GutTest


func test_stationary_target_aims_straight() -> void:
	var dir: Vector2 = LungeRules.aim_direction(Vector2.ZERO, Vector2(4, 0), Vector2.ZERO, 8.0, 1.0)
	assert_almost_eq(dir.x, 1.0, 0.001)
	assert_almost_eq(dir.y, 0.0, 0.001)


func test_moving_target_is_led() -> void:
	# Hedef +y yönünde koşuyorsa nişan +y tarafına kayar.
	var dir: Vector2 = LungeRules.aim_direction(Vector2.ZERO, Vector2(4, 0), Vector2(0, 6), 8.0, 1.0)
	assert_gt(dir.y, 0.2)
	assert_almost_eq(dir.length(), 1.0, 0.001)


func test_zero_lead_aims_directly() -> void:
	var dir: Vector2 = LungeRules.aim_direction(Vector2.ZERO, Vector2(4, 0), Vector2(0, 6), 8.0, 0.0)
	assert_almost_eq(dir.y, 0.0, 0.001)


func test_lead_angle_depends_on_speed_ratio_not_distance() -> void:
	# Varış süresi mesafeyle orantılı olduğundan kayma açısı yalnız hedef hızı / atılış hızı oranına bağlı.
	var near: Vector2 = LungeRules.aim_direction(Vector2.ZERO, Vector2(2, 0), Vector2(0, 6), 8.0, 1.0)
	var far: Vector2 = LungeRules.aim_direction(Vector2.ZERO, Vector2(8, 0), Vector2(0, 6), 8.0, 1.0)
	assert_almost_eq(far.angle(), near.angle(), 0.001)
	assert_almost_eq(near.angle(), atan2(6.0, 8.0), 0.001)


func test_steer_is_limited() -> void:
	var out: Vector2 = LungeRules.steer(Vector2.RIGHT, Vector2.DOWN, 0.1)
	assert_almost_eq(absf(Vector2.RIGHT.angle_to(out)), 0.1, 0.001)


func test_steer_reaches_desired_when_close() -> void:
	var out: Vector2 = LungeRules.steer(Vector2.RIGHT, Vector2.RIGHT.rotated(0.05), 0.1)
	assert_almost_eq(out.angle(), 0.05, 0.001)


func test_aim_locks_in_last_moments_of_windup() -> void:
	assert_false(LungeRules.is_aim_locked(0.5, 0.25))
	assert_true(LungeRules.is_aim_locked(0.25, 0.25))
	assert_true(LungeRules.is_aim_locked(0.1, 0.25))
