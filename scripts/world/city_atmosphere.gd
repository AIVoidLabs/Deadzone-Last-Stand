class_name CityAtmosphere
extends Node
## 8.3a: şehir atmosferi (yükseklik sisi, hacimsel sis, parıltı, renk ayarı, SSR, vinyet).
## Her şey kalite profilinden okunur; Quality.profile_changed ile canlı uygulanır.

const VIGNETTE_SHADER: Shader = preload("res://assets/shaders/hurt_vignette.gdshader")
const VIGNETTE_LAYER: int = 0

var _env: Environment
var _vignette: ColorRect


func _init(env: Environment = null) -> void:
	_env = env


func _ready() -> void:
	name = "CityAtmosphere"
	if _env == null:
		return
	_build_grade()
	_build_vignette()
	_apply(Quality.current)
	Quality.profile_changed.connect(_apply)
	Settings.changed.connect(func(key: StringName, _value: Variant) -> void:
		if key == &"display/brightness":
			_apply_brightness())


func _build_grade() -> void:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	gradient.colors = PackedColorArray([Tuning.ATMO_GRADE_SHADOW, Tuning.ATMO_GRADE_MID, Tuning.ATMO_GRADE_HIGHLIGHT])
	var tex: GradientTexture1D = GradientTexture1D.new()
	tex.gradient = gradient
	tex.width = 64
	_env.adjustment_color_correction = tex


func _build_vignette() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = VIGNETTE_LAYER
	add_child(layer)
	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = VIGNETTE_SHADER
	mat.set_shader_parameter(&"color", Color(0.0, 0.0, 0.0, 1.0))
	mat.set_shader_parameter(&"strength", Tuning.ATMO_VIGNETTE_STRENGTH)
	mat.set_shader_parameter(&"inner", Tuning.ATMO_VIGNETTE_INNER)
	_vignette.material = mat
	layer.add_child(_vignette)


## Ayar: display/brightness (1.0 = değişiklik yok).
func _apply_brightness() -> void:
	_env.adjustment_brightness = Settings.get_value(&"display/brightness")


func _apply(_profile_id: StringName) -> void:
	var on: bool = Tuning.FEATURE_CITY_ATMOSPHERE
	_env.fog_enabled = on
	_env.fog_light_color = Tuning.ATMO_FOG_COLOR
	_env.fog_density = Tuning.ATMO_FOG_DENSITY
	_env.fog_height = Tuning.ATMO_FOG_HEIGHT
	_env.fog_height_density = Tuning.ATMO_FOG_HEIGHT_DENSITY
	_env.volumetric_fog_enabled = on and bool(Quality.get_value("volumetric_fog"))
	_env.volumetric_fog_density = Tuning.ATMO_VOLUMETRIC_DENSITY
	_env.volumetric_fog_albedo = Tuning.ATMO_VOLUMETRIC_ALBEDO
	_env.volumetric_fog_length = Tuning.ATMO_VOLUMETRIC_LENGTH
	_env.glow_enabled = on and bool(Quality.get_value("glow"))
	_env.glow_intensity = Tuning.ATMO_GLOW_INTENSITY
	_env.glow_hdr_threshold = Tuning.ATMO_GLOW_THRESHOLD
	_env.glow_bloom = Tuning.ATMO_GLOW_BLOOM
	_env.adjustment_enabled = true
	_apply_brightness()
	_env.ssr_enabled = on and bool(Quality.get_value("ssr"))
	_vignette.visible = on and bool(Quality.get_value("vignette"))
