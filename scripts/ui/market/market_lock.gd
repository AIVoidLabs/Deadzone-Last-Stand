class_name MarketLock
extends Button
## Kart altındaki kilit düğmesi: açıkken gri asma kilit, kilitliyken altın kilit + iki yana zincir.
## Çizimi kendisi yapar; durumu set_state ile alır.

const FONT_SIZE: int = 14
const BORDER: float = 2.0
const ICON_WIDTH: float = 16.0
const ICON_GAP: float = 8.0
const CHAIN_LINK: Vector2 = Vector2(11.0, 6.0)
const CHAIN_PAD: float = 8.0
const DIM_ALPHA: float = 0.35
const BODY_COLOR: Color = Color(0.04, 0.032, 0.028, 0.88)

var locked: bool = false
var _active: bool = true


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for st: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(st, StyleBoxEmpty.new())


func _ready() -> void:
	for sig: Signal in [mouse_entered, mouse_exited, focus_entered, focus_exited]:
		sig.connect(queue_redraw)


func set_state(is_locked: bool, active: bool) -> void:
	locked = is_locked
	_active = active
	modulate.a = 1.0 if active else DIM_ALPHA
	queue_redraw()


func _draw() -> void:
	var lit: bool = (is_hovered() or has_focus()) and _active
	var color: Color = UiPalette.GOLD if locked else (UiPalette.BONE if lit else UiPalette.ASH)
	draw_rect(Rect2(Vector2.ZERO, size), BODY_COLOR)
	draw_rect(Rect2(Vector2.ONE, size - Vector2(2.0, 2.0)), Color(color, 0.95 if (locked or lit) else 0.4), false, BORDER)
	var label: String = Loc.t(&"run.shop.locked" if locked else &"run.shop.lock")
	var font: Font = UiFonts.heading()
	var text_width: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var total: float = ICON_WIDTH + ICON_GAP + text_width
	var left: float = (size.x - total) * 0.5
	var mid: float = size.y * 0.5
	_draw_padlock(Vector2(left, mid), color)
	draw_string(font, Vector2(left + ICON_WIDTH + ICON_GAP, mid + FONT_SIZE * 0.36), label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
	if locked:
		_draw_chain(CHAIN_PAD, left - CHAIN_PAD, mid, color)
		_draw_chain(left + total + CHAIN_PAD, size.x - CHAIN_PAD, mid, color)


## Asma kilit: gövde + kilpa (kilitliyken iki bacaklı kapalı, açıkken yana kalkık).
func _draw_padlock(origin: Vector2, color: Color) -> void:
	var body: Rect2 = Rect2(origin + Vector2(0.0, -2.0), Vector2(ICON_WIDTH, 11.0))
	draw_rect(body, color)
	draw_circle(body.get_center(), 1.8, BODY_COLOR)
	var arc_center: Vector2 = origin + Vector2(ICON_WIDTH * 0.5, -6.0 if locked else -8.0)
	draw_arc(arc_center, 4.6, PI, TAU, 12, color, 2.2)
	draw_line(arc_center + Vector2(-4.6, 0.0), origin + Vector2(ICON_WIDTH * 0.5 - 4.6, -2.0), color, 2.2)
	if locked:
		draw_line(arc_center + Vector2(4.6, 0.0), origin + Vector2(ICON_WIDTH * 0.5 + 4.6, -2.0), color, 2.2)


## Dönüşümlü yatay/dikey halkalardan zincir.
func _draw_chain(from_x: float, to_x: float, mid: float, color: Color) -> void:
	var x: float = from_x
	var flat_link: bool = true
	while x + CHAIN_LINK.x <= to_x:
		var link: Vector2 = CHAIN_LINK if flat_link else Vector2(CHAIN_LINK.y, CHAIN_LINK.x)
		draw_rect(Rect2(Vector2(x, mid - link.y * 0.5), link), color, false, 1.8)
		x += CHAIN_LINK.x * 0.7 if flat_link else CHAIN_LINK.y + 1.0
		flat_link = not flat_link
