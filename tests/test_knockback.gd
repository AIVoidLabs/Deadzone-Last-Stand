extends GutTest

const STEP: float = 1.0 / 60.0


func test_impulse_points_along_hit_and_scales_with_weight() -> void:
	var light: Vector2 = Knockback.impulse(Vector2(3.0, 0.0), 6.0, 1.0)
	var heavy: Vector2 = Knockback.impulse(Vector2(3.0, 0.0), 6.0, 3.0)
	assert_almost_eq(light.x, 6.0, 0.0001)
	assert_almost_eq(light.y, 0.0, 0.0001)
	assert_almost_eq(heavy.length(), light.length() / 3.0, 0.0001)


func test_no_direction_or_force_means_no_push() -> void:
	assert_eq(Knockback.impulse(Vector2.ZERO, 6.0, 1.0), Vector2.ZERO)
	assert_eq(Knockback.impulse(Vector2.RIGHT, 0.0, 1.0), Vector2.ZERO)


func test_simulated_travel_matches_formula() -> void:
	var row: Dictionary = EnemyData.get_row(EnemyData.WALKER)
	var force: float = WeaponData.get_row(WeaponData.PISTOL)["knockback"]
	var weight: float = row["weight"]
	var velocity: Vector2 = Knockback.impulse(Vector2.RIGHT, force, weight)
	var travelled: float = 0.0
	for _i in 600:
		travelled += velocity.x * STEP
		velocity = Knockback.decay(velocity, Tuning.KNOCKBACK_DAMPING, STEP)
	var expected: float = Knockback.travel_distance(force, weight, Tuning.KNOCKBACK_DAMPING)
	# Adım adım toplama kapalı formülü biraz aşar (60 Hz); pay buna göre.
	assert_almost_eq(travelled, expected, expected * 0.15)
	assert_lt(velocity.length(), 0.001)


func test_pistol_push_is_felt_but_does_not_clear_the_horde() -> void:
	# Tabanca vuruşu görünür bir itme vermeli ama zombiyi bir gövde boyundan fazla uzaklaştırmamalı.
	var row: Dictionary = EnemyData.get_row(EnemyData.WALKER)
	var force: float = WeaponData.get_row(WeaponData.PISTOL)["knockback"]
	var distance: float = Knockback.travel_distance(force, row["weight"], Tuning.KNOCKBACK_DAMPING)
	assert_gt(distance, 0.15)
	assert_lt(distance, float(row["radius"]) * 2.0)
