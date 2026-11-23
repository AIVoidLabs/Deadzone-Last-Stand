extends GutTest


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_stats_start_at_tuning_base() -> void:
	var stats: PlayerStats = PlayerStats.new()
	assert_eq(stats.max_hp(), Tuning.PLAYER_MAX_HP)
	assert_eq(stats.move_speed(), Tuning.PLAYER_SPEED)
	assert_eq(stats.armor(), Tuning.PLAYER_ARMOR)
	assert_eq(stats.dash_cooldown(), Tuning.DASH_COOLDOWN)
	assert_eq(stats.pickup_radius(), Tuning.PICKUP_MAGNET_RADIUS)
	assert_eq(stats.regen_per_second(), 0.0)
	assert_eq(stats.weapon_damage(10.0), 10.0)


func test_percent_stats_multiply() -> void:
	var stats: PlayerStats = PlayerStats.new()
	stats.add(StatData.DAMAGE, 20.0)
	stats.add(StatData.DAMAGE, 5.0)
	assert_almost_eq(stats.weapon_damage(10.0), 12.5, 0.0001)
	stats.add(StatData.FIRE_RATE, 25.0)
	assert_almost_eq(stats.fire_interval(1.0), 0.8, 0.0001, "atış hızı aralığı kısaltır")
	stats.add(StatData.RANGE, 10.0)
	assert_almost_eq(stats.weapon_range(10.0), 11.0, 0.0001)
	stats.add(StatData.MOVE_SPEED, -500.0)
	assert_almost_eq(stats.move_speed(), Tuning.PLAYER_SPEED * Tuning.MIN_STAT_MULTIPLIER, 0.0001, "çarpan alt sınırda")


func test_flat_and_capped_stats() -> void:
	var stats: PlayerStats = PlayerStats.new()
	stats.add(StatData.MAX_HP, 20.0)
	stats.add(StatData.ARMOR, 2.0)
	stats.add(StatData.HP_REGEN, 4.0)
	assert_eq(stats.max_hp(), Tuning.PLAYER_MAX_HP + 20.0)
	assert_eq(stats.armor(), Tuning.PLAYER_ARMOR + 2.0)
	assert_almost_eq(stats.regen_per_second(), 4.0 * Tuning.HP_REGEN_PER_POINT, 0.0001)
	stats.add(StatData.DASH_COOLDOWN, 1000.0)
	assert_almost_eq(stats.dash_cooldown(), Tuning.DASH_COOLDOWN * (1.0 - Tuning.DASH_COOLDOWN_CUT_CAP / 100.0), 0.0001)


func test_max_hp_has_floor() -> void:
	var stats: PlayerStats = PlayerStats.new()
	stats.add(StatData.MAX_HP, -Tuning.PLAYER_MAX_HP * 2.0)
	assert_eq(stats.max_hp(), Tuning.PLAYER_MIN_HP)


func test_player_health_stays_equal_to_stats_max_hp() -> void:
	var player: Player = Player.new()
	for amount: float in [-Tuning.PLAYER_MAX_HP, -15.0, 40.0, -Tuning.PLAYER_MAX_HP, 25.0]:
		player.stats.add(StatData.MAX_HP, amount)
		assert_eq(player.health.maximum, player.stats.max_hp(), "amount %s" % amount)
	player.free()


func test_changed_signal_carries_amount() -> void:
	var stats: PlayerStats = PlayerStats.new()
	watch_signals(stats)
	stats.add(StatData.LUCK, 10.0)
	assert_signal_emitted_with_parameters(stats, "changed", [StatData.LUCK, 10.0])


func test_health_raise_maximum_heals_added_amount() -> void:
	var health: Health = Health.new(100.0)
	health.take_damage(50.0)
	health.raise_maximum(20.0)
	assert_eq(health.maximum, 120.0)
	assert_eq(health.current, 70.0)


func test_loot_tracks_pending_levels() -> void:
	var loot: RunLoot = RunLoot.new()
	loot.add(RunLoot.xp_needed(1) + RunLoot.xp_needed(2))
	assert_eq(loot.pending_levels, 2)


func test_every_card_stat_exists_and_has_value_per_tier() -> void:
	for card: Dictionary in CardData.CARDS:
		assert_true(StatData.TABLE.has(card["stat"]), "bilinmeyen istatistik: %s" % card["stat"])
		var values: Array = card["values"]
		assert_eq(values.size(), CardData.TIERS.size())
		for t in range(1, values.size()):
			assert_gte(values[t], values[t - 1], "üst kademe daha çok verir")


func test_tier_chance_grows_with_level_and_luck_and_caps() -> void:
	var rare: Dictionary = CardData.TIERS[1]
	assert_gt(CardRules.tier_chance(rare, 5, 0.0), CardRules.tier_chance(rare, 1, 0.0))
	assert_gt(CardRules.tier_chance(rare, 5, 50.0), CardRules.tier_chance(rare, 5, 0.0))
	assert_eq(CardRules.tier_chance(rare, 1000, 0.0), rare["max_chance"])
	var legendary: Dictionary = CardData.TIERS[3]
	assert_eq(CardRules.tier_chance(legendary, legendary["from_level"] - 1, 100.0), 0.0, "erken seviyede çıkmaz")


func test_first_level_offer_is_mostly_common() -> void:
	var rng: RandomNumberGenerator = _rng(5)
	var counts: Array[int] = [0, 0, 0, 0]
	for _i in 2000:
		counts[CardRules.roll_tier(rng, CardData.TIERS, 1, 0.0)] += 1
	assert_eq(counts[2] + counts[3], 0, "1. seviyede destansı/efsanevi yok")
	assert_gt(counts[0], counts[1])


func test_offer_has_distinct_stats_with_tier_values() -> void:
	var rng: RandomNumberGenerator = _rng(9)
	for _i in 200:
		var offer: Array[Dictionary] = CardRules.roll_offer(rng, CardData.CARDS, CardData.TIERS, Tuning.CARD_OFFER_COUNT, 8, 30.0)
		assert_eq(offer.size(), Tuning.CARD_OFFER_COUNT)
		var seen: Dictionary = {}
		for card: Dictionary in offer:
			assert_false(seen.has(card["stat"]), "aynı istatistik iki kez")
			seen[card["stat"]] = true
			var row: Dictionary = CardData.CARDS.filter(func(c: Dictionary) -> bool: return c["stat"] == card["stat"])[0]
			assert_eq(card["value"], (row["values"] as Array)[card["tier"]])


func test_describe_formats() -> void:
	assert_eq(StatData.describe(StatData.DAMAGE, 12.0), "+%12 hasar")
	assert_eq(StatData.describe(StatData.MAX_HP, 10.0), "+10 can")
	assert_eq(StatData.describe(StatData.DASH_COOLDOWN, 7.5), "-%7,5 takla bekleme")
	assert_eq(StatData.short_value(StatData.DAMAGE, 12.0), "+%12")
	assert_eq(StatData.short_value(StatData.ARMOR, 2.0), "+2")
