class_name SettingsMenu
extends Control
## Ayarlar ekranı (ana menü ve duraklatma menüsü ortak kullanır). 4 sekme: GÖRÜNTÜ, SES, OYUN, KONTROLLER.
## Değişiklik anında uygulanır; ekran modu/çözünürlük değişince 10 sn "koru?" geri sayımı açılır.
## Klavye: yukarı/aşağı seçer, sol/sağ değiştirir, Q/E ya da PageUp/PageDown sekme, Esc geri.
## Kullanım: SettingsMenu.open(parent, on_closed). Satır kurucuları (add_row, add_note...) sekme sınıflarına açıktır.

signal closed

const TABS: Array[Dictionary] = [
	{"id": &"display", "key": &"set.tab.display"},
	{"id": &"audio", "key": &"set.tab.audio"},
	{"id": &"game", "key": &"set.tab.game"},
	{"id": &"controls", "key": &"set.tab.controls"},
]
const SECTION_OF_TAB: Dictionary = {
	&"display": [&"display", &"graphics"], &"audio": [&"audio"], &"game": [&"game"], &"controls": [&"input"],
}
const BACKDROP_DIM: float = 0.74
const TITLE_SIZE: int = 50
const OUTER_MARGIN: Vector2i = Vector2i(48, 22)
const TAB_SIZE: Vector2 = Vector2(200, 46)
const TAB_FONT: int = 19
const ROW_HEIGHT: float = 44.0
const NOTICE_TIME: float = 2.6

var _on_closed: Callable = Callable()
var _tab: int = 0
var _content: Control = null
var _list: VBoxContainer = null
var _scroll: ScrollContainer = null
var _desc: Label = null
var _tab_buttons: Array[GrungeButton] = []
var _syncs: Array[Callable] = []
var _desc_default: String = ""
var _notice_until: int = 0
## Ekran modu / çözünürlük için "koru?" akışı (SettingsShot da kullanır).
var keep_guard: SettingsKeepGuard = null
var _closing: bool = false
var _last_focus: int = 0


## Ayarlar ekranını parent altında açar. on_closed: kapanınca çağrılır (çağıran odağı geri alır).
static func open(parent: Node, on_closed: Callable = Callable()) -> SettingsMenu:
	var menu: SettingsMenu = SettingsMenu.new()
	menu._on_closed = on_closed
	parent.add_child(menu)
	return menu


func _init() -> void:
	name = "SettingsMenu"
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiTheme.get_theme()
	UiAssets.fill(self)


func _ready() -> void:
	keep_guard = SettingsKeepGuard.new()
	keep_guard.settled.connect(_on_keep_settled)
	add_child(keep_guard)
	add_child(ScreenBackdrop.create(true, BACKDROP_DIM))
	_build_content()
	Settings.changed.connect(_on_setting_changed)
	UiMotion.pop_in(_content)
	focus_row.call_deferred(0)


# --- Kurulum ---

func _build_content() -> void:
	_syncs.clear()
	_tab_buttons.clear()
	_content = MarginContainer.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiAssets.fill(_content)
	for side: String in ["left", "right"]:
		_content.add_theme_constant_override("margin_" + side, OUTER_MARGIN.x)
	for side: String in ["top", "bottom"]:
		_content.add_theme_constant_override("margin_" + side, OUTER_MARGIN.y)
	add_child(_content)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_content.add_child(column)
	var title: GrungeTitle = GrungeTitle.new()
	title.font_size = TITLE_SIZE
	title.set_text(Loc.t(&"set.title.a"), Loc.t(&"set.title.b"))
	column.add_child(title)
	column.add_child(SettingsChrome.tabs(TABS.map(func(t: Dictionary) -> StringName: return t["key"]), _select_tab, _tab_buttons))
	var parts: Dictionary = SettingsChrome.list_panel()
	_scroll = parts["scroll"]
	_list = parts["list"]
	column.add_child(parts["panel"])
	_desc = SettingsChrome.desc()
	column.add_child(_desc)
	column.add_child(SettingsChrome.bottom(ask_reset, close))
	_select_tab(_tab)


# --- Sekmeler ---

## Sekmeyi açar (SettingsShot da kullanır).
func show_tab(index: int) -> void:
	_select_tab(index)


func _select_tab(index: int) -> void:
	_tab = index
	for i: int in _tab_buttons.size():
		_style_tab(_tab_buttons[i], i == _tab)
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_syncs.clear()
	_build_tab(TABS[_tab]["id"])
	_scroll.scroll_vertical = 0
	_set_desc("")


func _build_tab(id: StringName) -> void:
	match id:
		&"display":
			SettingsTabDisplay.build(self, _list)
		&"audio":
			SettingsTabAudio.build(self, _list)
		&"game":
			SettingsTabGame.build(self, _list)
		&"controls":
			SettingsTabControls.build(self, _list)


func _style_tab(b: GrungeButton, active: bool) -> void:
	b.variant = &"primary" if active else &"normal"
	b.custom_minimum_size = TAB_SIZE
	b.add_theme_font_size_override("font_size", TAB_FONT)


func _step_tab(dir: int) -> void:
	UiSounds.play(UiSoundData.CLICK)
	_select_tab(SettingsUiRules.step_tab(_tab, dir, TABS.size()))
	focus_row.call_deferred(0)


## Listedeki index'inci odaklanabilir satıra odaklanır.
func focus_row(index: int) -> void:
	var rows: Array[Control] = []
	_collect_focusable(_list, rows)
	if rows.is_empty():
		return
	rows[clampi(index, 0, rows.size() - 1)].grab_focus()


func _collect_focusable(node: Node, out: Array[Control]) -> void:
	for child: Node in node.get_children():
		if child is SliderRow:
			out.append((child as SliderRow).focus_control())
		elif child is SettingRowBase and (child as Control).focus_mode == Control.FOCUS_ALL:
			out.append(child)
		else:
			_collect_focusable(child, out)


# --- Sekme sınıflarının kullandığı kurucular ---

func add_row(list: Control, row: Control, desc_key: StringName, extra: String = "") -> void:
	row.custom_minimum_size.y = ROW_HEIGHT
	list.add_child(row)
	var text: Callable = func() -> String:
		var base: String = Loc.t(desc_key) if Loc.has(desc_key) else ""
		return base if extra.is_empty() else (extra + "  " + base).strip_edges()
	var target: Control = (row as SliderRow).focus_control() if row is SliderRow else row
	target.focus_entered.connect(func() -> void: _set_desc(text.call()))
	row.mouse_entered.connect(func() -> void: _set_desc(text.call()))


func add_sync(fn: Callable) -> void:
	_syncs.append(fn)


func add_note(list: Control, text: String, color: Color) -> Label:
	return SettingsChrome.note(list, text, color)


func add_header(list: Control, text: String) -> void:
	SettingsChrome.header(list, text)


func refresh_rows() -> void:
	for fn: Callable in _syncs:
		fn.call()


## Açıklama alanında kısa süreli renkli bildirim (takas, geçersiz tuş...).
func notify(text: String, color: Color) -> void:
	_desc.text = text
	_desc.add_theme_color_override("font_color", color)
	_notice_until = Time.get_ticks_msec() + int(NOTICE_TIME * 1000.0)


func _set_desc(text: String) -> void:
	_desc_default = text
	_desc.text = text
	_desc.add_theme_color_override("font_color", UiPalette.BONE)
	_notice_until = 0


func _process(_delta: float) -> void:
	if _notice_until > 0 and Time.get_ticks_msec() > _notice_until:
		_set_desc(_desc_default)


# --- Ayar uygulama ---

## Ayarı uygular; ekran modu/çözünürlük ise koru-geri al geri sayımı açar.
func apply_setting(key: StringName, value: Variant) -> void:
	keep_guard.run(func() -> void: Settings.set_value(key, value))


func _on_keep_settled() -> void:
	refresh_rows()
	focus_row.call_deferred(_last_focus)


func _on_setting_changed(key: StringName, _value: Variant) -> void:
	if key == &"game/language":
		_rebuild.call_deferred()
	else:
		refresh_rows()


## Dil değişince tüm metinler yeniden kurulur; sekme ve odak korunur.
func _rebuild() -> void:
	var focused: Control = get_viewport().gui_get_focus_owner()
	_last_focus = 0
	var rows: Array[Control] = []
	_collect_focusable(_list, rows)
	if focused != null and rows.has(focused):
		_last_focus = rows.find(focused)
	if _content != null:
		_content.queue_free()
	_build_content()
	focus_row.call_deferred(_last_focus)


func ask_reset() -> void:
	GrungeConfirm.ask(self, &"set.reset.title", &"set.reset.body", _reset_tab)


func _reset_tab() -> void:
	keep_guard.run(func() -> void:
		for section: StringName in SECTION_OF_TAB[TABS[_tab]["id"]]:
			Settings.reset_section(section))
	refresh_rows()
	focus_row.call_deferred(0)


# --- Girdi ve kapanış ---

func _input(event: InputEvent) -> void:
	if _closing or not (event is InputEventKey) or not event.is_pressed() or (event as InputEventKey).echo:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
	elif event.is_action_pressed("ui_page_up") or (event as InputEventKey).physical_keycode == KEY_Q:
		get_viewport().set_input_as_handled()
		_step_tab(-1)
	elif event.is_action_pressed("ui_page_down") or (event as InputEventKey).physical_keycode == KEY_E:
		get_viewport().set_input_as_handled()
		_step_tab(1)


func close() -> void:
	if _closing:
		return
	_closing = true
	Settings.flush()
	if _on_closed.is_valid():
		_on_closed.call()
	closed.emit()
	queue_free()


## Görüntü aracı (UiShot): düzen SettingsShot'ta.
static func ui_shot(host: Node, opts: Dictionary) -> void:
	SettingsShot.build(host, opts)
