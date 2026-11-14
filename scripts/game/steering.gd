class_name Steering
extends RefCounted
## Zombi yönelme ve itişme kuralları. Yol bulma yok.

const EPSILON_SQ: float = 1e-8


## Hedefe doğru birim yön; hedefin üstündeyse sıfır.
static func seek(from: Vector2, to: Vector2) -> Vector2:
	var d: Vector2 = to - from
	if d.length_squared() < EPSILON_SQ:
		return Vector2.ZERO
	return d.normalized()


## min_dist içindeki komşulardan uzaklaştıran itme. Yakınlaştıkça güçlenir (0..1 / komşu).
static func separation(index: int, positions: PackedVector2Array, grid: SpatialGrid, min_dist: float) -> Vector2:
	var p: Vector2 = positions[index]
	var push: Vector2 = Vector2.ZERO
	var min_sq: float = min_dist * min_dist
	var starts: PackedInt32Array = grid.cell_start
	var order: PackedInt32Array = grid.sorted
	var c: Vector2i = grid.cell_coords(p)
	var reach: int = ceili(min_dist / grid.cell_size)
	for row in range(maxi(0, c.y - reach), mini(grid.rows - 1, c.y + reach) + 1):
		for col in range(maxi(0, c.x - reach), mini(grid.cols - 1, c.x + reach) + 1):
			var cell: int = row * grid.cols + col
			for k in range(starts[cell], starts[cell + 1]):
				var j: int = order[k]
				if j == index:
					continue
				var d: Vector2 = p - positions[j]
				var d_sq: float = d.length_squared()
				if d_sq >= min_sq:
					continue
				if d_sq < EPSILON_SQ:
					# Tam üst üste: indekse göre sabit bir yöne ayır.
					push += Vector2.RIGHT.rotated(float(index))
					continue
				var dist: float = sqrt(d_sq)
				push += d / dist * (1.0 - dist / min_dist)
	return push
