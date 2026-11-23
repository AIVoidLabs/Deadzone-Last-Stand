class_name BrushSlider
extends Control
## Fırça darbesi çubuklu kaydırıcı + çentikli metal tutamak. Klavye (sol/sağ) ve fare sürükleme.
## HSlider ile aynı alan adları: min_value, max_value, step, value, value_changed.

signal value_changed(value: float)

const TRACK_HEIGHT: float = 14.0
const KNOB_SIZE: Vector2 = Vector2(16, 30)
const KNOB_GROOVES: int = 3
const KEY_STEPS: float = 20.0

var min_value: float = 0.0
var max_value: float = 1.0
var step: float = 0.01
var value: float = 0.0

var _track: TextureRect = null
var _fill: TextureRect = null
var _knob: Control = null
var _drag: bool = false


func _init() -> void:
	custom_minimum_size = Vector2(170, KNOB_SIZE.y)
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_track = UiAssets.brush_rect("btn_stroke_b", Color(0.24, 0.2, 0.17), 0.4)
	_fill = UiAssets.brush_rect("btn_stroke_a", UiPalette.EMBER, 0.6)
	for r: TextureRect in [_track, _fill]:
		r.anchor_top = 0.5
		r.anchor_bottom = 0.5
		r.offset_top = -TRACK_HEIGHT * 0.5
		r.offset_bottom = TRACK_HEIGHT * 0.5
		r.anchor_right = 1.0
		add_child(r)
	_knob = Control.new()
	_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_knob.size = KNOB_SIZE
	_knob.draw.connect(func() -> void: draw_knob(_knob, Rect2(Vector2.ZERO, KNOB_SIZE), has_focus() or _drag))
	add_child(_knob)
	resized.connect(_layout)
	focus_entered.connect(func() -> void: _knob.queue_redraw())
	focus_exited.connect(func() -> void: _knob.queue_redraw())


## Çentikli metal tutamak (ToggleRow da kullanır).
static func draw_knob(ci: CanvasItem, r: Rect2, lit: bool) -> void:
	ci.draw_rect(r, Color(0.02, 0.015, 0.012))
	var body: Rect2 = r.grow(-1.5)
	var top: Color = Color(0.62, 0.6, 0.56) if lit else Color(0.5, 0.48, 0.45)
	ci.draw_rect(body, top.darkened(0.35))
	ci.draw_rect(Rect2(body.position, Vector2(body.size.x, body.size.y * 0.5)), top)
	for i: int in KNOB_GROOVES:
		var x: float = r.position.x + r.size.x * (i + 1.0) / (KNOB_GROOVES + 1.0)
		ci.draw_line(Vector2(x, r.position.y + 5.0), Vector2(x, r.end.y - 5.0), Color(0.08, 0.06, 0.05), 1.5)
	ci.draw_rect(body, UiPalette.EMBER if lit else Color(0.12, 0.1, 0.09), false, 1.0)


func set_value_no_signal(v: float) -> void:
	value = clampf(snappedf(v, step), min_value, max_value)
	_layout()


func _ratio() -> float:
	return 0.0 if max_value <= min_value else (value - min_value) / (max_value - min_value)


func _layout() -> void:
	if _knob == null:
		return
	var span: float = maxf(size.x - KNOB_SIZE.x, 1.0)
	_knob.position = Vector2(span * _ratio(), (size.y - KNOB_SIZE.y) * 0.5)
	(_fill.material as ShaderMaterial).set_shader_parameter("cut", clampf((_knob.position.x + KNOB_SIZE.x * 0.5) / maxf(size.x, 1.0), 0.0, 1.0))
	_knob.queue_redraw()


func _set_from_x(x: float) -> void:
	var span: float = maxf(size.x - KNOB_SIZE.x, 1.0)
	_change(min_value + clampf((x - KNOB_SIZE.x * 0.5) / span, 0.0, 1.0) * (max_value - min_value))


func _change(v: float) -> void:
	var nv: float = clampf(snappedf(v, step), min_value, max_value)
	if is_equal_approx(nv, value):
		return
	value = nv
	_layout()
	value_changed.emit(value)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_drag = mb.pressed
			if mb.pressed:
				grab_focus()
				_set_from_x(mb.position.x)
			_knob.queue_redraw()
			accept_event()
	elif event is InputEventMouseMotion and _drag:
		_set_from_x((event as InputEventMouseMotion).position.x)
		accept_event()
	elif event.is_action_pressed("ui_left"):
		_change(value - maxf(step, (max_value - min_value) / KEY_STEPS))
		accept_event()
	elif event.is_action_pressed("ui_right"):
		_change(value + maxf(step, (max_value - min_value) / KEY_STEPS))
		accept_event()
