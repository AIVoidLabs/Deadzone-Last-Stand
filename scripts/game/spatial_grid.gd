class_name SpatialGrid
extends RefCounted
## Sabit sınırlı, sayım sıralamalı uzay ızgarası (XZ düzlemi, Vector2).
## Her karede rebuild O(n + hücre); sorgular yalnız yakın hücreleri tarar.

var cell_size: float
var cols: int
var rows: int
## cell_start[c] .. cell_start[c + 1] aralığı, sorted içindeki c hücresinin elemanları.
var cell_start: PackedInt32Array = PackedInt32Array()
var sorted: PackedInt32Array = PackedInt32Array()

var _origin: Vector2
var _cell_of: PackedInt32Array = PackedInt32Array()


func _init(origin: Vector2, size: Vector2, p_cell_size: float) -> void:
	_origin = origin
	cell_size = p_cell_size
	cols = maxi(1, ceili(size.x / cell_size))
	rows = maxi(1, ceili(size.y / cell_size))
	cell_start.resize(cols * rows + 1)


func rebuild(positions: PackedVector2Array) -> void:
	var n: int = positions.size()
	cell_start.fill(0)
	_cell_of.resize(n)
	for i in n:
		var c: int = cell_index(positions[i])
		_cell_of[i] = c
		cell_start[c + 1] += 1
	for c in cols * rows:
		cell_start[c + 1] += cell_start[c]
	var cursor: PackedInt32Array = cell_start.duplicate()
	sorted.resize(n)
	for i in n:
		var c: int = _cell_of[i]
		sorted[cursor[c]] = i
		cursor[c] += 1


func cell_coords(p: Vector2) -> Vector2i:
	var local: Vector2 = (p - _origin) / cell_size
	return Vector2i(clampi(floori(local.x), 0, cols - 1), clampi(floori(local.y), 0, rows - 1))


func cell_index(p: Vector2) -> int:
	var c: Vector2i = cell_coords(p)
	return c.y * cols + c.x


## Dikdörtgene değen hücrelerdeki tüm adaylar (kesin mesafe süzmesi yok).
func query_rect(min_corner: Vector2, max_corner: Vector2) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	var a: Vector2i = cell_coords(min_corner)
	var b: Vector2i = cell_coords(max_corner)
	for row in range(a.y, b.y + 1):
		for col in range(a.x, b.x + 1):
			var c: int = row * cols + col
			for k in range(cell_start[c], cell_start[c + 1]):
				out.append(sorted[k])
	return out


## Merkeze radius içinde kalan indeksler (kesin).
func query_radius(center: Vector2, radius: float, positions: PackedVector2Array) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	var r_sq: float = radius * radius
	var span: Vector2 = Vector2(radius, radius)
	for i in query_rect(center - span, center + span):
		if positions[i].distance_squared_to(center) <= r_sq:
			out.append(i)
	return out


## En yakın canlı eleman; yoksa -1. alive[i] == 0 olanlar atlanır.
func nearest(center: Vector2, max_radius: float, positions: PackedVector2Array, alive: PackedByteArray) -> int:
	var best: int = -1
	var best_sq: float = max_radius * max_radius
	var span: Vector2 = Vector2(max_radius, max_radius)
	for i in query_rect(center - span, center + span):
		if alive[i] == 0:
			continue
		var d_sq: float = positions[i].distance_squared_to(center)
		if d_sq <= best_sq:
			best_sq = d_sq
			best = i
	return best
