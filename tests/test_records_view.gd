extends GutTest


func test_time_parts_splits_hours_minutes_seconds() -> void:
	var p: Dictionary = RecordsView.time_parts(3725.9)
	assert_eq(p["h"], 1)
	assert_eq(p["m"], 2)
	assert_eq(p["s"], 5)


func test_time_parts_negative_is_zero() -> void:
	var p: Dictionary = RecordsView.time_parts(-4.0)
	assert_eq(p["h"] + p["m"] + p["s"], 0)


func test_date_text_empty_without_stamp() -> void:
	assert_eq(RecordsView.date_text(0, 0), "")


func test_date_text_applies_bias() -> void:
	# 2026-01-02 03:04:00 UTC
	var unix: int = Time.get_unix_time_from_datetime_dict({"year": 2026, "month": 1, "day": 2, "hour": 3, "minute": 4, "second": 0})
	assert_eq(RecordsView.date_text(unix, 0), "02.01 03:04")
	assert_eq(RecordsView.date_text(unix, 180), "02.01 06:04")


func test_has_data_follows_runs() -> void:
	var save: Dictionary = RunRecord.empty()
	assert_false(RecordsView.has_data(save))
	save = RunRecord.apply_run(save, {"won": true, "wave": 3, "kills": 10, "time": 60.0})["save"]
	assert_true(RecordsView.has_data(save))
	assert_eq(RecordsView.last_run(save)["wave"], 3)


func test_rows_are_numbered_from_one() -> void:
	var rows: Array[Dictionary] = RecordsView.rows([{"wave": 5}, {"wave": 2}])
	assert_eq(rows.size(), 2)
	assert_eq(rows[0]["index"], 1)
	assert_eq(rows[1]["index"], 2)
	assert_eq(rows[1]["wave"], 2)


func test_has_record_zero_means_none() -> void:
	assert_false(RecordsView.has_record(0))
	assert_false(RecordsView.has_record(0.0))
	assert_true(RecordsView.has_record(12))
