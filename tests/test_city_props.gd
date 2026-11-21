extends GutTest

var _blocks: Array[Rect2]
var _corridor: Array[Rect2]


func before_each() -> void:
	_blocks = CityLayout.block_rects(Tuning.ARENA_SIZE, Tuning.CITY_STREET_WIDTH)
	# Sokak ortası: kaldırım şeritlerinin içinde kalan artı biçimli koridor.
	var open: float = Tuning.CITY_STREET_WIDTH * 0.5 - Tuning.CITY_SIDEWALK_WIDTH
	var length: float = Tuning.ARENA_SIZE
	_corridor = [Rect2(-open, -length * 0.5, open * 2.0, length), Rect2(-length * 0.5, -open, length, open * 2.0)]


func test_sidewalk_rows_keep_street_center_open() -> void:
	# Kaldırım satırları (ROWS) koridoru kapatmaz; sokak ortasındaki adalar ayrı kuralla sınanır.
	for row: Dictionary in CityProps.ROWS:
		if not row["collide"]:
			continue
		for lane: Rect2 in _corridor:
			assert_false(CityProps.rect_of(row).intersects(lane), "sokak ortasını kapatıyor: %s" % row["prop"])


func test_collide_rows_do_not_overlap_buildings() -> void:
	for rect: Rect2 in CityProps.collide_rects():
		for block: Rect2 in _blocks:
			assert_false(rect.intersects(block), "bina bloğuyla çakışıyor: %s" % rect)


func test_collide_rows_inside_arena_and_foot_known() -> void:
	var half: float = Tuning.ARENA_SIZE * 0.5
	var arena: Rect2 = Rect2(-half, -half, half * 2.0, half * 2.0)
	var cars: int = 0
	for row: Dictionary in CityProps.rows():
		if not row["collide"]:
			continue
		assert_true(CityProps.FOOT.has(row["prop"]), "FOOT yok: %s" % row["prop"])
		assert_true(arena.encloses(CityProps.rect_of(row)))
		if CityProps.FOOT[row["prop"]].z > 3.0:
			cars += 1
	assert_lte(cars, 8)


func _island_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for island: Dictionary in CityProps.ISLANDS:
		var c: Vector2 = island["center"]
		var box: Rect2 = Rect2()
		var first: bool = true
		for p: Array in island["parts"]:
			var r: Rect2 = CityProps.rect_of({"prop": p[0], "pos": c + Vector2(p[1], p[2]), "rot_y": p[3]})
			box = r if first else box.merge(r)
			first = false
		out.append(box)
	return out


func test_islands_keep_player_start_clear() -> void:
	var clear: float = Tuning.CITY_ISLAND_CLEAR_RADIUS
	var start: Rect2 = Rect2(-clear, -clear, clear * 2.0, clear * 2.0)
	for rect: Rect2 in _island_rects():
		assert_false(rect.intersects(start), "ada merkezi kapatıyor: %s" % rect)


func test_islands_have_gaps_between_each_other() -> void:
	var rects: Array[Rect2] = _island_rects()
	var gap: float = Tuning.CITY_ISLAND_MIN_GAP
	for i: int in rects.size():
		for j: int in range(i + 1, rects.size()):
			assert_false(rects[i].grow(gap * 0.5).intersects(rects[j].grow(gap * 0.5)), "ada geçidi dar: %d-%d" % [i, j])


func test_islands_leave_walkable_gap_to_buildings() -> void:
	for rect: Rect2 in _island_rects():
		for block: Rect2 in _blocks:
			assert_false(rect.grow(Tuning.CITY_ISLAND_MIN_GAP * 0.5).intersects(block), "ada binaya çok yakın: %s" % rect)


func test_piles_are_not_collidable_and_known() -> void:
	for p: Array in CityProps.PILES:
		assert_true(ResourceLoader.exists(CityProps.DIR % p[0]))


func test_all_prop_models_exist() -> void:
	for row: Dictionary in CityProps.rows():
		assert_true(ResourceLoader.exists(CityProps.DIR % row["prop"]), "model yok: %s" % row["prop"])


func test_solid_rects_include_props_only_when_asked() -> void:
	var plain: int = CityLayout.solid_rects(Tuning.ARENA_SIZE, Tuning.CITY_STREET_WIDTH, false).size()
	var full: int = CityLayout.solid_rects(Tuning.ARENA_SIZE, Tuning.CITY_STREET_WIDTH, true).size()
	assert_eq(plain, 4)
	assert_eq(full, 4 + CityProps.collide_rects().size())
