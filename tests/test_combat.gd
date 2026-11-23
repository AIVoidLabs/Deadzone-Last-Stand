extends GutTest


func test_mitigate_percent_armor() -> void:
	for a: float in [0.0, 3.0, 14.0]:
		var expected: float = 10.0 * 100.0 / (100.0 + Tuning.ARMOR_PERCENT_PER_POINT * a)
		assert_almost_eq(CombatMath.mitigate(10.0, a), maxf(Tuning.MIN_DAMAGE_AFTER_ARMOR, expected), 0.0001)
	assert_lt(CombatMath.mitigate(10.0, 14.0), CombatMath.mitigate(10.0, 3.0))


func test_mitigate_negative_armor_adds_damage_and_caps() -> void:
	var minus6: float = 10.0 * (1.0 + minf(Tuning.ARMOR_NEGATIVE_MAX_BONUS, Tuning.ARMOR_NEGATIVE_PER_POINT * 6.0 / 100.0))
	assert_almost_eq(CombatMath.mitigate(10.0, -6.0), minus6, 0.0001)
	assert_almost_eq(CombatMath.mitigate(10.0, -20.0), 10.0 * (1.0 + Tuning.ARMOR_NEGATIVE_MAX_BONUS), 0.0001, "eksi zırh üst sınırı")
	assert_gt(CombatMath.mitigate(10.0, -6.0), 10.0)


func test_mitigate_old_flat_behavior_when_feature_off() -> void:
	# Sabit const: kapalı yolu doğrudan sınanamaz; açıkken çarpan formülünden türeyen değer beklenir.
	if Tuning.FEATURE_ARMOR_PERCENT:
		assert_almost_eq(CombatMath.mitigate(10.0, 3.0), 10.0 * CombatMath.armor_multiplier(3.0), 0.0001)
	else:
		assert_almost_eq(CombatMath.mitigate(10.0, 3.0), 7.0, 0.0001)


func test_mitigate_has_floor() -> void:
	assert_almost_eq(CombatMath.mitigate(5.0, 10000.0), Tuning.MIN_DAMAGE_AFTER_ARMOR, 0.0001) # çok yüksek zırh: taban devrede


func test_mitigate_zero_damage_stays_zero() -> void:
	assert_eq(CombatMath.mitigate(0.0, 0.0), 0.0)


func test_segment_hits_circle_in_path() -> void:
	var t: float = CombatMath.segment_circle_t(Vector2(-2.0, 0.0), Vector2(2.0, 0.0), Vector2.ZERO, 0.5)
	assert_almost_eq(t, 0.375, 0.0001)


func test_segment_misses_circle_aside() -> void:
	assert_eq(CombatMath.segment_circle_t(Vector2(-2.0, 1.0), Vector2(2.0, 1.0), Vector2.ZERO, 0.5), -1.0)


func test_segment_too_short_misses() -> void:
	assert_eq(CombatMath.segment_circle_t(Vector2(-2.0, 0.0), Vector2(-1.0, 0.0), Vector2.ZERO, 0.5), -1.0)


func test_segment_starting_inside_hits_at_zero() -> void:
	assert_eq(CombatMath.segment_circle_t(Vector2(0.1, 0.0), Vector2(2.0, 0.0), Vector2.ZERO, 0.5), 0.0)


func test_fast_projectile_does_not_tunnel() -> void:
	# Bir kare boyunca gidilen yol zombi çapından uzun olsa da çarpışma bulunmalı.
	var row: Dictionary = WeaponData.get_row(WeaponData.PISTOL)
	var speed: float = row["projectile_speed"]
	var step: float = speed / 30.0
	var a: Vector2 = Vector2(-step * 0.5, 0.0)
	var b: Vector2 = Vector2(step * 0.5, 0.0)
	assert_gt(CombatMath.segment_circle_t(a, b, Vector2.ZERO, 0.1), -0.5)


func test_health_damage_and_death() -> void:
	var h: Health = Health.new(Tuning.PLAYER_MAX_HP)
	assert_almost_eq(h.take_damage(30.0), 30.0, 0.0001)
	assert_false(h.is_dead())
	assert_almost_eq(h.take_damage(999.0), Tuning.PLAYER_MAX_HP - 30.0, 0.0001)
	assert_true(h.is_dead())
	assert_eq(h.current, 0.0)


func test_health_heal_clamps() -> void:
	var h: Health = Health.new(50.0)
	h.take_damage(10.0)
	assert_almost_eq(h.heal(100.0), 10.0, 0.0001)
	assert_almost_eq(h.ratio(), 1.0, 0.0001)


func test_health_ignores_negative_damage() -> void:
	var h: Health = Health.new(50.0)
	assert_eq(h.take_damage(-5.0), 0.0)
	assert_almost_eq(h.current, 50.0, 0.0001)
