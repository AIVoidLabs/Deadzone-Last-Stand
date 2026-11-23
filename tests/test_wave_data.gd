extends GutTest
## Dalga tablosu bütünlüğü (sayılar değil yapı): dalga sayısından türer.


func test_table_has_ten_waves_at_least() -> void:
	assert_gte(WaveData.WAVES.size(), 2)


func test_every_wave_has_positive_duration_and_sane_spawn_fields() -> void:
	for row: Dictionary in WaveData.WAVES:
		assert_gt(float(row["duration"]), 0.0)
		assert_gt(float(row["interval_start"]), 0.0)
		assert_gt(float(row["interval_end"]), 0.0)
		assert_gte(int(row["batch_start"]), 1)
		assert_gte(int(row["batch_end"]), int(row["batch_start"]))


func test_max_alive_never_decreases() -> void:
	var prev: int = 0
	for row: Dictionary in WaveData.WAVES:
		assert_gte(int(row["max_alive"]), prev)
		prev = int(row["max_alive"])


func test_last_wave_has_boss_that_exists() -> void:
	var last: Dictionary = WaveData.WAVES[WaveData.WAVES.size() - 1]
	assert_true(last.has("boss"))
	assert_not_null(EnemyData.get_row(last["boss"]["kind"]))


func test_every_mix_kind_exists_in_enemy_data() -> void:
	for row: Dictionary in WaveData.WAVES:
		for kind: StringName in row["mix"]:
			assert_not_null(EnemyData.get_row(kind), "satır yok: %s" % kind)


func test_shop_weapon_unlocks_fit_in_the_run() -> void:
	for id: StringName in WeaponData.TABLE:
		assert_lte(int(WeaponData.TABLE[id].get("min_wave", 1)), WaveData.WAVES.size(), "silah turda açılmalı: %s" % id)
