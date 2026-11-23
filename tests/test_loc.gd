extends GutTest

const KEY_PATTERN: String = "%s"


func after_each() -> void:
	Loc.set_language(&"tr")


func _placeholders(text: String) -> int:
	return text.count("%s") + text.count("%d")


func test_every_key_has_both_languages_with_equal_placeholders() -> void:
	var table: Dictionary = Loc.table()
	assert_gt(table.size(), 0)
	for key: StringName in table:
		var row: Dictionary = table[key]
		for lang: StringName in Loc.LANGS:
			assert_true(row.has(lang) and not String(row[lang]).is_empty(), "%s: %s boş" % [key, lang])
		assert_eq(_placeholders(row["tr"]), _placeholders(row["en"]), "%s: yer tutucu sayısı farklı" % key)


func test_language_switch_and_fallback() -> void:
	Loc.set_language(&"en")
	assert_eq(Loc.t(&"common.back"), "BACK")
	Loc.set_language(&"tr")
	assert_eq(Loc.t(&"common.back"), "GERİ")
	Loc.set_language(&"xx")
	assert_eq(Loc.language, &"tr", "bilinmeyen dil Türkçeye düşer")
	assert_eq(Loc.t(&"yok.anahtar"), "yok.anahtar", "eksik anahtar kendisi")
	assert_eq(Loc.t_in(&"en", &"common.on"), "ON")
	assert_eq(Loc.language, &"tr", "t_in dili değiştirmez")


func test_args_are_formatted() -> void:
	assert_eq(Loc.t(&"common.minutes_seconds", [3, 5]), "3 dk 5 sn")
	Loc.set_language(&"en")
	assert_eq(Loc.t(&"common.minutes_seconds", [3, 5]), "3m 5s")
	assert_eq(Loc.clock(125.0), "2:05")


func test_content_ids_have_names() -> void:
	for stat: StringName in StatData.TABLE:
		for key: String in ["stat.", "card."]:
			assert_true(Loc.has(StringName(key + stat)), "eksik: %s%s" % [key, stat])
		assert_true(Loc.has(StringName("stat." + stat + ".format")))
		assert_true(Loc.has(StringName("stat." + stat + ".short")))
		assert_true(Loc.has(StringName("cat." + StatData.category_of(stat))), "kategori adı: %s" % stat)
	for id: StringName in ItemData.ids():
		assert_true(Loc.has(StringName("item." + id)), "eşya adı: %s" % id)
	for id: StringName in WeaponData.TABLE:
		assert_true(Loc.has(StringName("weapon." + id)), "silah adı: %s" % id)
	for i: int in CardData.TIERS.size():
		assert_true(Loc.has(StringName("tier.%d" % i)))
	for id: StringName in [EnemyData.WALKER, EnemyData.RUNNER, EnemyData.TANK, EnemyData.JUMPER, EnemyData.TONGUE, EnemyData.ARMORED, EnemyData.SCREAMER, EnemyData.SPITTER, EnemyData.THROWER, EnemyData.BLOATER, EnemyData.BOSS_HEAP]:
		assert_true(Loc.has(StringName("enemy." + id)), "düşman adı: %s" % id)


func test_card_titles_from_brief() -> void:
	assert_eq(Loc.card_title(&"damage"), "KEMİK KIRAN")
	assert_eq(Loc.card_title(&"luck"), "ŞEYTAN TÜYÜ")
	Loc.set_language(&"en")
	assert_eq(Loc.card_title(&"damage"), "BONEBREAKER")
	assert_eq(Loc.enemy_name(EnemyData.BOSS_HEAP), "THE HEAP")


func test_stat_describe_follows_language() -> void:
	assert_eq(StatData.describe(&"damage", 8.0), "+%8 hasar")
	assert_eq(StatData.short_value(&"max_hp", 10.0), "+10")
	assert_eq(StatData.describe(&"max_hp", -5.0), "-5 can")
	assert_eq(StatData.describe(&"dash_cooldown", 12.0), "-%12 takla bekleme")
	assert_eq(StatData.describe(&"dash_cooldown", -12.0), "+%12 takla bekleme")
	assert_eq(StatData.describe(&"move_speed", -3.0), "-%3 hareket hızı")
	assert_eq(StatData.describe(&"damage", 7.5), "+%7,5 hasar", "ondalık ayracı virgül")
	assert_eq(StatData.short_value(&"damage", 12.0), "+%12")
	Loc.set_language(&"en")
	assert_eq(StatData.describe(&"damage", 8.0), "+8% damage")
	assert_eq(StatData.describe(&"dash_cooldown", 12.0), "-12% dash cooldown", "İngilizcede Dash kalır")
	assert_eq(StatData.describe(&"damage", 7.5), "+7.5% damage")
	assert_eq(StatData.display_name(&"armor"), "Armor")
