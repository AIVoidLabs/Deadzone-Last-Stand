extends GutTest
## BloatRules: mesafeye göre asker hasarı, zombi hasarı, itme yönü; sayılar EnemyData satırından.

var _row: Dictionary = EnemyData.get_row(EnemyData.BLOATER)
var _radius: float = float(_row["bloat_radius"])
var _full: float = float(_row["bloat_player_damage"])
var _edge: float = float(_row["bloat_edge_factor"])
var _pr: float = Tuning.PLAYER_RADIUS


func test_center_full_damage() -> void:
	assert_almost_eq(BloatRules.player_damage(0.0, _radius, _full, _edge, _pr), _full, 0.001)
	assert_almost_eq(BloatRules.player_damage(_pr, _radius, _full, _edge, _pr), _full, 0.001)


func test_edge_reduced() -> void:
	assert_almost_eq(BloatRules.player_damage(_radius + _pr, _radius, _full, _edge, _pr), _full * _edge, 0.001)


func test_falloff_monotonic_and_outside_zero() -> void:
	var near: float = BloatRules.player_damage(1.0, _radius, _full, _edge, _pr)
	var far: float = BloatRules.player_damage(2.5, _radius, _full, _edge, _pr)
	assert_gt(near, far)
	assert_eq(BloatRules.player_damage(_radius + _pr + 0.1, _radius, _full, _edge, _pr), 0.0)


func test_zombie_damage_in_and_out() -> void:
	var dmg: float = float(_row["bloat_zombie_damage"])
	assert_eq(BloatRules.zombie_damage(_radius + 0.3, _radius, dmg, 0.4), dmg)
	assert_eq(BloatRules.zombie_damage(_radius + 0.5, _radius, dmg, 0.4), 0.0)


func test_push_direction() -> void:
	assert_eq(BloatRules.push_direction(Vector2.ZERO, Vector2(3, 0), Vector2.UP), Vector2.RIGHT)
	assert_eq(BloatRules.push_direction(Vector2.ONE, Vector2.ONE, Vector2.UP), Vector2.UP)


func test_row_is_bloat_kind() -> void:
	assert_eq(_row["attack_kind"], &"bloat")
	assert_lt(_edge, 1.0)
