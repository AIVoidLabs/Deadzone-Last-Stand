class_name SettingsTabControls
extends RefCounted
## KONTROLLER sekmesi: tuş atama (Settings.rebind) + sabit tuşların listesi.

const FIXED_KEY_SIZE: int = 16
const FIXED_KEY_WIDTH: float = 96.0
const BIND_ROW_HEIGHT: float = 38.0
const FIXED_COLUMN_GAP: int = 24


static func keys() -> Array[StringName]:
	return [&"input"]


static func build(menu: SettingsMenu, list: VBoxContainer) -> void:
	if Tuning.FEATURE_KEY_REBIND:
		menu.add_header(list, Loc.t(&"set.controls.rebind"))
		for action: StringName in SettingsSchema.REBINDABLE:
			_bind_row(menu, list, action)
	menu.add_header(list, Loc.t(&"set.controls.fixed"))
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", FIXED_COLUMN_GAP)
	grid.add_theme_constant_override("v_separation", 4)
	var pad: MarginContainer = MarginContainer.new()
	pad.add_theme_constant_override("margin_left", SettingRowBase.SIDE_PAD)
	pad.add_child(grid)
	list.add_child(pad)
	for item: Array in SettingsUiRules.FIXED_KEYS:
		_fixed_cell(grid, item[0], Loc.t(item[1]))


static func _bind_row(menu: SettingsMenu, list: VBoxContainer, action: StringName) -> void:
	var row: KeyBindRow = KeyBindRow.new()
	row.setup(action, Loc.t(StringName("set.key." + action)))
	row.bound.connect(func(_a: StringName, swapped: StringName) -> void:
		UiSounds.play(UiSoundData.BUY)
		menu.refresh_rows()
		if swapped != &"":
			menu.notify(Loc.t(&"set.key.swapped", [Loc.t(StringName("set.key." + swapped))]), UiPalette.AMBER))
	row.rejected.connect(func(_a: StringName) -> void:
		UiSounds.play(UiSoundData.DENY)
		UiMotion.shake(row)
		menu.notify(Loc.t(&"set.key.forbidden"), UiPalette.BAD))
	row.cancelled.connect(func(_a: StringName) -> void: menu.notify(Loc.t(&"set.key.cancelled"), UiPalette.ASH))
	menu.add_sync(row.queue_redraw)
	menu.add_row(list, row, &"set.key.hint", Loc.t(StringName("set.key." + action + ".desc")))
	row.custom_minimum_size.y = BIND_ROW_HEIGHT


## Sabit tuş: değiştirilemez, odak almaz; yalnız bilgi.
static func _fixed_cell(grid: GridContainer, key_text: String, what: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cap: Label = Label.new()
	cap.text = key_text
	cap.custom_minimum_size = Vector2(FIXED_KEY_WIDTH, 0)
	cap.add_theme_font_override("font", UiFonts.heading())
	cap.add_theme_font_size_override("font_size", FIXED_KEY_SIZE)
	cap.add_theme_color_override("font_color", UiPalette.AMBER)
	var text: Label = Label.new()
	text.text = what
	text.add_theme_font_override("font", UiFonts.bold())
	text.add_theme_font_size_override("font_size", 16)
	text.add_theme_color_override("font_color", UiPalette.ASH)
	row.add_child(cap)
	row.add_child(text)
	grid.add_child(row)
