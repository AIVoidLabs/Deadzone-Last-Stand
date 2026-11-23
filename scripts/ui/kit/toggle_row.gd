class_name ToggleRow
extends SettingRowBase
## Aç/kapa satırı. value_changed(value: bool). Sol/sağ, Enter ve tıklama değiştirir.

const SWITCH_SIZE: Vector2 = Vector2(58, 30)
const TRACK_H: float = 14.0
const KNOB_SIZE: Vector2 = Vector2(16, 30)
const SWITCH_PAD: float = 12.0
const KNOB_TIME: float = 0.12

var _value: bool = false
var _on_text: String = ""
var _off_text: String = ""
var _text_label: Label = null
var _switch: Control = null
var _track: TextureRect = null
var _fill: TextureRect = null
var _knob: Control = null


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
	_switch = Control.new()
	_switch.custom_minimum_size = SWITCH_SIZE + Vector2(12.0, 0)
	_switch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_switch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_holder.add_child(_switch)
	_track = UiAssets.brush_rect("btn_stroke_b", Color(0.24, 0.2, 0.17), 0.4)
	_fill = UiAssets.brush_rect("btn_stroke_a", UiPalette.EMBER, 0.6)
	for r: TextureRect in [_track, _fill]:
		r.position = Vector2(SWITCH_PAD, (SWITCH_SIZE.y - TRACK_H) * 0.5)
		r.size = Vector2(SWITCH_SIZE.x, TRACK_H)
		_switch.add_child(r)
	_knob = Control.new()
	_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_knob.size = KNOB_SIZE
	_knob.draw.connect(func() -> void: BrushSlider.draw_knob(_knob, Rect2(Vector2.ZERO, KNOB_SIZE), has_focus() or _value))
	_switch.add_child(_knob)
	_knob.position.x = SWITCH_PAD
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
	if _knob == null:
		return
	var x: float = SWITCH_PAD + (SWITCH_SIZE.x - KNOB_SIZE.x if v else 0.0)
	(_fill.material as ShaderMaterial).set_shader_parameter("cut", 1.0 if v else 0.0)
	_knob.queue_redraw()
	if Tuning.FEATURE_UI_MOTION and is_inside_tree():
		var t: Tween = create_tween()
		t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		t.tween_property(_knob, "position:x", x, KNOB_TIME)
	else:
		_knob.position.x = x


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



func _set_active(a: bool) -> void:
	super._set_active(a)
	if _knob != null:
		_knob.queue_redraw()
