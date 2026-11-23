class_name SettingsTabDisplay
extends RefCounted
## GÖRÜNTÜ sekmesi: ekran modu, çözünürlük, eşitleme, kare sınırı, ölçek, parlaklık, kalite, FPS.

const QUALITY_NOTE_SIZE: int = 16


static func keys() -> Array[StringName]:
	return [&"display", &"graphics"]


static func build(menu: SettingsMenu, list: VBoxContainer) -> void:
	SettingsRows.choice(menu, list, &"display/mode", func(v: Variant) -> String: return Loc.t(SettingsUiRules.choice_key(&"display/mode", v)))
	var res: ChoiceRow = SettingsRows.choice(menu, list, &"display/resolution", func(v: Variant) -> String: return str(v).replace("x", " × "))
	var locked: Label = menu.add_note(list, Loc.t(&"set.resolution.locked"), UiPalette.AMBER)
	menu.add_sync(func() -> void: _lock_resolution(res, locked))
	_lock_resolution(res, locked)
	SettingsRows.toggle(menu, list, &"display/vsync")
	SettingsRows.choice(menu, list, &"display/fps_cap", func(v: Variant) -> String: return Loc.t(&"set.val.fps_cap.0") if int(v) == 0 else str(v))
	SettingsRows.slider(menu, list, &"display/render_scale")
	SettingsRows.slider(menu, list, &"display/brightness")
	SettingsRows.choice(menu, list, &"graphics/quality", func(v: Variant) -> String: return Loc.t(SettingsUiRules.choice_key(&"graphics/quality", v)))
	var note: Label = menu.add_note(list, "", UiPalette.ASH)
	menu.add_sync(func() -> void: note.text = quality_text(Settings.get_value(&"graphics/quality")))
	note.text = quality_text(Settings.get_value(&"graphics/quality"))
	SettingsRows.toggle(menu, list, &"display/show_fps")


## Çözünürlük yalnız pencerede etkin: kilitliyken soluk, odaksız, altında uyarı.
static func _lock_resolution(row: ChoiceRow, note: Label) -> void:
	var editable: bool = SettingsUiRules.resolution_editable(Settings.get_value(&"display/mode"))
	row.modulate.a = 1.0 if editable else 0.4
	row.focus_mode = Control.FOCUS_ALL if editable else Control.FOCUS_NONE
	row.mouse_filter = Control.MOUSE_FILTER_STOP if editable else Control.MOUSE_FILTER_IGNORE
	note.visible = not editable


## Profilin kısa açıklaması (en çok zombi sayısı profil tablosundan).
static func quality_text(profile: StringName) -> String:
	return Loc.t(StringName("set.quality.%s" % profile), [QualityProfiles.get_profile(profile)["max_enemies"]])
