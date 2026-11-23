extends GutTest


func test_chance_one_always_drops() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	for i in 50:
		assert_true(PickupRules.should_drop(1.0, rng))


func test_chance_zero_never_drops() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	for i in 50:
		assert_false(PickupRules.should_drop(0.0, rng))


func test_chance_matches_rate() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var hits: int = 0
	for i in 2000:
		if PickupRules.should_drop(Tuning.DROP_CHANCE_WALKER, rng):
			hits += 1
	assert_almost_eq(float(hits) / 2000.0, Tuning.DROP_CHANCE_WALKER, 0.05)


func test_rows_carry_chances() -> void:
	assert_eq(float(EnemyData.TABLE[&"walker"]["drop_chance"]), Tuning.DROP_CHANCE_WALKER)
	assert_eq(float(EnemyData.TABLE[&"tank"]["drop_chance"]), Tuning.DROP_CHANCE_SPECIAL)
