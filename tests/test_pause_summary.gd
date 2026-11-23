extends GutTest


func test_gains_skip_zero_and_follow_stat_order() -> void:
	var bonus: Dictionary = {&"damage": 12.0, &"max_hp": 20.0, &"luck": 0.0}
	var rows: Array[Dictionary] = PauseSummary.gains(func(stat: StringName) -> float: return bonus.get(stat, 0.0))
	assert_eq(rows.size(), 2)
	assert_eq(rows[0]["stat"], &"max_hp", "StatData sırası: max_hp önce")
	assert_eq(rows[1]["stat"], &"damage")
	assert_eq(rows[1]["category"], StatData.category_of(&"damage"))


func test_gains_keep_negative_values() -> void:
	var rows: Array[Dictionary] = PauseSummary.gains(func(stat: StringName) -> float: return -5.0 if stat == &"dash_cooldown" else 0.0)
	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["value"], -5.0)


func test_weapon_rows_clamp_tier() -> void:
	var rows: Array[Dictionary] = PauseSummary.weapon_rows([{"id": &"pistol", "tier": 1}, {"id": &"smg", "tier": 99}, {"id": &"knife", "tier": 0}])
	assert_eq(rows[0]["tier_index"], 0)
	assert_eq(rows[1]["tier"], WeaponData.max_tier())
	assert_eq(rows[2]["tier"], 1)


func test_counters_order_and_clock() -> void:
	var rows: Array[Dictionary] = PauseSummary.counters(4, 125.0, 37, 6, 210)
	assert_eq(rows.size(), 5)
	assert_eq(rows[0]["value"], "4")
	assert_eq(rows[1]["value"], "2:05")
	assert_eq(rows[4]["value"], "210")
