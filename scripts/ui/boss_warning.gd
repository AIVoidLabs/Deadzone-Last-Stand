class_name BossWarning
extends CanvasLayer
## Boss uyarısı: ekranın üstünde "YIĞIN GELİYOR" yazısı + kırmızı kenar nabzı (Tuning.BOSS_WARNING_TIME sn). SpawnDirector.boss_warning
## sinyaliyle başlar; yazı WaveBanner, kenar nabzı HurtVignette'in shader'ıyla. Ses yok (sessiz).

const SHADER: Shader = preload("res://assets/shaders/hurt_vignette.gdshader")
const TEXT: String = "YIĞIN GELİYOR"
const TEXT_COLOR: Color = Color(1.0, 0.22, 0.16)
## Yazı ekran yüksekliğinin bu oranında (HUD dalga yazısının üstünde).
const TOP_RATIO: float = 0.14
const LAYER_INDEX: int = 2
## Nabız hızı (Hz) ve kenar kızarmasının en yüksek gücü.
const PULSE_HZ: float = 1.5
const MAX_STRENGTH: float = 0.9

var director: SpawnDirector

var _banner: WaveBanner
var _rect: ColorRect
var _material: ShaderMaterial
var _left: float = 0.0


func _ready() -> void:
	name = "BossWarning"
	layer = LAYER_INDEX
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_rect = ColorRect.new()
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _material
	_rect.visible = false
	add_child(_rect)
	_banner = WaveBanner.new()
	add_child(_banner)
	_banner.anchor_top = TOP_RATIO
	_banner.anchor_bottom = TOP_RATIO
	director.boss_warning.connect(_start)
	set_process(false)


func _start() -> void:
	_left = Tuning.BOSS_WARNING_TIME
	_banner.flash(TEXT, TEXT_COLOR, maxf(Tuning.BOSS_WARNING_TIME - 0.6, 0.1))
	_rect.visible = true
	set_process(true)


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		_rect.visible = false
		set_process(false)
		return
	var fade: float = clampf(_left / Tuning.BOSS_WARNING_TIME, 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin((Tuning.BOSS_WARNING_TIME - _left) * TAU * PULSE_HZ)
	_material.set_shader_parameter(&"strength", MAX_STRENGTH * pulse * (0.4 + 0.6 * fade))
