class_name CityLayout
extends RefCounted
## Şehir kavşağı düzeni (saf): oyun alanı içindeki dört köşe bina bloğu ve zombi itme/doğma kaydırma.
## Sokak genişliği Tuning.CITY_STREET_WIDTH; bloklar köşelerde kalan kare alanı doldurur.


## Dört köşe bloğunun XZ dikdörtgenleri (sıra: -x-z, +x-z, -x+z, +x+z).
static func block_rects(arena_size: float, street_width: float) -> Array[Rect2]:
	var half: float = arena_size * 0.5
	var side: float = half - street_width * 0.5
	var rects: Array[Rect2] = []
	for sz: float in [-1.0, 1.0]:
		for sx: float in [-1.0, 1.0]:
			var corner: Vector2 = Vector2(street_width * 0.5 if sx > 0.0 else -half, street_width * 0.5 if sz > 0.0 else -half)
			rects.append(Rect2(corner, Vector2(side, side)))
	return rects


## Daire (yarıçap r) bir bloğun içindeyse en yakın kenara iter (bloka sürtünerek kayma); değilse aynen döner.
static func push_out(p: Vector2, r: float, rects: Array[Rect2]) -> Vector2:
	for rect: Rect2 in rects:
		var grown: Rect2 = rect.grow(r)
		if not grown.has_point(p):
			continue
		var left: float = p.x - grown.position.x
		var right: float = grown.end.x - p.x
		var top: float = p.y - grown.position.y
		var bottom: float = grown.end.y - p.y
		var best: float = minf(minf(left, right), minf(top, bottom))
		if best == left:
			return Vector2(grown.position.x, p.y)
		if best == right:
			return Vector2(grown.end.x, p.y)
		if best == top:
			return Vector2(p.x, grown.position.y)
		return Vector2(p.x, grown.end.y)
	return p
