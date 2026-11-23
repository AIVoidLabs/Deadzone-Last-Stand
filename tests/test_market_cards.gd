extends GutTest
## MarketCards.weapon_stats (saf): kademe çarpanlarıyla gösterilen sayılar.


func test_weapon_stats_follow_tier_multipliers() -> void:
	var row: Dictionary = WeaponData.get_row(WeaponData.PISTOL)
	var tier_row: Dictionary = WeaponData.tier_row(2)
	var stats: Dictionary = MarketCards.weapon_stats(row, tier_row)
	assert_eq(stats["damage"], roundi(float(row["damage"]) * float(tier_row["damage_mult"])))
	assert_almost_eq(float(stats["rate"]), float(tier_row["rate_mult"]) / float(row["fire_interval"]), 0.001)
	assert_eq(stats["range"], roundi(float(row["max_range"])))


func test_shotgun_has_pellets() -> void:
	var stats: Dictionary = MarketCards.weapon_stats(WeaponData.get_row(WeaponData.SHOTGUN), WeaponData.tier_row(1))
	assert_gt(stats["pellets"], 1)
