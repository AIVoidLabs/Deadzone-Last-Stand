extends GutTest
## StaticCaches.clear_all: doldur -> temizle -> boş.


func test_clear_all_empties_caches() -> void:
	Loc.table()
	UiAssets.tex(UiAssets.NOISE)
	var theme: Theme = UiTheme.get_theme()
	assert_not_null(theme)
	assert_false(Loc._merged.is_empty())
	StaticCaches.clear_all()
	assert_true(Loc._merged.is_empty())
	assert_true(UiAssets._tex.is_empty())
	assert_null(UiTheme._theme)


func test_caches_refill_after_clear() -> void:
	StaticCaches.clear_all()
	assert_false(Loc.table().is_empty())
	assert_not_null(UiTheme.get_theme())
