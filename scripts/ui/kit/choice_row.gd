class_name ChoiceRow
extends SettingRowBase
## Seçim satırı: ◄ değer ►. value_changed(index: int). Sol/sağ ile döner; oklara ve değere tıklanır.

const ARROW_SIZE: Vector2 = Vector2(9, 14)
const ARROW_PAD: float = 14.0

var _options: Array = []
var _index: int = 0
var _value_label: Label = null
var _arrows: Control = null


func _init() -> void:
	super._init()
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_value_label = Label.new()
	_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_value_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_value_label.add_theme_font_override("font", UiFonts.heading())
	_value_label.add_theme_font_size_override("font_size", 19)
	_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_holder.add_child(_value_label)
	_arrows = Control.new()
	_arrows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiAssets.fill(_arrows)
	_arrows.draw.connect(_draw_arrows)
	_value_label.add_child(_arrows)
	focus_entered.connect(_refresh)
	focus_exited.connect(_refresh)


func setup(label_text: String, options: Array, index: int = 0) -> void:
	set_label(label_text)
	_options = options
	set_index(index)


func set_options(options: Array, index: int = 0) -> void:
	_options = options
	set_index(index)


func set_index(i: int) -> void:
	if _options.is_empty():
		_value_label.text = ""
		return
	_index = posmod(i, _options.size())
	_value_label.text = str(_options[_index])


func get_choice() -> int:
	return _index


func _has_focus_inside() -> bool:
	return has_focus()


func _step(dir: int) -> void:
	if _options.is_empty():
		return
	set_index(_index + dir)
	value_changed.emit(_index)


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_step(-1)
		accept_event()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_accept"):
		_step(1)
		accept_event()
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var rel: float = (mb.position.x - (_holder.global_position.x - global_position.x)) / _holder.size.x
			_step(-1 if rel < 0.33 else 1)
			accept_event()


func _set_active(a: bool) -> void:
	super._set_active(a)
	if _arrows != null:
		_arrows.queue_redraw()


func _draw_arrows() -> void:
	var cy: float = _arrows.size.y * 0.5
	var col: Color = UiPalette.EMBER if _active else UiPalette.ASH
	var lx: float = ARROW_PAD
	var rx: float = _arrows.size.x - ARROW_PAD
	_arrows.draw_colored_polygon(PackedVector2Array([Vector2(lx, cy), Vector2(lx + ARROW_SIZE.x, cy - ARROW_SIZE.y * 0.5), Vector2(lx + ARROW_SIZE.x, cy + ARROW_SIZE.y * 0.5)]), col)
	_arrows.draw_colored_polygon(PackedVector2Array([Vector2(rx, cy), Vector2(rx - ARROW_SIZE.x, cy - ARROW_SIZE.y * 0.5), Vector2(rx - ARROW_SIZE.x, cy + ARROW_SIZE.y * 0.5)]), col)
