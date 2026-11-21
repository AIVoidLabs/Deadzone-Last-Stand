class_name CityLayout
extends RefCounted
## Şehir kavşağı düzeni (saf): oyun alanı içindeki dört köşe bina bloğu ve zombi itme/doğma kaydırma.
## Sokak genişliği Tuning.CITY_STREET_WIDTH; bloklar köşelerde kalan kare alanı doldurur.


## Doğrudan karşıdan gelişte teğet yönü seçmek için eşik (|teğet · yön|).
const TANGENT_TIE: float = 0.15


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


## Bloklar + (isteniyorsa) çarpışmalı proplar: zombi itmesi ve doğma kaydırması bunu kullanır.
static func solid_rects(arena_size: float, street_width: float, with_props: bool) -> Array[Rect2]:
	var rects: Array[Rect2] = block_rects(arena_size, street_width)
	if with_props:
		rects.append_array(CityProps.collide_rects())
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


## p'den a→b doğrusu (daire yarıçapı r) dikdörtgenlere değiyor mu: en yakın girişin Vector3(t, nx, ny) değeri
## (t: parçanın 0..1 oranı, (nx, ny): girilen yüzün dışa normali); değmiyorsa t = -1. Sınırda duran ya da içinden başlayan sayılmaz.
static func first_hit(a: Vector2, b: Vector2, r: float, rects: Array[Rect2]) -> Vector3:
	var best: Vector3 = Vector3(-1.0, 0.0, 0.0)
	var lo_x: float = minf(a.x, b.x)
	var hi_x: float = maxf(a.x, b.x)
	var lo_y: float = minf(a.y, b.y)
	var hi_y: float = maxf(a.y, b.y)
	for rect: Rect2 in rects:
		var g: Rect2 = rect.grow(r)
		if hi_x <= g.position.x or lo_x >= g.end.x or hi_y <= g.position.y or lo_y >= g.end.y:
			continue
		var hit: Vector3 = _slab_hit(a, b - a, g)
		if hit.x >= 0.0 and (best.x < 0.0 or hit.x < best.x):
			best = hit
	return best


## Tek dikdörtgen için kesişim (first_hit'in çekirdeği); girişi 0..1 aralığında değilse t = -1.
static func _slab_hit(a: Vector2, d: Vector2, g: Rect2) -> Vector3:
	var t_in: float = -INF
	var t_out: float = INF
	var normal: Vector2 = Vector2.ZERO
	for axis in 2:
		var lo: float = g.position[axis]
		var hi: float = g.end[axis]
		if absf(d[axis]) < 0.000001:
			if a[axis] <= lo or a[axis] >= hi:
				return Vector3(-1.0, 0.0, 0.0)
			continue
		var t1: float = (lo - a[axis]) / d[axis]
		var t2: float = (hi - a[axis]) / d[axis]
		if t1 > t2:
			var swap: float = t1
			t1 = t2
			t2 = swap
		if t1 > t_in:
			t_in = t1
			normal = Vector2.ZERO
			normal[axis] = -1.0 if d[axis] > 0.0 else 1.0
		t_out = minf(t_out, t2)
	if t_in > t_out or t_out <= 0.0 or t_in < 0.0 or t_in >= 1.0:
		return Vector3(-1.0, 0.0, 0.0)
	return Vector3(t_in, normal.x, normal.y)


## Önü engelliyse hareket yönünü engelin kenarına teğet kaydırır (look m ileriye bakar); engel yoksa dir aynen.
## dir'in uzunluğu korunur (0..1 hız çarpanı olabilir). Engele yaklaştıkça (blend) teğete doğru karışır; kenara dayanınca saf teğet.
static func steer(p: Vector2, dir: Vector2, r: float, look: float, blend: float, rects: Array[Rect2]) -> Vector2:
	var length: float = dir.length()
	if length < 0.0001:
		return dir
	var unit: Vector2 = dir / length
	var hit: Vector3 = first_hit(p, p + unit * look, r, rects)
	if hit.x < 0.0:
		return dir
	var tangent: Vector2 = Vector2(-hit.z, hit.y)
	var along: float = tangent.dot(unit)
	if absf(along) < TANGENT_TIE:
		# Tam karşıdan: engelin ortasından uzak yana (yakın köşeye) kay.
		var center: Vector2 = _rect_center_near(p + unit * look * hit.x, r, rects)
		along = tangent.dot(p - center)
	if along < 0.0:
		tangent = -tangent
	var w: float = 1.0 - clampf(hit.x * blend, 0.0, 1.0)
	return (unit * (1.0 - w) + tangent * w).normalized() * length


## Noktaya (yarıçap r büyütmeyle) en yakın dikdörtgenin merkezi (teğet yönü belirsizken yan seçmek için).
static func _rect_center_near(at: Vector2, r: float, rects: Array[Rect2]) -> Vector2:
	var best: Vector2 = at
	var best_d: float = INF
	for rect: Rect2 in rects:
		var d: float = rect.grow(r + 0.05).get_center().distance_squared_to(at)
		if rect.grow(r + 0.05).has_point(at) and d < best_d:
			best_d = d
			best = rect.get_center()
	return best


## Hızlı adım a→b bir dikdörtgeni baştan başa geçtiyse (iki ucu da dışarıda) zombiyi girişte durdurur; yoksa b.
## İçine girip çıkmayan adımlar push_out'un kenarda kaymasına bırakılır.
static func anti_tunnel(a: Vector2, b: Vector2, r: float, rects: Array[Rect2]) -> Vector2:
	var hit: Vector3 = first_hit(a, b, r, rects)
	if hit.x < 0.0 or push_out(b, r, rects) != b:
		return b
	return a.lerp(b, hit.x)


## push_out'u birkaç kez uygular (bir dikdörtgenin kenarı yanındakinin içine düşebilir); doğma ve iniş noktaları için.
static func settle(p: Vector2, r: float, rects: Array[Rect2], passes: int) -> Vector2:
	for _i in passes:
		var q: Vector2 = push_out(p, r, rects)
		if q == p:
			break
		p = q
	return p


## a→b atış doğrusu engele çarparsa çarpma noktası (margin kadar önünde) ve oran (0..1); çarpmazsa b ve 1.
static func clip_shot(a: Vector2, b: Vector2, r: float, margin: float, rects: Array[Rect2]) -> Vector3:
	var hit: Vector3 = first_hit(a, b, r, rects)
	if hit.x < 0.0:
		return Vector3(b.x, b.y, 1.0)
	var len: float = a.distance_to(b)
	var t: float = maxf(hit.x - margin / maxf(len, 0.0001), 0.0)
	var q: Vector2 = a.lerp(b, t)
	return Vector3(q.x, q.y, t)
