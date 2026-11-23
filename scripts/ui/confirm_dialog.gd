class_name GrungeConfirm
extends Control
## Onay penceresi (çıkış, kayıt sıfırlama, ana menüye dönüş...). Esc = vazgeç, varsayılan odak VAZGEÇ'te.
## Kullanım: GrungeConfirm.ask(parent, &"anahtar.baslik", &"anahtar.govde", on_yes)
## Ana ekran ve duraklatma menüsü ortak kullanır; duraklıyken de çalışır (PROCESS_MODE_ALWAYS).

const BACKDROP_DIM: float = 0.62
const PANEL_WIDTH: float = 560.0
const TITLE_SIZE: int = 40
const BODY_SIZE: int = 20
const BODY_LINES: int = 3
const GAP: int = 18
const BUTTON_GAP: int = 16

var _title_key: StringName = &""
var _body_key: StringName = &""
var _on_yes: Callable = Callable()
var _on_no: Callable = Callable()
var _previous_focus: Control = null
var _title: Label = null
var _body: Label = null
var _yes: GrungeButton = null
var _no: GrungeButton = null
var _closing: bool = false


## Pencereyi parent altında açar; başlık/gövde Loc anahtarıdır. Döner: açılan pencere.
static func ask(parent: Node, title_key: StringName, body_key: StringName, on_yes: Callable, on_no: Callable = Callable()) -> GrungeConfirm:
	var dialog: GrungeConfirm = GrungeConfirm.new()
	dialog._title_key = title_key
	dialog._body_key = body_key
	dialog._on_yes = on_yes
	dialog._on_no = on_no
	var viewport: Viewport = parent.get_viewport()
	dialog._previous_focus = viewport.gui_get_focus_owner() if viewport != null else null
	parent.add_child(dialog)
	return dialog


func _init() -> void:
	name = "GrungeConfirm"
	add_to_group(&"grunge_confirm")
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiTheme.get_theme()
	UiAssets.fill(self)


func _ready() -> void:
	add_child(ScreenBackdrop.create(true, BACKDROP_DIM))
	var center: CenterContainer = CenterContainer.new()
	UiAssets.fill(center)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel: GrungePanel = GrungePanel.new()
	panel.content_margin = 34
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	center.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", GAP)
	panel.add_child(column)
	_title = _label(UiFonts.heading(), TITLE_SIZE, UiPalette.EMBER)
	column.add_child(_title)
	_body = _label(UiFonts.body(), BODY_SIZE, UiPalette.BONE)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(0.0, BODY_SIZE * 1.4 * BODY_LINES)
	column.add_child(_body)
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", BUTTON_GAP)
	column.add_child(buttons)
	_yes = GrungeButton.create("", &"danger")
	_no = GrungeButton.create("", &"normal")
	for b: GrungeButton in [_yes, _no]:
		b.custom_minimum_size = Vector2(220.0, 56.0)
		buttons.add_child(b)
		UiSounds.hook(b)
	_yes.pressed.connect(_answer.bind(true))
	_no.pressed.connect(_answer.bind(false))
	_no.focus_neighbor_left = _yes.get_path()
	_yes.focus_neighbor_right = _no.get_path()
	_yes.focus_neighbor_left = _yes.get_path()
	_no.focus_neighbor_right = _no.get_path()
	_refresh_texts()
	Settings.changed.connect(_on_setting_changed)
	UiMotion.pop_in(panel)
	UiSounds.play(UiSoundData.HOVER)
	_no.grab_focus.call_deferred()


func _label(font: Font, size: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4)
	return l


func _refresh_texts() -> void:
	_title.text = Loc.t(_title_key)
	_body.text = Loc.t(_body_key)
	_yes.text = Loc.t(&"common.yes")
	_no.text = Loc.t(&"common.cancel")


func _on_setting_changed(key: StringName, _value: Variant) -> void:
	if key == &"game/language":
		_refresh_texts()


## Esc: vazgeç. Pencere açıkken altındaki ekranın Esc'i (duraklatma dahil) çalışmaz.
func _input(event: InputEvent) -> void:
	if _closing:
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		_answer(false)


func _answer(yes: bool) -> void:
	if _closing:
		return
	_closing = true
	if is_instance_valid(_previous_focus) and _previous_focus.is_inside_tree():
		_previous_focus.grab_focus()
	var action: Callable = _on_yes if yes else _on_no
	queue_free()
	if action.is_valid():
		action.call()


## Görüntü aracı (UiShot) için.
static func ui_shot(host: Node, _opts: Dictionary) -> void:
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0.25, 0.22, 0.2)
	UiAssets.fill(backdrop)
	host.add_child(backdrop)
	GrungeConfirm.ask(host, &"confirm.quit.title", &"confirm.quit.body", Callable())
