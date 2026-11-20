extends GutTest
## LobRules (saf) ve ona bağlı kurallar: yay, hedef noktası, isabet, asit tikleri, tür sınırı ve havuz sınırı.


func test_target_point_leads_and_clips_to_range() -> void:
	var from: Vector2 = Vector2.ZERO
	var point: Vector2 = LobRules.target_point(from, Vector2(4.0, 0.0), Vector2(2.0, 0.0), 0.5, 8.0, 30.0)
	assert_eq(point, Vector2(5.0, 0.0), "hız x lead eklenir")
	point = LobRules.target_point(from, Vector2(7.0, 0.0), Vector2(4.0, 0.0), 0.5, 8.0, 30.0)
	assert_eq(point, Vector2(8.0, 0.0), "menzille kırpılır")
	point = LobRules.target_point(from, Vector2(29.0, 0.0), Vector2(9.0, 0.0), 1.0, 99.0, 30.0)
	assert_eq(point.x, 30.0, "arena ile kırpılır")


func test_position_follows_an_arc_from_release_height_to_ground() -> void:
	var from: Vector2 = Vector2(0.0, 0.0)
	var dest: Vector2 = Vector2(8.0, 0.0)
	var start: Vector3 = LobRules.position_at(from, dest, 0.0, 2.5, 1.3)
	assert_eq(start, Vector3(0.0, 1.3, 0.0))
	var end: Vector3 = LobRules.position_at(from, dest, 1.0, 2.5, 1.3)
	assert_almost_eq(end.y, 0.0, 0.0001)
	assert_eq(Vector2(end.x, end.z), dest)
	var mid: Vector3 = LobRules.position_at(from, dest, 0.5, 2.5, 1.3)
	assert_almost_eq(mid.y, 2.5 + 0.65, 0.0001, "tepe: arc + kalan bırakış yüksekliği")
	assert_almost_eq(mid.x, 4.0, 0.0001)


func test_progress_is_clamped() -> void:
	assert_eq(LobRules.progress(-1.0, 1.0), 0.0)
	assert_eq(LobRules.progress(0.5, 1.0), 0.5)
	assert_eq(LobRules.progress(3.0, 1.0), 1.0)


func test_rock_hit_uses_radius_plus_player_radius() -> void:
	var radius: float = float(EnemyData.get_row(EnemyData.THROWER)["throw_radius"])
	var edge: float = radius + Tuning.PLAYER_RADIUS
	assert_true(LobRules.hits(Vector2(edge - 0.01, 0.0), Vector2.ZERO, radius, Tuning.PLAYER_RADIUS))
	assert_false(LobRules.hits(Vector2(edge + 0.01, 0.0), Vector2.ZERO, radius, Tuning.PLAYER_RADIUS))


func test_pool_membership() -> void:
	var radius: float = float(EnemyData.get_row(EnemyData.SPITTER)["acid_radius"])
	assert_true(LobRules.in_pool(Vector2(radius - 0.01, 0.0), Vector2.ZERO, radius))
	assert_false(LobRules.in_pool(Vector2(radius + 0.01, 0.0), Vector2.ZERO, radius))


func test_acid_ticks_accumulate_without_loss() -> void:
	var row: Dictionary = EnemyData.get_row(EnemyData.SPITTER)
	var interval: float = row["acid_tick"]
	var acc: float = 0.0
	var ticks: int = 0
	for _i in 120:
		var step: Vector2 = LobRules.advance_tick(acc, 1.0 / 60.0, interval)
		acc = step.x
		ticks += int(step.y)
	# 2 sn içinde 2 / interval tik (kayan nokta payı 1).
	assert_between(ticks, int(2.0 / interval) - 1, int(2.0 / interval))
	var big: Vector2 = LobRules.advance_tick(0.0, interval * 3.5, interval)
	assert_eq(int(big.y), 3)
	assert_almost_eq(big.x, interval * 0.5, 0.0001)


func test_swat_range_is_contact_plus_melee_range() -> void:
	assert_true(LobRules.wants_swat(1.5, 1.0, 0.6))
	assert_false(LobRules.wants_swat(1.7, 1.0, 0.6))


func test_pick_kind_capped_drops_kinds_at_their_limit() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var mix: Dictionary = {&"walker": 1.0, &"screamer": 50.0}
	for _i in 100:
		assert_eq(SpawnRules.pick_kind_capped(rng, mix, {&"screamer": 2}, {&"screamer": 2}), &"walker", "sınırdaki tür seçilmez")
	var seen: bool = false
	for _i in 100:
		if SpawnRules.pick_kind_capped(rng, mix, {&"screamer": 2}, {&"screamer": 1}) == &"screamer":
			seen = true
	assert_true(seen, "sınırın altındaki tür seçilebilir")
	assert_eq(mix.size(), 2, "girdi karışımı değişmez")


func test_wave_mix_follows_spec_and_flags() -> void:
	var w: Array = WaveData.WAVES
	assert_true(w[1]["mix"].has(&"armored"))
	assert_false(w[1]["mix"].has(&"spitter"))
	assert_true(w[2]["mix"].has(&"spitter") and w[2]["mix"].has(&"bloater"))
	assert_true(w[3]["mix"].has(&"thrower") and w[3]["mix"].has(&"screamer"))
	assert_eq(w[3]["max_alive_kind"][&"screamer"], 2)
	assert_eq(w[4]["max_alive_kind"][&"screamer"], 2)
	var mix: Dictionary = WaveData.active_mix(w[4]["mix"])
	assert_eq(mix.has(&"spitter"), Tuning.FEATURE_ZOMBIE_SPIT)
	assert_eq(mix.has(&"thrower"), Tuning.FEATURE_ZOMBIE_THROW)
	assert_true(mix.has(&"walker"))


func test_acid_pool_cap_replaces_the_oldest() -> void:
	var m: EnemyManager = EnemyManager.new()
	var lob: LobAttack = LobAttack.new(m)
	var row: Dictionary = EnemyData.get_row(EnemyData.SPITTER)
	for n in Tuning.ACID_POOL_MAX + 3:
		lob._add_pool(Vector2(float(n), 0.0), row)
	assert_eq(lob._pool_left.size(), Tuning.ACID_POOL_MAX)
	assert_eq(lob._pool_pos[0].x, 3.0, "en eski üç havuz düştü")
	assert_eq(m.spit_pools, Tuning.ACID_POOL_MAX + 3)
	m.free()


func test_lob_melee_flag_moves_with_swap_and_shrink() -> void:
	var m: EnemyManager = EnemyManager.new()
	m._pos.resize(3)
	var lob: LobAttack = LobAttack.new(m)
	var row: Dictionary = EnemyData.get_row(EnemyData.THROWER)
	var contact: float = 1.0
	lob.windup_time(2, row, contact + 0.1, contact)
	lob.windup_time(0, row, contact + 50.0, contact)
	assert_eq(lob._melee[2], 1 if Tuning.FEATURE_THROW_MELEE else 0)
	assert_eq(lob._melee[0], 0)
	lob.swap_from_last(0, 2)
	assert_eq(lob._melee[0], lob._melee[2])
	lob.shrink(2)
	assert_eq(lob._melee.size(), 2)
	lob.swap_from_last(0, 5)
	assert_eq(lob._melee[0], 0, "eski bayrak sonradan doğana geçmez")
	m.free()


func test_take_dot_respects_dash_and_does_not_grant_iframes() -> void:
	var player: Player = Player.new()
	add_child_autofree(player)
	var events: Array = []
	player.event.connect(func(event_name: StringName, _data: Dictionary) -> void: events.append(event_name))
	var before: float = player.health.current
	player.take_dot(4.0)
	assert_lt(player.health.current, before)
	assert_eq(events, [&"dot"], "vurulma olayı yok")
	var after_first: float = player.health.current
	player.take_dot(4.0)
	assert_lt(player.health.current, after_first, "dokunulmazlık vermez: art arda tik işler")
	player.request_dash()
	player._physics_process(0.016)
	assert_true(player.is_dashing())
	var during: float = player.health.current
	player.take_dot(4.0)
	assert_eq(player.health.current, during, "dash dokunulmazlığında hasar yok")
