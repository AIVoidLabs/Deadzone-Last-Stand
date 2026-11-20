class_name SprintAttack
extends RefCounted
## Koşucunun durmadan koşu saldırısı (Tuning.FEATURE_RUNNER_SPRINT; SpecialAttacks'ın parçası).
## EnemyManager'ın dizilerini işler; kurallar SprintRules'ta. Görüntüye durum (WINDUP = çığlık, SPRINT, STRIKE)
## ve `strike` olayıyla haber verilir. Sayaçlar: lunge_starts = başlayan pençe, lunge_hits = isabet eden pençe.

const S = ZombieRules.State

var _m: EnemyManager


func _init(manager: EnemyManager) -> void:
	_m = manager


## Çığlık boyunca yerinde askere döner.
func scream_tick(i: int, p: Vector2, target: Vector2) -> void:
	var face: Vector2 = Steering.seek(p, target)
	if face != Vector2.ZERO:
		_m._aim[i] = face


## Çığlık bitti: koşu başlar (süresiz).
func begin(i: int) -> ZombieRules.State:
	_m._enter(i, S.SPRINT, 0.0)
	return S.SPRINT


## Pençe bitti: yeniden çığlık atmadan koşuya döner.
func end_strike(i: int) -> ZombieRules.State:
	_m._enter(i, S.SPRINT, 0.0)
	return S.SPRINT


## SPRINT / STRIKE karesi: sınırlı dönüşle askere koşar, temasta pençeler. Dönüş: yeni konum.
func act(i: int, state: ZombieRules.State, p: Vector2, dir: Vector2, delta: float, target: Vector2) -> Vector2:
	var row: Dictionary = _m._rows[i]
	var contact: float = Tuning.PLAYER_RADIUS + _m._radius[i]
	var dist: float = p.distance_to(target)
	var speed: float = row["sprint_speed"]
	if state == S.SPRINT:
		if SprintRules.gives_up(dist, contact, row["sprint_trigger_range"], row["sprint_give_up_factor"]):
			_m._enter(i, S.CHASE, 0.0)
			return p
		if SprintRules.wants_strike(dist, contact, row["strike_range"], _m._aim[i], dir, row["strike_face_dot"]):
			_m.lunge_starts += 1
			_m._enter(i, S.STRIKE, SprintRules.strike_duration(row["strike_hit_time"], row["strike_recover"]))
	elif state == S.STRIKE:
		var left: float = _m._timer[i]
		var recover: float = row["strike_recover"]
		if SprintRules.is_hit_moment(left, delta, recover):
			_strike(i, row, dist, contact, target - p)
		speed = SprintRules.strike_speed(speed, left, recover, row["strike_move_factor"], row["strike_recover_factor"])
		if SprintRules.is_passing(left, recover):
			# Pençeden sonra dönmeden geçip gider (askerin içinden/yanından); yay çizip yeniden gelir.
			return p + _m._aim[i] * speed * delta
	_m._aim[i] = SprintRules.run_direction(_m._aim[i], dir, row["sprint_turn_rate"], delta)
	return p + _m._aim[i] * speed * delta


## Askerle temas çözümü uygulanır mı: pençeden sonra geçip giden koşucu askerin içinden geçer.
func is_solid(i: int, state: ZombieRules.State) -> bool:
	return state != S.STRIKE or not SprintRules.is_passing(_m._timer[i], float(_m._rows[i]["strike_recover"]))


## Pençenin indiği an: asker erişimde ve açıktaysa (dash dokunulmazlığı yoksa) hasar alır.
func _strike(i: int, row: Dictionary, dist: float, contact: float, toward: Vector2) -> void:
	var hit: bool = _m.player.is_exposed() and ZombieRules.strike_hits(dist, contact, row["strike_hit_range"])
	if hit:
		_m.lunge_hits += 1
		_m.player.take_hit(_m._damage[i], toward)
	_m._nodes[i].event.emit(&"strike", {"hit": hit})
