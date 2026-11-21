extends GutTest

const CLEAR: float = Tuning.WAVE_CLEAR_TIME
const BREAK: float = Tuning.WAVE_BREAK_TIME
## Faz sınırını kesin aşmak için.
const STEP_PAD: float = 0.001


func _run() -> WaveRun:
	return WaveRun.new(WaveData.WAVES, CLEAR, BREAK)


func _duration(i: int) -> float:
	return WaveData.WAVES[i]["duration"]


func test_starts_at_first_wave() -> void:
	var run: WaveRun = _run()
	assert_eq(run.index, 0)
	assert_eq(run.phase, WaveRun.Phase.WAVE)
	assert_almost_eq(run.phase_left, _duration(0), 0.0001)
	assert_almost_eq(run.progress(), 0.0, 0.0001)


func test_wave_goes_clear_then_break_then_next() -> void:
	var run: WaveRun = _run()
	assert_eq(run.tick(_duration(0) * 0.5), WaveRun.NO_CHANGE)
	assert_almost_eq(run.progress(), 0.5, 0.001)
	assert_eq(run.tick(_duration(0) * 0.5 + STEP_PAD), WaveRun.Phase.CLEAR)
	assert_eq(run.tick(CLEAR + STEP_PAD), WaveRun.Phase.BREAK)
	assert_eq(run.index, 0, "arada dalga numarası değişmez")
	assert_eq(run.tick(BREAK + STEP_PAD), WaveRun.Phase.WAVE)
	assert_eq(run.index, 1)
	assert_almost_eq(run.phase_left, _duration(1), 0.0001)


func test_last_wave_wins_without_break() -> void:
	var run: WaveRun = _run()
	run.start_at(run.wave_count() - 1)
	assert_true(run.is_last())
	run.tick(_duration(run.index) + STEP_PAD)
	assert_eq(run.tick(CLEAR + STEP_PAD), WaveRun.Phase.WON)
	assert_eq(run.tick(100.0), WaveRun.NO_CHANGE, "kazandıktan sonra akış durur")


func test_full_run_visits_every_wave() -> void:
	var run: WaveRun = _run()
	var started: int = 1
	for _i in 10000:
		if run.tick(0.25) == WaveRun.Phase.WAVE:
			started += 1
		if run.phase == WaveRun.Phase.WON:
			break
	assert_eq(run.phase, WaveRun.Phase.WON)
	assert_eq(started, WaveData.WAVES.size())


func test_end_wave_skips_to_clear_only_during_wave() -> void:
	var run: WaveRun = _run()
	run.end_wave()
	assert_eq(run.phase, WaveRun.Phase.CLEAR)
	assert_almost_eq(run.phase_left, CLEAR, 0.0001)
	run.tick(CLEAR + STEP_PAD)
	run.end_wave()
	assert_eq(run.phase, WaveRun.Phase.BREAK, "arada end_wave bir şey yapmaz")


func test_start_at_clamps() -> void:
	var run: WaveRun = _run()
	run.start_at(999)
	assert_eq(run.index, run.wave_count() - 1)
	run.start_at(-5)
	assert_eq(run.index, 0)


func test_wave_table_rows_are_valid() -> void:
	for row: Dictionary in WaveData.WAVES:
		assert_gt(row["duration"], 0.0)
		assert_gt(row["interval_end"], 0.0)
		assert_lte(row["interval_end"], row["interval_start"], "dalga içinde doğma sıklaşır")
		assert_lte(row["batch_start"], row["batch_end"])
		assert_gt(row["max_alive"], 0)
		for kind: StringName in row["mix"]:
			assert_true(EnemyData.TABLE.has(kind), "bilinmeyen tür: %s" % kind)


# --- Boss dalgası (7.4) ---

const WARNING: float = Tuning.BOSS_WARNING_TIME


func _boss_run() -> WaveRun:
	var run: WaveRun = WaveRun.new(WaveData.WAVES, CLEAR, BREAK, true, WARNING)
	run.start_at(run.wave_count() - 1)
	return run


func _boss_spawn_time() -> float:
	return float(WaveData.WAVES[WaveData.WAVES.size() - 1]["boss"]["spawn_time"])


func test_last_wave_defines_a_boss_that_exists() -> void:
	var boss: Dictionary = WaveData.WAVES[WaveData.WAVES.size() - 1]["boss"]
	assert_true(EnemyData.TABLE.has(boss["kind"]))
	for i in WaveData.WAVES.size() - 1:
		assert_false(WaveData.WAVES[i].has("boss"), "boss yalnız son dalgada")


func test_boss_disabled_wave_ends_by_timer_as_before() -> void:
	var run: WaveRun = _run()
	run.start_at(run.wave_count() - 1)
	assert_eq(run.boss_stage, WaveRun.BossStage.NONE)
	assert_eq(run.tick(_duration(run.index) + STEP_PAD), WaveRun.Phase.CLEAR)
	assert_eq(run.horde_factor(), 1.0)


func test_earlier_waves_have_no_boss_stage_even_when_enabled() -> void:
	var run: WaveRun = WaveRun.new(WaveData.WAVES, CLEAR, BREAK, true, WARNING)
	assert_eq(run.boss_stage, WaveRun.BossStage.NONE)


func test_boss_warns_then_spawns_after_warning_time() -> void:
	var run: WaveRun = _boss_run()
	assert_eq(run.boss_stage, WaveRun.BossStage.WAITING)
	run.tick(_boss_spawn_time() - 0.5)
	assert_eq(run.boss_event, &"")
	run.tick(0.5 + STEP_PAD)
	assert_eq(run.boss_event, &"warn")
	assert_eq(run.boss_stage, WaveRun.BossStage.WARNING)
	run.boss_event = &""
	run.tick(WARNING + STEP_PAD)
	assert_eq(run.boss_event, &"spawn")
	assert_eq(run.boss_stage, WaveRun.BossStage.ALIVE)


func test_wave_clock_stops_while_boss_alive_and_never_ends_by_timer() -> void:
	var run: WaveRun = _boss_run()
	run.tick(_boss_spawn_time() + WARNING + STEP_PAD)
	var left: float = run.phase_left
	assert_eq(run.tick(_duration(run.index) * 3.0), WaveRun.NO_CHANGE)
	assert_eq(run.phase, WaveRun.Phase.WAVE, "boss ölmeden dalga bitmez")
	assert_eq(run.phase_left, left, "boss canlıyken süre durur")


func test_boss_wave_does_not_end_by_timer_before_boss_spawns() -> void:
	var run: WaveRun = _boss_run()
	run.tick(_boss_spawn_time() - 1.0)
	assert_eq(run.phase, WaveRun.Phase.WAVE)
	assert_gt(run.phase_left, 0.0)


func test_boss_defeat_ends_wave_into_clear_and_last_wave_wins() -> void:
	var run: WaveRun = _boss_run()
	run.tick(_boss_spawn_time() + WARNING + STEP_PAD)
	assert_true(run.boss_defeated(Tuning.BOSS_DEATH_CLEAR_TIME))
	assert_eq(run.phase, WaveRun.Phase.CLEAR)
	assert_eq(run.tick(Tuning.BOSS_DEATH_CLEAR_TIME + STEP_PAD), WaveRun.Phase.WON)


func test_boss_defeat_ignored_when_no_boss_is_expected() -> void:
	var run: WaveRun = _run()
	assert_false(run.boss_defeated(1.0))
	var boss_run: WaveRun = _boss_run()
	assert_false(boss_run.boss_defeated(1.0), "doğmadan ölemez")


func test_horde_factor_only_while_boss_alive() -> void:
	var run: WaveRun = _boss_run()
	assert_eq(run.horde_factor(), 1.0)
	run.tick(_boss_spawn_time() + WARNING + STEP_PAD)
	assert_eq(run.horde_factor(), Tuning.BOSS_HORDE_FACTOR)


func test_force_boss_holds_any_wave_when_enabled() -> void:
	var run: WaveRun = WaveRun.new(WaveData.WAVES, CLEAR, BREAK, true, WARNING)
	run.force_boss()
	assert_eq(run.boss_stage, WaveRun.BossStage.ALIVE)
	assert_eq(run.tick(_duration(0) * 2.0), WaveRun.NO_CHANGE)
	assert_true(run.boss_defeated(1.0))
	var off: WaveRun = _run()
	off.force_boss()
	assert_eq(off.boss_stage, WaveRun.BossStage.NONE, "bayrak kapalıyken etkisiz")


func test_start_at_resets_boss_state() -> void:
	var run: WaveRun = _boss_run()
	run.tick(_boss_spawn_time() + WARNING + STEP_PAD)
	run.start_at(0)
	assert_eq(run.boss_stage, WaveRun.BossStage.NONE)
	assert_eq(run.boss_event, &"")
