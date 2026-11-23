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


func test_early_window_only_first_part() -> void:
	var dash: Dash = _new_dash()
	assert_false(dash.in_early_window(Tuning.DASH_IFRAMES), "aktif değil")
	dash.start()
	assert_true(dash.in_early_window(Tuning.DASH_IFRAMES), "başlangıçta pencere açık")
	dash.tick(Tuning.DASH_IFRAMES + 0.01)
	assert_false(dash.in_early_window(Tuning.DASH_IFRAMES), "pencere kapandı")
	assert_true(dash.is_active())


func test_move_speed_bonus_capped() -> void:
	var stats: PlayerStats = PlayerStats.new()
	stats.add(StatData.MOVE_SPEED, 500.0)
	assert_almost_eq(stats.move_speed(), Tuning.PLAYER_SPEED * (1.0 + Tuning.MOVE_SPEED_BONUS_CAP / 100.0), 0.0001)


func test_cancel_ends_dash_but_keeps_cooldown() -> void:
	var d: Dash = _new_dash()
	d.start()
	d.cancel()
	assert_false(d.is_active())
	assert_false(d.can_start(), "bekleme akmaya devam eder")


func _dashing_player() -> Player:
	var player: Player = Player.new()
	add_child_autofree(player)
	player.request_dash()
	player._physics_process(0.001)
	return player


func test_root_rejected_in_dash_iframe_window() -> void:
	if not (Tuning.FEATURE_DASH_EARLY_IFRAMES and Tuning.FEATURE_ROOT):
		pending("takla dokunulmazlığı / bağlama kapalı")
		return
	var player: Player = _dashing_player()
	assert_true(player.is_dashing())
	player.root(1.0)
	assert_false(player.is_rooted(), "dokunulmaz pencerede bağ reddedilir")
	assert_true(player.is_dashing())


func test_root_in_late_dash_cuts_dash_then_roots() -> void:
	if not (Tuning.FEATURE_DASH_EARLY_IFRAMES and Tuning.FEATURE_ROOT):
		pending("takla dokunulmazlığı / bağlama kapalı")
		return
	var player: Player = _dashing_player()
	watch_signals(player)
	while player.dash.is_active() and player.dash.in_early_window(Tuning.DASH_IFRAMES):
		player._physics_process(0.005)
	assert_true(player.is_dashing(), "pencere bitti ama takla sürüyor")
	player.root(1.0)
	assert_true(player.is_rooted())
	assert_false(player.is_dashing())
	assert_false(player.dash.is_active())
	assert_signal_emitted(player, "state_changed")
	assert_signal_emitted(player, "event")


func test_hit_during_dash_leaves_no_stale_knock() -> void:
	if not Tuning.FEATURE_DASH_EARLY_IFRAMES:
		pending("takla dokunulmazlığı kapalı")
		return
	var player: Player = _dashing_player()
	while player.dash.in_early_window(Tuning.DASH_IFRAMES):
		player._physics_process(0.005)
	player.take_hit(1.0, Vector2.RIGHT)
	assert_eq(player._knock, Vector2.ZERO, "takla sırasında itme yazılmaz")
