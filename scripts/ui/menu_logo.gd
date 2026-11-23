class_name MenuLogo
extends Control
## Oyun başlığı: iki satır (DEADZONE kırmızı-turuncu, LAST STAND kemik), hafif eğik; harflerden kan akar.
## Akıntılar yavaşça uzar ve durur (aşınmış afiş hissi).

const TOP_SIZE: int = 112
const BOTTOM_SIZE: int = 64
const TILT_DEG: float = -2.4
const LINE_GAP: int = -14
const DRIP_COUNT: int = 7
const DRIP_SPAN: Vector2 = Vector2(0.06, 0.94)
const DRIP_LENGTH: Vector2 = Vector2(26.0, 84.0)
const DRIP_WIDTH: Vector2 = Vector2(7.0, 13.0)
const DRIP_GROW_TIME: float = 5.0
const DRIP_START_Y: float = 0.80
const DRIP_COLOR: Color = Color(0.70, 0.07, 0.09, 0.95)
const SEED: int = 11

var _top: GrungeTitle = null
var _bottom: GrungeTitle = null
var _drips: Array[Dictionary] = []
var _age: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", LINE_GAP)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	_top = GrungeTitle.new()
	_top.font_size = TOP_SIZE
	_bottom = GrungeTitle.new()
	_bottom.font_size = BOTTOM_SIZE
	column.add_child(_top)
	column.add_child(_bottom)
	_make_drips()
	refresh_text()
	column.resized.connect(func() -> void:
		custom_minimum_size = column.get_combined_minimum_size()
		pivot_offset = size * 0.5
		queue_redraw())
	rotation_degrees = TILT_DEG


func refresh_text() -> void:
	_top.set_text(Loc.t(&"menu.title.accent"), "")
	_bottom.set_text("", Loc.t(&"menu.title.rest"))


func _make_drips() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED
	for i: int in DRIP_COUNT:
		var u: float = lerpf(DRIP_SPAN.x, DRIP_SPAN.y, (float(i) + rng.randf_range(0.1, 0.9)) / float(DRIP_COUNT))
		_drips.append({
			"u": u, "len": rng.randf_range(DRIP_LENGTH.x, DRIP_LENGTH.y), "w": rng.randf_range(DRIP_WIDTH.x, DRIP_WIDTH.y),
			"delay": rng.randf_range(0.0, 1.6),
		})


func _process(delta: float) -> void:
	if _age < DRIP_GROW_TIME + 2.0:
		_age += delta
		queue_redraw()


func _draw() -> void:
	var top_height: float = _top.size.y
	var width: float = _top.size.x
	var x0: float = _top.position.x
	var y0: float = _top.position.y + top_height * DRIP_START_Y
	for drip: Dictionary in _drips:
		var t: float = clampf((_age - float(drip["delay"])) / DRIP_GROW_TIME, 0.0, 1.0)
		t = 1.0 - pow(1.0 - t, 3.0)
		var length: float = float(drip["len"]) * t
		if length < 1.0:
			continue
		var w: float = float(drip["w"])
		var x: float = x0 + width * float(drip["u"])
		draw_rect(Rect2(x - w * 0.5, y0, w, length), DRIP_COLOR)
		draw_circle(Vector2(x, y0 + length), w * 0.75, DRIP_COLOR)
