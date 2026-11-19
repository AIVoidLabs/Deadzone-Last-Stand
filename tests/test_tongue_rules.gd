extends GutTest

const ROW_ID: StringName = EnemyData.TONGUE


func _row() -> Dictionary:
	return EnemyData.get_row(ROW_ID)


func test_flight_reaches_full_length_at_flight_time() -> void:
	var row: Dictionary = _row()
	var reach: float = float(row["tongue_range"]) + SpecialAttacks.TONGUE_REACH_MARGIN
	var speed: float = float(row["tongue_speed"])
	var t: float = TongueRules.flight_time(reach, speed)
	assert_almost_eq(TongueRules.tip_distance(t, speed, reach), reach, 0.001)
	assert_almost_eq(TongueRules.tip_distance(t * 0.5, speed, reach), reach * 0.5, 0.001)
	assert_eq(TongueRules.tip_distance(t * 3.0, speed, reach), reach, "uç erişimde durur")


func test_tongue_is_visible_long_enough_to_react() -> void:
	# Hazırlık + uçuş: asker kenara çekilebilmeli (görünür hızlı dil, anlık ışın değil).
	var row: Dictionary = _row()
	var to_player: float = float(row["tongue_range"])
	var flight: float = to_player / float(row["tongue_speed"])
	assert_gt(flight, 0.3, "dil gözle izlenebilir hızda")
	var dodge: float = (float(row["tongue_lock_time"]) + flight) * Tuning.PLAYER_SPEED
	assert_gt(dodge, (Tuning.PLAYER_RADIUS + float(row["tongue_hit_radius"])) * 2.0, "kilitten sonra yana kaçılabilir")


func test_sweep_catches_target_on_the_line_even_when_fast() -> void:
	# Tek karede askerin tamamını aşan adım da yakalar.
	assert_true(TongueRules.catches(Vector2.ZERO, Vector2.RIGHT, 2.0, 8.0, Vector2(5.0, 0.0), 0.3))
	assert_false(TongueRules.catches(Vector2.ZERO, Vector2.RIGHT, 2.0, 4.0, Vector2(5.0, 0.0), 0.3), "uç henüz gelmedi")
	assert_false(TongueRules.catches(Vector2.ZERO, Vector2.RIGHT, 2.0, 8.0, Vector2(5.0, 1.0), 0.3), "yana kaçan kurtulur")


func test_pull_moves_toward_zombie_at_pull_speed() -> void:
	var v: Vector2 = TongueRules.pull_velocity(Vector2(5.0, 0.0), Vector2.ZERO, 1.8, 1.0, 1.0 / 60.0)
	assert_almost_eq(v.length(), 1.8, 0.001)
	assert_lt(v.x, 0.0, "dilciye doğru")


func test_pull_never_overshoots_stop_distance() -> void:
	var delta: float = 1.0 / 60.0
	var v: Vector2 = TongueRules.pull_velocity(Vector2(1.01, 0.0), Vector2.ZERO, 1.8, 1.0, delta)
	assert_almost_eq(1.01 + v.x * delta, 1.0, 0.0001)
	assert_eq(TongueRules.pull_velocity(Vector2(0.9, 0.0), Vector2.ZERO, 1.8, 1.0, delta), Vector2.ZERO)


func test_release_reasons() -> void:
	assert_eq(TongueRules.release(3.0, 1.0, 1.0), TongueRules.Release.NONE)
	assert_eq(TongueRules.release(1.0, 1.0, 1.0), TongueRules.Release.NEAR)
	assert_eq(TongueRules.release(3.0, 1.0, 0.0), TongueRules.Release.TIMEOUT)


func test_pull_ends_within_time_limit_from_full_range() -> void:
	# Sınır süre çekişi uzatmaz: en uzak yakalamada bile asker sınır dolunca bırakılır.
	var row: Dictionary = _row()
	assert_gt(float(row["tongue_pull_time"]), 0.0)
	assert_lte(float(row["tongue_pull_speed"]), 2.0, "yavaş çekiş (Taha: ~1.5-2 m/sn)")
	assert_gte(float(row["tongue_pull_speed"]), 1.5)
