class_name CrystalCounter
extends HBoxContainer
## Kristal sayacı: simge + sayı; değer değişince sayarak akar, kısa bir vuruş yapar.

const ICON_SIZE: float = 46.0
const FONT_SIZE: int = 38
const COUNT_TIME: float = 0.45
const POP_SCALE: float = 1.14
const POP_TIME: float = 0.2
const GAP: int = 8

var _label: Label
var _shown: float = 0.0
var _target: int = 0
var _tween: Tween
var _pop: Tween
var _tint_tween: Tween


func _init() -> void:
	add_theme_constant_override("separation", GAP)
	alignment = BoxContainer.ALIGNMENT_END
	var icon: TextureRect = TextureRect.new()
	icon.texture = Emblems.tex(&"icon_crystal")
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	_label = Label.new()
	_label.add_theme_font_override("font", UiFonts.heading())
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_color", UiPalette.BONE)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("shadow_offset_x", 3)
	_label.add_theme_constant_override("shadow_offset_y", 3)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.text = "0"
	add_child(_label)
	resized.connect(func() -> void: pivot_offset = size * 0.5)


func set_value(value: int, animate: bool) -> void:
	if value == _target and animate:
		return
	_target = value
	if _tween != null:
		_tween.kill()
	if not animate or not Tuning.FEATURE_UI_MOTION:
		_show(float(value))
		return
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_method(_show, _shown, float(value), COUNT_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pulse(UiPalette.GOLD)


## Kısa büyüme + renk vuruşu (kazanç: altın, yetersizlik: kırmızı).
func pulse(color: Color) -> void:
	if not Tuning.FEATURE_UI_MOTION:
		return
	if _pop != null:
		_pop.kill()
	_label.add_theme_color_override("font_color", color)
	_pop = create_tween()
	_pop.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_pop.tween_property(self, "scale", Vector2.ONE * POP_SCALE, POP_TIME * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pop.tween_property(self, "scale", Vector2.ONE, POP_TIME)
	if _tint_tween != null:
		_tint_tween.kill()
	_tint_tween = create_tween()
	_tint_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tint_tween.tween_method(_tint, color, UiPalette.BONE, POP_TIME * 2.0)


func _tint(color: Color) -> void:
	_label.add_theme_color_override("font_color", color)


func _show(value: float) -> void:
	_shown = value
	_label.text = str(roundi(value))
