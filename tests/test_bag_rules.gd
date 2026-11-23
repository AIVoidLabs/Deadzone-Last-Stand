extends GutTest
## BagRules / BagSchedule / RunLoot kanalları: değer, tür dengesi, ömür, yanıp sönme, konum, takvim.

var _rng: RandomNumberGenerator


func before_each() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 12345


func _rects() -> Array[Rect2]:
	return CityLayout.solid_rects(Tuning.ARENA_SIZE, Tuning.CITY_STREET_WIDTH, Tuning.FEATURE_CITY_PROPS)


func test_value_grows_with_wave() -> void:
	assert_eq(BagRules.value_for_wave(1), Tuning.BAG_VALUE_BASE + Tuning.BAG_VALUE_PER_WAVE)
	assert_eq(BagRules.value_for_wave(4), Tuning.BAG_VALUE_BASE + Tuning.BAG_VALUE_PER_WAVE * 4)


func test_pick_kind_balances_counts() -> void:
	assert_eq(BagRules.pick_kind(1, 0, _rng), BagRules.KIND_XP)
	assert_eq(BagRules.pick_kind(0, 2, _rng), BagRules.KIND_MONEY)


func test_wave_with_max_bags_has_both_kinds() -> void:
	for seed_value in 40:
		_rng.seed = seed_value
		var schedule: BagSchedule = BagSchedule.new()
		schedule.start_wave(1)
		for _i in Tuning.BAG_MAX_PER_WAVE:
			schedule.register(BagRules.pick_kind(schedule.money_count, schedule.xp_count, _rng))
		assert_gt(schedule.money_count, 0)
		assert_gt(schedule.xp_count, 0)


func test_lifetime_and_blink() -> void:
	var blink_from: float = Tuning.BAG_LIFETIME - Tuning.BAG_BLINK_TIME
	assert_false(BagRules.expired(Tuning.BAG_LIFETIME - 0.01))
	assert_true(BagRules.expired(Tuning.BAG_LIFETIME))
	assert_true(BagRules.is_shown(0.0))
	assert_true(BagRules.is_shown(blink_from - 0.01))
	var shown: int = 0
	var hidden: int = 0
	var t: float = blink_from
	while t < Tuning.BAG_LIFETIME:
		if BagRules.is_shown(t):
			shown += 1
		else:
			hidden += 1
		t += 0.02
	assert_gt(shown, 0)
	assert_gt(hidden, 0)


func test_pick_point_respects_distance_and_walkability() -> void:
	var rects: Array[Rect2] = _rects()
	var origin: Vector2 = Vector2.ZERO
	var found: int = 0
	for seed_value in 60:
		_rng.seed = seed_value
		var p: Vector2 = BagRules.pick_point(origin, rects, _rng)
		if p == BagRules.NO_POINT:
			continue
		found += 1
		assert_between(p.distance_to(origin), Tuning.BAG_MIN_DIST - 0.001, Tuning.BAG_MAX_DIST + 0.001)
		assert_true(BagRules.is_walkable(p, rects))
	assert_gt(found, 30)


func test_walkable_rejects_blocks_and_outside() -> void:
	var rects: Array[Rect2] = _rects()
	var inside_block: Vector2 = rects[0].get_center()
	assert_false(BagRules.is_walkable(inside_block, rects))
	assert_false(BagRules.is_walkable(Vector2(Tuning.ARENA_SIZE, 0.0), rects))


func test_pick_point_gives_up_when_everything_blocked() -> void:
	var all: Array[Rect2] = [Rect2(-1000.0, -1000.0, 2000.0, 2000.0)]
	assert_eq(BagRules.pick_point(Vector2.ZERO, all, _rng), BagRules.NO_POINT)


func test_schedule_timing_and_cap() -> void:
	var schedule: BagSchedule = BagSchedule.new()
	schedule.start_wave(2)
	assert_false(schedule.tick(Tuning.BAG_FIRST_DELAY - 0.5, false))
	assert_true(schedule.tick(0.6, false))
	schedule.register(BagRules.KIND_MONEY)
	for i in Tuning.BAG_MAX_PER_WAVE - 1:
		assert_false(schedule.tick(Tuning.BAG_INTERVAL - 0.5, false))
		assert_true(schedule.tick(0.6, false))
		schedule.register(BagRules.KIND_XP if i % 2 == 0 else BagRules.KIND_MONEY)
	assert_eq(schedule.spawned(), Tuning.BAG_MAX_PER_WAVE)
	assert_false(schedule.tick(1000.0, false))


func test_schedule_waits_while_bag_active_and_resets_per_wave() -> void:
	var schedule: BagSchedule = BagSchedule.new()
	schedule.start_wave(1)
	assert_false(schedule.tick(Tuning.BAG_FIRST_DELAY + 1.0, true))
	assert_true(schedule.tick(0.1, false))
	schedule.register(BagRules.KIND_XP)
	schedule.start_wave(2)
	assert_eq(schedule.spawned(), 0)
	assert_false(schedule.tick(Tuning.BAG_FIRST_DELAY - 1.0, false))


func test_in_reach_uses_collect_radius() -> void:
	assert_true(BagRules.in_reach(Vector2(Tuning.BAG_COLLECT_RADIUS - 0.01, 0.0), Vector2.ZERO))
	assert_false(BagRules.in_reach(Vector2(Tuning.BAG_COLLECT_RADIUS + 0.01, 0.0), Vector2.ZERO))


func test_arrow_hidden_on_screen_and_clamped_off_screen() -> void:
	var size: Vector2 = Vector2(1280.0, 720.0)
	assert_false(BagRules.arrow_placement(size * 0.5, size, 50.0)["visible"])
	var off: Dictionary = BagRules.arrow_placement(Vector2(3000.0, 360.0), size, 50.0)
	assert_true(off["visible"])
	assert_almost_eq((off["pos"] as Vector2).x, size.x - 50.0, 0.01)
	assert_almost_eq(float(off["angle"]), 0.0, 0.01)


func test_loot_channels_are_separate() -> void:
	var loot: RunLoot = RunLoot.new()
	loot.add_money(30)
	assert_eq(loot.crystals, 30)
	assert_eq(loot.xp, 0)
	var gained: int = loot.add_xp(RunLoot.xp_needed(1))
	assert_eq(gained, 1)
	assert_eq(loot.crystals, 30)
	assert_eq(loot.level, 2)


func test_stats_count_bags_by_kind() -> void:
	var stats: RunStats = RunStats.new()
	stats.on_bag(BagRules.KIND_MONEY, 20)
	stats.on_bag(BagRules.KIND_XP, 25)
	assert_eq(stats.crystals, 20)
	assert_eq(stats.bag_xp, 25)
