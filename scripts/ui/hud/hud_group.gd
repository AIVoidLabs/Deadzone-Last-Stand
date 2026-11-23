class_name HudGroup
extends MarginContainer
## HUD köşe grubu: köşeye çapalı, game/hud_scale köşeden büyür/küçülür, isteğe bağlı fırça zemin plakası.
## corner: (0,0) sol üst, (1,0) sağ üst, (0.5,0) üst orta, (0,1) sol alt. İçerik add_content ile eklenir.

const PLATE_DETAIL: float = 0.25

var corner: Vector2 = Vector2.ZERO
var _pad: MarginContainer = null


## Köşe, kenar boşluğu, plaka (maske adı, boşsa yok) ve plaka/iç boşluk ayarı.
func configure(p_corner: Vector2, margin: float, plate_mask: String, plate_color: Color, pad: Vector2i) -> void:
	corner = p_corner
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	anchor_left = corner.x
	anchor_right = corner.x
	anchor_top = corner.y
	anchor_bottom = corner.y
	offset_left = margin * (1.0 - 2.0 * corner.x)
	offset_right = offset_left
	offset_top = margin * (1.0 - 2.0 * corner.y)
	offset_bottom = offset_top
	grow_horizontal = Control.GROW_DIRECTION_BEGIN if corner.x >= 1.0 else (Control.GROW_DIRECTION_BOTH if corner.x > 0.0 else Control.GROW_DIRECTION_END)
	grow_vertical = Control.GROW_DIRECTION_BEGIN if corner.y >= 1.0 else Control.GROW_DIRECTION_END
	if plate_mask != "":
		var plate: TextureRect = UiAssets.brush_rect(plate_mask, plate_color, PLATE_DETAIL)
		plate.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(plate)
	_pad = MarginContainer.new()
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.add_theme_constant_override("margin_left", pad.x)
	_pad.add_theme_constant_override("margin_right", pad.x)
	_pad.add_theme_constant_override("margin_top", pad.y)
	_pad.add_theme_constant_override("margin_bottom", pad.y)
	add_child(_pad)
	resized.connect(_update_pivot)


func add_content(node: Control) -> void:
	_pad.add_child(node)


## HUD ölçeği (köşeden büyür).
func apply_scale(factor: float) -> void:
	scale = Vector2.ONE * factor
	_update_pivot()


func _update_pivot() -> void:
	pivot_offset = Vector2(size.x * corner.x, size.y * corner.y)
