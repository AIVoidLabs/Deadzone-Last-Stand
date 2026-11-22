class_name GrungeBar
extends Control
## Çubuk: dolgu + geciken açık renk hasar gölgesi + çentikler (notch: kesir aralığı, ör. 0.1).

@export var fill_color: Color = UiPalette.BLOOD:
	set(v):
		fill_color = v
		_push()
@export var notch: float = 0.0:
	set(v):
		notch = v
		_push()

const LAG_DELAY: float = 0.35
const LAG_SPEED: float = 0.9
const FLASH_DECAY: float = 4.0
const DEFAULT_SIZE: Vector2 = Vector2(220, 20)

var _value: float = 1.0
var _lag: float = 1.0
var _lag_wait: float = 0.0
var _flash: float = 0.0
var _rect: ColorRect = null
var _mat: ShaderMaterial = null


func _init() -> void:
	custom_minimum_size = DEFAULT_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_mat = UiAssets.mat("bar")
	_rect = ColorRect.new()
	UiAssets.fill(_rect)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _mat
	add_child(_rect)
	resized.connect(_push)
	_push()


func set_value(v: float, maximum: float) -> void:
	var nv: float = clampf(v / maxf(maximum, 0.0001), 0.0, 1.0)
	if nv < _value:
		_lag_wait = LAG_DELAY
		_flash = 1.0
	elif nv > _lag:
		_lag = nv
	_value = nv
	_push()
	set_process(true)


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * FLASH_DECAY)
	if _lag_wait > 0.0:
		_lag_wait -= delta
	elif _lag > _value:
		_lag = maxf(_value, _lag - delta * LAG_SPEED)
	elif _flash <= 0.0:
		set_process(false)
	_push()


func _push() -> void:
	if _mat == null:
		return
	_mat.set_shader_parameter("rect_size", size)
	_mat.set_shader_parameter("fill_color", fill_color)
	_mat.set_shader_parameter("value", _value)
	_mat.set_shader_parameter("lag", _lag)
	_mat.set_shader_parameter("notch", notch)
	_mat.set_shader_parameter("flash", _flash)
