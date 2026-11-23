extends GutTest


func test_keep_prompt_only_for_display_mode_and_resolution() -> void:
	assert_true(SettingsUiRules.needs_keep_prompt(&"display/mode"))
	assert_true(SettingsUiRules.needs_keep_prompt(&"display/resolution"))
	assert_false(SettingsUiRules.needs_keep_prompt(&"display/vsync"))
	assert_false(SettingsUiRules.needs_keep_prompt(&"audio/master"))


func test_countdown_rounds_up_and_expires() -> void:
	assert_eq(SettingsUiRules.seconds_left(0.0), int(SettingsUiRules.KEEP_SECONDS))
	assert_eq(SettingsUiRules.seconds_left(0.2), int(SettingsUiRules.KEEP_SECONDS))
	assert_eq(SettingsUiRules.seconds_left(SettingsUiRules.KEEP_SECONDS - 0.5), 1)
	assert_eq(SettingsUiRules.seconds_left(SettingsUiRules.KEEP_SECONDS + 3.0), 0)
	assert_false(SettingsUiRules.expired(SettingsUiRules.KEEP_SECONDS - 0.01))
	assert_true(SettingsUiRules.expired(SettingsUiRules.KEEP_SECONDS))


func test_resolution_only_in_windowed_mode() -> void:
	assert_true(SettingsUiRules.resolution_editable(&"windowed"))
	assert_false(SettingsUiRules.resolution_editable(&"fullscreen"))
	assert_false(SettingsUiRules.resolution_editable(&"borderless"))


func test_tab_step_wraps() -> void:
	var count: int = SettingsUiRules.TABS.size()
	assert_eq(SettingsUiRules.step_tab(0, -1), count - 1)
	assert_eq(SettingsUiRules.step_tab(count - 1, 1), 0)
	assert_eq(SettingsUiRules.step_tab(1, 1), 2)


func test_choice_key_and_key_label() -> void:
	assert_eq(SettingsUiRules.choice_key(&"display/mode", &"windowed"), &"set.val.mode.windowed")
	assert_eq(SettingsUiRules.key_label(KEY_W), "W")
	assert_eq(SettingsUiRules.key_label(KEY_SPACE), "SPACE")


func test_every_setting_choice_has_texts() -> void:
	for key: StringName in [&"display/mode", &"graphics/quality", &"game/language"]:
		for value: Variant in SettingsSchema.choices_of(key):
			assert_true(Loc.has(SettingsUiRules.choice_key(key, value)), "metin yok: %s %s" % [key, value])
