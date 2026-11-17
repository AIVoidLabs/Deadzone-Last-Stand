class_name WaveBanner
extends Label
## Ekranın üst-ortasında beliren, bir süre kalıp sönen büyük yazı ("DALGA 2", "DALGA TEMİZLENDİ").

const FONT_SIZE: int = 44
const OUTLINE_SIZE: int = 8
const OUTLINE_COLOR: Color = Color(0.0, 0.0, 0.0, 0.6)
## Ekran yüksekliğine oranla yazının üst kenarı.
const TOP_RATIO: float = 0.22
const FADE_IN: float = 0.15
const FADE_OUT: float = 0.45

var _tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	anchor_top = TOP_RATIO
	anchor_bottom = TOP_RATIO
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override("font_size", FONT_SIZE)
	add_theme_constant_override("outline_size", OUTLINE_SIZE)
	add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	modulate.a = 0.0


## text'i hold saniye gösterir; önceki yazıyı keser.
func flash(message: String, color: Color, hold: float) -> void:
	text = message
	add_theme_color_override("font_color", color)
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, FADE_IN)
	_tween.tween_interval(hold)
	_tween.tween_property(self, "modulate:a", 0.0, FADE_OUT)
