class_name GrungePanel
extends PanelContainer
## Yırtık kenarlı, kirli siyah panel. İçerik kenar boşlukları content_margin ile.

@export var content_margin: int = 18
@export var panel_alpha: float = 0.95

var _mat: ShaderMaterial = null


func _init() -> void:
	_mat = UiAssets.mat("grunge_panel")
	_mat.set_shader_parameter("scratch_tex", UiAssets.tex("scratches"))
	material = _mat
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	add_theme_stylebox_override("panel", sb)
	resized.connect(_on_resized)


func _ready() -> void:
	var sb: StyleBox = get_theme_stylebox("panel")
	for side: int in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		sb.set_content_margin(side, content_margin)
	_mat.set_shader_parameter("base", Color(0.065, 0.055, 0.05, panel_alpha))
	_on_resized()


func _on_resized() -> void:
	_mat.set_shader_parameter("rect_size", size)
