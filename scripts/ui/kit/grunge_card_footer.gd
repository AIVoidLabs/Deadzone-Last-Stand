class_name GrungeCardFooter
extends Control
## Kartın alt çizgisi: tuş ipucu rozeti, nadirlik çizikleri, fiyat. Yalnız çizim (GrungeCard kullanır).

const HINT_POS: Vector2 = Vector2(0.115, 0.075)
const HINT_RADIUS: float = 0.052
const TICK_SPACING: float = 0.028
const TICK_HEIGHT: float = 0.034
const BOTTOM_Y: float = 0.94
const LEFT_X: float = 0.10
const RIGHT_X: float = 0.90
## Boyut 0 olursa yazı motoru hata basar (kart henüz yerleşmemişken çizim).
const MIN_FONT: int = 8

var tier: int = -1
var tier_name: String = ""
var hint: String = ""
var price: int = -1
var price_color: Color = UiPalette.GOLD
var scale_k: float = 1.0
var locked: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if hint != "":
		_draw_hint()
	if tier >= 0:
		_draw_tier()
	if price >= 0:
		_draw_price()
	if locked:
		_draw_lock()


func _draw_hint() -> void:
	var c: Vector2 = Vector2(size.x * HINT_POS.x, size.y * HINT_POS.y)
	var r: float = size.x * HINT_RADIUS
	draw_circle(c, r, Color(0.02, 0.015, 0.012, 0.8))
	draw_arc(c, r, 0.0, TAU, 28, Color(UiPalette.BONE, 0.85), 2.0 * scale_k, true)
	var fs: int = maxi(MIN_FONT, roundi(15.0 * scale_k))
	var f: Font = UiFonts.heading()
	var ts: Vector2 = f.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(f, c + Vector2(-ts.x * 0.5, ts.y * 0.3), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiPalette.BONE)


func _draw_tier() -> void:
	var col: Color = UiPalette.tier_color(tier)
	var y1: float = size.y * BOTTOM_Y
	var x: float = size.x * LEFT_X
	var h: float = size.y * TICK_HEIGHT
	var step: float = size.x * TICK_SPACING
	for i: int in tier + 1:
		draw_line(Vector2(x + i * step, y1), Vector2(x + i * step + h * 0.35, y1 - h), col, 3.0 * scale_k, true)
	if tier_name != "":
		var fs: int = maxi(11, roundi(13.0 * scale_k))
		draw_string(UiFonts.heading(), Vector2(x + (tier + 1) * step + 6.0 * scale_k, y1 - 1.0), tier_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col.lerp(UiPalette.BONE, 0.35))


func _draw_price() -> void:
	var fs: int = maxi(MIN_FONT, roundi(18.0 * scale_k))
	var f: Font = UiFonts.heading()
	var txt: String = str(price)
	var ts: Vector2 = f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var rx: float = size.x * RIGHT_X
	var y: float = size.y * BOTTOM_Y
	draw_string(f, Vector2(rx - ts.x, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, price_color)
	# kristal: küçük baklava
	var d: float = fs * 0.42
	var c: Vector2 = Vector2(rx - ts.x - d * 1.6, y - fs * 0.34)
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -d), c + Vector2(d * 0.75, 0), c + Vector2(0, d), c + Vector2(-d * 0.75, 0)]), price_color)


## Kilit köşe işareti: sağ üstte zincir halkalı asma kilit.
func _draw_lock() -> void:
	var k: float = scale_k
	var c: Vector2 = Vector2(size.x - 26.0 * k, 28.0 * k)
	draw_circle(c, 17.0 * k, Color(0.02, 0.015, 0.012, 0.85))
	draw_arc(c + Vector2(0, -3.0 * k), 6.0 * k, PI, TAU, 14, UiPalette.BONE, 2.4 * k, true)
	draw_rect(Rect2(c + Vector2(-8.0 * k, -3.0 * k), Vector2(16.0 * k, 12.0 * k)), UiPalette.BONE)
	draw_circle(c + Vector2(0, 2.5 * k), 1.8 * k, Color(0.05, 0.04, 0.03))
	var link: Color = Color(UiPalette.ASH, 0.9)
	for i: int in 3:
		draw_arc(c + Vector2(-20.0 * k - i * 7.0 * k, 4.0 * k + i * 2.0 * k), 3.6 * k, 0.0, TAU, 8, link, 1.8 * k, true)
