extends GutTest


func _run_of(won: bool, wave: int, kills: int, time: float, level: int = 5) -> Dictionary:
	return {"won": won, "wave": wave, "kills": kills, "crystals": kills * 2, "time": time, "level": level}


func test_empty_record_is_readable_and_zeroed() -> void:
	var save: Dictionary = RunRecord.empty()
	assert_true(RunRecord.is_readable(save))
	assert_eq(save["totals"][&"runs"], 0)
	assert_eq(save["records"][&"fastest_win"], 0.0)
	assert_eq(save["history"].size(), 0)


func test_corrupt_data_becomes_empty() -> void:
	for bad: Variant in [null, 5, "metin", [], {"version": "x"}, {"version": 0}, {"version": RunRecord.VERSION + 1}]:
		assert_false(RunRecord.is_readable(bad), "okunmamalı: %s" % str(bad))
		assert_eq(RunRecord.sanitize(bad), RunRecord.empty())


func test_sanitize_repairs_fields() -> void:
	var raw: Dictionary = {
		"version": 1,
		"totals": {"runs": 3.0, "wins": -2, "kills": "çok", "crystals": 40, "play_time": 12.5},
		"records": {"best_wave": 7, "fastest_win": NAN},
		"history": ["bozuk", {"won": true, "wave": 4, "kills": 10}],
	}
	var out: Dictionary = RunRecord.sanitize(raw)
	assert_eq(out["totals"][&"runs"], 3)
	assert_eq(out["totals"][&"wins"], 0, "eksi değer sıfırlanır")
	assert_eq(out["totals"][&"kills"], 0)
	assert_eq(out["totals"][&"play_time"], 12.5)
	assert_eq(out["records"][&"best_wave"], 7)
	assert_eq(out["records"][&"fastest_win"], 0.0)
	assert_eq(out["history"].size(), 1, "dict olmayan kayıt atılır")
	assert_eq(out["history"][0]["wave"], 4)


func test_json_roundtrip_keeps_values() -> void:
	var first: Dictionary = RunRecord.apply_run(RunRecord.empty(), _run_of(true, 10, 200, 600.0))["save"]
	var parsed: Variant = JSON.parse_string(JSON.stringify(first))
	assert_true(RunRecord.is_readable(parsed))
	var back: Dictionary = RunRecord.sanitize(parsed)
	assert_eq(back["totals"][&"kills"], 200)
	assert_eq(back["records"][&"fastest_win"], 600.0)
	assert_eq(back["history"].size(), 1)


func test_apply_run_totals_and_records() -> void:
	var result: Dictionary = RunRecord.apply_run(RunRecord.empty(), _run_of(false, 4, 50, 120.0, 3))
	var save: Dictionary = result["save"]
	assert_eq(save["totals"][&"runs"], 1)
	assert_eq(save["totals"][&"wins"], 0)
	assert_eq(save["totals"][&"kills"], 50)
	assert_eq(save["records"][&"best_wave"], 4)
	assert_eq(save["records"][&"fastest_win"], 0.0, "yenilgi hızlı galibiyet sayılmaz")
	assert_true(result["new_records"].has(&"best_wave"))
	assert_false(result["new_records"].has(&"fastest_win"))
	var second: Dictionary = RunRecord.apply_run(save, _run_of(true, 10, 40, 500.0, 2))
	assert_eq(second["save"]["records"][&"most_kills"], 50, "düşük değer rekoru bozmaz")
	assert_eq(second["save"]["records"][&"fastest_win"], 500.0)
	assert_eq(second["save"]["totals"][&"wins"], 1)
	assert_true(second["new_records"].has(&"fastest_win"))
	assert_false(second["new_records"].has(&"most_kills"))
	var third: Dictionary = RunRecord.apply_run(second["save"], _run_of(true, 10, 40, 700.0))
	assert_eq(third["save"]["records"][&"fastest_win"], 500.0, "daha yavaş galibiyet rekoru bozmaz")


func test_history_is_newest_first_and_capped() -> void:
	var save: Dictionary = RunRecord.empty()
	for i: int in RunRecord.HISTORY_MAX + 4:
		save = RunRecord.apply_run(save, _run_of(false, i + 1, i, 10.0))["save"]
	assert_eq(save["history"].size(), RunRecord.HISTORY_MAX)
	assert_eq(save["history"][0]["wave"], RunRecord.HISTORY_MAX + 4, "en yeni başta")
