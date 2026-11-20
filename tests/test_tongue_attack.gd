extends GutTest
## Dilcinin örnek başına yakın vuruş bayrağı, sıkıştırmada (takas + kısaltma) paralel dizilerle birlikte kayar.


func _setup(count: int) -> Array:
	var m: EnemyManager = EnemyManager.new()
	m._pos.resize(count)
	var ta: TongueAttack = TongueAttack.new(m)
	return [m, ta]


func test_melee_flag_moves_with_swap() -> void:
	var s: Array = _setup(3)
	var ta: TongueAttack = s[1]
	var row: Dictionary = EnemyData.TABLE[&"tongue"]
	var contact: float = 1.0
	ta.windup_time(2, row, contact + 0.1, contact)
	ta.windup_time(0, row, contact + 50.0, contact)
	assert_eq(ta._melee[2], 1 if Tuning.FEATURE_TONGUE_MELEE else 0)
	ta.swap_from_last(0, 2)
	assert_eq(ta._melee[0], ta._melee[2])
	s[0].free()


func test_shrink_drops_stale_flags() -> void:
	var s: Array = _setup(3)
	var ta: TongueAttack = s[1]
	ta.windup_time(2, EnemyData.TABLE[&"tongue"], 1.1, 1.0)
	ta.shrink(2)
	assert_eq(ta._melee.size(), 2)
	ta.swap_from_last(0, 5)
	assert_eq(ta._melee[0], 0)
	s[0].free()
