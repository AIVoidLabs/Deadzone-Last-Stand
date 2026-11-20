extends GutTest
## ArmorRules: önden / yandan / arkadan / sınır ve belirsiz yön; satır sayıları EnemyData'dan.

var _row: Dictionary = EnemyData.get_row(EnemyData.ARMORED)
var _half: float = deg_to_rad(float(_row["armor_front_half_deg"]))
var _front: float = float(_row["armor_front_factor"])
var _back: float = float(_row["armor_back_factor"])


func test_front_hit_reduced() -> void:
	assert_eq(ArmorRules.factor(Vector2.RIGHT, Vector2.RIGHT, _half, _front, _back), _front)


func test_front_cone_edge_inclusive() -> void:
	var edge: Vector2 = Vector2.RIGHT.rotated(_half - 0.001)
	assert_true(ArmorRules.is_front(Vector2.RIGHT, edge, _half))
	assert_false(ArmorRules.is_front(Vector2.RIGHT, Vector2.RIGHT.rotated(_half + 0.001), _half))
	assert_true(ArmorRules.is_front(Vector2.RIGHT, Vector2.RIGHT.rotated(-_half + 0.001), _half))


func test_side_and_back_amplified() -> void:
	assert_eq(ArmorRules.factor(Vector2.RIGHT, Vector2.UP, _half, _front, _back), _back)
	assert_eq(ArmorRules.factor(Vector2.RIGHT, Vector2.LEFT, _half, _front, _back), _back)


func test_unknown_direction_neutral() -> void:
	assert_eq(ArmorRules.factor(Vector2.RIGHT, Vector2.ZERO, _half, _front, _back), 1.0)
	assert_eq(ArmorRules.factor(Vector2.ZERO, Vector2.RIGHT, _half, _front, _back), 1.0)


func test_row_values_match_design() -> void:
	assert_lt(_front, 1.0)
	assert_gt(_back, 1.0)
	assert_true(_row.has("armor_turn_rate"))
