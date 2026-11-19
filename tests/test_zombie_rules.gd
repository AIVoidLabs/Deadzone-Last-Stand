extends GutTest

const S = ZombieRules.State


func _walker() -> Dictionary:
	return EnemyData.get_row(EnemyData.WALKER)


func test_attack_cycle_returns_to_chase() -> void:
	assert_eq(ZombieRules.after_timer(S.SPAWN), S.CHASE)
	assert_eq(ZombieRules.after_timer(S.WINDUP), S.RECOVER)
	assert_eq(ZombieRules.after_timer(S.RECOVER), S.CHASE)
	assert_eq(ZombieRules.after_timer(S.STAGGER), S.CHASE)
	assert_eq(ZombieRules.after_timer(S.DYING), S.INACTIVE)


func test_lunge_cycle() -> void:
	assert_eq(ZombieRules.after_timer(S.WINDUP, S.LUNGE), S.LUNGE)
	assert_eq(ZombieRules.after_timer(S.LUNGE), S.RECOVER)
	assert_false(ZombieRules.can_stagger(S.LUNGE))
	assert_true(ZombieRules.can_take_damage(S.LUNGE))
	assert_true(ZombieRules.is_timed(S.LUNGE))


func test_jump_and_lash_cycles() -> void:
	assert_eq(ZombieRules.after_timer(S.WINDUP, S.JUMP), S.JUMP)
	assert_eq(ZombieRules.after_timer(S.JUMP), S.RECOVER)
	assert_eq(ZombieRules.after_timer(S.WINDUP, S.LASH), S.LASH)
	assert_eq(ZombieRules.after_timer(S.LASH), S.RECOVER)
	assert_false(ZombieRules.can_take_damage(S.JUMP), "havadaki vurulamaz")
	assert_true(ZombieRules.can_take_damage(S.LASH))
	assert_false(ZombieRules.can_stagger(S.JUMP))
	assert_false(ZombieRules.can_stagger(S.LASH))
	assert_eq(ZombieRules.after_timer(S.PULL), S.RECOVER, "çekiş süresi dolunca bırakır")
	assert_true(ZombieRules.can_take_damage(S.PULL), "çekerken vurulup öldürülebilir")
	assert_false(ZombieRules.can_stagger(S.PULL), "çekiş sendelemeyle bozulmaz")


func test_runner_lunge_is_fair_but_not_trivial() -> void:
	# Koşucu atılırken normal koşudan hızlı, ama dash (hız x süre) ve hazırlık süresi kaçışa yeter.
	var row: Dictionary = EnemyData.get_row(EnemyData.RUNNER)
	assert_gt(float(row["lunge_speed"]), Tuning.PLAYER_SPEED, "atılış koşudan hızlı")
	assert_gt(Tuning.DASH_DURATION, 0.0)
	assert_gt(float(row["attack_windup"]), 0.4, "tepki payı")
	assert_lt(float(row["lunge_lock_time"]), float(row["attack_windup"]))


func test_only_chase_moves_and_is_untimed() -> void:
	for state: int in S.values():
		assert_eq(ZombieRules.can_move(state), state == S.CHASE)
	assert_false(ZombieRules.is_timed(S.CHASE))
	assert_true(ZombieRules.is_timed(S.WINDUP))
	assert_true(ZombieRules.is_timed(S.SPAWN))


func test_dying_and_inactive_take_no_damage() -> void:
	assert_false(ZombieRules.can_take_damage(S.DYING))
	assert_false(ZombieRules.can_take_damage(S.INACTIVE))
	assert_true(ZombieRules.can_take_damage(S.SPAWN))
	assert_true(ZombieRules.can_take_damage(S.WINDUP))


func test_stagger_interrupts_attack_but_not_spawn_or_death() -> void:
	assert_true(ZombieRules.can_stagger(S.WINDUP))
	assert_true(ZombieRules.can_stagger(S.CHASE))
	assert_false(ZombieRules.can_stagger(S.SPAWN))
	assert_false(ZombieRules.can_stagger(S.DYING))


func test_attack_starts_within_range_only() -> void:
	var row: Dictionary = _walker()
	var contact: float = Tuning.PLAYER_RADIUS + float(row["radius"])
	var attack_range: float = row["attack_range"]
	assert_true(ZombieRules.wants_attack(contact, contact, attack_range))
	assert_true(ZombieRules.wants_attack(contact + attack_range, contact, attack_range))
	assert_false(ZombieRules.wants_attack(contact + attack_range + 0.01, contact, attack_range))


func test_strike_misses_when_target_left_reach() -> void:
	var row: Dictionary = _walker()
	var contact: float = Tuning.PLAYER_RADIUS + float(row["radius"])
	var hit_range: float = row["attack_hit_range"]
	assert_true(ZombieRules.strike_hits(contact + hit_range * 0.5, contact, hit_range))
	assert_false(ZombieRules.strike_hits(contact + hit_range + 0.01, contact, hit_range))


func test_player_can_walk_out_of_a_windup() -> void:
	# Hazırlık süresince koşan asker vuruş erişiminden çıkabilmeli; yoksa saldırıdan kaçılamaz.
	var row: Dictionary = _walker()
	var escape: float = Tuning.PLAYER_SPEED * float(row["attack_windup"])
	assert_gt(escape, float(row["attack_hit_range"]))
	assert_gt(float(row["attack_hit_range"]), float(row["attack_range"]))
