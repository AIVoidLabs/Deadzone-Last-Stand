class_name UiFonts
extends RefCounted
## Yalnız Inter (OFL, değişken wght). Başlık: 900 + dar + hafif embolden. Büyük harfler elle yazılır.

const FONT_PATH: String = "res://assets/fonts/Inter.woff2"
const HEADING_WEIGHT: int = 900
const BOLD_WEIGHT: int = 700
const BODY_WEIGHT: int = 500
const HEADING_WIDTH: float = 0.86
const HEADING_EMBOLDEN: float = 0.18
const HEADING_SPACING: int = 1

static var _base: FontFile = null
static var _cache: Dictionary = {}


static func heading() -> Font:
	return _make(&"heading", HEADING_WEIGHT, HEADING_WIDTH, HEADING_EMBOLDEN, HEADING_SPACING)


static func bold() -> Font:
	return _make(&"bold", BOLD_WEIGHT, 1.0, 0.0, 0)


static func body() -> Font:
	return _make(&"body", BODY_WEIGHT, 1.0, 0.0, 0)


static func _make(key: StringName, weight: int, width: float, embolden: float, spacing: int) -> Font:
	if _cache.has(key):
		return _cache[key]
	if _base == null:
		_base = load(FONT_PATH) as FontFile
	var fv: FontVariation = FontVariation.new()
	fv.base_font = _base
	fv.variation_opentype = {_tag("wght"): weight}
	fv.variation_embolden = embolden
	fv.variation_transform = Transform2D(Vector2(width, 0.0), Vector2(0.0, 1.0), Vector2.ZERO)
	fv.spacing_glyph = spacing
	_cache[key] = fv
	return fv


## OpenType dört karakterli etiket -> tamsayı.
static func _tag(s: String) -> int:
	var b: PackedByteArray = s.to_ascii_buffer()
	return (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3]
