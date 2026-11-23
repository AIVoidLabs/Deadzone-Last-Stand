class_name SettingsTabGame
extends RefCounted
## OYUN sekmesi: dil, kamera, sarsıntı, kan, kızarma, HUD ölçeği, odak kaybı.


static func keys() -> Array[StringName]:
	return [&"game"]


static func build(menu: SettingsMenu, list: VBoxContainer) -> void:
	if Tuning.FEATURE_LANGUAGE:
		SettingsRows.choice(menu, list, &"game/language", func(v: Variant) -> String: return Loc.t(SettingsUiRules.choice_key(&"game/language", v)))
	SettingsRows.toggle(menu, list, &"game/dynamic_camera")
	SettingsRows.slider(menu, list, &"game/screen_shake")
	SettingsRows.toggle(menu, list, &"game/blood")
	SettingsRows.slider(menu, list, &"game/hurt_flash")
	SettingsRows.slider(menu, list, &"game/hud_scale")
	SettingsRows.toggle(menu, list, &"game/pause_on_focus_loss")
