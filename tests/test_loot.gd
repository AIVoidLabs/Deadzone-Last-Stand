extends GutTest


func test_xp_needed_grows() -> void:
	var first: int = RunLoot.xp_needed(1)
	assert_eq(first, (1 + Tuning.XP_LEVEL_OFFSET) * (1 + Tuning.XP_LEVEL_OFFSET))
	assert_gt(RunLoot.xp_needed(2), first)


func test_add_counts_crystals_and_levels() -> void:
	var loot: RunLoot = RunLoot.new()
	var need: int = RunLoot.xp_needed(1)
	assert_eq(loot.add(need - 1), 0)
	assert_eq(loot.level, 1)
	assert_eq(loot.add(1), 1, "tam eşikte seviye atlar")
	assert_eq(loot.level, 2)
	assert_eq(loot.xp, 0)
	assert_eq(loot.crystals, need)


func test_big_add_can_gain_several_levels() -> void:
	var loot: RunLoot = RunLoot.new()
	var total: int = RunLoot.xp_needed(1) + RunLoot.xp_needed(2) + 1
	assert_eq(loot.add(total), 2)
	assert_eq(loot.level, 3)
	assert_eq(loot.xp, 1)
	assert_almost_eq(loot.level_progress(), 1.0 / RunLoot.xp_needed(3), 0.0001)


func test_spend_keeps_xp() -> void:
	var loot: RunLoot = RunLoot.new()
	loot.add(10)
	assert_false(loot.spend(11))
	assert_eq(loot.crystals, 10)
	assert_true(loot.spend(4))
	assert_eq(loot.crystals, 6)
	assert_eq(loot.xp, 10, "harcamak XP'yi düşürmez")


func test_pull_accelerates_and_caps() -> void:
	var s: float = PickupRules.pull_speed(Tuning.PICKUP_PULL_START_SPEED, Tuning.PICKUP_PULL_ACCEL, Tuning.PICKUP_PULL_MAX_SPEED, 0.1)
	assert_gt(s, Tuning.PICKUP_PULL_START_SPEED)
	assert_eq(PickupRules.pull_speed(s, Tuning.PICKUP_PULL_ACCEL, Tuning.PICKUP_PULL_MAX_SPEED, 100.0), Tuning.PICKUP_PULL_MAX_SPEED)


func test_pull_step_never_overshoots() -> void:
	var p: Vector2 = PickupRules.pull_step(Vector2.ZERO, Vector2(1.0, 0.0), 100.0, 1.0)
	assert_eq(p, Vector2(1.0, 0.0))
	var q: Vector2 = PickupRules.pull_step(Vector2.ZERO, Vector2(10.0, 0.0), 2.0, 0.5)
	assert_almost_eq(q.x, 1.0, 0.0001)


func test_hop_is_parabola() -> void:
	var d: float = Tuning.PICKUP_HOP_TIME
	var h: float = Tuning.PICKUP_HOP_HEIGHT
	assert_almost_eq(PickupRules.hop_height(0.0, d, h), 0.0, 0.0001)
	assert_almost_eq(PickupRules.hop_height(d * 0.5, d, h), h, 0.0001)
	assert_almost_eq(PickupRules.hop_height(d, d, h), 0.0, 0.0001)


func test_magnet_and_value_scale() -> void:
	var r: float = Tuning.PICKUP_MAGNET_RADIUS
	assert_true(PickupRules.in_magnet(Vector2(r - 0.01, 0.0), Vector2.ZERO, r))
	assert_false(PickupRules.in_magnet(Vector2(r + 0.01, 0.0), Vector2.ZERO, r))
	assert_eq(PickupRules.value_scale(1, Tuning.PICKUP_VALUE_SCALE, Tuning.PICKUP_MAX_SCALE), 1.0)
	assert_gt(PickupRules.value_scale(3, Tuning.PICKUP_VALUE_SCALE, Tuning.PICKUP_MAX_SCALE), 1.0)
	assert_eq(PickupRules.value_scale(10000, Tuning.PICKUP_VALUE_SCALE, Tuning.PICKUP_MAX_SCALE), Tuning.PICKUP_MAX_SCALE)
