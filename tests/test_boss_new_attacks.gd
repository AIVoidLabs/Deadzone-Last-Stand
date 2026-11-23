extends GutTest
## 11.F boss yeni saldırıları: kusmuk yağmuru (SpewRules), zincir hücum (BossRules.chain_*), yanan yarık izi (BossTrail),
## bayraklar kapalıyken satır eskisi gibi. Sayılar boss satırından.

const A = BossRules.Attack

var _walker: Dictionary = EnemyData.get_row(EnemyData.WALKER)
var _row: Dictionary = EnemyDataBoss.build(EnemyData.get_row(EnemyData.WALKER), true, true, true, false)
var _off: Dictionary = EnemyDataBoss.build(EnemyData.get_row(EnemyData.WALKER), false, false, false, false)


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_flags_off_row_is_the_old_boss() -> void:
	for key: String in ["spew_min", "spew_windup", "charge_chain_rage", "trail_step", "anim_spew"]:
		assert_false(_off.has(key), "%s kapalıyken yok" % key)
	assert_eq(_off["attack_weights"].size(), 3)
	assert_eq(BossRules.chain_total(true, _off), 1)
	assert_false(BossRules.available(20.0, 5.0, _off).has(A.SPEW))
	assert_true(BossRules.available(20.0, 5.0, _row).has(A.SPEW))


func test_spew_clip_flag_only_adds_clip_when_on() -> void:
	var with_clip: Dictionary = EnemyDataBoss.build(_walker, true, false, false, true)
	var without: Dictionary = EnemyDataBoss.build(_walker, true, false, false, false)
	assert_eq(without["anim_spew"], [&"roar"], "yedek klip roar")
	if Tuning.FEATURE_BOSS_MODEL:
		assert_eq(with_clip["anim_spew"], [&"spew"])
		assert_eq(float(with_clip["spew_anim_hit_time"]), float(EnemyDataBoss.LOOK_V_SPEW["spew_anim_hit_time"]))
	assert_false(EnemyDataBoss.build(_walker, false, false, false, true).has("anim_spew"), "kusmuk kapalıyken klip alanı da yok")


func test_spew_only_between_min_and_max() -> void:
	assert_false(BossRules.available(float(_row["spew_min"]) - 0.1, 5.0, _row).has(A.SPEW))
	assert_true(BossRules.available(float(_row["spew_min"]), 5.0, _row).has(A.SPEW))
	assert_true(BossRules.available(float(_row["spew_max"]), 5.0, _row).has(A.SPEW))
	assert_false(BossRules.available(float(_row["spew_max"]) + 0.1, 5.0, _row).has(A.SPEW))


func test_spew_weight_doubles_when_far() -> void:
	var near: float = float(_row["spew_far_dist"]) - 0.1
	var far: float = float(_row["spew_far_dist"]) + 0.1
	var base: float = float(_row["attack_weights"][&"spew"])
	assert_eq(SpewRules.weight(near, base, _row), base)
	assert_eq(SpewRules.weight(far, base, _row), base * float(_row["spew_far_mult"]))
	# Uzakta (yalnız spew + çağrı): kusmuk payı ağırlıkla artar.
	var summon: float = float(_row["attack_weights"][&"summon"])
	var spew: float = base * float(_row["spew_far_mult"])
	var summon_share: float = summon / (spew + summon)
	assert_eq(BossRules.pick(far, A.NONE, 0.0, _row, summon_share - 0.01), A.SUMMON)
	assert_eq(BossRules.pick(far, A.NONE, 0.0, _row, summon_share + 0.01), A.SPEW)
	assert_gt(spew / (spew + summon), base / (base + summon), "uzaktan payı artar")


func test_spew_count_and_windup_follow_rage() -> void:
	assert_eq(SpewRules.count(false, _row), int(_row["spew_count"]))
	assert_eq(SpewRules.count(true, _row), int(_row["spew_count_rage"]))
	assert_almost_eq(BossRules.windup(float(_row["spew_windup"]), true, _row), float(_row["spew_windup"]) * float(_row["rage_windup_factor"]), 0.0001)


func test_landing_points_stay_in_fan_and_distance_band() -> void:
	var from: Vector2 = Vector2.ZERO
	var target: Vector2 = Vector2(18.0, 0.0)
	var half: float = deg_to_rad(float(_row["spew_spread"])) * 0.5
	for seed_value in 50:
		var pts: Array[Vector2] = SpewRules.landing_points(from, target, 7, float(_row["spew_spread"]), float(_row["spew_dist_lo"]),
				float(_row["spew_dist_hi"]), 100.0, _rng(seed_value))
		assert_eq(pts.size(), 7)
		for p: Vector2 in pts:
			assert_lte(absf(p.angle()), half + 0.0001, "yelpaze içinde")
			assert_gte(p.length(), 18.0 * float(_row["spew_dist_lo"]) - 0.0001)
			assert_lte(p.length(), 18.0 * float(_row["spew_dist_hi"]) + 0.0001)


func test_landing_points_clamped_to_arena() -> void:
	var pts: Array[Vector2] = SpewRules.landing_points(Vector2.ZERO, Vector2(20.0, 0.0), 5, 50.0, 0.7, 1.15, 10.0, _rng(1))
	for p: Vector2 in pts:
		assert_lte(absf(p.x), 10.0)
		assert_lte(absf(p.y), 10.0)


## Bağımsız ölçüm (has_gap'i kullanmaz): askeri 72 yönde 0.1 m adımlarla yürütür; yol arenada, engelsiz, askerin dışında
## başladığı havuzlara girmeden ve (başlangıçta değdiği havuzların) dışında bitiyorsa yön açıktır. Dönüş: açık yön sayısı.
func _open_dirs(pts: Array[Vector2], target: Vector2, half: float, blocks: Array[Rect2]) -> int:
	var pool_r: float = float(_row["spew_pool_radius"])
	var reach: float = pool_r + Tuning.PLAYER_RADIUS
	var escape: float = float(_row["spew_escape_len"])
	var open: int = 0
	for s in 72:
		var dir: Vector2 = Vector2.from_angle(TAU * float(s) / 72.0)
		var ok: bool = true
		var steps: int = int(escape / 0.1)
		for n in range(1, steps + 1):
			var at: Vector2 = target + dir * (0.1 * float(n))
			if absf(at.x) > half - Tuning.PLAYER_RADIUS or absf(at.y) > half - Tuning.PLAYER_RADIUS:
				ok = false
			for r: Rect2 in blocks:
				if r.grow(Tuning.PLAYER_RADIUS).has_point(at):
					ok = false
			for p: Vector2 in pts:
				var from_start: float = p.distance_to(target)
				if from_start <= pool_r - Tuning.PLAYER_RADIUS:
					continue
				var inside: bool = at.distance_to(p) < reach - 0.0001
				if inside and (from_start > reach or n == steps):
					ok = false
		if ok:
			open += 1
	return open


func test_escape_gap_always_remains() -> void:
	var blocked: float = float(_row["spew_pool_radius"])
	var escape: float = float(_row["spew_escape_len"])
	var none: Array[Rect2] = []
	for dist: float in [10.0, 14.0, 22.0, 30.0]:
		for seed_value in 100:
			var target: Vector2 = Vector2(dist, 0.0)
			var pts: Array[Vector2] = SpewRules.landing_points(Vector2.ZERO, target, 7, float(_row["spew_spread"]),
					float(_row["spew_dist_lo"]), float(_row["spew_dist_hi"]), 100.0, _rng(seed_value))
			var safe: Array[Vector2] = SpewRules.ensure_gap(pts, target, blocked, Tuning.PLAYER_RADIUS, escape, 100.0, none)
			assert_gt(_open_dirs(safe, target, 100.0, none), 0, "açık yön var (dist %.0f seed %d)" % [dist, seed_value])
			assert_gte(safe.size(), 1)
			assert_lte(safe.size(), pts.size())


func test_escape_gap_with_soldier_against_the_arena_wall() -> void:
	# Duvara dayanmış asker: duvara bakan yönler kapalı; kalan yönleri havuzlar kapatırsa top çıkarılır.
	var blocked: float = float(_row["spew_pool_radius"])
	var escape: float = float(_row["spew_escape_len"])
	var half: float = 30.0
	var target: Vector2 = Vector2(half - Tuning.PLAYER_RADIUS - 0.1, 0.0)
	var none: Array[Rect2] = []
	var ring: Array[Vector2] = []
	for deg in [110.0, 145.0, 180.0, 215.0, 250.0]:
		ring.append(target + Vector2.from_angle(deg_to_rad(deg)) * (blocked + Tuning.PLAYER_RADIUS + 0.8))
	assert_false(SpewRules.has_gap(ring, target, blocked, Tuning.PLAYER_RADIUS, escape, half, none), "duvar + toplar: kaçış yok")
	assert_eq(_open_dirs(ring, target, half, none), 0, "bağımsız ölçüm de kapalı")
	var safe: Array[Vector2] = SpewRules.ensure_gap(ring, target, blocked, Tuning.PLAYER_RADIUS, escape, half, none)
	assert_lt(safe.size(), ring.size(), "top çıkarıldı")
	assert_gt(_open_dirs(safe, target, half, none), 0)
	assert_true(SpewRules.has_gap(safe, target, blocked, Tuning.PLAYER_RADIUS, escape, half, none))
	# Duvarsız aynı yerleşimde (duvarın ötesi açık sayılsaydı) boşluk olurdu: duvar yönü gerçekten kapalı sayılıyor.
	assert_true(SpewRules.has_gap(ring, target, blocked, Tuning.PLAYER_RADIUS, escape, half * 3.0, none), "geniş arenada kaçış var")


func test_obstacle_closes_escape_directions() -> void:
	var none: Array[Rect2] = []
	# Asker bir binanın dibinde: bina yönü kapalı, kalan açık tarafı havuzlar kapatırsa top çıkar.
	var blocked: float = float(_row["spew_pool_radius"])
	var escape: float = float(_row["spew_escape_len"])
	var wall: Array[Rect2] = [Rect2(Vector2(10.5, -20.0), Vector2(5.0, 40.0))]
	var target: Vector2 = Vector2(10.0 - 0.2, 0.0)
	var pts: Array[Vector2] = []
	for deg in [110.0, 145.0, 180.0, 215.0, 250.0]:
		pts.append(target + Vector2.from_angle(deg_to_rad(deg)) * (blocked + Tuning.PLAYER_RADIUS + 0.8))
	assert_false(SpewRules.has_gap(pts, target, blocked, Tuning.PLAYER_RADIUS, escape, 100.0, wall))
	assert_true(SpewRules.has_gap(pts, target, blocked, Tuning.PLAYER_RADIUS, escape, 100.0, none))


func test_clip_points_moves_balls_to_the_obstacle_edge_before_gap_check() -> void:
	var wall: Array[Rect2] = [Rect2(Vector2(5.0, -20.0), Vector2(5.0, 40.0))]
	var pts: Array[Vector2] = [Vector2(8.0, 0.0), Vector2(3.0, 1.0)]
	var clipped: Array[Vector2] = SpewRules.clip_points(Vector2.ZERO, pts, Tuning.OBSTACLE_SHOT_RADIUS, Tuning.OBSTACLE_SHOT_MARGIN, wall)
	assert_lt(clipped[0].x, 5.0, "bina içine inen top önünde kalır")
	assert_eq(clipped[1], pts[1], "engelsiz top değişmez")


func test_ensure_gap_drops_the_ball_that_walls_the_soldier_in() -> void:
	# Askerin etrafını halka gibi saran toplar: boşluk açılana dek en yakınlar çıkar.
	var target: Vector2 = Vector2(10.0, 0.0)
	var ring: Array[Vector2] = []
	var none: Array[Rect2] = []
	var r: float = float(_row["spew_pool_radius"])
	for k in 8:
		ring.append(target + Vector2.from_angle(TAU * k / 8.0) * (r + Tuning.PLAYER_RADIUS + 0.5))
	assert_false(SpewRules.has_gap(ring, target, r, Tuning.PLAYER_RADIUS, 3.0, 100.0, none), "tam kuşatma")
	var safe: Array[Vector2] = SpewRules.ensure_gap(ring, target, r, Tuning.PLAYER_RADIUS, 3.0, 100.0, none)
	assert_true(SpewRules.has_gap(safe, target, r, Tuning.PLAYER_RADIUS, 3.0, 100.0, none))
	assert_eq(ring.size(), 8, "girdi değişmez")


func test_ball_on_the_soldier_does_not_remove_the_gap() -> void:
	# Tam üstüne inen top askeri vurur (kıpırdamayan bedel öder); kaçış yönünü tek başına kapatmaz.
	var target: Vector2 = Vector2(12.0, 0.0)
	var pts: Array[Vector2] = [target, target + Vector2(0.0, 6.0)]
	var none: Array[Rect2] = []
	assert_true(SpewRules.has_gap(pts, target, 1.6, Tuning.PLAYER_RADIUS, 3.0, 100.0, none))


func test_ball_touching_the_soldier_closes_the_direction_toward_it() -> void:
	var target: Vector2 = Vector2(12.0, 0.0)
	var r: float = float(_row["spew_pool_radius"])
	var touching: Vector2 = target + Vector2(r + Tuning.PLAYER_RADIUS - 0.1, 0.0)
	var none: Array[Rect2] = []
	var pts: Array[Vector2] = [touching]
	assert_false(SpewRules.direction_open(pts, target, Vector2.RIGHT, r, Tuning.PLAYER_RADIUS, 3.0, 100.0, none), "değen havuza doğru yön kapalı")
	assert_true(SpewRules.direction_open(pts, target, Vector2.LEFT, r, Tuning.PLAYER_RADIUS, 3.0, 100.0, none), "ters yön açık")


func test_flight_and_arc() -> void:
	assert_eq(SpewRules.flight(1.0, _row), float(_row["spew_flight_min"]))
	assert_eq(SpewRules.flight(1000.0, _row), float(_row["spew_flight_max"]))
	var mid: float = SpewRules.flight(16.0, _row)
	assert_almost_eq(mid, 16.0 / float(_row["spew_ball_speed"]), 0.0001)
	assert_almost_eq(SpewRules.arc(mid, _row), mid * float(_row["spew_arc_per_sec"]), 0.0001)


func test_acid_row_carries_pool_and_direct_hit_values() -> void:
	var acid: Dictionary = SpewRules.acid_row(_row)
	assert_eq(acid["attack_kind"], &"spit")
	assert_eq(float(acid["acid_radius"]), float(_row["spew_pool_radius"]))
	assert_eq(float(acid["acid_time"]), float(_row["spew_pool_life"]))
	assert_eq(float(acid["spew_hit_damage"]), float(_row["spew_damage"]))
	assert_true(acid.has(SpewRules.BOSS_BALL_KEY), "boss topu işaretli")
	assert_eq(float(_row["spew_windup"]), float(EnemyDataBoss.SPEW_ROW["spew_windup"]))
	assert_eq(float(_row["spew_recover"]), float(EnemyDataBoss.SPEW_ROW["spew_recover"]))


func test_chain_only_in_rage() -> void:
	assert_eq(BossRules.chain_total(false, _row), 1)
	assert_eq(BossRules.chain_total(true, _row), int(_row["charge_chain_rage"]))
	assert_eq(int(_row["charge_chain_rage"]), int(EnemyDataBoss.CHAIN_ROW["charge_chain_rage"]))
	assert_false(BossRules.chain_continues(1, false, _row), "öfke dışı tek hücum")
	assert_true(BossRules.chain_continues(1, true, _row))
	assert_true(BossRules.chain_continues(2, true, _row))
	assert_false(BossRules.chain_continues(3, true, _row), "üçüncüden sonra biter")
	assert_true(float(_row["charge_chain_windup"]) > float(_row["charge_lock_time"]), "yeniden nişan kilitten uzun: kaçılabilir")


func test_trail_drops_every_step_and_keeps_remainder_between_frames() -> void:
	var trail: BossTrail = BossTrail.new(_row)
	var step: float = float(_row["trail_step"])
	var all: Array[Vector2] = []
	var x: float = 0.0
	for _i in 100:
		all.append_array(trail.points_along(Vector2(x, 0.0), Vector2(x + 0.37, 0.0)))
		x += 0.37
	# 37 m yol: ilk parça başlangıçta, sonra her 1.2 m.
	assert_eq(all.size(), int(floor(37.0 / step)) + 1)
	assert_almost_eq(all[0].x, 0.0, 0.0001)
	assert_almost_eq(all[1].x - all[0].x, step, 0.0001)
	assert_almost_eq(all[5].x - all[4].x, step, 0.0001)


func test_trail_part_cap_replaces_the_oldest_and_reuses_slots() -> void:
	var trail: BossTrail = BossTrail.new(_row)
	var cap: int = int(_row["trail_max"])
	var slots: Array[int] = []
	for n in cap + 3:
		slots.append(trail.add(Vector2(float(n), 0.0)))
	assert_eq(trail.count(), cap)
	assert_eq(slots[cap], slots[0], "yuva yeniden kullanılır")
	assert_lt(slots.max(), cap)


func test_trail_intensity_fades_only_in_the_last_seconds() -> void:
	var life: float = float(_row["trail_life"])
	var fade: float = float(_row["trail_fade"])
	assert_eq(BossTrail.intensity(0.0, life, fade), 1.0)
	assert_almost_eq(BossTrail.intensity(life - fade, life, fade), 1.0, 0.0001)
	assert_almost_eq(BossTrail.intensity(life - fade * 0.5, life, fade), 0.5, 0.0001)
	assert_eq(BossTrail.intensity(life, life, fade), 0.0)


func test_trail_burns_on_the_part_at_dps_without_slowing() -> void:
	var trail: BossTrail = BossTrail.new(_row)
	trail.add(Vector2.ZERO)
	var total: float = 0.0
	for _i in 60:
		total += trail.tick(1.0 / 60.0, Vector2(0.3, 0.0), true)
	# 1 sn'de dps hasar; ölçüm en çok bir tik (dps x tik) sapar.
	var one_tick: float = float(_row["trail_burn_dps"]) * float(_row["trail_burn_tick"])
	assert_almost_eq(total, float(_row["trail_burn_dps"]), one_tick + 0.0001)
	assert_eq(fposmod(total, one_tick), 0.0, "hasar tam tikler hâlinde")
	assert_gt(total, 0.0)


func test_trail_does_not_burn_outside_or_when_invulnerable() -> void:
	var trail: BossTrail = BossTrail.new(_row)
	trail.add(Vector2.ZERO)
	var outside: float = float(_row["trail_radius"]) + 0.1
	var total: float = 0.0
	for _i in 120:
		total += trail.tick(1.0 / 60.0, Vector2(outside, 0.0), true)
	assert_eq(total, 0.0, "parçanın dışında")
	for _i in 60:
		total += trail.tick(1.0 / 60.0, Vector2.ZERO, false)
	assert_eq(total, 0.0, "takla/dokunulmazlık")


func test_trail_part_burns_out_after_its_life() -> void:
	var trail: BossTrail = BossTrail.new(_row)
	trail.add(Vector2.ZERO)
	var life: float = float(_row["trail_life"])
	var burned: float = 0.0
	var t: float = 0.0
	while t < life + 1.0:
		burned += trail.tick(0.05, Vector2.ZERO, true)
		t += 0.05
	assert_eq(trail.count(), 0)
	assert_lte(burned, float(_row["trail_burn_dps"]) * life + 0.01, "ömür boyunca en çok dps x ömür")
	var after: float = trail.tick(1.0, Vector2.ZERO, true)
	assert_eq(after, 0.0, "söndükten sonra hasar yok")


func test_trail_touching_uses_part_radius() -> void:
	var r: float = float(_row["trail_radius"])
	assert_true(BossTrail.touching(Vector2.ZERO, Vector2(r - 0.01, 0.0), r))
	assert_false(BossTrail.touching(Vector2.ZERO, Vector2(r + 0.01, 0.0), r))


func test_trail_stops_burning_after_boss_death() -> void:
	var trail: BossTrail = BossTrail.new(_row)
	trail.add(Vector2.ZERO)
	var before: float = trail.tick(float(_row["trail_burn_tick"]) + 0.01, Vector2.ZERO, true)
	assert_gt(before, 0.0)
	trail.stop_burning()
	var after: float = 0.0
	for _i in 30:
		after += trail.tick(0.05, Vector2.ZERO, true)
	assert_eq(after, 0.0, "boss ölünce iz yakmaz")
	assert_gt(trail.count(), 0, "parçalar yaşlanıp kendiliğinden gider")


func test_attack_weights_keep_the_old_values_and_add_spew() -> void:
	var weights: Dictionary = _row["attack_weights"]
	for key: StringName in EnemyDataBoss.ROW["attack_weights"]:
		assert_eq(float(weights[key]), float(EnemyDataBoss.ROW["attack_weights"][key]), "%s ağırlığı korunur" % key)
	assert_eq(float(weights[&"spew"]), EnemyDataBoss.SPEW_WEIGHT)
	assert_eq(_off["attack_weights"], EnemyDataBoss.ROW["attack_weights"])


func test_chain_resets_on_stun_and_single_charge_outside_rage() -> void:
	var mind: BossMind = BossMind.new(_row)
	mind.begin_charge()
	assert_eq(mind.chain_done, 1)
	assert_false(mind.finish_charge(_row), "öfke dışında tek hücum")
	assert_eq(mind.chain_done, 0, "zincir bitince sıfırlanır")
	mind.raged = true
	mind.begin_charge()
	assert_true(mind.finish_charge(_row), "öfkede zincir sürer (sonraki durum WINDUP)")
	assert_eq(mind.chain_done, 1)
	mind.begin_charge()
	mind.stun()
	assert_eq(mind.chain_done, 0, "sersemlemede zincir sıfırlanır")
	for _n in BossRules.chain_total(true, _row):
		mind.begin_charge()
	assert_false(mind.finish_charge(_row), "zincirin son hücumundan sonra toparlanma")
	assert_eq(mind.chain_done, 0)


func test_begin_charge_resets_hit_records() -> void:
	var mind: BossMind = BossMind.new(_row)
	mind.charge_hit_player = true
	mind.charge_hit_nodes[self] = true
	mind.dust_left = 5.0
	mind.begin_charge()
	assert_false(mind.charge_hit_player)
	assert_true(mind.charge_hit_nodes.is_empty())
	assert_eq(mind.dust_left, 0.0)


func _lob() -> Array:
	var m: EnemyManager = EnemyManager.new()
	return [m, LobAttack.new(m)]


func test_boss_death_cancels_only_boss_balls_in_flight() -> void:
	var pair: Array = _lob()
	var m: EnemyManager = pair[0]
	var lob: LobAttack = pair[1]
	var acid: Dictionary = SpewRules.acid_row(_row)
	lob.launch_ball(acid, Vector3.ZERO, Vector2.ZERO, Vector2(5.0, 0.0), 1.0, 1.0)
	lob.launch_ball(acid, Vector3.ZERO, Vector2.ZERO, Vector2(6.0, 0.0), 1.0, 1.0)
	var spit: Dictionary = EnemyData.get_row(EnemyData.SPITTER)
	lob._lob_from.append(Vector2.ZERO)
	lob._lob_dest.append(Vector2(7.0, 0.0))
	lob._lob_left.append(1.0)
	lob._lob_row.append(spit)
	assert_eq(lob.cancel_boss_balls(), 2)
	assert_eq(lob._lob_left.size(), 1, "tükürücü topu kalır")
	assert_false(lob._is_boss_ball(lob._lob_row[0]))
	assert_eq(lob.cancel_boss_balls(), 0)
	m.free()


func test_cancelled_balls_never_land_or_leave_pools() -> void:
	var pair: Array = _lob()
	var m: EnemyManager = pair[0]
	var lob: LobAttack = pair[1]
	lob.launch_ball(SpewRules.acid_row(_row), Vector3.ZERO, Vector2.ZERO, Vector2(5.0, 0.0), 0.2, 1.0)
	lob.cancel_boss_balls()
	m.player = null
	# tick oyuncu ister; iptal sonrası liste boş olduğundan erken döner
	lob.tick(1.0)
	assert_eq(lob._pool_left.size(), 0)
	assert_eq(lob.spew_pools, 0)
	m.free()


func test_boss_balls_use_their_own_counters() -> void:
	var pair: Array = _lob()
	var m: EnemyManager = pair[0]
	var lob: LobAttack = pair[1]
	lob.launch_ball(SpewRules.acid_row(_row), Vector3.ZERO, Vector2.ZERO, Vector2(5.0, 0.0), 1.0, 1.0)
	assert_eq(m.spit_shots, 0, "kusmuk tükürücü atış sayacını artırmaz")
	lob._add_pool(Vector2(5.0, 0.0), SpewRules.acid_row(_row))
	assert_eq(lob.spew_pools, 1)
	assert_eq(m.spit_pools, 0)
	lob._add_pool(Vector2(9.0, 0.0), EnemyData.get_row(EnemyData.SPITTER))
	assert_eq(m.spit_pools, 1)
	assert_eq(lob.spew_pools, 1)
	m.free()


func test_pool_cap_evicts_the_pool_expiring_soonest_with_mixed_lifetimes() -> void:
	var pair: Array = _lob()
	var m: EnemyManager = pair[0]
	var lob: LobAttack = pair[1]
	var long_row: Dictionary = SpewRules.acid_row(_row)
	var short_row: Dictionary = long_row.duplicate()
	short_row["acid_time"] = float(long_row["acid_time"]) * 0.2
	# En eski havuz uzun yaşar; ikincisi kısa: tampon dolunca kısa olan (en çabuk sönecek) gider, en eskisi kalır.
	lob._add_pool(Vector2(0.0, 0.0), long_row)
	lob._add_pool(Vector2(1.0, 0.0), short_row)
	for n in Tuning.ACID_POOL_MAX - 2:
		lob._add_pool(Vector2(float(n + 2), 0.0), long_row)
	assert_eq(lob._pool_left.size(), Tuning.ACID_POOL_MAX)
	lob._add_pool(Vector2(99.0, 0.0), long_row)
	assert_eq(lob._pool_left.size(), Tuning.ACID_POOL_MAX)
	assert_eq(lob._pool_pos[0].x, 0.0, "uzun ömürlü en eski havuz kalır")
	assert_false(lob._pool_pos.has(Vector2(1.0, 0.0)), "en çabuk sönecek havuz yerini verdi")
	m.free()
