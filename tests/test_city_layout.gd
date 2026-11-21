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


func test_steer_leaves_free_path_alone() -> void:
	var dir: Vector2 = Vector2.RIGHT
	assert_eq(CityLayout.steer(Vector2(-5.0, 0.0), dir, 0.5, 2.5, 0.6, _rects), dir)


func test_steer_slides_along_block_face() -> void:
	# Blok 3 (+x+z) sol yüzü x = street/2: yüzün hemen önünden doğrudan içine giden yön teğete döner.
	var face_x: float = Tuning.CITY_STREET_WIDTH * 0.5 - 0.5
	var p: Vector2 = Vector2(face_x - 0.2, 12.0)
	var out: Vector2 = CityLayout.steer(p, Vector2(1.0, 0.2).normalized(), 0.5, 2.5, 0.6, _rects)
	assert_lt(absf(out.x), 0.05, "yüze paralel kayar")
	assert_gt(out.y, 0.9, "yön korunur (aşağı/yukarı)")


func test_steer_keeps_length() -> void:
	var p: Vector2 = Vector2(Tuning.CITY_STREET_WIDTH * 0.5 - 1.0, 12.0)
	assert_almost_eq(CityLayout.steer(p, Vector2(0.5, 0.0), 0.5, 2.5, 0.6, _rects).length(), 0.5, 0.001)


func test_first_hit_reports_entry_face() -> void:
	var hit: Vector3 = CityLayout.first_hit(Vector2(0.0, 15.0), Vector2(30.0, 15.0), 0.0, _rects)
	assert_gt(hit.x, 0.0)
	assert_lt(hit.x, 1.0)
	assert_eq(Vector2(hit.y, hit.z), Vector2(-1.0, 0.0))


func test_first_hit_ignores_start_on_boundary_moving_away() -> void:
	var edge: float = Tuning.CITY_STREET_WIDTH * 0.5
	assert_lt(CityLayout.first_hit(Vector2(edge, 15.0), Vector2(0.0, 15.0), 0.0, _rects).x, 0.0)


func test_anti_tunnel_stops_fast_step_before_thin_rect() -> void:
	var thin: Array[Rect2] = [Rect2(Vector2(5.0, -1.0), Vector2(0.2, 2.0))]
	var out: Vector2 = CityLayout.anti_tunnel(Vector2(0.0, 0.0), Vector2(10.0, 0.0), 0.3, thin)
	assert_lt(out.x, 5.0)
	assert_eq(CityLayout.anti_tunnel(Vector2(0.0, 5.0), Vector2(10.0, 5.0), 0.3, thin), Vector2(10.0, 5.0))


func test_settle_resolves_adjacent_rects() -> void:
	var two: Array[Rect2] = [Rect2(Vector2(0.0, 0.0), Vector2(4.0, 4.0)), Rect2(Vector2(5.2, 0.0), Vector2(4.0, 4.0))]
	var out: Vector2 = CityLayout.settle(Vector2(3.9, 2.0), 0.5, two, 3)
	assert_eq(CityLayout.push_out(out, 0.5, two), out)


func test_clip_shot_lands_before_wall() -> void:
	var shot: Vector3 = CityLayout.clip_shot(Vector2(0.0, 15.0), Vector2(30.0, 15.0), 0.1, 0.15, _rects)
	assert_lt(shot.z, 1.0)
	assert_lt(shot.x, Tuning.CITY_STREET_WIDTH * 0.5)
	var free: Vector3 = CityLayout.clip_shot(Vector2(0.0, 0.0), Vector2(5.0, 0.0), 0.1, 0.15, _rects)
	assert_eq(free.z, 1.0)



func test_line_of_sight() -> void:
	var blocks: Array[Rect2] = CityLayout.block_rects(Tuning.ARENA_SIZE, Tuning.CITY_STREET_WIDTH)
	var w: float = Tuning.CITY_STREET_WIDTH * 0.5
	var half: float = Tuning.ARENA_SIZE * 0.5
	var mid: float = -half * 0.5
	# Merkezden sokak boyunca: açık.
	assert_true(CityLayout.line_of_sight(Vector2.ZERO, Vector2(half - 1.0, 0.0), blocks))
	# Sokaktan bloğun içinden öbür yana: kapalı.
	assert_false(CityLayout.line_of_sight(Vector2(-w + 1.0, mid), Vector2(-w - 3.0, mid), blocks))
	# Blok içinden başlayan hat engellenmiş sayılmaz (çarpışma yalnız girişi sayar).
	assert_true(CityLayout.line_of_sight(Vector2(-w - 3.0, mid), Vector2(-w - 6.0, mid), blocks))
