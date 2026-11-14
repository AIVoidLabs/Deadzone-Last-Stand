extends GutTest

const HALF: float = 30.0

var _grid: SpatialGrid


func before_each() -> void:
	_grid = SpatialGrid.new(Vector2(-HALF, -HALF), Vector2(HALF * 2.0, HALF * 2.0), Tuning.GRID_CELL_SIZE)


func test_seek_points_to_target() -> void:
	var dir: Vector2 = Steering.seek(Vector2.ZERO, Vector2(0.0, 5.0))
	assert_almost_eq(dir.x, 0.0, 0.0001)
	assert_almost_eq(dir.y, 1.0, 0.0001)


func test_seek_on_target_is_zero() -> void:
	assert_eq(Steering.seek(Vector2.ONE, Vector2.ONE), Vector2.ZERO)


func test_overlapping_neighbors_push_apart() -> void:
	var positions: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.5, 0.0)])
	_grid.rebuild(positions)
	var push_a: Vector2 = Steering.separation(0, positions, _grid, 0.9)
	var push_b: Vector2 = Steering.separation(1, positions, _grid, 0.9)
	assert_lt(push_a.x, 0.0, "ilki sola itilmeli")
	assert_gt(push_b.x, 0.0, "ikincisi sağa itilmeli")


func test_far_neighbors_do_not_push() -> void:
	var positions: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(3.0, 0.0)])
	_grid.rebuild(positions)
	assert_eq(Steering.separation(0, positions, _grid, 0.9), Vector2.ZERO)


func test_identical_positions_still_separate() -> void:
	var positions: PackedVector2Array = PackedVector2Array([Vector2(1.0, 1.0), Vector2(1.0, 1.0)])
	_grid.rebuild(positions)
	assert_ne(Steering.separation(0, positions, _grid, 0.9), Vector2.ZERO)


func test_push_works_across_cell_borders() -> void:
	var edge: float = -HALF + Tuning.GRID_CELL_SIZE
	var positions: PackedVector2Array = PackedVector2Array([Vector2(edge - 0.1, 0.0), Vector2(edge + 0.1, 0.0)])
	_grid.rebuild(positions)
	assert_lt(Steering.separation(0, positions, _grid, 0.9).x, 0.0)
