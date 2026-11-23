class_name GrungeTitle
extends HBoxContainer
## İki renkli başlık: vurgu (turuncu-kırmızı) + gövde (kemik). Yazıda aşınma.

@export var font_size: int = 56:
	set(v):
		font_size = v
		_restyle()

const SHADOW_OFFSET: Vector2i = Vector2i(3, 4)
const GAP: int = 14

var _accent: Label = null
var _rest: Label = null


func _init() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", GAP)
	_accent = _make_label(UiPalette.EMBER)
	_rest = _make_label(UiPalette.BONE)
	add_child(_accent)
	add_child(_rest)
	_restyle()


func _make_label(c: Color) -> Label:
	var l: Label = Label.new()
	l.add_theme_font_override("font", UiFonts.title())
	l.add_theme_color_override("font_color", c)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("shadow_offset_x", SHADOW_OFFSET.x)
	l.add_theme_constant_override("shadow_offset_y", SHADOW_OFFSET.y)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.material = UiAssets.mat("text_wear")
	return l


func set_text(accent: String, rest: String) -> void:
	_accent.text = accent
	_accent.visible = accent != ""
	_rest.text = rest
	_rest.visible = rest != ""


func set_colors(accent: Color, rest: Color) -> void:
	_accent.add_theme_color_override("font_color", accent)
	_rest.add_theme_color_override("font_color", rest)


func _restyle() -> void:
	if _accent == null:
		return
	_accent.add_theme_font_override("font", UiFonts.tight(font_size))
	_rest.add_theme_font_override("font", UiFonts.tight(font_size))
	_accent.add_theme_font_size_override("font_size", font_size)
	_rest.add_theme_font_size_override("font_size", font_size)
