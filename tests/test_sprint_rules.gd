extends GutTest
## Koşucunun durmadan koşu saldırısı (Tuning.FEATURE_RUNNER_SPRINT): tetik, dönüş, vuruş anı, geçip gitme, bırakma.

const S = ZombieRules.State
const STEP: float = 1.0 / 60.0


func _row() -> Dictionary:
	return EnemyData.get_row(EnemyData.RUNNER)


func _contact(row: Dictionary) -> float:
	return Tuning.PLAYER_RADIUS + float(row["radius"])


func test_runner_row_uses_sprint_when_enabled() -> void:
	var row: Dictionary = _row()
	if not Tuning.FEATURE_RUNNER_SPRINT:
		assert_eq(row["attack_kind"], &"lunge", "kapalıyken eski atılış")
		return
	assert_eq(row["attack_kind"], &"sprint")
	assert_eq(float(row["attack_windup"]), float(row["scream_time"]), "çığlık = hazırlık")
	assert_almost_eq(float(row["sprint_speed"]), 7.8 * Tuning.GAME_PACE, 0.0001, "hız tempoyla çarpılır")
	assert_eq(SpecialAttacks.start_range(row), float(row["sprint_trigger_range"]))
	assert_eq(SpecialAttacks.windup_next(row), S.SPRINT)


func test_trigger_only_inside_range() -> void:
	var row: Dictionary = _row()
	if not EnemyData.sprints(row):
		pass_test("koşu kapalı")
		return
	var contact: float = _contact(row)
	var trigger: float = row["sprint_trigger_range"]
	assert_true(SprintRules.triggers(contact + trigger, contact, trigger))
	assert_false(SprintRules.triggers(contact + trigger + 0.01, contact, trigger))


func test_sprint_state_is_untimed_and_strike_returns_to_sprint() -> void:
	assert_false(ZombieRules.is_timed(S.SPRINT), "koşu süresiz: durmaz")
	assert_true(ZombieRules.is_timed(S.STRIKE))
	assert_eq(ZombieRules.after_timer(S.STRIKE), S.SPRINT, "pençeden sonra yeniden çığlık yok")
	assert_false(ZombieRules.can_stagger(S.SPRINT), "koşarken sendelemez")
	assert_false(ZombieRules.can_stagger(S.STRIKE))
	assert_true(ZombieRules.can_stagger(S.WINDUP), "çığlıkta sendeler")
	assert_true(ZombieRules.can_take_damage(S.SPRINT))


func test_turn_is_limited_so_a_side_dodge_makes_it_overshoot() -> void:
	var row: Dictionary = _row()
	if not EnemyData.sprints(row):
		pass_test("koşu kapalı")
		return
	var turn: float = row["sprint_turn_rate"]
	# Asker birden tam yana geçti: bir karede en çok turn_rate * delta döner.
	var dir: Vector2 = SprintRules.run_direction(Vector2.RIGHT, Vector2.UP, turn, STEP)
	assert_almost_eq(absf(Vector2.RIGHT.angle_to(dir)), turn * STEP, 0.0001)
	# Dönüş yarıçapı (hız / açısal hız) zombi gövdesinden büyük: yay çizer, yerinde dönmez.
	assert_gt(float(row["sprint_speed"]) / turn, float(row["radius"]) * 2.0)


func test_never_stops_while_turning_back() -> void:
	# Askeri geçen koşucu durmadan geri döner: her karede hız sabit, yön adım adım askere yönelir.
	var row: Dictionary = _row()
	if not EnemyData.sprints(row):
		pass_test("koşu kapalı")
		return
	var speed: float = row["sprint_speed"]
	var turn: float = row["sprint_turn_rate"]
	var p: Vector2 = Vector2(2.0, 0.0)
	var aim: Vector2 = Vector2.RIGHT
	var target: Vector2 = Vector2.ZERO
	var closest: float = INF
	for _i in int(PI / turn / STEP) + 120:
		aim = SprintRules.run_direction(aim, Steering.seek(p, target), turn, STEP)
		var next: Vector2 = p + aim * speed * STEP
		assert_almost_eq(p.distance_to(next), speed * STEP, 0.0001)
		p = next
		closest = minf(closest, p.distance_to(target))
	assert_lt(closest, 1.0, "yay çizip askere geri döndü")


func test_strike_lands_at_hit_time() -> void:
	var row: Dictionary = _row()
	if not EnemyData.sprints(row):
		pass_test("koşu kapalı")
		return
	var hit_time: float = row["strike_hit_time"]
	var recover: float = row["strike_recover"]
	var left: float = SprintRules.strike_duration(hit_time, recover)
	var elapsed: float = 0.0
	var hits: int = 0
	var hit_at: float = -1.0
	while left > 0.0:
		left -= STEP
		elapsed += STEP
		if SprintRules.is_hit_moment(left, STEP, recover):
			hits += 1
			hit_at = elapsed
	assert_eq(hits, 1, "tek vuruş")
	assert_almost_eq(hit_at, hit_time, STEP)
	# Vuruşa kadar move_factor, geçerken recover_factor; durmaz.
	var speed: float = row["sprint_speed"]
	var before: float = SprintRules.strike_speed(speed, recover + 0.1, recover, row["strike_move_factor"], row["strike_recover_factor"])
	var after: float = SprintRules.strike_speed(speed, recover - 0.1, recover, row["strike_move_factor"], row["strike_recover_factor"])
	assert_almost_eq(before, speed * float(row["strike_move_factor"]), 0.0001)
	assert_almost_eq(after, speed * float(row["strike_recover_factor"]), 0.0001)
	assert_gt(after, 0.0)
	assert_false(SprintRules.is_passing(recover + 0.01, recover), "vuruştan önce döner")
	assert_true(SprintRules.is_passing(recover, recover), "vuruştan sonra geçip gider")


func test_strike_starts_near_and_reaches() -> void:
	var row: Dictionary = _row()
	if not EnemyData.sprints(row):
		pass_test("koşu kapalı")
		return
	var contact: float = _contact(row)
	var reach: float = contact + float(row["strike_range"])
	var face: float = row["strike_face_dot"]
	assert_true(SprintRules.wants_strike(reach, contact, row["strike_range"], Vector2.UP, Vector2.UP, face))
	assert_false(SprintRules.wants_strike(reach + 0.01, contact, row["strike_range"], Vector2.UP, Vector2.UP, face))
	assert_false(SprintRules.wants_strike(reach, contact, row["strike_range"], Vector2.UP, Vector2.DOWN, face), "sırtı dönükken pençelemez")
	assert_gt(float(row["strike_hit_range"]), float(row["strike_range"]), "başladığı yerden vurabilir")


func test_runs_past_after_strike_and_comes_back_later() -> void:
	# Ayakta duran askere temas ederek pençeler; vuruştan sonra dönmeden geçip gider, yay çizip yeniden gelir.
	# İki darbe arası pençe süresinden belirgin uzun olmalı (temasta kalıp kesintisiz vurmaz) ama koşucu durmaz.
	var row: Dictionary = _row()
	if not EnemyData.sprints(row):
		pass_test("koşu kapalı")
		return
	var contact: float = _contact(row)
	var speed: float = row["sprint_speed"]
	var turn: float = row["sprint_turn_rate"]
	var hit_time: float = row["strike_hit_time"]
	var recover: float = row["strike_recover"]
	var duration: float = SprintRules.strike_duration(hit_time, recover)
	var target: Vector2 = Vector2.ZERO
	var p: Vector2 = Vector2(0.0, contact)
	var aim: Vector2 = Vector2.UP
	var striking: bool = true
	var left: float = duration
	var hits: PackedFloat32Array = PackedFloat32Array()
	var passed_far: float = 0.0
	var t: float = 0.0
	while t < 12.0 and hits.size() < 2:
		t += STEP
		var dir: Vector2 = Steering.seek(p, target)
		var v: float = speed
		if striking:
			left -= STEP
			if SprintRules.is_hit_moment(left, STEP, recover):
				hits.append(t)
			v = SprintRules.strike_speed(speed, left, recover, row["strike_move_factor"], row["strike_recover_factor"])
			if left <= 0.0:
				striking = false
		elif SprintRules.wants_strike(p.distance_to(target), contact, row["strike_range"], aim, dir, row["strike_face_dot"]):
			striking = true
			left = duration
		if not (striking and SprintRules.is_passing(left, recover)):
			aim = SprintRules.run_direction(aim, dir, turn, STEP)
		p += aim * v * STEP
		# Geçerken temas çözümü yok; koşarken askerin içine girmez.
		if not (striking and SprintRules.is_passing(left, recover)) and p.length() < contact:
			p = p.normalized() * contact
		passed_far = maxf(passed_far, p.length())
	assert_eq(hits.size(), 2, "yeniden geldi ve vurdu")
	assert_gt(hits[1] - hits[0], duration * 2.0, "darbeler arası nefes payı")
	assert_gt(passed_far, contact + float(row["strike_range"]), "askerin öbür yanına geçti")


func test_gives_up_when_player_far() -> void:
	var row: Dictionary = _row()
	if not EnemyData.sprints(row):
		pass_test("koşu kapalı")
		return
	var contact: float = _contact(row)
	var trigger: float = row["sprint_trigger_range"]
	var factor: float = row["sprint_give_up_factor"]
	assert_false(SprintRules.gives_up(contact + trigger * factor, contact, trigger, factor))
	assert_true(SprintRules.gives_up(contact + trigger * factor + 0.01, contact, trigger, factor))
	assert_gt(factor, 1.0, "tetik menzilinde koşu bitmez")
