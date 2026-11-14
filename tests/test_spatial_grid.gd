extends GutTest

const HALF: float = 30.0

var _grid: SpatialGrid


func before_each() -> void:
	_grid = SpatialGrid.new(Vector2(-HALF, -HALF), Vector2(HALF * 2.0, HALF * 2.0), Tuning.GRID_CELL_SIZE)


func _random_positions(count: int, seed_value: int) -> PackedVector2Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var out: PackedVector2Array = PackedVector2Array()
	for _i in count:
		out.append(Vector2(rng.randf_range(-HALF, HALF), rng.randf_range(-HALF, HALF)))
	return out


func test_every_index_sorted_once() -> void:
	var positions: PackedVector2Array = _random_positions(300, 1)
	_grid.rebuild(positions)
	var seen: Dictionary = {}
	for i in _grid.sorted:
		seen[i] = true
	assert_eq(seen.size(), positions.size())
	assert_eq(_grid.cell_start[_grid.cols * _grid.rows], positions.size())


func test_query_radius_matches_brute_force() -> void:
	var positions: PackedVector2Array = _random_positions(400, 2)
	_grid.rebuild(positions)
	var center: Vector2 = Vector2(3.3, -7.1)
	var radius: float = 6.0
	var expected: Array[int] = []
	for i in positions.size():
		if positions[i].distance_to(center) <= radius:
			expected.append(i)
	var got: Array = Array(_grid.query_radius(center, radius, positions))
	got.sort()
	assert_eq(got, Array(expected))


func test_nearest_matches_brute_force_and_skips_dead() -> void:
	var positions: PackedVector2Array = _random_positions(200, 3)
	_grid.rebuild(positions)
	var alive: PackedByteArray = PackedByteArray()
	alive.resize(positions.size())
	alive.fill(1)
	var center: Vector2 = Vector2.ZERO
	var brute: int = -1
	for i in positions.size():
		if brute < 0 or positions[i].length() < positions[brute].length():
			brute = i
	assert_eq(_grid.nearest(center, 100.0, positions, alive), brute)
	alive[brute] = 0
	assert_ne(_grid.nearest(center, 100.0, positions, alive), brute)


func test_nearest_respects_radius() -> void:
	var positions: PackedVector2Array = PackedVector2Array([Vector2(10.0, 0.0)])
	_grid.rebuild(positions)
	var alive: PackedByteArray = PackedByteArray([1])
	assert_eq(_grid.nearest(Vector2.ZERO, 5.0, positions, alive), -1)
	assert_eq(_grid.nearest(Vector2.ZERO, 11.0, positions, alive), 0)


func test_out_of_bounds_positions_are_clamped_into_grid() -> void:
	var positions: PackedVector2Array = PackedVector2Array([Vector2(999.0, -999.0)])
	_grid.rebuild(positions)
	assert_eq(_grid.sorted.size(), 1)
