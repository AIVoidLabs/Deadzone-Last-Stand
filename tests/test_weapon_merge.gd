extends GutTest

const MAX_TIER: int = 4
const PISTOL: StringName = &"pistol"
const SHOTGUN: StringName = &"shotgun"


func _slot(id: StringName, tier: int) -> Dictionary:
	return {"id": id, "tier": tier}


func _add(slots: Array[Dictionary], id: StringName) -> Dictionary:
	return WeaponMerge.add(slots, id, Tuning.WEAPON_SLOTS, MAX_TIER)


func test_new_weapon_takes_free_slot_at_tier_one() -> void:
	var r: Dictionary = _add([_slot(PISTOL, 1)], SHOTGUN)
	assert_true(r["ok"])
	assert_false(r["merged"])
	assert_eq(r["slots"].size(), 2)
	assert_eq(r["slots"][1], _slot(SHOTGUN, 1))


func test_same_weapon_same_tier_merges_up() -> void:
	var r: Dictionary = _add([_slot(PISTOL, 1)], PISTOL)
	assert_true(r["merged"])
	assert_eq(r["slots"], [_slot(PISTOL, 2)])


func test_different_tier_does_not_merge() -> void:
	var r: Dictionary = _add([_slot(PISTOL, 2)], PISTOL)
	assert_false(r["merged"])
	assert_eq(r["slots"].size(), 2)


func test_merge_cascades() -> void:
	var slots: Array[Dictionary] = [_slot(PISTOL, 3), _slot(PISTOL, 2), _slot(PISTOL, 1)]
	var r: Dictionary = _add(slots, PISTOL)
	assert_eq(r["slots"], [_slot(PISTOL, 4)])


func test_max_tier_does_not_merge() -> void:
	var r: Dictionary = _add([_slot(PISTOL, MAX_TIER)], PISTOL)
	assert_false(r["merged"])
	assert_eq(r["slots"].size(), 2)


func test_full_slots_reject_unmergeable_weapon() -> void:
	var slots: Array[Dictionary] = []
	for i: int in Tuning.WEAPON_SLOTS:
		slots.append(_slot(PISTOL, 2))
	var r: Dictionary = _add(slots, SHOTGUN)
	assert_false(r["ok"])
	assert_eq(r["slots"], slots)


func test_full_slots_accept_mergeable_weapon() -> void:
	var slots: Array[Dictionary] = []
	for i: int in Tuning.WEAPON_SLOTS:
		slots.append(_slot(PISTOL, 2))
	slots[3] = _slot(SHOTGUN, 1)
	var r: Dictionary = _add(slots, SHOTGUN)
	assert_true(r["ok"])
	assert_eq(r["slots"].size(), Tuning.WEAPON_SLOTS - 0)
	assert_eq(r["slots"][3], _slot(SHOTGUN, 2))


func test_input_is_not_modified() -> void:
	var slots: Array[Dictionary] = [_slot(PISTOL, 1)]
	_add(slots, PISTOL)
	assert_eq(slots, [_slot(PISTOL, 1)])


func test_tier_table_is_increasing() -> void:
	assert_eq(WeaponData.max_tier(), MAX_TIER)
	for t: int in range(2, MAX_TIER + 1):
		assert_gt(WeaponData.tier_row(t)["damage_mult"], WeaponData.tier_row(t - 1)["damage_mult"])
		assert_gt(WeaponData.tier_row(t)["rate_mult"], WeaponData.tier_row(t - 1)["rate_mult"])
