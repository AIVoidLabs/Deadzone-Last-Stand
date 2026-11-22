extends GutTest


func test_counters_accumulate() -> void:
	var stats: RunStats = RunStats.new()
	stats.on_kill(&"walker")
	stats.on_kill(&"walker")
	stats.on_kill(&"runner")
	stats.on_damage_dealt(10.0)
	stats.on_damage_dealt(2.5)
	stats.on_damage_taken(4.0)
	stats.on_crystal(3)
	stats.on_dash()
	stats.on_shot()
	assert_eq(stats.kills, 3)
	assert_eq(stats.kills_by_kind[&"walker"], 2)
	assert_eq(stats.kills_by_kind[&"runner"], 1)
	assert_almost_eq(stats.damage_dealt, 12.5, 0.0001)
	assert_eq(stats.crystals, 3)
	assert_eq(stats.dashes, 1)
	assert_eq(stats.shots, 1)


func test_level_and_wave_only_rise() -> void:
	var stats: RunStats = RunStats.new()
	stats.set_wave(5)
	stats.set_wave(3)
	stats.set_level(4)
	stats.set_level(2)
	assert_eq(stats.wave, 5)
	assert_eq(stats.level, 4)


func test_time_stops_after_finish() -> void:
	var stats: RunStats = RunStats.new()
	stats.tick(1.5)
	stats.finish(true)
	stats.tick(10.0)
	assert_almost_eq(stats.time, 1.5, 0.0001)
	assert_true(stats.won)


func test_cards_items_weapons_in_summary() -> void:
	var stats: RunStats = RunStats.new()
	stats.add_card(&"damage", 2)
	stats.add_item(&"magnet")
	stats.add_item(&"magnet")
	stats.set_weapons([&"pistol", &"smg"])
	var summary: Dictionary = stats.summary()
	assert_eq(summary["cards"].size(), 1)
	assert_eq(summary["cards"][0]["tier"], 2)
	assert_eq(summary["items"][&"magnet"], 2)
	assert_eq(summary["weapons"].size(), 2)
	stats.add_card(&"luck", 0)
	assert_eq(summary["cards"].size(), 1, "özet kopyadır")


func test_summary_feeds_run_record() -> void:
	var stats: RunStats = RunStats.new()
	stats.on_kill(&"walker")
	stats.on_crystal(5)
	stats.set_wave(3)
	stats.tick(30.0)
	stats.finish(false)
	var result: Dictionary = RunRecord.apply_run(RunRecord.empty(), stats.summary())
	assert_eq(result["save"]["totals"][&"kills"], 1)
	assert_eq(result["save"]["records"][&"best_wave"], 3)
