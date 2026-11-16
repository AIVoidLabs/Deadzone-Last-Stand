extends GutTest

const EPSILON: float = 0.0001


func _new() -> HitStop:
	return HitStop.new(Tuning.HIT_STOP_COOLDOWN)


func test_starts_and_ends_after_duration() -> void:
	var stop: HitStop = _new()
	assert_true(stop.request(1.0, Tuning.HIT_STOP_KILL_TIME))
	assert_true(stop.is_active(1.0 + Tuning.HIT_STOP_KILL_TIME * 0.5))
	assert_false(stop.is_active(1.0 + Tuning.HIT_STOP_KILL_TIME + EPSILON))


func test_cooldown_blocks_back_to_back_kills() -> void:
	var stop: HitStop = _new()
	stop.request(0.0, Tuning.HIT_STOP_KILL_TIME)
	var blocked_at: float = Tuning.HIT_STOP_KILL_TIME + Tuning.HIT_STOP_COOLDOWN * 0.5
	assert_false(stop.request(blocked_at, Tuning.HIT_STOP_KILL_TIME))
	var open_at: float = Tuning.HIT_STOP_KILL_TIME + Tuning.HIT_STOP_COOLDOWN + EPSILON
	assert_true(stop.request(open_at, Tuning.HIT_STOP_KILL_TIME))


func test_zero_duration_does_nothing() -> void:
	var stop: HitStop = _new()
	assert_false(stop.request(0.0, 0.0))
	assert_false(stop.is_active(0.0))


func test_reset_clears_cooldown() -> void:
	var stop: HitStop = _new()
	stop.request(0.0, Tuning.HIT_STOP_KILL_TIME)
	stop.reset()
	assert_false(stop.is_active(0.0))
	assert_true(stop.request(0.001, Tuning.HIT_STOP_KILL_TIME))


func test_hordes_cannot_freeze_the_game() -> void:
	# Her karede öldürme olsa bile oyunun en fazla küçük bir kısmı duraksamada geçmeli.
	var share: float = Tuning.HIT_STOP_KILL_TIME / (Tuning.HIT_STOP_KILL_TIME + Tuning.HIT_STOP_COOLDOWN)
	assert_lt(share, 0.25)
