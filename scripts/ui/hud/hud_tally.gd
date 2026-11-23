class_name HudTally
extends HudGroup
## Sağ üst: kristal ve öldürme sayacı. Sayı artınca küçük zıplar (yaylı, tween üretmez).

const ICON_SIZE: float = 28.0
const VALUE_SIZE: int = 27
const VALUE_MIN_WIDTH: float = 74.0
const POP_SCALE: float = 0.28
const POP_RATE: float = 5.0
const ROW_GAP: int = 3
const PLATE_COLOR: Color = Color(0.03, 0.025, 0.02, 0.55)

var _crystal_value: Label = null
var _kill_value: Label = null
var _crystals: int = -1
var _kills: int = -1
var _crystal_pop: float = 0.0
var _kill_pop: float = 0.0


func _init() -> void:
	configure(Vector2(1.0, 0.0), 14.0, "band_c", PLATE_COLOR, Vector2i(16, 8))
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", ROW_GAP)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_content(box)
	if Tuning.FEATURE_PICKUPS:
		_crystal_value = _add_row(box, HudIcon.create(&"icon_crystal", HudIcon.Glyph.CRYSTAL, UiPalette.GOLD, ICON_SIZE), UiPalette.GOLD)
	_kill_value = _add_row(box, HudIcon.create(&"icon_kill", HudIcon.Glyph.KILL, UiPalette.BONE, ICON_SIZE), UiPalette.BONE)
	set_process(false)


func _add_row(box: VBoxContainer, icon: HudIcon, color: Color) -> Label:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	var value: Label = Label.new()
	value.add_theme_font_override("font", UiFonts.heading())
	value.add_theme_font_size_override("font_size", VALUE_SIZE)
	value.add_theme_color_override("font_color", color)
	value.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	value.add_theme_constant_override("shadow_offset_x", 2)
	value.add_theme_constant_override("shadow_offset_y", 3)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.custom_minimum_size = Vector2(VALUE_MIN_WIDTH, 0.0)
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value.resized.connect(func() -> void: value.pivot_offset = Vector2(value.size.x, value.size.y * 0.5))
	row.add_child(value)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	return value


func set_crystals(value: int) -> void:
	if value == _crystals or _crystal_value == null:
		return
	if _crystals >= 0 and value > _crystals:
		_crystal_pop = 1.0
		set_process(true)
	_crystals = value
	_crystal_value.text = str(value)


func set_kills(value: int) -> void:
	if value == _kills:
		return
	if _kills >= 0 and value > _kills:
		_kill_pop = 1.0
		set_process(true)
	_kills = value
	_kill_value.text = str(value)


func _process(delta: float) -> void:
	_kill_pop = HudRules.decay(_kill_pop, delta, POP_RATE)
	_kill_value.scale = Vector2.ONE * (1.0 + POP_SCALE * _kill_pop)
	if _crystal_value != null:
		_crystal_pop = HudRules.decay(_crystal_pop, delta, POP_RATE)
		_crystal_value.scale = Vector2.ONE * (1.0 + POP_SCALE * _crystal_pop)
	if _kill_pop <= 0.0 and _crystal_pop <= 0.0:
		set_process(false)
