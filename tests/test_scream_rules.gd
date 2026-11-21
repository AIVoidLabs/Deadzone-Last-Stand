extends GutTest
## ScreamRules: mesafe davranışı, halka noktaları, çağrı sınırı; sayılar EnemyData satırından.

var _row: Dictionary = EnemyData.get_row(EnemyData.SCREAMER)
var _range: float = float(_row["scream_range"])
var _keep: float = float(_row["scream_keep_min"])


func test_approaches_when_far() -> void:
	assert_eq(ScreamRules.move_vector(_range + 1.0, _range, _keep, Vector2.RIGHT), Vector2.RIGHT)


func test_stands_in_band() -> void:
	assert_eq(ScreamRules.move_vector((_range + _keep) * 0.5, _range, _keep, Vector2.RIGHT), Vector2.ZERO)
	assert_eq(ScreamRules.move_vector(_range, _range, _keep, Vector2.RIGHT), Vector2.ZERO)
	assert_eq(ScreamRules.move_vector(_keep, _range, _keep, Vector2.RIGHT), Vector2.ZERO)


func test_flees_when_close() -> void:
	assert_eq(ScreamRules.move_vector(_keep - 0.5, _range, _keep, Vector2.RIGHT), Vector2.LEFT)


func test_ring_points_on_radius_and_count() -> void:
	var radius: float = float(_row["scream_radius"])
	var points: PackedVector2Array = ScreamRules.ring_points(Vector2(2, 3), radius, int(_row["scream_count"]), 0.4, 100.0)
	assert_eq(points.size(), int(_row["scream_count"]))
	for p in points:
		assert_almost_eq(p.distance_to(Vector2(2, 3)), radius, 0.001)


func test_ring_points_clamped_to_arena() -> void:
	for p in ScreamRules.ring_points(Vector2(9.5, 0), 2.5, 3, 0.0, 10.0):
		assert_lte(p.x, 10.0)
		assert_gte(p.x, -10.0)


func test_allowed_count_limits() -> void:
	var want: int = int(_row["scream_count"])
	var cap: int = int(_row["scream_max_alive"])
	assert_eq(ScreamRules.allowed_count(want, 0, cap, 0, 100), want)
	assert_eq(ScreamRules.allowed_count(want, cap - 1, cap, 0, 100), 1)
	assert_eq(ScreamRules.allowed_count(want, cap, cap, 0, 100), 0)
	assert_eq(ScreamRules.allowed_count(want, 0, cap, 99, 100), 1)
	assert_eq(ScreamRules.allowed_count(want, 0, cap, 120, 100), 0)
