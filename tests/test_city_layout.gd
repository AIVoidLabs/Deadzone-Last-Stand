extends GutTest

var _rects: Array[Rect2]


func before_each() -> void:
	_rects = CityLayout.block_rects(Tuning.ARENA_SIZE, Tuning.CITY_STREET_WIDTH)


func test_four_blocks_fill_the_corners() -> void:
	assert_eq(_rects.size(), 4)
	var side: float = Tuning.ARENA_SIZE * 0.5 - Tuning.CITY_STREET_WIDTH * 0.5
	for rect: Rect2 in _rects:
		assert_almost_eq(rect.size.x, side, 0.001)


func test_center_is_free() -> void:
	assert_eq(CityLayout.push_out(Vector2.ZERO, 0.5, _rects), Vector2.ZERO)


func test_point_inside_block_is_pushed_to_street() -> void:
	var inside: Vector2 = _rects[3].get_center()
	var out: Vector2 = CityLayout.push_out(inside, 0.5, _rects)
	assert_eq(CityLayout.push_out(out, 0.5, _rects), out)
	assert_false(_rects[3].has_point(out))
