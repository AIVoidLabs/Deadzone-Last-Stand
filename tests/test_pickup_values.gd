extends GutTest
## PickupRules.total_value: toplanmış sayılacak kristal değerleri (clear_all / take_all bunu kullanır).

const HOP: int = Pickups.State.HOP
const IDLE: int = Pickups.State.IDLE
const PULL: int = Pickups.State.PULL


func test_total_value_sums_everything_by_default() -> void:
	var values: PackedInt32Array = PackedInt32Array([3, 5, 7])
	var states: PackedByteArray = PackedByteArray([HOP, PULL, IDLE])
	assert_eq(PickupRules.total_value(values, states), 15)


func test_total_value_filters_pulled_ones() -> void:
	var values: PackedInt32Array = PackedInt32Array([3, 5, 7, 11])
	var states: PackedByteArray = PackedByteArray([HOP, PULL, IDLE, PULL])
	assert_eq(PickupRules.total_value(values, states, PULL), 16)
	assert_eq(PickupRules.total_value(values, states, IDLE), 7)


func test_total_value_empty_is_zero() -> void:
	assert_eq(PickupRules.total_value(PackedInt32Array(), PackedByteArray(), PULL), 0)
