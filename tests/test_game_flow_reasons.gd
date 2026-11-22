extends GutTest
## GameFlow'un saf kısmı: duraklatma nedenleri kümesi.


func test_pause_follows_reason_set() -> void:
	var reasons: PauseReasons = PauseReasons.new()
	assert_false(reasons.is_paused())
	assert_true(reasons.add(&"menu"))
	assert_false(reasons.add(&"menu"), "aynı neden ikinci kez değişiklik sayılmaz")
	assert_true(reasons.add(&"pause"))
	assert_true(reasons.is_paused())
	assert_true(reasons.remove(&"menu"))
	assert_true(reasons.is_paused(), "pause hâlâ var")
	assert_true(reasons.remove(&"pause"))
	assert_false(reasons.is_paused())
	assert_false(reasons.remove(&"pause"), "olmayan neden değişiklik sayılmaz")


func test_has_other_and_clear() -> void:
	var reasons: PauseReasons = PauseReasons.new()
	reasons.add(&"pause")
	assert_false(reasons.has_other_than(&"pause"))
	reasons.add(&"end")
	assert_true(reasons.has_other_than(&"pause"))
	assert_true(reasons.clear())
	assert_false(reasons.is_paused())
	assert_false(reasons.clear(), "boşken temizlemek değişiklik sayılmaz")


func test_game_flow_declares_reasons() -> void:
	assert_eq(GameFlow.REASON_PAUSE, &"pause")
	assert_eq(GameFlow.REASON_MENU, &"menu")
	assert_eq(GameFlow.REASON_END, &"end")
	assert_false(GameFlow.is_paused(), "testler duraklatılmış başlamamalı")
