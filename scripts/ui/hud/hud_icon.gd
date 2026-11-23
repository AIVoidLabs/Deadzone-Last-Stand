class_name HudIcon
extends Control
## Küçük HUD simgesi: amblem dokusu varsa o, yoksa elle çizilen yedek (kristal ya da öldürme).

enum Glyph { CRYSTAL, KILL, BULLET }

const SHADOW: Vector2 = Vector2(1.5, 2.0)
const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.7)

var emblem: StringName = &""
var glyph: Glyph = Glyph.CRYSTAL
var tint: Color = Color.WHITE


static func create(p_emblem: StringName, p_glyph: Glyph, p_tint: Color, px: float) -> HudIcon:
	var icon: HudIcon = HudIcon.new()
	icon.emblem = p_emblem
	icon.glyph = p_glyph
	icon.tint = p_tint
	icon.custom_minimum_size = Vector2(px, px)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	if Emblems.has(emblem):
		draw_texture_rect(Emblems.tex(emblem), Rect2(SHADOW, size), false, SHADOW_COLOR)
		draw_texture_rect(Emblems.tex(emblem), rect, false)
		return
	_draw_glyph(SHADOW, SHADOW_COLOR)
	_draw_glyph(Vector2.ZERO, tint)


func _draw_glyph(off: Vector2, color: Color) -> void:
	var c: Vector2 = size * 0.5 + off
	var r: float = minf(size.x, size.y) * 0.42
	if glyph == Glyph.CRYSTAL:
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.75, -r * 0.1), c + Vector2(0, r), c + Vector2(-r * 0.75, -r * 0.1)]), color)
		if off == Vector2.ZERO:
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.75, -r * 0.1), c + Vector2(0, -r * 0.1)]), color.lightened(0.35))
	elif glyph == Glyph.BULLET:
		var k: float = r * 0.4
		draw_circle(c, r, Color(UiPalette.INK, 0.7))
		draw_arc(c, r, 0.0, TAU, 28, Color(UiPalette.ASH, 0.4), 1.5, true)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -k), c + Vector2(k, 0), c + Vector2(0, k), c + Vector2(-k, 0)]), color)
	else:
		draw_arc(c, r * 0.8, 0.0, TAU, 24, color, 2.5, true)
		draw_line(c + Vector2(-r, 0), c + Vector2(-r * 0.35, 0), color, 2.5)
		draw_line(c + Vector2(r, 0), c + Vector2(r * 0.35, 0), color, 2.5)
		draw_line(c + Vector2(0, -r), c + Vector2(0, -r * 0.35), color, 2.5)
		draw_line(c + Vector2(0, r), c + Vector2(0, r * 0.35), color, 2.5)
