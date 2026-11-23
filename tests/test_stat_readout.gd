extends GutTest
## StatReadout (saf): sayı biçimi, gerçek değer, yüzde yeri ve işaret.

const TR: Dictionary = {"decimal": ",", "percent_prefix": true, "per_second": "/sn", "seconds": " sn"}
const EN: Dictionary = {"decimal": ".", "percent_prefix": false, "per_second": "/s", "seconds": "s"}


func test_number_trims_zero_and_uses_decimal() -> void:
	assert_eq(StatReadout.number(12.0, "."), "12")
	assert_eq(StatReadout.number(12.5, ","), "12,5")
	assert_eq(StatReadout.number(-0.04, "."), "0")


func test_percent_placement() -> void:
	assert_eq(StatReadout.format(StatData.DAMAGE, 12.5, TR), "%12,5")
	assert_eq(StatReadout.format(StatData.DAMAGE, 12.5, EN), "12.5%")
	assert_eq(StatReadout.format(StatData.MOVE_SPEED, -3.0, TR), "-%3")


func test_flat_stats_include_base() -> void:
	assert_eq(StatReadout.format(StatData.MAX_HP, 10.0, EN), StatReadout.number(Tuning.PLAYER_MAX_HP + 10.0, "."))
	assert_eq(StatReadout.format(StatData.ARMOR, 0.0, EN), StatReadout.number(Tuning.PLAYER_ARMOR, "."))


func test_regen_is_per_second() -> void:
	assert_eq(StatReadout.format(StatData.HP_REGEN, 4.0, EN), StatReadout.number(4.0 * Tuning.HP_REGEN_PER_POINT, ".") + "/s")


func test_dash_cooldown_shows_real_seconds() -> void:
	var base: String = StatReadout.number_fine(Tuning.DASH_COOLDOWN, ".")
	assert_eq(StatReadout.format(StatData.DASH_COOLDOWN, 0.0, EN), base + "s")
	var cut: float = PlayerStats.dash_cooldown_for(12.0)
	assert_eq(StatReadout.format(StatData.DASH_COOLDOWN, 12.0, EN), StatReadout.number_fine(cut, ".") + "s")
	assert_lt(cut, Tuning.DASH_COOLDOWN, "kesinti süreyi kısaltır")
	assert_eq(StatReadout.format(StatData.DASH_COOLDOWN, 12.0, TR), StatReadout.number_fine(cut, ",") + " sn")


func test_dash_cooldown_respects_cap() -> void:
	var capped: float = PlayerStats.dash_cooldown_for(Tuning.DASH_COOLDOWN_CUT_CAP)
	assert_almost_eq(PlayerStats.dash_cooldown_for(Tuning.DASH_COOLDOWN_CUT_CAP + 30.0), capped, 0.0001)
	assert_gt(PlayerStats.dash_cooldown_for(-10.0), Tuning.DASH_COOLDOWN, "eksi bonus bekletmeyi uzatır")


func test_number_fine_trims_zeros() -> void:
	assert_eq(StatReadout.number_fine(1.4, ","), "1,4")
	assert_eq(StatReadout.number_fine(1.32, "."), "1.32")
	assert_eq(StatReadout.number_fine(2.0, "."), "2")
	assert_eq(StatReadout.number_fine(10.0, "."), "10")
