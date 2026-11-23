class_name HudBadge
extends Control
## Seviye rozeti: koyu daire, amber halka, ortada seviye sayısı, üstte küçük "SV".

const DIAMETER: float = 54.0
const RING_WIDTH: float = 3.0
const NUMBER_SIZE: int = 26
const TAG_SIZE: int = 11

var _level: int = 1
var _tag: String = ""


func _init() -> void:
	custom_minimum_size = Vector2(DIAMETER, DIAMETER)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_level(level: int, tag: String) -> void:
	if level == _level and tag == _tag:
		return
	_level = level
	_tag = tag
	queue_redraw()


func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.5 - RING_WIDTH
	draw_circle(c + Vector2(1.5, 2.5), r + RING_WIDTH, Color(0, 0, 0, 0.55))
	draw_circle(c, r, Color(UiPalette.INK, 0.92))
	draw_arc(c, r, 0.0, TAU, 40, UiPalette.AMBER, RING_WIDTH, true)
	draw_arc(c, r - RING_WIDTH, 0.0, TAU, 40, Color(UiPalette.BLOOD, 0.8), 1.5, true)
	var tag_font: Font = UiFonts.heading()
	var tag_w: float = tag_font.get_string_size(_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, TAG_SIZE).x
	draw_string(tag_font, c + Vector2(-tag_w * 0.5, -r * 0.42), _tag, HORIZONTAL_ALIGNMENT_LEFT, -1, TAG_SIZE, UiPalette.ASH)
	var text: String = str(_level)
	var size_px: int = NUMBER_SIZE if text.length() < 3 else NUMBER_SIZE - 6
	var w: float = tag_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
	draw_string(tag_font, c + Vector2(-w * 0.5, r * 0.55), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, UiPalette.BONE)
