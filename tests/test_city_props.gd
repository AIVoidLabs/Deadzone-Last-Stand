extends GutTest

var _blocks: Array[Rect2]
var _corridor: Array[Rect2]


func before_each() -> void:
	_blocks = CityLayout.block_rects(Tuning.ARENA_SIZE, Tuning.CITY_STREET_WIDTH)
	# Sokak ortası: kaldırım şeritlerinin içinde kalan artı biçimli koridor.
	var open: float = Tuning.CITY_STREET_WIDTH * 0.5 - Tuning.CITY_SIDEWALK_WIDTH
	var length: float = Tuning.ARENA_SIZE
	_corridor = [Rect2(-open, -length * 0.5, open * 2.0, length), Rect2(-length * 0.5, -open, length, open * 2.0)]


func test_collide_rows_keep_street_center_open() -> void:
	for rect: Rect2 in CityProps.collide_rects():
		for lane: Rect2 in _corridor:
			assert_false(rect.intersects(lane), "sokak ortasını kapatıyor: %s" % rect)


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
	assert_lte(cars, 4)


func test_all_prop_models_exist() -> void:
	for row: Dictionary in CityProps.rows():
		assert_true(ResourceLoader.exists(CityProps.DIR % row["prop"]), "model yok: %s" % row["prop"])


func test_solid_rects_include_props_only_when_asked() -> void:
	var plain: int = CityLayout.solid_rects(Tuning.ARENA_SIZE, Tuning.CITY_STREET_WIDTH, false).size()
	var full: int = CityLayout.solid_rects(Tuning.ARENA_SIZE, Tuning.CITY_STREET_WIDTH, true).size()
	assert_eq(plain, 4)
	assert_eq(full, 4 + CityProps.collide_rects().size())
