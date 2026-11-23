class_name WaveBanner
extends Label
## Ekranın üst-ortasında beliren, bir süre kalıp sönen büyük yazı ("DALGA 2", "DALGA TEMİZLENDİ").
## FEATURE_NEW_HUD açıkken: iki renkli fırça şeridi üstünde kemik rengi büyük harf; flash'ın rengi şeridin rengidir.

const FONT_SIZE: int = 44
const OUTLINE_SIZE: int = 8
const OUTLINE_COLOR: Color = Color(0.0, 0.0, 0.0, 0.6)
## Ekran yüksekliğine oranla yazının üst kenarı.
const TOP_RATIO: float = 0.22
const FADE_IN: float = 0.15
const FADE_OUT: float = 0.45
# Yeni görünüm
const NEW_FONT_SIZE: int = 52
const FRONT_SIDE: float = 64.0
const BACK_SIDE: float = 110.0
const FRONT_INSET: float = 4.0
const BACK_BLEED: float = 12.0
const POP_FROM: float = 0.82
const POP_TIME: float = 0.28
const ACCENT_DARKEN: float = 0.12

var _tween: Tween = null
var _back: TextureRect = null
var _front: TextureRect = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	anchor_top = TOP_RATIO
	anchor_bottom = TOP_RATIO
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0
	if Tuning.FEATURE_NEW_HUD:
		_build_new_look()
		return
	add_theme_font_size_override("font_size", FONT_SIZE)
	add_theme_constant_override("outline_size", OUTLINE_SIZE)
	add_theme_color_override("font_outline_color", OUTLINE_COLOR)


func _build_new_look() -> void:
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_theme_font_override("font", UiFonts.heading())
	add_theme_font_size_override("font_size", NEW_FONT_SIZE)
	add_theme_color_override("font_color", UiPalette.BONE)
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	add_theme_constant_override("shadow_offset_x", 3)
	add_theme_constant_override("shadow_offset_y", 4)
	_back = UiAssets.brush_rect("band_c", Color(UiPalette.INK, 0.9), 0.2)
	_front = UiAssets.brush_rect("band_a", UiPalette.EMBER, 0.55)
	for plate: TextureRect in [_back, _front]:
		plate.show_behind_parent = true
		add_child(plate)
	resized.connect(_layout_plates)
	resized.connect(func() -> void: pivot_offset = size * 0.5)


## Şeritleri yazı genişliğine göre ortalar (yazı ya da boyut değişince).
func _layout_plates() -> void:
	if _back == null:
		return
	var width: float = get_theme_font("font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, NEW_FONT_SIZE).x
	var mid: float = size.x * 0.5
	_back.position = Vector2(mid - width * 0.5 - BACK_SIDE, -BACK_BLEED)
	_back.size = Vector2(width + BACK_SIDE * 2.0, size.y + BACK_BLEED * 2.0)
	_front.position = Vector2(mid - width * 0.5 - FRONT_SIDE, FRONT_INSET)
	_front.size = Vector2(width + FRONT_SIDE * 2.0, size.y - FRONT_INSET * 2.0)


## text'i hold saniye gösterir; önceki yazıyı keser. color: eski görünümde yazı, yenisinde şerit rengi.
func flash(message: String, color: Color, hold: float) -> void:
	text = message
	if _front != null:
		var mat: ShaderMaterial = _front.material
		mat.set_shader_parameter("tint", color.darkened(ACCENT_DARKEN))
		mat.set_shader_parameter("tint_dark", color.darkened(0.7))
		_layout_plates()
		if Tuning.FEATURE_UI_MOTION:
			scale = Vector2.ONE * POP_FROM
			create_tween().tween_property(self, "scale", Vector2.ONE, POP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		add_theme_color_override("font_color", color)
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, FADE_IN)
	_tween.tween_interval(hold)
	_tween.tween_property(self, "modulate:a", 0.0, FADE_OUT)
