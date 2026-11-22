extends GutTest
## 8.3j: dis blok pencereleri (CityOuterWindows).


func test_tilted_block_has_no_faces() -> void:
	var tilted: Array = [32.0, 34.0, 16.0, 14.0, 24.0, 1, true]
	assert_eq(CityOuterWindows.street_faces(tilted, 1.0, 1.0).size(), 0)


func test_street_adjacent_face_included() -> void:
	var row: Array = [14.0, 34.0, 14.0, 16.0, 18.0, 0, false]
	var faces: Array[Dictionary] = CityOuterWindows.street_faces(row, -1.0, 1.0)
	assert_eq(faces.size(), 1)
	assert_eq(faces[0]["normal"], Vector3(1.0, 0.0, 0.0))


func test_far_block_has_no_faces() -> void:
	var row: Array = [18.0, 56.0, 20.0, 14.0, 9.0, 1, false]
	assert_eq(CityOuterWindows.street_faces(row, 1.0, 1.0).size(), 0)


func test_positions_stay_inside_face() -> void:
	var length: float = 16.0
	var height: float = 18.0
	var pts: Array[Vector2] = CityOuterWindows.face_positions(length, height)
	assert_gt(pts.size(), 0)
	for p: Vector2 in pts:
		assert_lte(absf(p.x) + Tuning.CITY_FACADE_WINDOW_SIZE.x * 0.5, length * 0.5)
		assert_lte(p.y + Tuning.CITY_FACADE_WINDOW_SIZE.y, height)
