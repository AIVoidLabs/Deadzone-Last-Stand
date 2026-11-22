class_name GrungeButton
extends Button
## Fırça darbesi zeminli düğme. Üzerine gelince / odakta boya soldan sağa akar.
## variant: normal, primary, danger, small.

const VARIANTS: Dictionary = {
	&"normal": {"size": Vector2(280, 56), "font": 21, "base": Color("352B27"), "fill": Color("D8400F")},
	&"primary": {"size": Vector2(320, 64), "font": 24, "base": Color("A8141B"), "fill": Color("FF5A1C")},
	&"danger": {"size": Vector2(280, 56), "font": 21, "base": Color("3A0F10"), "fill": Color("C4161E")},
	&"small": {"size": Vector2(150, 42), "font": 16, "base": Color("352B27"), "fill": Color("D8400F")},
}
const FILL_TIME: float = 0.26
const PRESS_SCALE: float = 0.965
const DISABLED_ALPHA: float = 0.45
const TEXT_OUTLINE: int = 5

var variant: StringName = &"normal":
	set(v):
		variant = v
		_apply_variant()

var _base: TextureRect = null
var _fill: TextureRect = null
var _sweep: float = 0.0
var _tween: Tween = null
var _lit: bool = false


static func create(text: String, variant_id: StringName = &"normal") -> GrungeButton:
	var b: GrungeButton = GrungeButton.new()
	b.text = text
	b.variant = variant_id
	return b


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_base = UiAssets.brush_rect("btn_stroke_a", Color.WHITE, 0.5)
	_fill = UiAssets.brush_rect("btn_stroke_a", Color.WHITE, 0.4)
	for r: TextureRect in [_base, _fill]:
		r.show_behind_parent = true
		UiAssets.fill(r)
		r.offset_left = -10
		r.offset_right = 10
		r.offset_top = -4
		r.offset_bottom = 4
		add_child(r)
	_fill.texture = UiAssets.tex("btn_stroke_b")
	(_fill.material as ShaderMaterial).set_shader_parameter("mask_tex", UiAssets.tex("btn_stroke_b"))
	(_fill.material as ShaderMaterial).set_shader_parameter("sweep", 0.0)
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	add_theme_constant_override("outline_size", TEXT_OUTLINE)
	mouse_entered.connect(_refresh_lit)
	mouse_exited.connect(_refresh_lit)
	focus_entered.connect(_refresh_lit)
	focus_exited.connect(_refresh_lit)
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	resized.connect(func() -> void: pivot_offset = size * 0.5)
	_apply_variant()


func _apply_variant() -> void:
	if _base == null:
		return
	var v: Dictionary = VARIANTS.get(variant, VARIANTS[&"normal"])
	custom_minimum_size = v["size"]
	add_theme_font_override("font", UiFonts.heading())
	add_theme_font_size_override("font_size", v["font"])
	var bm: ShaderMaterial = _base.material
	bm.set_shader_parameter("tint", v["base"])
	bm.set_shader_parameter("tint_dark", (v["base"] as Color).darkened(0.5))
	var fm: ShaderMaterial = _fill.material
	fm.set_shader_parameter("tint", v["fill"])
	fm.set_shader_parameter("tint_dark", (v["fill"] as Color).darkened(0.5))


func _notification(what: int) -> void:
	if what == NOTIFICATION_DISABLED or what == NOTIFICATION_ENABLED:
		modulate.a = DISABLED_ALPHA if disabled else 1.0


func _refresh_lit() -> void:
	var lit: bool = (is_hovered() or has_focus()) and not disabled
	if lit == _lit:
		return
	_lit = lit
	_animate_sweep(1.0 if lit else 0.0)


func _animate_sweep(to: float) -> void:
	if _tween != null:
		_tween.kill()
	if not Tuning.FEATURE_UI_MOTION:
		_set_sweep(to)
		return
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_method(_set_sweep, _sweep, to, FILL_TIME * absf(to - _sweep) + 0.001)


func _set_sweep(v: float) -> void:
	_sweep = v
	(_fill.material as ShaderMaterial).set_shader_parameter("sweep", v)


func _on_down() -> void:
	scale = Vector2.ONE * PRESS_SCALE


func _on_up() -> void:
	scale = Vector2.ONE
