class_name HudBossView
extends HudGroup
## Boss çubuğunun yeni görünümü: kara plaka, kan kırmızısı ad, geniş çubuk (hasarda parlar, öfkede kızıl), öfke eşiği çentiği.

const BAR_SIZE: Vector2 = Vector2(560.0, 24.0)
const TOP_OFFSET: float = 112.0
const NAME_SIZE: int = 22
const BAR_COLOR: Color = Color("D9742A")
const RAGE_COLOR: Color = Color("F0281E")
const NAME_COLOR: Color = Color("FF6A4A")
const TICK_COLOR: Color = Color(0.95, 0.92, 0.85, 0.9)
const TICK_WIDTH: float = 2.0
const PLATE_COLOR: Color = Color(0.03, 0.02, 0.02, 0.66)

var _name: Label = null
var _bar: GrungeBar = null
var _tick: ColorRect = null
var _hp_now: float = -1.0
var _raged: bool = false


func _init() -> void:
	configure(Vector2(0.5, 0.0), TOP_OFFSET, "band_b", PLATE_COLOR, Vector2i(26, 8))
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_content(box)
	_name = Label.new()
	_name.add_theme_font_override("font", UiFonts.heading())
	_name.add_theme_font_size_override("font_size", NAME_SIZE)
	_name.add_theme_color_override("font_color", NAME_COLOR)
	_name.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_name.add_theme_constant_override("shadow_offset_x", 2)
	_name.add_theme_constant_override("shadow_offset_y", 3)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_name)
	_bar = GrungeBar.new()
	_bar.custom_minimum_size = BAR_SIZE
	_bar.fill_color = BAR_COLOR
	box.add_child(_bar)
	_tick = ColorRect.new()
	_tick.color = TICK_COLOR
	_tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tick.anchor_top = 0.0
	_tick.anchor_bottom = 1.0
	_bar.add_child(_tick)
	visible = false


func set_name_text(text: String) -> void:
	_name.text = text


## Ölçek: üst boşluk da ölçeğe uyar (dalga saatinin altında kalsın).
func apply_scale(factor: float) -> void:
	super.apply_scale(factor)
	offset_top = TOP_OFFSET * factor
	offset_bottom = offset_top


## hp_frac: kalan can oranı; threshold: öfke eşiği (0..1).
func set_status(hp_frac: float, raged: bool, threshold: float) -> void:
	if not is_equal_approx(hp_frac, _hp_now):
		_hp_now = hp_frac
		_bar.set_value(hp_frac, 1.0)
	if raged != _raged:
		_raged = raged
		_bar.fill_color = RAGE_COLOR if raged else BAR_COLOR
	_tick.anchor_left = threshold
	_tick.anchor_right = threshold
	_tick.offset_left = -TICK_WIDTH * 0.5
	_tick.offset_right = TICK_WIDTH * 0.5
	_tick.visible = threshold > 0.0 and threshold < 1.0
