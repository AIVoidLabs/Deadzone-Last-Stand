extends GutTest
## WeaponReadout (saf): birleşme önizlemesi yalnız değişen değerleri, ipucu satırları silaha özgü alanları gösterir.


func test_changes_lists_only_differing_stats() -> void:
	var before: Dictionary = WeaponReadout.stats(WeaponData.PISTOL, 1)
	var after: Dictionary = WeaponReadout.stats(WeaponData.PISTOL, 2)
	var list: Array[Dictionary] = WeaponReadout.changes(before, after)
	var stats: Array = []
	for change: Dictionary in list:
		stats.append(change["stat"])
	assert_eq(stats, [WeaponReadout.STAT_DAMAGE, WeaponReadout.STAT_RATE], "menzil kademeyle değişmez")
	assert_eq(list[0]["before"], before["damage"])
	assert_eq(list[0]["after"], after["damage"])


func test_changes_empty_for_same_tier() -> void:
	var s: Dictionary = WeaponReadout.stats(WeaponData.SHOTGUN, 2)
	assert_eq(WeaponReadout.changes(s, s).size(), 0)


func test_rate_gain_percent_matches_tier_multipliers() -> void:
	var expected: int = roundi((float(WeaponData.tier_row(2)["rate_mult"]) / float(WeaponData.tier_row(1)["rate_mult"]) - 1.0) * 100.0)
	var s1: Dictionary = WeaponReadout.stats(WeaponData.SMG, 1)
	var s2: Dictionary = WeaponReadout.stats(WeaponData.SMG, 2)
	assert_eq(WeaponReadout.rate_gain_percent(float(s1["rate"]), float(s2["rate"])), expected)
	assert_eq(WeaponReadout.rate_gain_percent(0.0, 1.0), 0)


func test_percent_text_prefix() -> void:
	assert_eq(WeaponReadout.percent_text(12, true), "%12")
	assert_eq(WeaponReadout.percent_text(12, false), "12%")


func test_merge_lines_show_before_and_after() -> void:
	Loc.set_language(&"tr")
	var lines: Array[String] = WeaponReadout.merge_lines(WeaponData.PISTOL, 1, 2)
	assert_eq(lines.size(), 2)
	var s1: Dictionary = WeaponReadout.stats(WeaponData.PISTOL, 1)
	var s2: Dictionary = WeaponReadout.stats(WeaponData.PISTOL, 2)
	assert_string_contains(lines[0], str(s1["damage"]))
	assert_string_contains(lines[0], str(s2["damage"]))
	assert_string_contains(lines[1], "+")


func test_merge_lines_pellets_variant_shows_count() -> void:
	Loc.set_language(&"tr")
	var lines: Array[String] = WeaponReadout.merge_lines(WeaponData.SHOTGUN, 1, 2)
	var pellets: int = int(WeaponReadout.stats(WeaponData.SHOTGUN, 1)["pellets"])
	assert_string_contains(lines[0], "x%d" % pellets)


func test_tooltip_lines_have_core_stats_and_specials() -> void:
	Loc.set_language(&"en")
	var pistol: Array[String] = WeaponReadout.tooltip_lines(WeaponData.PISTOL, 1)
	assert_eq(pistol.size(), 3)
	var burner: Array[String] = WeaponReadout.tooltip_lines(WeaponData.FLAME_SWORD, 1)
	assert_gt(burner.size(), 3, "yay + yanma satırı eklenir")
	Loc.set_language(&"tr")


func test_every_weapon_has_tooltip_lines_in_both_languages() -> void:
	for lang: StringName in [&"tr", &"en"]:
		Loc.set_language(lang)
		for id: StringName in WeaponData.ids():
			for tier: int in WeaponData.max_tier():
				assert_gte(WeaponReadout.tooltip_lines(id, tier + 1).size(), 3, "%s %s K%d" % [lang, id, tier + 1])
	Loc.set_language(&"tr")


func test_tooltip_place_stays_inside_view() -> void:
	var view: Vector2 = Vector2(800.0, 600.0)
	var tip: Vector2 = Vector2(200.0, 120.0)
	# Sol alt köşedeki hedef: üstte, soldan taşmadan.
	var pos: Vector2 = WeaponTooltip.place(Rect2(Vector2(0.0, 540.0), Vector2(40.0, 40.0)), tip, view)
	assert_gte(pos.x, WeaponTooltip.EDGE)
	assert_lt(pos.y, 540.0)
	# Üst kenardaki hedef: panel altta açılır.
	pos = WeaponTooltip.place(Rect2(Vector2(380.0, 4.0), Vector2(40.0, 40.0)), tip, view)
	assert_gt(pos.y, 44.0)
	# Sağ alt köşe: sağdan ve alttan taşmaz.
	pos = WeaponTooltip.place(Rect2(Vector2(780.0, 580.0), Vector2(40.0, 40.0)), tip, view)
	assert_lte(pos.x + tip.x, view.x - WeaponTooltip.EDGE + 0.01)
	assert_lte(pos.y + tip.y, view.y - WeaponTooltip.EDGE + 0.01)


func test_market_card_merge_preview_replaces_full_stats() -> void:
	Loc.set_language(&"tr")
	var entry: Dictionary = {"kind": ShopRules.WEAPON, "id": WeaponData.PISTOL, "state": "ok", "price": 10, "locked": false, "merged": true, "tier": 2}
	var lines: Array = MarketCards.card_data(entry, 0)["lines"]
	assert_eq(lines.size(), 1 + WeaponReadout.merge_lines(WeaponData.PISTOL, 1, 2).size())
	var fresh: Dictionary = entry.duplicate()
	fresh["merged"] = false
	fresh["tier"] = 1
	assert_eq((MarketCards.card_data(fresh, 0)["lines"] as Array).size(), 3, "ilk alım: tam sayılar")
