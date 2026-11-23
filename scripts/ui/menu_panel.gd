class_name MenuPanel
extends Control
## Menü alt ekranlarının ortak kabuğu (rekorlar, emeği geçenler): bulanık karartılmış zemin, ortada kirli siyah panel,
## başlık, GERİ düğmesi. Esc kapatır ve olayı tüketir (alttaki ekran / GameFlow duraklatması çalışmaz).
## Alt sınıflar _title_key() ve _fill(column) yazar; dil değişince _fill yeniden çağrılır.

const BACKDROP_DIM: float = 0.7
const PANEL_SIZE: Vector2 = Vector2(1100, 620)
const PANEL_MARGIN: int = 30
const TITLE_SIZE: int = 54
const COLUMN_GAP: int = 14
const FOOTER_GAP: int = 16
const BUTTON_SIZE: Vector2 = Vector2(260, 52)

var _on_closed: Callable = Callable()
var _title: GrungeTitle = null
var _content: VBoxContainer = null
var _back: GrungeButton = null
var _closing: bool = false


func _init() -> void:
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
	panel.content_margin = PANEL_MARGIN
	panel.custom_minimum_size = PANEL_SIZE
	center.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", COLUMN_GAP)
	panel.add_child(column)
	_title = GrungeTitle.new()
	_title.font_size = TITLE_SIZE
	column.add_child(_title)
	_content = VBoxContainer.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", COLUMN_GAP)
	column.add_child(_content)
	Settings.changed.connect(_on_setting_changed)
	_refresh()
	UiMotion.pop_in(panel)
	UiSounds.play(UiSoundData.HOVER)


func _title_key() -> StringName:
	return &""


## Alt sınıf: içeriği kurar (footer dahil: _make_footer).
func _fill(_column: VBoxContainer) -> void:
	pass


func _refresh() -> void:
	_title.set_text(Loc.t(_title_key()), "")
	for child: Node in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_fill(_content)
	if _back != null:
		_back.grab_focus.call_deferred()


## GERİ + isteğe bağlı ek düğmeler; ortada, panelin altında.
func _make_footer(extra: Array[Control] = []) -> HBoxContainer:
	var footer: HBoxContainer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", FOOTER_GAP)
	_back = GrungeButton.create(Loc.t(&"common.back"), &"normal")
	_back.custom_minimum_size = BUTTON_SIZE
	_back.pressed.connect(close)
	UiSounds.hook(_back, true)
	footer.add_child(_back)
	for control: Control in extra:
		footer.add_child(control)
	return footer


func _on_setting_changed(key: StringName, _value: Variant) -> void:
	if key == &"game/language":
		_refresh()


func _input(event: InputEvent) -> void:
	if _closing:
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		if get_tree().get_nodes_in_group(&"grunge_confirm").size() > 0:
			return
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	if _closing:
		return
	_closing = true
	queue_free()
	if _on_closed.is_valid():
		_on_closed.call()


## Ortak yardımcılar.
static func make_label(text: String, font: Font, size: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func flat_box(color: Color, edge: Color = Color(0, 0, 0, 0), edge_width: int = 0) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = edge
	sb.border_width_left = edge_width
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb
