class_name MarketSlot
extends Button
## Silah yuvası: silah amblemi + kademe çizikleri. Boş yuva kesik çerçeve. armed: satış onayı bekliyor.

const BORDER: float = 2.0
const INSET: float = 7.0
const TICK_SIZE: Vector2 = Vector2(9.0, 3.0)
const TICK_GAP: float = 2.0
const TICK_MARGIN: float = 7.0
const CONFIRM_HEIGHT: float = 22.0
const CONFIRM_FONT: int = 12
const BODY_COLOR: Color = Color(0.05, 0.04, 0.035, 0.9)

var weapon_id: StringName = &""
var tier: int = 0
var armed: bool = false:
	set(v):
		armed = v
		queue_redraw()
var _sell: int = 0


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for st: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(st, StyleBoxEmpty.new())


func _ready() -> void:
	for sig: Signal in [mouse_entered, mouse_exited, focus_entered, focus_exited]:
		sig.connect(queue_redraw)


## slot: {id, tier} ya da boş sözlük (boş yuva).
func setup(slot: Dictionary, sell_value: int) -> void:
	weapon_id = slot.get("id", &"")
	tier = int(slot.get("tier", 0))
	_sell = sell_value
	tooltip_text = "" if is_empty() or Tuning.FEATURE_WEAPON_TOOLTIP else Loc.weapon_name(weapon_id)
	queue_redraw()


func is_empty() -> bool:
	return weapon_id == &""


func _draw() -> void:
	var lit: bool = is_hovered() or has_focus()
	var border: Color = UiPalette.BLOOD.lightened(0.2) if armed else (UiPalette.BONE if lit else Color(UiPalette.ASH, 0.45))
	draw_rect(Rect2(Vector2.ZERO, size), BODY_COLOR)
	if is_empty():
		var mid: Vector2 = size * 0.5
		draw_line(mid + Vector2(-6.0, 0.0), mid + Vector2(6.0, 0.0), Color(UiPalette.ASH, 0.3), 2.0)
		draw_line(mid + Vector2(0.0, -6.0), mid + Vector2(0.0, 6.0), Color(UiPalette.ASH, 0.3), 2.0)
	else:
		_draw_weapon()
	draw_rect(Rect2(Vector2.ONE, size - Vector2(2.0, 2.0)), border, false, BORDER)
	if armed:
		_draw_confirm()


func _draw_weapon() -> void:
	var tex: Texture2D = Emblems.tex(StringName("weapon_" + weapon_id))
	var box: Rect2 = Rect2(Vector2(INSET, INSET), size - Vector2(INSET, INSET) * 2.0)
	var k: float = minf(box.size.x / tex.get_width(), box.size.y / tex.get_height())
	var draw_size: Vector2 = Vector2(tex.get_width(), tex.get_height()) * k
	draw_texture_rect(tex, Rect2(box.get_center() - draw_size * 0.5, draw_size), false)
	var tick_color: Color = UiPalette.tier_color(tier - 1) if tier > 1 else UiPalette.BONE
	for i: int in tier:
		var pos: Vector2 = Vector2(TICK_MARGIN + i * (TICK_SIZE.x + TICK_GAP), size.y - TICK_MARGIN - TICK_SIZE.y)
		draw_rect(Rect2(pos, TICK_SIZE), tick_color)


func _draw_confirm() -> void:
	var bar: Rect2 = Rect2(0.0, size.y - CONFIRM_HEIGHT, size.x, CONFIRM_HEIGHT)
	draw_rect(bar, Color(UiPalette.BLOOD, 0.95))
	var font: Font = UiFonts.heading()
	var label: String = Loc.t(&"run.shop.sell", [_sell])
	var fs: int = CONFIRM_FONT
	while fs > 8 and font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > size.x - 6.0:
		fs -= 1
	var width: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, Vector2((size.x - width) * 0.5, bar.position.y + CONFIRM_HEIGHT * 0.5 + fs * 0.36), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiPalette.BONE)
