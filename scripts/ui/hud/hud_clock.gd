class_name HudClock
extends HudGroup
## Üst orta: "DALGA 2/5" + büyük süre. Son 5 sn'de süre kırmızı ve her saniye vuruşlu; dalga bitince "TEMİZLENDİ".

const WAVE_SIZE: int = 19
const TIME_SIZE: int = 46
const TIME_MIN_WIDTH: float = 180.0
const WAVE_MIN_WIDTH: float = 160.0
const POP_SCALE: float = 0.32
const POP_RATE: float = 3.2
const PLATE_COLOR: Color = Color(0.03, 0.025, 0.02, 0.6)

var _wave: Label = null
var _time: Label = null
var _wave_text: String = ""
var _time_text: String = ""
var _state: int = 0
var _pop: float = 0.0


func _init() -> void:
	configure(Vector2(0.5, 0.0), 12.0, "band_a", PLATE_COLOR, Vector2i(26, 6))
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", -4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_content(box)
	_wave = _make_label(WAVE_SIZE, UiPalette.ASH, WAVE_MIN_WIDTH)
	box.add_child(_wave)
	_time = _make_label(TIME_SIZE, UiPalette.BONE, TIME_MIN_WIDTH)
	box.add_child(_time)
	_time.resized.connect(func() -> void: _time.pivot_offset = _time.size * 0.5)
	set_process(false)


func _make_label(font_size: int, color: Color, min_width: float) -> Label:
	var l: Label = Label.new()
	l.add_theme_font_override("font", UiFonts.heading())
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 3)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(min_width, 0.0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Dalga etiketi: dalga yoksa (sonsuz kip) gizlenir. last: son dalga (kor turuncu).
func set_wave(number: int, total: int, last: bool) -> void:
	_wave.visible = total > 0
	if total <= 0:
		return
	var text: String = Loc.t(&"hud.final_wave") if last else Loc.t(&"hud.wave_fmt", [number, total])
	if text == _wave_text:
		return
	_wave_text = text
	_wave.text = text
	_wave.add_theme_color_override("font_color", UiPalette.EMBER if last else UiPalette.ASH)


## Süre (tam sn). final_n: son saniye sayacı (0 = değil). cleared: dalga bitti, süre yerine "TEMİZLENDİ".
func set_time(seconds: int, final_n: int, cleared: bool) -> void:
	var state: int = 2 if cleared else (1 if final_n > 0 else 0)
	var text: String = Loc.t(&"hud.cleared_short") if cleared else Loc.clock(seconds)
	if text == _time_text and state == _state:
		return
	var tick: bool = final_n > 0 and text != _time_text
	_time_text = text
	if state != _state:
		_state = state
		_time.add_theme_color_override("font_color", [UiPalette.BONE, UiPalette.BAD, UiPalette.GOOD][state])
		_time.add_theme_font_size_override("font_size", TIME_SIZE if state != 2 else TIME_SIZE - 12)
	_time.text = text
	if tick:
		_pop = 1.0
		set_process(true)


func _process(delta: float) -> void:
	_pop = HudRules.decay(_pop, delta, POP_RATE)
	_time.scale = Vector2.ONE * (1.0 + POP_SCALE * _pop)
	if _pop <= 0.0:
		set_process(false)
