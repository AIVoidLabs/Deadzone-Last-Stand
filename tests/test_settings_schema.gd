extends GutTest


func test_every_key_has_valid_default() -> void:
	var defaults: Dictionary = SettingsSchema.defaults()
	for key: StringName in SettingsSchema.keys():
		assert_true(defaults.has(key), "varsayılan yok: %s" % key)
		var again: Variant = SettingsSchema.sanitize(key, defaults[key])
		assert_eq(again, defaults[key], "varsayılan kendi kendine geçerli olmalı: %s" % key)


func test_sections_cover_all_keys() -> void:
	var count: int = 0
	for section: StringName in SettingsSchema.SECTIONS:
		count += SettingsSchema.keys_in(section).size()
	assert_eq(count, SettingsSchema.keys().size())


func test_float_is_clamped_and_snapped() -> void:
	assert_eq(SettingsSchema.sanitize(&"display/brightness", 9.0), 1.5)
	assert_eq(SettingsSchema.sanitize(&"display/brightness", -3), 0.7)
	assert_almost_eq(float(SettingsSchema.sanitize(&"audio/master", 0.52)), 0.5, 0.0001, "adım 0.05")
	assert_eq(SettingsSchema.sanitize(&"audio/master", "yüksek"), 1.0, "tip bozuksa varsayılan")
	assert_eq(SettingsSchema.sanitize(&"audio/master", "yüksek", 0.4), 0.4, "tip bozuksa fallback")


func test_choice_accepts_string_and_rejects_unknown() -> void:
	assert_eq(SettingsSchema.sanitize(&"display/mode", "windowed"), &"windowed")
	assert_eq(SettingsSchema.sanitize(&"display/mode", "yok"), &"fullscreen")
	assert_eq(SettingsSchema.sanitize(&"display/fps_cap", 144), 144)
	assert_eq(SettingsSchema.sanitize(&"display/fps_cap", 77), 0)
	assert_eq(SettingsSchema.sanitize(&"game/language", &"en"), &"en")


func test_bool_and_unknown_key() -> void:
	assert_eq(SettingsSchema.sanitize(&"game/blood", false), false)
	assert_eq(SettingsSchema.sanitize(&"game/blood", 0), false)
	assert_eq(SettingsSchema.sanitize(&"game/blood", "evet"), true)
	assert_null(SettingsSchema.sanitize(&"yok/yok", 1))


func test_platform_and_feature_defaults() -> void:
	assert_eq(SettingsSchema.defaults(true, false)[&"graphics/quality"], &"high")
	assert_eq(SettingsSchema.defaults(true, true)[&"graphics/quality"], &"low", "web varsayılanı düşük")
	assert_eq(SettingsSchema.defaults(false, false)[&"display/mode"], &"windowed")


func test_resolve_repairs_raw_values() -> void:
	var base: Dictionary = SettingsSchema.defaults()
	var out: Dictionary = SettingsSchema.resolve({&"audio/sfx": 5.0, &"display/mode": "saçma", &"game/blood": false}, base)
	assert_eq(out[&"audio/sfx"], 1.0)
	assert_eq(out[&"display/mode"], base[&"display/mode"])
	assert_eq(out[&"game/blood"], false)
	assert_eq(out.size(), SettingsSchema.keys().size())


func test_bindings_sanitize() -> void:
	var good: Dictionary = SettingsSchema.sanitize(&"input/bindings", {"dash": KEY_SHIFT, "move_up": KEY_UP})
	assert_eq(good[&"dash"], KEY_SHIFT)
	assert_eq(good[&"move_up"], KEY_UP)
	assert_eq(good[&"move_left"], KEY_A, "eksik eylem varsayılan")
	var clash: Dictionary = SettingsSchema.sanitize(&"input/bindings", {"dash": KEY_W})
	assert_eq(clash, SettingsSchema.DEFAULT_BINDINGS, "çakışma varsayılana döner")
	var forbidden: Dictionary = SettingsSchema.sanitize(&"input/bindings", {"dash": KEY_ESCAPE})
	assert_eq(forbidden[&"dash"], KEY_SPACE, "Esc atanamaz")
	assert_eq(SettingsSchema.sanitize(&"input/bindings", 5), SettingsSchema.DEFAULT_BINDINGS)


func test_rebind_swaps_on_conflict() -> void:
	var start: Dictionary = SettingsSchema.DEFAULT_BINDINGS.duplicate()
	var result: Dictionary = SettingsSchema.rebind(start, &"dash", KEY_W)
	assert_true(result["ok"])
	assert_eq(result["swapped"], &"move_up")
	assert_eq(result["bindings"][&"dash"], KEY_W)
	assert_eq(result["bindings"][&"move_up"], KEY_SPACE, "takas")
	assert_false(SettingsSchema.rebind(start, &"dash", KEY_F5)["ok"], "debug tuşu atanamaz")
	assert_false(SettingsSchema.rebind(start, &"pause", KEY_Q)["ok"], "bilinmeyen eylem")


func test_parse_resolution_and_language() -> void:
	assert_eq(SettingsSchema.parse_resolution("1920x1080"), Vector2i(1920, 1080))
	assert_eq(SettingsSchema.parse_resolution("saçma"), Vector2i(1600, 900))
	assert_eq(SettingsSchema.language_for_locale("tr_TR"), &"tr")
	assert_eq(SettingsSchema.language_for_locale("en_US"), &"en")
	assert_eq(SettingsSchema.language_for_locale("de"), &"en")


func test_measurement_args() -> void:
	var cap: PackedStringArray = PackedStringArray(["--capture=build/x.png", "--god"])
	var none: PackedStringArray = PackedStringArray()
	assert_true(SettingsSchema.skips_user_settings(cap, none, true))
	assert_false(SettingsSchema.skips_user_settings(cap, none, false), "yayın yapıda argüman yok sayılır")
	assert_false(SettingsSchema.skips_user_settings(PackedStringArray(["--god"]), none, true), "--god ölçüm değil")
	assert_true(SettingsSchema.skips_user_settings(none, PackedStringArray(["-s", "res://addons/gut/gut_cmdln.gd"]), true))
	assert_true(SettingsSchema.skips_user_settings(PackedStringArray(["--arena"]), none, true))
	assert_true(SettingsSchema.skips_user_settings(PackedStringArray(["--bench"]), none, true))


func test_menu_skipping_args() -> void:
	var none: PackedStringArray = PackedStringArray()
	assert_false(SettingsSchema.skips_menu(none, true), "argümansız menü açılır")
	assert_true(SettingsSchema.skips_menu(PackedStringArray(["--god"]), true))
	assert_true(SettingsSchema.skips_menu(PackedStringArray(["--wave=3"]), true))
	assert_true(SettingsSchema.skips_menu(PackedStringArray(["--autoplay"]), true))
	assert_false(SettingsSchema.skips_menu(PackedStringArray(["--wave=3"]), false), "yayın yapıda yok sayılır")
