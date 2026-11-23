class_name SettingsChrome
extends RefCounted
## Ayarlar ekranının iskeleti (sekme düğmeleri, liste paneli, açıklama alanı, alt düğmeler). SettingsMenu kullanır; yalnız kurar.

const PANEL_WIDTH: float = 980.0
const DESC_HEIGHT: float = 58.0
const DESC_SIZE: int = 18
const HINT_SIZE: int = 13
const HINT_MIN_WIDTH: float = 300.0
const BOTTOM_BUTTON: Vector2 = Vector2(220, 52)
const PANEL_MARGIN: int = 14
const NOTE_SIZE: int = 15
const HEADER_SIZE: int = 15


## Sekme düğmeleri; buttons dizisi doldurulur. on_select(index) çağrılır.
static func tabs(tab_keys: Array, on_select: Callable, buttons: Array[GrungeButton]) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	for i: int in tab_keys.size():
		var b: GrungeButton = GrungeButton.create(Loc.t(tab_keys[i]), &"normal")
		UiSounds.hook(b, true)
		b.pressed.connect(on_select.bind(i))
		row.add_child(b)
		buttons.append(b)
	return row


## {panel, scroll, list}: kaydırılabilir satır listesi.
static func list_panel() -> Dictionary:
	var panel: GrungePanel = GrungePanel.new()
	panel.content_margin = PANEL_MARGIN
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	panel.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 2)
	scroll.add_child(list)
	return {"panel": panel, "scroll": scroll, "list": list}


static func desc() -> Label:
	var label: Label = Label.new()
	label.custom_minimum_size = Vector2(PANEL_WIDTH, DESC_HEIGHT)
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", DESC_SIZE)
	label.add_theme_color_override("font_color", UiPalette.BONE)
	return label


## Sıfırla (sol) · tuş ipucu (orta) · Geri (sağ).
static func bottom(on_reset: Callable, on_back: Callable) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_theme_constant_override("separation", 24)
	var reset: GrungeButton = GrungeButton.create(Loc.t(&"set.reset"), &"danger")
	reset.custom_minimum_size = BOTTOM_BUTTON
	reset.pressed.connect(on_reset)
	var back: GrungeButton = GrungeButton.create(Loc.t(&"common.back"), &"primary")
	back.custom_minimum_size = BOTTOM_BUTTON
	back.pressed.connect(on_back)
	var hint: Label = Label.new()
	hint.text = Loc.t(&"set.hint")
	hint.add_theme_font_size_override("font_size", HINT_SIZE)
	hint.add_theme_color_override("font_color", UiPalette.ASH)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(HINT_MIN_WIDTH, 0)
	for b: GrungeButton in [reset, back]:
		UiSounds.hook(b, true)
	row.add_child(reset)
	row.add_child(hint)
	row.add_child(back)
	return row


## Liste içi açıklama notu (görünürlüğü etiketle birlikte değişir).
static func note(list: Control, text: String, color: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", NOTE_SIZE)
	l.add_theme_color_override("font_color", color)
	var pad: MarginContainer = MarginContainer.new()
	pad.add_theme_constant_override("margin_left", SettingRowBase.SIDE_PAD)
	pad.add_theme_constant_override("margin_right", SettingRowBase.SIDE_PAD)
	pad.add_child(l)
	list.add_child(pad)
	l.visibility_changed.connect(func() -> void: pad.visible = l.visible)
	return l


## Liste içi bölüm başlığı.
static func header(list: Control, text: String) -> void:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_override("font", UiFonts.heading())
	l.add_theme_font_size_override("font_size", HEADER_SIZE)
	l.add_theme_color_override("font_color", UiPalette.EMBER)
	var pad: MarginContainer = MarginContainer.new()
	pad.add_theme_constant_override("margin_left", SettingRowBase.SIDE_PAD)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 2)
	pad.add_child(l)
	list.add_child(pad)
