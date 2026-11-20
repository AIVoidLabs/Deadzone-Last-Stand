extends GutTest


func test_fire_next_spawns_on_next_empty_tick() -> void:
	var r: ArenaRespawn = ArenaRespawn.new(Tuning.DEBUG_ARENA_RESPAWN_DELAY)
	r.fire_next()
	assert_true(r.tick(false, 0.0))
	assert_false(r.tick(false, 0.0))


func test_no_respawn_while_enemy_alive() -> void:
	var r: ArenaRespawn = ArenaRespawn.new(Tuning.DEBUG_ARENA_RESPAWN_DELAY)
	for _i in 10:
		assert_false(r.tick(true, Tuning.DEBUG_ARENA_RESPAWN_DELAY))


func test_respawns_after_delay() -> void:
	var r: ArenaRespawn = ArenaRespawn.new(Tuning.DEBUG_ARENA_RESPAWN_DELAY)
	assert_false(r.tick(false, Tuning.DEBUG_ARENA_RESPAWN_DELAY * 0.5))
	assert_true(r.tick(false, Tuning.DEBUG_ARENA_RESPAWN_DELAY * 0.6))


func test_timer_restarts_after_respawn() -> void:
	var r: ArenaRespawn = ArenaRespawn.new(1.0)
	assert_true(r.tick(false, 1.5))
	assert_false(r.tick(false, 0.5))


func test_alive_resets_countdown() -> void:
	var r: ArenaRespawn = ArenaRespawn.new(1.0)
	r.tick(false, 0.9)
	r.tick(true, 0.1)
	assert_false(r.tick(false, 0.5))
