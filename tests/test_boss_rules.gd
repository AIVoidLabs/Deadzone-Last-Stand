extends GutTest
## BossRules + ShockRing: saldırı seçimi, halka/merkez isabeti, hücum süpürmesi, duvar, öfke; sayılar boss satırından.

const A = BossRules.Attack
const S = ZombieRules.State

var _row: Dictionary = EnemyData.get_row(EnemyData.BOSS_HEAP)


func test_row_matches_spec_numbers() -> void:
	assert_eq(float(_row["max_hp"]), 2200.0)
	assert_almost_eq(float(_row["speed"]), 1.6 * Tuning.GAME_PACE, 0.0001)
	assert_almost_eq(float(_row["charge_speed"]), 11.0 * Tuning.GAME_PACE, 0.0001)
	assert_eq(float(_row["stagger_time"]), 0.0, "sendelemez")
	assert_gte(float(_row["weight"]), 50.0, "itilmez")
	assert_eq(float(_row["radius"]), 1.4)
	assert_eq(int(_row["drop_value"]), 150)
	assert_eq(_row["attack_kind"], &"boss")


func test_available_attacks_follow_distance_bands() -> void:
	var near: Array[int] = BossRules.available(float(_row["slam_range"]) - 0.1, 5.0, _row)
	assert_true(near.has(A.SLAM))
	assert_false(near.has(A.CHARGE))
	var mid: float = (float(_row["charge_min"]) + float(_row["charge_max"])) * 0.5
	assert_true(BossRules.available(mid, 5.0, _row).has(A.CHARGE))
	assert_false(BossRules.available(mid, 5.0, _row).has(A.SLAM))
	assert_true(BossRules.available(float(_row["charge_max"]) + 1.0, 5.0, _row).is_empty(), "çok uzakta bekleme sürerken saldırı yok")


func test_summon_waits_for_cooldown_at_any_distance() -> void:
	for dist: float in [1.0, 10.0, 25.0]:
		assert_false(BossRules.available(dist, 0.5, _row).has(A.SUMMON))
		assert_true(BossRules.available(dist, 0.0, _row).has(A.SUMMON))


func test_pick_never_repeats_when_an_alternative_exists() -> void:
	var mid: float = (float(_row["charge_min"]) + float(_row["charge_max"])) * 0.5
	for roll: float in [0.0, 0.3, 0.6, 0.99]:
		assert_ne(BossRules.pick(mid, A.CHARGE, 0.0, _row, roll), A.CHARGE, "hücum üst üste seçilmez (çağrı var)")
		assert_ne(BossRules.pick(mid, A.SUMMON, 0.0, _row, roll), A.SUMMON)


func test_pick_allows_repeat_only_without_alternative_and_none_when_nothing() -> void:
	var near: float = float(_row["slam_range"]) - 0.5
	assert_eq(BossRules.pick(near, A.SLAM, 5.0, _row, 0.5), A.SLAM, "tek seçenek: tekrar serbest")
	assert_eq(BossRules.pick(float(_row["charge_max"]) + 3.0, A.NONE, 5.0, _row, 0.5), A.NONE)


func test_pick_follows_weights() -> void:
	# Yakında yalnız slam + çağrı: ağırlık oranı roll aralıklarına dönüşür.
	var near: float = float(_row["slam_range"]) - 0.5
	var weights: Dictionary = _row["attack_weights"]
	var slam_share: float = float(weights[&"slam"]) / (float(weights[&"slam"]) + float(weights[&"summon"]))
	assert_eq(BossRules.pick(near, A.NONE, 0.0, _row, slam_share - 0.01), A.SLAM)
	assert_eq(BossRules.pick(near, A.NONE, 0.0, _row, slam_share + 0.01), A.SUMMON)


func test_attack_names_and_rage_windup() -> void:
	assert_eq(BossRules.attack_name(A.SLAM), &"slam")
	assert_eq(BossRules.attack_name(A.NONE), &"")
	assert_almost_eq(BossRules.windup(1.0, true, _row), float(_row["rage_windup_factor"]), 0.0001)
	assert_eq(BossRules.windup(1.0, false, _row), 1.0)


func test_rage_triggers_once_below_threshold() -> void:
	var max_hp: float = float(_row["max_hp"])
	var threshold: float = max_hp * float(_row["rage_threshold"])
	assert_false(BossRules.should_rage(threshold + 1.0, max_hp, false, _row))
	assert_true(BossRules.should_rage(threshold - 1.0, max_hp, false, _row))
	assert_false(BossRules.should_rage(threshold - 1.0, max_hp, true, _row), "bir kez")
	assert_false(BossRules.should_rage(0.0, max_hp, false, _row), "ölüyse kükremez")


func test_rage_multipliers() -> void:
	assert_almost_eq(BossRules.rage_speed(1.0, _row), float(_row["rage_speed_factor"]), 0.0001)
	assert_eq(BossRules.ring_count(false), 1)
	assert_eq(BossRules.ring_count(true), 2, "öfkede iki halka")


func test_ring_hits_once_when_front_passes_the_soldier() -> void:
	var ring: ShockRing = ShockRing.new(Vector2.ZERO, float(_row["slam_ring_speed"]), float(_row["slam_ring_max"]), float(_row["slam_ring_width"]))
	var soldier: Vector2 = Vector2(4.0, 0.0)
	var hits: int = 0
	for _i in 200:
		if ring.step(1.0 / 60.0, soldier, Tuning.PLAYER_RADIUS, true):
			hits += 1
	assert_eq(hits, 1, "geçtiği karede bir kez")
	assert_true(ring.is_done())


func test_ring_misses_soldier_beyond_max_radius() -> void:
	var ring: ShockRing = ShockRing.new(Vector2.ZERO, float(_row["slam_ring_speed"]), float(_row["slam_ring_max"]), float(_row["slam_ring_width"]))
	var far: Vector2 = Vector2(float(_row["slam_ring_max"]) + Tuning.PLAYER_RADIUS + 1.0, 0.0)
	for _i in 200:
		assert_false(ring.step(1.0 / 60.0, far, Tuning.PLAYER_RADIUS, true))


func test_ring_does_not_hit_soldier_already_inside() -> void:
	# Halka askerin üstünden zaten geçti (asker içeride): yeniden vurmaz.
	var ring: ShockRing = ShockRing.new(Vector2.ZERO, 7.0, 9.0, 0.6)
	ring.front = 6.0
	assert_false(ring.step(1.0 / 60.0, Vector2(2.0, 0.0), Tuning.PLAYER_RADIUS, true))


func test_dash_invulnerability_lets_the_ring_pass() -> void:
	var ring: ShockRing = ShockRing.new(Vector2.ZERO, 7.0, 9.0, 0.6)
	var soldier: Vector2 = Vector2(3.0, 0.0)
	for _i in 200:
		assert_false(ring.step(1.0 / 60.0, soldier, Tuning.PLAYER_RADIUS, false), "dokunulmazken vurmaz")
	assert_false(ring.hit)


func test_sweep_catches_fast_frames() -> void:
	# Büyük karede ön kenar askerin üstünden atlasa da bant süpürülür.
	assert_true(BossRules.sweep_hits(1.0, 5.0, 0.6, 3.0, 0.4))
	assert_false(BossRules.sweep_hits(1.0, 2.0, 0.6, 3.0, 0.4))
	assert_false(BossRules.sweep_hits(6.0, 7.0, 0.6, 3.0, 0.4), "bant ötesinde kalan asker")


func test_center_damage_radius() -> void:
	assert_true(BossRules.center_hit(float(_row["slam_center_radius"]) - 0.1, _row))
	assert_false(BossRules.center_hit(float(_row["slam_center_radius"]) + 0.1, _row))
	assert_gt(float(_row["slam_center_damage"]), 0.0)


func test_charge_capsule_hits_soldier_on_path_only() -> void:
	var radius: float = float(_row["radius"])
	var pr: float = Tuning.PLAYER_RADIUS
	assert_true(BossRules.sweep_capsule_hits(Vector2.ZERO, Vector2(2, 0), radius, Vector2(1.0, radius), pr))
	assert_false(BossRules.sweep_capsule_hits(Vector2.ZERO, Vector2(2, 0), radius, Vector2(1.0, radius + pr + 0.3), pr), "yandan kaçış")
	assert_true(BossRules.sweep_capsule_hits(Vector2.ZERO, Vector2(2, 0), radius, Vector2(2.0 + radius, 0.0), pr), "uç noktada")


func test_wall_hit_and_distance() -> void:
	assert_true(BossRules.hits_wall(Vector2(10.1, 0.0), 10.0))
	assert_false(BossRules.hits_wall(Vector2(10.0, 0.0), 10.0), "duvara paralel gidiş çarpma değil")
	assert_false(BossRules.hits_wall(Vector2(3.0, -9.0), 10.0))
	assert_almost_eq(BossRules.wall_distance(Vector2(2.0, 0.0), Vector2.RIGHT, 10.0), 8.0, 0.0001)
	assert_almost_eq(BossRules.wall_distance(Vector2(0.0, 0.0), Vector2(-1, -1).normalized(), 10.0), 10.0 * sqrt(2.0), 0.001)


func test_boss_states_are_timed_and_never_stagger() -> void:
	assert_true(ZombieRules.is_timed(S.CHARGE))
	assert_true(ZombieRules.is_timed(S.STUN))
	assert_true(ZombieRules.is_timed(S.ROAR))
	assert_eq(ZombieRules.after_timer(S.CHARGE), S.RECOVER)
	assert_eq(ZombieRules.after_timer(S.STUN), S.CHASE)
	assert_eq(ZombieRules.after_timer(S.ROAR), S.CHASE)
	for state: S in [S.CHARGE, S.STUN, S.ROAR]:
		assert_false(ZombieRules.can_stagger(state))
		assert_true(ZombieRules.can_take_damage(state), "kükreme ve sersem dokunulmaz değil")
		assert_false(ZombieRules.can_move(state))


func test_router_flags_boss_states() -> void:
	assert_eq(SpecialAttacks.is_special(_row), Tuning.FEATURE_BOSS)
	assert_true(SpecialAttacks.acts_in(S.CHARGE))
	assert_true(SpecialAttacks.acts_in(S.STUN))
	assert_true(SpecialAttacks.acts_in(S.ROAR))
	assert_true(SpecialAttacks.faces_in(S.CHARGE))
	assert_false(SpecialAttacks.faces_in(S.STUN))
