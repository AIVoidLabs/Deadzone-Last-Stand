extends GutTest
## StatCaps (saf): tavan tablosu, etkin değer, işe yarar artış, panel metni, kart ve eşya filtresi.

const EN: Dictionary = {"decimal": ".", "percent_prefix": false, "per_second": "/s", "seconds": "s"}
const MS: StringName = StatData.MOVE_SPEED
const DC: StringName = StatData.DASH_COOLDOWN


func _rng(seed_value: int = 3) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


## Verilen statlar tavanda, gerisi sıfır.
func _bonus_of(capped: Array) -> Callable:
	return func(stat: StringName) -> float:
		return StatCaps.CAPS[stat] if capped.has(stat) else 0.0


func test_caps_come_from_tuning() -> void:
	assert_eq(StatCaps.CAPS[MS], Tuning.MOVE_SPEED_BONUS_CAP)
	assert_eq(StatCaps.CAPS[DC], Tuning.DASH_COOLDOWN_CUT_CAP)
	assert_false(StatCaps.has_cap(StatData.DAMAGE))


func test_effective_bonus_clamps_above_cap_only() -> void:
	assert_eq(StatCaps.effective_bonus(MS, Tuning.MOVE_SPEED_BONUS_CAP + 30.0), Tuning.MOVE_SPEED_BONUS_CAP)
	assert_eq(StatCaps.effective_bonus(MS, 10.0), 10.0)
	assert_eq(StatCaps.effective_bonus(MS, -5.0), -5.0)
	assert_eq(StatCaps.effective_bonus(StatData.DAMAGE, 999.0), 999.0)


func test_is_capped_at_and_above_cap() -> void:
	assert_true(StatCaps.is_capped(MS, Tuning.MOVE_SPEED_BONUS_CAP))
	assert_true(StatCaps.is_capped(MS, Tuning.MOVE_SPEED_BONUS_CAP + 1.0))
	assert_false(StatCaps.is_capped(MS, Tuning.MOVE_SPEED_BONUS_CAP - 0.1))
	assert_false(StatCaps.is_capped(StatData.DAMAGE, 1000.0))


func test_useful_gain_is_remaining_room() -> void:
	var cap: float = Tuning.MOVE_SPEED_BONUS_CAP
	assert_eq(StatCaps.useful_gain(MS, 0.0, 4.0), 4.0)
	assert_almost_eq(StatCaps.useful_gain(MS, cap - 1.0, 4.0), 1.0, 0.0001)
	assert_eq(StatCaps.useful_gain(MS, cap, 4.0), 0.0)
	assert_eq(StatCaps.useful_gain(MS, cap + 20.0, 4.0), 0.0)
	assert_eq(StatCaps.useful_gain(StatData.DAMAGE, 500.0, 4.0), 4.0)


func test_player_stats_uses_the_table() -> void:
	var stats: PlayerStats = PlayerStats.new()
	stats.add(MS, Tuning.MOVE_SPEED_BONUS_CAP + 40.0)
	assert_almost_eq(stats.move_speed(), Tuning.PLAYER_SPEED * (1.0 + Tuning.MOVE_SPEED_BONUS_CAP / 100.0), 0.0001)
	assert_almost_eq(PlayerStats.dash_cooldown_for(Tuning.DASH_COOLDOWN_CUT_CAP + 30.0), Tuning.DASH_COOLDOWN * (1.0 - Tuning.DASH_COOLDOWN_CUT_CAP / 100.0), 0.0001)


func test_readout_clamps_and_tags_at_cap() -> void:
	var over: float = Tuning.MOVE_SPEED_BONUS_CAP + 25.0
	var cap_text: String = StatReadout.number(Tuning.MOVE_SPEED_BONUS_CAP, ".") + "%"
	assert_eq(StatReadout.format(MS, over, EN, true), cap_text)
	assert_eq(StatReadout.tagged(MS, over, "MAX", EN, true), cap_text + " MAX")
	assert_eq(StatReadout.tagged(MS, Tuning.MOVE_SPEED_BONUS_CAP, "MAX", EN, true), cap_text + " MAX")


func test_readout_below_cap_has_no_tag() -> void:
	assert_eq(StatReadout.tagged(MS, 10.0, "MAX", EN, true), "10%")
	assert_eq(StatReadout.tagged(StatData.DAMAGE, 500.0, "MAX", EN, true), "500%")


func test_readout_flag_off_is_old_behaviour() -> void:
	var over: float = Tuning.MOVE_SPEED_BONUS_CAP + 25.0
	assert_eq(StatReadout.format(MS, over, EN, false), StatReadout.number(over, ".") + "%")
	assert_eq(StatReadout.tagged(MS, over, "MAX", EN, false), StatReadout.number(over, ".") + "%")


func test_dash_cooldown_tag_at_cap() -> void:
	var text: String = StatReadout.tagged(DC, Tuning.DASH_COOLDOWN_CUT_CAP + 5.0, "MAX", EN, true)
	var seconds: String = StatReadout.number_fine(PlayerStats.dash_cooldown_for(Tuning.DASH_COOLDOWN_CUT_CAP), ".")
	assert_eq(text, seconds + "s MAX")


func test_card_offer_skips_capped_stat() -> void:
	var bonus_of: Callable = _bonus_of([MS])
	for seed_value: int in 40:
		var offer: Array[Dictionary] = CardRules.roll_offer(_rng(seed_value), CardData.CARDS, CardData.TIERS, Tuning.CARD_OFFER_COUNT, 5, 0.0, bonus_of)
		assert_eq(offer.size(), Tuning.CARD_OFFER_COUNT)
		for card: Dictionary in offer:
			assert_ne(card["stat"], MS)


func test_card_offer_without_callable_unchanged() -> void:
	var a: Array[Dictionary] = CardRules.roll_offer(_rng(9), CardData.CARDS, CardData.TIERS, 3, 5, 0.0)
	var none_capped: Callable = func(_stat: StringName) -> float: return 0.0
	var b: Array[Dictionary] = CardRules.roll_offer(_rng(9), CardData.CARDS, CardData.TIERS, 3, 5, 0.0, none_capped)
	assert_eq(a, b)


func test_card_offer_relaxes_when_pool_too_small() -> void:
	var cards: Array = [{"stat": MS, "values": [1.0, 2.0, 3.0, 4.0]}, {"stat": DC, "values": [1.0, 2.0, 3.0, 4.0]}, {"stat": StatData.LUCK, "values": [1.0, 2.0, 3.0, 4.0]}]
	var offer: Array[Dictionary] = CardRules.roll_offer(_rng(), cards, CardData.TIERS, 3, 1, 0.0, _bonus_of([MS, DC]))
	assert_eq(offer.size(), 3, "havuz yetmeyince tavandaki kartlarla tamamlanır")
	assert_eq(offer[0]["stat"], StatData.LUCK, "işe yarayan kart önce")
	var all_capped: Array[Dictionary] = CardRules.roll_offer(_rng(), cards.slice(0, 2), CardData.TIERS, 2, 1, 0.0, _bonus_of([MS, DC]))
	assert_eq(all_capped.size(), 2, "hepsi tavandaysa kilitlenmez")


func test_wasted_item_detection() -> void:
	var bonus_of: Callable = _bonus_of([MS])
	var only_speed: Array = [{"stat": MS, "value": 2.0}]
	var mixed: Array = [{"stat": MS, "value": 3.0}, {"stat": StatData.ARMOR, "value": 1.0}]
	var tradeoff: Array = [{"stat": StatData.ARMOR, "value": 2.0}, {"stat": MS, "value": -3.0}]
	assert_true(StatCaps.is_wasted(only_speed, bonus_of))
	assert_false(StatCaps.is_wasted(mixed, bonus_of))
	assert_false(StatCaps.is_wasted(tradeoff, bonus_of), "eksi etki tavan sayılmaz")
	assert_eq(StatCaps.capped_stats(mixed, bonus_of), [MS] as Array[StringName])
	assert_eq(StatCaps.capped_stats(only_speed, _bonus_of([])), [] as Array[StringName])


func test_item_pool_drops_wasted_items() -> void:
	var bonus_of: Callable = _bonus_of([MS, DC])
	var effects_of: Callable = func(id: StringName) -> Array: return ItemData.get_row(id)["effects"]
	var pool: Array = StatCaps.filter_wasted(ItemData.ids(), effects_of, bonus_of, Tuning.SHOP_OFFER_COUNT)
	assert_false(pool.has(&"sprint_spikes"), "tek etkisi hız olan eşya elenir")
	assert_false(pool.has(&"adrenaline"), "olumlu etkilerinin hepsi (hız, takla) tavanda")
	assert_true(pool.has(&"magnet"), "tavansız stat kalır")
	assert_true(pool.has(&"blitz_core"), "takla mesafesi tavansız: kalır")


func test_item_pool_keeps_mixed_and_relaxes() -> void:
	var bonus_of: Callable = _bonus_of([MS])
	var table: Dictionary = {
		&"s1": [{"stat": MS, "value": 2.0}],
		&"s2": [{"stat": MS, "value": 4.0}],
		&"ok": [{"stat": StatData.ARMOR, "value": 1.0}],
	}
	var effects_of: Callable = func(id: StringName) -> Array: return table[id]
	assert_eq(StatCaps.filter_wasted([&"s1", &"s2", &"ok"], effects_of, bonus_of, 1), [&"ok"])
	var relaxed: Array = StatCaps.filter_wasted([&"s1", &"s2", &"ok"], effects_of, bonus_of, 3)
	assert_eq(relaxed.size(), 3, "havuz boşalmasın diye elenenler geri katılır")
	assert_eq(relaxed[0], &"ok")
	assert_eq(StatCaps.filter_wasted([&"s1", &"s2"], effects_of, bonus_of, 1), [&"s1"])


func test_pause_summary_clamps_and_flags() -> void:
	var bonus_of: Callable = func(stat: StringName) -> float: return Tuning.MOVE_SPEED_BONUS_CAP + 20.0 if stat == MS else 0.0
	var rows: Array[Dictionary] = PauseSummary.gains(bonus_of)
	assert_eq(rows.size(), 1)
	if Tuning.FEATURE_STAT_CAP_HONESTY:
		assert_true(rows[0]["capped"])
		assert_eq(rows[0]["value"], Tuning.MOVE_SPEED_BONUS_CAP)
