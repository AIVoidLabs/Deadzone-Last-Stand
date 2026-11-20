extends GutTest

const KIND_KEYS: Dictionary = {
	&"melee": [],
	&"lunge": ["lunge_range", "lunge_speed", "lunge_time", "lunge_lead", "lunge_lock_time", "lunge_turn_rate", "lunge_hit_range"],
	&"sprint": ["sprint_trigger_range", "scream_time", "sprint_speed", "sprint_turn_rate", "sprint_give_up_factor", "strike_range",
		"strike_hit_range", "strike_hit_time", "strike_recover", "strike_move_factor", "strike_recover_factor", "strike_face_dot"],
	&"jump": ["jump_range", "jump_time", "jump_height", "jump_lock_time", "jump_lead", "jump_max_range", "land_radius"],
	&"tongue": ["tongue_range", "tongue_lock_time", "tongue_hit_radius", "root_time", "tongue_miss_recover",
		"tongue_speed", "tongue_lead", "tongue_pull_speed", "tongue_pull_time", "tongue_release_gap"],
	&"spit": ["spit_range", "spit_lock", "spit_lead", "spit_flight", "spit_arc", "acid_radius", "acid_time", "acid_tick", "acid_damage"],
	&"throw": ["throw_range", "throw_lock", "throw_lead", "throw_flight", "throw_arc", "throw_radius", "throw_melee_range",
		"throw_melee_windup", "throw_melee_hit_range", "throw_melee_recover"],
	&"scream": ["scream_range", "scream_keep_min", "scream_time", "scream_radius", "scream_count", "scream_max_alive", "scream_cooldown"],
	&"bloat": ["bloat_prime_range", "bloat_prime_time", "bloat_radius", "bloat_player_damage", "bloat_edge_factor", "bloat_zombie_damage", "bloat_death_fuse"],
}


func test_every_row_has_its_attack_keys_and_a_model() -> void:
	for id: StringName in EnemyData.TABLE:
		var row: Dictionary = EnemyData.TABLE[id]
		assert_true(KIND_KEYS.has(row["attack_kind"]), "%s: bilinmeyen saldırı türü" % id)
		for key: String in KIND_KEYS[row["attack_kind"]]:
			assert_true(row.has(key), "%s: %s eksik" % [id, key])
		assert_true(ZombieVisual.MODELS.has(row["model"]) or ZombieVisual.VC_MODELS.has(row["model"]), "%s: model yok" % id)


func test_special_attack_timings_leave_a_reaction_window() -> void:
	var jumper: Dictionary = EnemyData.get_row(EnemyData.JUMPER)
	assert_lt(float(jumper["jump_lock_time"]), float(jumper["attack_windup"]))
	# İşaret görünürken (hazırlık + havada) asker halkadan çıkabilmeli.
	var visible_time: float = float(jumper["attack_windup"]) + float(jumper["jump_time"])
	assert_gt(Tuning.PLAYER_SPEED * visible_time, float(jumper["land_radius"]) + Tuning.PLAYER_RADIUS)
	var tongue: Dictionary = EnemyData.get_row(EnemyData.TONGUE)
	assert_eq(float(tongue["root_time"]), 1.0, "bağ süresi 1 sn (Taha)")
	assert_lt(float(tongue["tongue_lock_time"]), float(tongue["attack_windup"]))
	assert_gt(float(tongue["attack_recover"]), float(tongue["root_time"]), "bağdan sonra dinlenme")


func test_player_root_blocks_dash_and_expires() -> void:
	var player: Player = Player.new()
	add_child_autofree(player)
	player.root(1.0)
	assert_true(player.is_rooted())
	player.request_dash()
	player._physics_process(0.1)
	assert_false(player.is_dashing(), "bağlıyken dash yok")
	player._physics_process(1.0)
	assert_false(player.is_rooted(), "1 sn sonra otomatik çözülür")
	player.request_dash()
	player._physics_process(0.016)
	assert_true(player.is_dashing(), "bağ çözülünce dash çalışır")


func test_player_release_is_safe_when_not_rooted() -> void:
	var player: Player = Player.new()
	add_child_autofree(player)
	player.release_root()
	assert_false(player.is_rooted())


func test_special_rows_follow_the_spec() -> void:
	for id: StringName in EnemyDataSpecials.ROWS:
		assert_true(EnemyData.TABLE.has(id), "%s tabloda yok" % id)
		var row: Dictionary = EnemyData.TABLE[id]
		assert_eq(row["id"], id)
		assert_true(row.has("tint") or EnemyDataSpecials.model_enabled(id), "%s: model yokken tint gerekir" % id)
		var look: Dictionary = EnemyDataSpecials.ROWS[id]["look_v"]
		assert_true(look.has("model") and look.has("anim_idle") and look.has("anim_walk") and look.has("anim_spawn"), "%s: look_v eksik" % id)
	# Hızlar tempo ile çarpılır (spec "tempo öncesi").
	assert_almost_eq(float(EnemyData.TABLE[EnemyData.SPITTER]["speed"]), 2.4 * Tuning.GAME_PACE, 0.0001)
	assert_eq(EnemyData.TABLE[EnemyData.SPITTER]["attack_kind"], &"spit")
	assert_eq(EnemyData.TABLE[EnemyData.THROWER]["attack_kind"], &"throw")
