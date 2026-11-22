class_name FpsCounter
extends CanvasLayer
## Sağ üst köşede FPS göstergesi (ayar: display/show_fps). Duraklatılmış oyunda da çalışır.

const LAYER: int = 99
const REFRESH_TIME: float = 0.25
const MARGIN: int = 10
const FONT_SIZE: int = 16
const COLOR: Color = Color(0.91, 0.87, 0.8, 0.85)

var _label: Label
var _left: float = 0.0


func _ready() -> void:
	name = "FpsCounter"
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_label.offset_right = -MARGIN
	_label.offset_top = MARGIN
	_label.add_theme_font_size_override(&"font_size", FONT_SIZE)
	_label.add_theme_color_override(&"font_color", COLOR)
	_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_label.add_theme_constant_override(&"outline_size", 4)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_refresh()


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		_refresh()


func _refresh() -> void:
	_left = REFRESH_TIME
	_label.text = "%d FPS" % int(Engine.get_frames_per_second())
