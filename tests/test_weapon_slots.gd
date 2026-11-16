extends GutTest

const EPSILON: float = 0.0001


func _offset(index: int, count: int) -> Vector2:
	return WeaponSlots.offset(index, count, Tuning.WEAPON_ORBIT_RADIUS, deg_to_rad(Tuning.WEAPON_START_ANGLE_DEG))


func test_every_slot_sits_on_the_orbit() -> void:
	for count: int in range(1, Tuning.WEAPON_SLOTS + 1):
		for i: int in count:
			assert_almost_eq(_offset(i, count).length(), Tuning.WEAPON_ORBIT_RADIUS, EPSILON)


func test_single_weapon_uses_start_angle() -> void:
	var expected: Vector2 = Vector2.from_angle(deg_to_rad(Tuning.WEAPON_START_ANGLE_DEG)) * Tuning.WEAPON_ORBIT_RADIUS
	assert_almost_eq(_offset(0, 1).distance_to(expected), 0.0, EPSILON)


func test_full_ring_is_evenly_spaced_and_balanced() -> void:
	var count: int = Tuning.WEAPON_SLOTS
	var sum: Vector2 = Vector2.ZERO
	var expected_gap: float = 2.0 * Tuning.WEAPON_ORBIT_RADIUS * sin(PI / count)
	for i: int in count:
		sum += _offset(i, count)
		assert_almost_eq(_offset(i, count).distance_to(_offset(i + 1, count)), expected_gap, EPSILON)
	assert_almost_eq(sum.length(), 0.0, EPSILON)


func test_slots_do_not_overlap_the_soldier() -> void:
	assert_gt(Tuning.WEAPON_ORBIT_RADIUS, Tuning.PLAYER_RADIUS * 1.5)


func test_no_weapons_means_no_offset() -> void:
	assert_eq(WeaponSlots.offset(0, 0, 1.0, 0.0), Vector2.ZERO)
