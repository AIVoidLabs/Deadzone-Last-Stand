extends GutTest


func _make() -> AcidExposure:
	return AcidExposure.new(Tuning.ACID_SLOW_PERCENT, Tuning.ACID_BURN_DPS, Tuning.ACID_BURN_LINGER, Tuning.ACID_BURN_TICK)


func test_no_slow_without_touch() -> void:
	var a: AcidExposure = _make()
	assert_eq(a.speed_multiplier(), 1.0)
	assert_eq(a.tick(0.1), 0.0)


func test_slow_while_in_pool_without_burn() -> void:
	var a: AcidExposure = _make()
	var burn: float = 0.0
	for _n in 30:
		a.touch()
		burn += a.tick(1.0 / 60.0)
	assert_almost_eq(a.speed_multiplier(), 1.0 - Tuning.ACID_SLOW_PERCENT, 0.0001)
	assert_eq(burn, 0.0, "havuzdayken yanma yok (havuzun kendi tiki vuruyor)")


func test_burn_lingers_after_leaving_then_stops() -> void:
	var a: AcidExposure = _make()
	a.touch()
	a.tick(1.0 / 60.0)
	var burn: float = 0.0
	var t: float = 0.0
	while t < Tuning.ACID_BURN_LINGER + 0.5:
		burn += a.tick(1.0 / 60.0)
		t += 1.0 / 60.0
	# Tek tik hasarın yarısı tolerans: bir tik eksik/fazla olursa test kırılır.
	assert_almost_eq(burn, Tuning.ACID_BURN_DPS * Tuning.ACID_BURN_LINGER, Tuning.ACID_BURN_DPS * Tuning.ACID_BURN_TICK * 0.5)
	assert_eq(a.speed_multiplier(), 1.0, "süre bitince yavaşlama kalkar")
	assert_eq(a.tick(0.1), 0.0)


func test_reset_clears() -> void:
	var a: AcidExposure = _make()
	a.touch()
	a.reset()
	assert_false(a.is_active())
