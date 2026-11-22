class_name ScreenBackdrop
extends Control
## Arkadaki sahneyi bulanıklaştırıp karartır (mip bulanıklığı, duraklatmada çalışır) + köşe sıçraması + vinyet.

const BLUR_LOD: float = 3.2
const SPLAT_TINT: Color = Color(0.45, 0.04, 0.05, 0.4)
const SPLAT_FRACTION: float = 0.42

var _rect: ColorRect = null
var _mat: ShaderMaterial = null
var _blur: bool = true
var _dim: float = 0.6


static func create(blur: bool, dim: float) -> ScreenBackdrop:
	var b: ScreenBackdrop = ScreenBackdrop.new()
	b._blur = blur
	b._dim = dim
	return b


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_mat = UiAssets.mat("backdrop")
	_rect = ColorRect.new()
	UiAssets.fill(_rect)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _mat
	add_child(_rect)
	_add_splat("splat_1", Vector2(0.0, 1.0))
	_add_splat("splat_3", Vector2(1.0, 0.0))
	_apply()


func set_dim(v: float) -> void:
	_dim = v
	_apply()


func set_blur(b: bool) -> void:
	_blur = b
	_apply()


func _apply() -> void:
	if _mat == null:
		return
	_mat.set_shader_parameter("dim", _dim)
	_mat.set_shader_parameter("blur_lod", BLUR_LOD if _blur else 0.0)


## Köşeye taşan koyu kan sıçraması; ekran oranından bağımsız (anchor + oran koruma).
func _add_splat(mask: String, corner: Vector2) -> void:
	var s: TextureRect = UiAssets.brush_rect(mask, SPLAT_TINT, 0.0)
	s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	s.set_anchor(SIDE_LEFT, corner.x - SPLAT_FRACTION * 0.5)
	s.set_anchor(SIDE_RIGHT, corner.x + SPLAT_FRACTION * 0.5)
	s.set_anchor(SIDE_TOP, corner.y - SPLAT_FRACTION * 0.9)
	s.set_anchor(SIDE_BOTTOM, corner.y + SPLAT_FRACTION * 0.9)
	add_child(s)
