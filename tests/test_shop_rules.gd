extends GutTest

const ITEMS: Array = [&"a", &"b", &"c", &"d", &"e", &"f"]
const WEAPONS: Array = [&"pistol", &"shotgun"]


func _rng(seed_value: int = 7) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _roll(chance: float, previous: Array[Dictionary] = [], seed_value: int = 7) -> Array[Dictionary]:
	return ShopRules.roll_offer(_rng(seed_value), ITEMS, WEAPONS, 4, chance, previous)


func test_price_grows_with_wave() -> void:
	assert_eq(ShopRules.price(20, 0, 0.15), 20)
	assert_eq(ShopRules.price(20, 4, 0.15), 32)
	assert_eq(ShopRules.price(1, 0, 0.0), 1)


func test_reroll_cost_rises_per_reroll() -> void:
	assert_eq(ShopRules.reroll_cost(0, 5, 2), 5)
	assert_eq(ShopRules.reroll_cost(3, 5, 2), 11)


func test_sell_value_doubles_per_tier() -> void:
	assert_eq(ShopRules.sell_value(30, 1, 0.5), 15)
	assert_eq(ShopRules.sell_value(30, 3, 0.5), 60)


func test_offer_has_requested_count_without_duplicates() -> void:
	for seed_value: int in 20:
		var offer: Array[Dictionary] = _roll(0.5, [], seed_value)
		assert_eq(offer.size(), 4)
		var seen: Dictionary = {}
		for entry: Dictionary in offer:
			var key: String = "%s:%s" % [entry["kind"], entry["id"]]
			assert_false(seen.has(key), "tekrar: %s" % key)
			seen[key] = true


func test_weapon_chance_extremes() -> void:
	for entry: Dictionary in _roll(0.0):
		assert_eq(entry["kind"], ShopRules.ITEM)
	var all_weapons: Array[Dictionary] = ShopRules.roll_offer(_rng(), ITEMS, WEAPONS, 2, 1.0, [])
	for entry: Dictionary in all_weapons:
		assert_eq(entry["kind"], ShopRules.WEAPON)


func test_same_seed_same_offer() -> void:
	assert_eq(_roll(0.3, [], 5), _roll(0.3, [], 5))


func test_locked_unsold_entries_are_kept_in_front() -> void:
	var previous: Array[Dictionary] = [
		{"kind": ShopRules.ITEM, "id": &"e", "locked": true, "sold": false},
		{"kind": ShopRules.ITEM, "id": &"a", "locked": false, "sold": false},
		{"kind": ShopRules.ITEM, "id": &"b", "locked": true, "sold": true},
	]
	var offer: Array[Dictionary] = _roll(0.0, previous)
	assert_eq(offer[0]["id"], &"e")
	assert_true(offer[0]["locked"])
	assert_eq(offer.size(), 4)
	for entry: Dictionary in offer.slice(1):
		assert_false(entry["locked"])


func test_small_pool_does_not_hang() -> void:
	var offer: Array[Dictionary] = ShopRules.roll_offer(_rng(), [&"a"], [], 4, 0.3, [])
	assert_eq(offer.size(), 1)


func test_item_table_is_consistent() -> void:
	for id: StringName in ItemData.ids():
		var row: Dictionary = ItemData.get_row(id)
		assert_gt(row["price"], 0)
		assert_false((row["effects"] as Array).is_empty())
		for effect: Dictionary in row["effects"]:
			assert_true(StatData.TABLE.has(effect["stat"]), "%s: bilinmeyen istatistik" % id)


func test_weighted_weapon_pick_prefers_heavy_weights() -> void:
	var counts: Dictionary = {&"w1": 0, &"w2": 0}
	var rng: RandomNumberGenerator = _rng(3)
	for _i in 300:
		var offer: Array[Dictionary] = ShopRules.roll_offer(rng, [], [&"w1", &"w2"], 1, 1.0, [], {&"w1": 9.0, &"w2": 1.0})
		counts[offer[0]["id"]] += 1
	assert_gt(counts[&"w1"], counts[&"w2"] * 3)


func test_shop_pool_unlocks_by_wave() -> void:
	assert_true(WeaponData.shop_pool(1).has(WeaponData.KNIFE))
	assert_false(WeaponData.shop_pool(1).has(WeaponData.LIGHTSABER))
	assert_true(WeaponData.shop_pool(99).has(WeaponData.LIGHTSABER))
