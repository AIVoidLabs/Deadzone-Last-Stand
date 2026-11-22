class_name ToggleRow
extends SettingRowBase
## Aç/kapa satırı. value_changed(value: bool). Sol/sağ, Enter ve tıklama değiştirir.

const SWITCH_SIZE: Vector2 = Vector2(58, 26)

var _value: bool = false
var _on_text: String = ""
var _off_text: String = ""
var _text_label: Label = null


func _init() -> void:
	super._init()
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_text_label = Label.new()
	_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_text_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_text_label.add_theme_font_override("font", UiFonts.bold())
	_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_holder.add_child(_text_label)
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(SWITCH_SIZE.x + 12.0, 0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_holder.add_child(spacer)
	focus_entered.connect(_refresh)
	focus_exited.connect(_refresh)


func setup(label_text: String, value: bool, on_text: String = "", off_text: String = "") -> void:
	set_label(label_text)
	_on_text = on_text
	_off_text = off_text
	set_value(value)


func set_value(v: bool) -> void:
	_value = v
	_text_label.text = _on_text if v else _off_text
	queue_redraw()


func get_value() -> bool:
	return _value


func _has_focus_inside() -> bool:
	return has_focus()


func _gui_input(event: InputEvent) -> void:
	var hit: bool = event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right")
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		hit = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if hit:
		set_value(not _value)
		value_changed.emit(_value)
		accept_event()


func _draw() -> void:
	super._draw()
	var r: Rect2 = Rect2(Vector2(size.x - SettingRowBase.SIDE_PAD - SWITCH_SIZE.x, (size.y - SWITCH_SIZE.y) * 0.5), SWITCH_SIZE)
	draw_rect(r, Color(0.03, 0.025, 0.022, 0.95))
	draw_rect(r, Color(UiPalette.ASH, 0.55), false, 1.5)
	var knob_w: float = SWITCH_SIZE.x * 0.46
	var kx: float = r.position.x + (SWITCH_SIZE.x - knob_w - 3.0 if _value else 3.0)
	var knob: Rect2 = Rect2(kx, r.position.y + 3.0, knob_w, SWITCH_SIZE.y - 6.0)
	draw_rect(knob, UiPalette.EMBER if _value else UiPalette.ASH.darkened(0.35))
