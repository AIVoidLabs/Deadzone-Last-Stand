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
