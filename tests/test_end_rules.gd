extends GutTest


func test_top_kinds_sorted_and_limited() -> void:
	var top: Array[Dictionary] = EndRules.top_kinds({&"walker": 50, &"runner": 12, &"tank": 12, &"jumper": 0, &"boss_heap": 1}, 3)
	assert_eq(top.size(), 3)
	assert_eq(top[0]["id"], &"walker")
	assert_eq(top[1]["id"], &"runner", "eşitlikte kimlik sırası")
	assert_eq(top[2]["id"], &"tank")


func test_top_kinds_empty() -> void:
	assert_eq(EndRules.top_kinds({}, 3).size(), 0)
	assert_eq(EndRules.top_kinds({&"walker": 4}, 0).size(), 0)


func test_card_groups_merge_by_stat() -> void:
	var groups: Array[Dictionary] = EndRules.card_groups([
		{"stat": &"damage", "tier": 0}, {"stat": &"armor", "tier": 1}, {"stat": &"damage", "tier": 2}, "bozuk"])
	assert_eq(groups.size(), 2)
	assert_eq(groups[0]["stat"], &"damage")
	assert_eq(groups[0]["count"], 2)
	assert_eq(groups[0]["tier"], 2)
	assert_eq(groups[1]["count"], 1)


func test_record_flags_map_rows() -> void:
	var flags: Dictionary = EndRules.record_flags([&"most_kills", &"fastest_win", &"bilinmeyen"])
	assert_true(flags[&"kills"])
	assert_true(flags[&"time"])
	assert_false(flags[&"wave"])
	assert_false(flags[&"level"])


func test_counted_reaches_target() -> void:
	assert_eq(EndRules.counted(200, 0.0), 0)
	assert_eq(EndRules.counted(200, 1.0), 200)
	assert_eq(EndRules.counted(200, 2.0), 200, "p sınırlanır")
	assert_gt(EndRules.counted(200, 0.5), 100, "başta hızlı")


func test_row_progress_staggers() -> void:
	assert_eq(EndRules.row_progress(0.1, 2, 0.2, 0.5), 0.0)
	assert_almost_eq(EndRules.row_progress(0.65, 2, 0.2, 0.5), 0.5, 0.0001)
	assert_eq(EndRules.row_progress(9.0, 2, 0.2, 0.5), 1.0)


func test_group_digits() -> void:
	assert_eq(EndRules.group_digits(0, "."), "0")
	assert_eq(EndRules.group_digits(999, "."), "999")
	assert_eq(EndRules.group_digits(1000, "."), "1.000")
	assert_eq(EndRules.group_digits(1234567, ","), "1,234,567")
	assert_eq(EndRules.group_digits(-4500, ","), "-4,500")
