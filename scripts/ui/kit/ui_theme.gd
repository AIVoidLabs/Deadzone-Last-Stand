class_name UiTheme
extends RefCounted
## Tek Theme: Inter gövde yazısı, kemik rengi, boş düğme zemini (zemini GrungeButton çizer), fırça kaydırıcı.

const BODY_SIZE: int = 18
const GRABBER_SIZE: Vector2i = Vector2i(14, 26)
const SLIDER_TRACK_HEIGHT: float = 8.0

static var _theme: Theme = null


static func clear_cache() -> void:
	_theme = null


static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


static func _build() -> Theme:
	var th: Theme = Theme.new()
	th.default_font = UiFonts.body()
	th.default_font_size = BODY_SIZE
	var empty: StyleBoxEmpty = StyleBoxEmpty.new()
	th.set_color("font_color", "Label", UiPalette.BONE)
	th.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.7))
	th.set_constant("shadow_offset_x", "Label", 1)
	th.set_constant("shadow_offset_y", "Label", 2)
	for st: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		th.set_stylebox(st, "Button", empty)
	th.set_font("font", "Button", UiFonts.heading())
	th.set_color("font_color", "Button", UiPalette.BONE)
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_focus_color", "Button", Color.WHITE)
	th.set_color("font_pressed_color", "Button", Color.WHITE)
	th.set_color("font_disabled_color", "Button", UiPalette.ASH.darkened(0.3))
	th.set_color("default_color", "RichTextLabel", UiPalette.BONE)
	th.set_font("normal_font", "RichTextLabel", UiFonts.body())
	th.set_font("bold_font", "RichTextLabel", UiFonts.bold())
	_slider(th)
	_scroll(th)
	return th


static func _slider(th: Theme) -> void:
	var track: StyleBoxFlat = _flat(Color(0.03, 0.025, 0.022, 0.95), Color(UiPalette.ASH, 0.5), 1, 2)
	track.content_margin_top = SLIDER_TRACK_HEIGHT * 0.5
	track.content_margin_bottom = SLIDER_TRACK_HEIGHT * 0.5
	var fill: StyleBoxFlat = _flat(UiPalette.EMBER, Color.TRANSPARENT, 0, 2)
	fill.content_margin_top = SLIDER_TRACK_HEIGHT * 0.5
	fill.content_margin_bottom = SLIDER_TRACK_HEIGHT * 0.5
	th.set_stylebox("slider", "HSlider", track)
	th.set_stylebox("grabber_area", "HSlider", fill)
	th.set_stylebox("grabber_area_highlight", "HSlider", fill)
	th.set_icon("grabber", "HSlider", _grabber(UiPalette.BONE.darkened(0.15)))
	th.set_icon("grabber_highlight", "HSlider", _grabber(Color.WHITE))
	th.set_icon("grabber_disabled", "HSlider", _grabber(UiPalette.ASH.darkened(0.4)))


static func _scroll(th: Theme) -> void:
	th.set_stylebox("scroll", "VScrollBar", _flat(Color(0.03, 0.025, 0.022, 0.8), Color.TRANSPARENT, 0, 2))
	var g: StyleBoxFlat = _flat(UiPalette.ASH.darkened(0.35), Color.TRANSPARENT, 0, 2)
	th.set_stylebox("grabber", "VScrollBar", g)
	th.set_stylebox("grabber_highlight", "VScrollBar", _flat(UiPalette.ASH, Color.TRANSPARENT, 0, 2))
	th.set_stylebox("grabber_pressed", "VScrollBar", _flat(UiPalette.EMBER, Color.TRANSPARENT, 0, 2))


static func _flat(bg: Color, border: Color, bw: int, r: int) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(r)
	return s


## Kaydırıcı tutamağı: kemik rengi dikdörtgen, koyu çerçeveli.
static func _grabber(c: Color) -> Texture2D:
	var img: Image = Image.create(GRABBER_SIZE.x, GRABBER_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(UiPalette.INK)
	img.fill_rect(Rect2i(2, 2, GRABBER_SIZE.x - 4, GRABBER_SIZE.y - 4), c)
	return ImageTexture.create_from_image(img)
