class_name HudVitals
extends HudGroup
## Sol üst: seviye rozeti + can çubuğu (sayı, hasar gölgesi, düşük canda nabız) + takla şarjı + XP ince çubuğu.
## Setter'lar yalnız değer değişince iş yapar (her karede çağrılabilir).

const BAR_WIDTH: float = 250.0
const HP_HEIGHT: float = 26.0
const DASH_HEIGHT: float = 10.0
const XP_HEIGHT: float = 9.0
const GAP: int = 5
const BADGE_GAP: int = 10
const HP_TEXT_SIZE: int = 15
const PULSE_HZ: float = 1.8
const LOW_THRESHOLD: float = Tuning.LOW_HEALTH_THRESHOLD
const HP_COLOR: Color = Color("B3121A")
const HP_LOW_COLOR: Color = Color("FF3B2A")
const DASH_READY_COLOR: Color = Color("7EC0F2")
const DASH_CHARGING_COLOR: Color = Color("2D5E92")
const XP_COLOR: Color = Color("D9A62E")
const PLATE_COLOR: Color = Color(0.03, 0.025, 0.02, 0.55)

var _badge: HudBadge = null
var _hp: GrungeBar = null
var _hp_text: Label = null
var _dash: GrungeBar = null
var _xp: GrungeBar = null
var _hp_now: float = -1.0
var _hp_max: float = -1.0
var _hp_shown: int = -1
var _dash_now: float = -1.0
var _xp_now: float = -1.0
var _low: bool = false
var _clock: float = 0.0


func _init() -> void:
	configure(Vector2(0.0, 0.0), 14.0, "band_b", PLATE_COLOR, Vector2i(14, 10))
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", BADGE_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_content(row)
	_badge = HudBadge.new()
	_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_badge)
	var bars: VBoxContainer = VBoxContainer.new()
	bars.add_theme_constant_override("separation", GAP)
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(bars)
	_hp = _make_bar(BAR_WIDTH, HP_HEIGHT, HP_COLOR)
	bars.add_child(_hp)
	_hp_text = Label.new()
	_hp_text.add_theme_font_override("font", UiFonts.heading())
	_hp_text.add_theme_font_size_override("font_size", HP_TEXT_SIZE)
	_hp_text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_hp_text.add_theme_constant_override("outline_size", 4)
	_hp_text.add_theme_constant_override("shadow_offset_x", 0)
	_hp_text.add_theme_constant_override("shadow_offset_y", 0)
	_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiAssets.fill(_hp_text)
	_hp.add_child(_hp_text)
	_dash = _make_bar(BAR_WIDTH, DASH_HEIGHT, DASH_READY_COLOR)
	_dash.visible = Tuning.FEATURE_DASH
	bars.add_child(_dash)
	_xp = _make_bar(BAR_WIDTH, XP_HEIGHT, XP_COLOR)
	_xp.visible = Tuning.FEATURE_PICKUPS
	_badge.visible = Tuning.FEATURE_PICKUPS
	bars.add_child(_xp)
	set_process(false)


func _make_bar(width: float, height: float, color: Color) -> GrungeBar:
	var bar: GrungeBar = GrungeBar.new()
	bar.custom_minimum_size = Vector2(width, height)
	bar.fill_color = color
	return bar


func set_health(current: float, maximum: float) -> void:
	if is_equal_approx(current, _hp_now) and is_equal_approx(maximum, _hp_max):
		return
	_hp_now = current
	_hp_max = maximum
	_hp.set_value(current, maximum)
	var shown: int = ceili(current)
	if shown != _hp_shown:
		_hp_shown = shown
		_hp_text.text = "%d/%d" % [shown, ceili(maximum)]
	var low: bool = LowHealthRule.is_low(current / maxf(maximum, 0.001), LOW_THRESHOLD)
	if low != _low:
		_low = low
		set_process(low)
		if not low:
			_hp.fill_color = HP_COLOR
			_hp_text.add_theme_color_override("font_color", UiPalette.BONE)


func set_dash(readiness: float) -> void:
	if is_equal_approx(readiness, _dash_now):
		return
	_dash_now = readiness
	_dash.set_value(readiness, 1.0)
	_dash.fill_color = DASH_READY_COLOR if readiness >= 1.0 else DASH_CHARGING_COLOR


func set_xp(progress: float) -> void:
	if is_equal_approx(progress, _xp_now):
		return
	_xp_now = progress
	_xp.set_value(progress, 1.0)


func set_level(level: int) -> void:
	_badge.set_level(level, Loc.t(&"hud.level_short"))


func _process(delta: float) -> void:
	_clock += delta
	var k: float = HudRules.pulse(_clock, PULSE_HZ)
	_hp.fill_color = HP_COLOR.lerp(HP_LOW_COLOR, k)
	_hp_text.add_theme_color_override("font_color", UiPalette.BONE.lerp(Color.WHITE, k))
