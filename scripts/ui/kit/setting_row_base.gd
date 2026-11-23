class_name SettingRowBase
extends PanelContainer
## Ayar satırı tabanı: solda etiket, sağda değer. Odak / üzerine gelince ember vurgusu.
## Alt sınıflar: SliderRow, ToggleRow, ChoiceRow (hepsi signal value_changed(value)).

@warning_ignore("unused_signal")
signal value_changed(value: Variant)

const ROW_HEIGHT: float = 50.0
const LABEL_SIZE: int = 19
const SIDE_PAD: int = 16
const ACCENT_WIDTH: float = 4.0
const HOLDER_MIN_WIDTH: float = 250.0

var _label: Label = null
var _holder: HBoxContainer = null
var _active: bool = false


func _init() -> void:
	custom_minimum_size = Vector2(0, ROW_HEIGHT)
	var sb: StyleBoxEmpty = StyleBoxEmpty.new()
	sb.content_margin_left = SIDE_PAD
	sb.content_margin_right = SIDE_PAD
	add_theme_stylebox_override("panel", sb)
	var hb: HBoxContainer = HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hb)
	_label = Label.new()
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_label.add_theme_font_override("font", UiFonts.bold())
	_label.add_theme_font_size_override("font_size", LABEL_SIZE)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(_label)
	_holder = HBoxContainer.new()
	_holder.custom_minimum_size = Vector2(HOLDER_MIN_WIDTH, 0)
	_holder.size_flags_vertical = Control.SIZE_FILL
	_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(_holder)
	mouse_entered.connect(_refresh)
	mouse_exited.connect(_refresh)


func set_label(text: String) -> void:
	_label.text = text


func _set_active(a: bool) -> void:
	_active = a
	_label.add_theme_color_override("font_color", Color.WHITE if a else UiPalette.BONE)
	queue_redraw()


func _refresh() -> void:
	_set_active(_has_focus_inside() or get_global_rect().has_point(get_global_mouse_position()) and is_visible_in_tree())


func _has_focus_inside() -> bool:
	return false


func _draw() -> void:
	if not _active:
		draw_line(Vector2(0, size.y - 1), Vector2(size.x, size.y - 1), Color(UiPalette.ASH, 0.12), 1.0)
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(UiPalette.EMBER, 0.13))
	draw_rect(Rect2(0, 3, ACCENT_WIDTH, size.y - 6), UiPalette.EMBER)
