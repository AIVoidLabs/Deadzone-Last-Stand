class_name UiAssets
extends RefCounted
## Arayüz doku ve shader yükleyici. Her çağrı yeni ShaderMaterial verir (uniform'lar düğüme özel).

const TEX_DIR: String = "res://assets/textures/ui/"
const SHADER_DIR: String = "res://assets/shaders/ui/"
const NOISE: String = "noise_tile"

static var _tex: Dictionary = {}
static var _shaders: Dictionary = {}


static func tex(name: String) -> Texture2D:
	if not _tex.has(name):
		_tex[name] = load(TEX_DIR + name + ".png") as Texture2D
	return _tex[name]


## Gürültü dokusu bağlı materyal; mask verilirse mask_tex da atanır.
static func mat(shader_name: String, mask: String = "") -> ShaderMaterial:
	if not _shaders.has(shader_name):
		_shaders[shader_name] = load(SHADER_DIR + shader_name + ".gdshader") as Shader
	var m: ShaderMaterial = ShaderMaterial.new()
	m.shader = _shaders[shader_name]
	m.set_shader_parameter("noise_tex", tex(NOISE))
	if mask != "":
		m.set_shader_parameter("mask_tex", tex(mask))
	return m


## Üst düğümü tamamen doldurur (anchor 0..1, offset 0). set_anchors_preset offset'i bozabilir.
static func fill(c: Control) -> void:
	c.anchor_left = 0.0
	c.anchor_top = 0.0
	c.anchor_right = 1.0
	c.anchor_bottom = 1.0
	c.offset_left = 0.0
	c.offset_top = 0.0
	c.offset_right = 0.0
	c.offset_bottom = 0.0


## Fırça maskesiyle boyanan düğüm (şerit, leke, sıçrama, tebeşir). tint tüm rengi belirler.
static func brush_rect(mask: String, tint: Color, detail: float = 0.6) -> TextureRect:
	var r: TextureRect = TextureRect.new()
	r.texture = tex(mask)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m: ShaderMaterial = mat("brush", mask)
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("tint_dark", tint.darkened(0.55))
	m.set_shader_parameter("detail_amount", detail)
	r.material = m
	return r
