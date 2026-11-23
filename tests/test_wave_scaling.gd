extends GutTest
## WaveScaling (saf): dalga çarpanlarının okunması, varsayılan 1.0, boss hariç, birikmeme, özellik bayrağı.


func test_wave_rows_carry_the_planned_curve() -> void:
	var first: Dictionary = WaveData.WAVES[0]
	var last: Dictionary = WaveData.WAVES[WaveData.WAVES.size() - 1]
	var walker: Dictionary = EnemyData.get_row(EnemyData.WALKER)
	assert_eq(WaveScaling.hp_mult(first, walker, true), float(first["enemy_hp_mult"]), "ilk dalga tablodaki değer")
	assert_eq(WaveScaling.damage_mult(first, walker, true), float(first["enemy_damage_mult"]))
	for k in range(1, WaveData.WAVES.size()):
		var prev: Dictionary = WaveData.WAVES[k - 1]
		var cur: Dictionary = WaveData.WAVES[k]
		assert_gte(float(cur["enemy_hp_mult"]), float(prev["enemy_hp_mult"]), "can çarpanı dalgayla düşmez (dalga %d)" % (k + 1))
		assert_gte(float(cur["enemy_damage_mult"]), float(prev["enemy_damage_mult"]), "hasar çarpanı dalgayla düşmez (dalga %d)" % (k + 1))
	assert_gt(float(last["enemy_hp_mult"]), float(first["enemy_hp_mult"]))
	assert_gt(float(last["enemy_damage_mult"]), float(first["enemy_damage_mult"]))


func test_reads_multipliers_and_defaults_to_one() -> void:
	var walker: Dictionary = EnemyData.get_row(EnemyData.WALKER)
	var wave: Dictionary = {"enemy_hp_mult": 1.5, "enemy_damage_mult": 1.2}
	assert_almost_eq(WaveScaling.hp_mult(wave, walker, true), 1.5, 0.0001)
	assert_almost_eq(WaveScaling.damage_mult(wave, walker, true), 1.2, 0.0001)
	assert_eq(WaveScaling.hp_mult({}, walker, true), 1.0)
	assert_eq(WaveScaling.damage_mult({}, walker, true), 1.0)


func test_boss_is_not_scaled() -> void:
	var boss: Dictionary = EnemyData.get_row(EnemyData.BOSS_HEAP)
	var wave: Dictionary = {"enemy_hp_mult": 2.0, "enemy_damage_mult": 2.0}
	assert_eq(WaveScaling.hp_mult(wave, boss, true), 1.0)
	assert_eq(WaveScaling.damage_mult(wave, boss, true), 1.0)


func test_feature_off_gives_one() -> void:
	var walker: Dictionary = EnemyData.get_row(EnemyData.WALKER)
	var wave: Dictionary = {"enemy_hp_mult": 2.0, "enemy_damage_mult": 2.0}
	assert_eq(WaveScaling.hp_mult(wave, walker, false), 1.0)
	assert_eq(WaveScaling.damage_mult(wave, walker, false), 1.0)


func test_pool_reuse_does_not_accumulate() -> void:
	var spitter: Dictionary = EnemyData.get_row(&"spitter")
	var base_acid: float = float(spitter["acid_damage"])
	var base_contact: float = float(spitter["contact_damage"])
	var wave: Dictionary = {"enemy_hp_mult": 1.3, "enemy_damage_mult": 1.25}
	var spawn_values: Array[float] = []
	for _i in 3:
		var m: float = WaveScaling.damage_mult(wave, spitter, true)
		spawn_values.append(float(spitter["max_hp"]) * WaveScaling.hp_mult(wave, spitter, true))
		var scaled: Dictionary = WaveScaling.scaled_row(spitter, m)
		assert_almost_eq(float(scaled["acid_damage"]), base_acid * 1.25, 0.0001)
		assert_almost_eq(float(scaled["contact_damage"]), base_contact * 1.25, 0.0001)
	assert_eq(spawn_values[0], spawn_values[2], "her doğuş temel satırdan hesaplanır")
	assert_eq(float(spitter["acid_damage"]), base_acid, "temel satır değişmez")
	assert_eq(float(spitter["contact_damage"]), base_contact)


func test_scaled_row_with_one_returns_same_row() -> void:
	var walker: Dictionary = EnemyData.get_row(EnemyData.WALKER)
	assert_eq(WaveScaling.scaled_row(walker, 1.0), walker)
