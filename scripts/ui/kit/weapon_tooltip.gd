class_name WeaponTooltip
extends GrungePanel
## Silah ipucu paneli: ad, kademe, istatistik satırları. Hedef denetimin üstünde (yer yoksa altında) açılır, pencereden taşmaz.
## Sahibi bir tam ekran Control'a ekler; fareyi yutmaz. show_for / hide_tip ile yönetilir.

const GAP: float = 8.0
const EDGE: float = 8.0
const TITLE_SIZE: int = 16
const LINE_SIZE: int = 14
const MIN_WIDTH: float = 168.0
const LINE_GAP: int = 3

var _box: VBoxContainer = null


func _init() -> void:
	super()
	content_margin = 12
	panel_alpha = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 20
	visible = false
	custom_minimum_size.x = MIN_WIDTH
	_box = VBoxContainer.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_theme_constant_override("separation", LINE_GAP)
	add_child(_box)


func show_for(target: Control, id: StringName, tier: int) -> void:
	for child: Node in _box.get_children():
		_box.remove_child(child)
		child.queue_free()
	_box.add_child(_label(Loc.weapon_name(id).to_upper(), UiFonts.heading(), TITLE_SIZE, UiPalette.BONE))
	_box.add_child(_label(Loc.tier_name(tier - 1), UiFonts.heading(), LINE_SIZE - 1, UiPalette.tier_color(tier - 1)))
	for text: String in WeaponReadout.tooltip_lines(id, tier):
		_box.add_child(_label(text, UiFonts.body(), LINE_SIZE, UiPalette.BONE))
	visible = true
	size = get_combined_minimum_size()
	global_position = place(target.get_global_transform() * Rect2(Vector2.ZERO, target.size), size, get_viewport_rect().size)


func hide_tip() -> void:
	visible = false


## Hedefin üstüne ortalı; üstte yer yoksa altına; pencere kenarından EDGE içeride kalır (saf).
static func place(target: Rect2, tip: Vector2, view: Vector2) -> Vector2:
	var x: float = target.get_center().x - tip.x * 0.5
	var y: float = target.position.y - tip.y - GAP
	if y < EDGE:
		y = target.end.y + GAP
	return Vector2(clampf(x, EDGE, maxf(EDGE, view.x - tip.x - EDGE)), clampf(y, EDGE, maxf(EDGE, view.y - tip.y - EDGE)))


static func _label(text: String, font: Font, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
