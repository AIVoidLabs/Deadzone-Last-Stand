class_name CityNeonFont
extends RefCounted
## 8.3e: neon tabela çizgi yazı tipi (kodla). Harf: 2x2 ızgarada [x0, y0, x1, y1] tamsayı parçaları (0..2).
## Şekil: yükseklik 1 olan birimde [x0, y0, x1, y1, renk] (renk 0 = tabela rengi, 1 = kırmızı, 2 = mavi); genişlik = aspect.

const GLYPHS: Dictionary = {
	"A": [[0, 0, 0, 2], [2, 0, 2, 2], [0, 2, 2, 2], [0, 1, 2, 1]],
	"B": [[0, 0, 0, 2], [0, 2, 2, 2], [2, 2, 2, 1], [0, 1, 2, 1], [2, 1, 2, 0], [0, 0, 2, 0]],
	"E": [[0, 0, 0, 2], [0, 2, 2, 2], [0, 1, 1, 1], [0, 0, 2, 0]],
	"H": [[0, 0, 0, 2], [2, 0, 2, 2], [0, 1, 2, 1]],
	"I": [[0, 2, 2, 2], [1, 2, 1, 0], [0, 0, 2, 0]],
	"L": [[0, 0, 0, 2], [0, 0, 2, 0]],
	"M": [[0, 0, 0, 2], [2, 0, 2, 2], [0, 2, 1, 1], [1, 1, 2, 2]],
	"N": [[0, 0, 0, 2], [2, 0, 2, 2], [0, 2, 2, 0]],
	"O": [[0, 0, 0, 2], [2, 0, 2, 2], [0, 2, 2, 2], [0, 0, 2, 0]],
	"P": [[0, 0, 0, 2], [0, 2, 2, 2], [2, 2, 2, 1], [0, 1, 2, 1]],
	"R": [[0, 0, 0, 2], [0, 2, 2, 2], [2, 2, 2, 1], [0, 1, 2, 1], [1, 1, 2, 0]],
	"T": [[0, 2, 2, 2], [1, 2, 1, 0]],
	"Z": [[0, 2, 2, 2], [2, 2, 0, 0], [0, 0, 2, 0]],
	"2": [[0, 2, 2, 2], [2, 2, 2, 1], [2, 1, 0, 1], [0, 1, 0, 0], [0, 0, 2, 0]],
	"4": [[0, 2, 0, 1], [0, 1, 2, 1], [2, 2, 2, 0]],
}

const SHAPES: Dictionary = {
	&"arrow": {"aspect": 1.6, "segs": [[0.0, 0.5, 1.6, 0.5, 0], [1.6, 0.5, 1.05, 1.0, 0], [1.6, 0.5, 1.05, 0.0, 0]]},
	&"cup": {"aspect": 1.0, "segs": [[0.1, 0.05, 0.1, 0.6, 0], [0.1, 0.05, 0.7, 0.05, 0], [0.7, 0.05, 0.7, 0.6, 0], [0.1, 0.6, 0.7, 0.6, 0],
		[0.7, 0.45, 0.95, 0.45, 0], [0.95, 0.45, 0.95, 0.2, 0], [0.95, 0.2, 0.7, 0.2, 0],
		[0.25, 0.7, 0.35, 0.8, 0], [0.35, 0.8, 0.25, 0.9, 0], [0.5, 0.7, 0.6, 0.8, 0], [0.6, 0.8, 0.5, 0.9, 0]]},
	&"barber": {"aspect": 0.4, "segs": [[0.0, 0.0, 0.0, 1.0, 0], [0.35, 0.0, 0.35, 1.0, 0], [0.0, 0.0, 0.35, 0.0, 0], [0.0, 1.0, 0.35, 1.0, 0],
		[0.0, 0.08, 0.35, 0.28, 1], [0.0, 0.33, 0.35, 0.53, 2], [0.0, 0.58, 0.35, 0.78, 1], [0.0, 0.8, 0.35, 0.98, 2]]},
}


## Metin için parçalar: [[x0, y0, x1, y1, harf_indeksi, renk], ...] ve toplam genişlik (yükseklik = 1).
static func text_segments(text: String) -> Dictionary:
	var out: Array = []
	var cw: float = 0.6
	var step: float = cw + 0.22
	for i: int in text.length():
		var glyph: Array = GLYPHS.get(text[i], [])
		for g: Array in glyph:
			out.append([g[0] * cw * 0.5 + i * step, g[1] * 0.5, g[2] * cw * 0.5 + i * step, g[3] * 0.5, i, 0])
	return {"segs": out, "width": text.length() * step - 0.22}


static func shape_segments(shape: StringName) -> Dictionary:
	var def: Dictionary = SHAPES[shape]
	var out: Array = []
	for s: Array in def["segs"]:
		out.append([s[0], s[1], s[2], s[3], 0, s[4]])
	return {"segs": out, "width": def["aspect"]}
