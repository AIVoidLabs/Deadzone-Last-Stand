class_name SliderRow
extends SettingRowBase
## Kaydırıcı satırı. value_changed(value: float). format: &"percent" (0.6 -> 60%), &"number", &"fixed2".

const SLIDER_MIN_WIDTH: float = 170.0
const VALUE_WIDTH: float = 62.0

var _slider: BrushSlider = null
var _value_label: Label = null
var _format: StringName = &"percent"


func _init() -> void:
	super._init()
	_slider = BrushSlider.new()
	_slider.custom_minimum_size = Vector2(SLIDER_MIN_WIDTH, 0)
	_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_slider.focus_mode = Control.FOCUS_ALL
	_holder.add_child(_slider)
	_value_label = Label.new()
	_value_label.custom_minimum_size = Vector2(VALUE_WIDTH, 0)
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_value_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_value_label.add_theme_font_override("font", UiFonts.bold())
	_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_holder.add_child(_value_label)
	_slider.value_changed.connect(_on_changed)
	_slider.focus_entered.connect(_refresh)
	_slider.focus_exited.connect(_refresh)


func setup(label_text: String, value: float, min_value: float = 0.0, max_value: float = 1.0, step: float = 0.01, format: StringName = &"percent") -> void:
	set_label(label_text)
	_format = format
	_slider.min_value = min_value
	_slider.max_value = max_value
	_slider.step = step
	_slider.set_value_no_signal(value)
	_update_text()


func set_value(v: float) -> void:
	_slider.set_value_no_signal(v)
	_update_text()


func get_value() -> float:
	return _slider.value


func focus_control() -> Control:
	return _slider


func _has_focus_inside() -> bool:
	return _slider.has_focus()


func _on_changed(v: float) -> void:
	_update_text()
	value_changed.emit(v)


func _update_text() -> void:
	var v: float = _slider.value
	match _format:
		&"percent":
			_value_label.text = "%d%%" % roundi(v * 100.0)
		&"fixed2":
			_value_label.text = "%.2f" % v
		_:
			_value_label.text = str(snappedf(v, _slider.step))
