class_name SpecialAttacks
extends RefCounted
## Yürüyenden farklı saldırı düzenleri: koşucunun atılışı ya da durmadan koşusu (SprintAttack), zıplayanın sıçrayıp inişi, dilcinin dili.
## EnemyManager'ın paralel dizilerini onun adına işler (durum, süre ve nişan manager'da kalır;
## görüntüye yalnız zombi düğümünün `event` sinyaliyle haber verilir).

const S = ZombieRules.State
## Dil atışının erişimi tongue_range'in bu kadar ötesine uzanır (m).
const TONGUE_REACH_MARGIN: float = 1.0
## Eski anlık ışının görüntüde uzama süresi (sn).
const OLD_EXTEND_TIME: float = 0.12

var _m: EnemyManager
var _sprint: SprintAttack


func _init(manager: EnemyManager) -> void:
	_m = manager
	_sprint = SprintAttack.new(manager)


## Bu türün özel saldırısı açık mı (kapalıysa yürüyen gibi yaklaşıp vurur).
static func is_special(row: Dictionary) -> bool:
	match row["attack_kind"]:
		&"lunge", &"sprint":
			return Tuning.FEATURE_ZOMBIE_LUNGE
		&"jump":
			return Tuning.FEATURE_ZOMBIE_JUMP
		&"tongue":
			return Tuning.FEATURE_ZOMBIE_TONGUE
	return false


## Bu durumda saldırı SpecialAttacks'ta işlenir (act / finish).
static func acts_in(state: ZombieRules.State) -> bool:
	return faces_in(state) or state == S.LASH or state == S.PULL


## Bu durumda zombi nişan yönüne bakar (kovalarken askere döner).
static func faces_in(state: ZombieRules.State) -> bool:
	return state == S.WINDUP or state == S.LUNGE or state == S.JUMP or state == S.SPRINT or state == S.STRIKE


## Kovalarken saldırıyı başlatan mesafe payı (temasın üstüne).
static func start_range(row: Dictionary) -> float:
	if not is_special(row):
		return row["attack_range"]
	match row["attack_kind"]:
		&"lunge":
			return row["lunge_range"]
		&"sprint":
			return row["sprint_trigger_range"]
		&"jump":
			return row["jump_range"]
	return row["tongue_range"]


## Hazırlıktan sonra geçilecek durum (özel saldırı kapalıysa RECOVER: yürüyenin vuruşu).
static func windup_next(row: Dictionary) -> ZombieRules.State:
	if not is_special(row):
		return S.RECOVER
	match row["attack_kind"]:
		&"lunge":
			return S.LUNGE
		&"sprint":
			return S.SPRINT
		&"jump":
			return S.JUMP
	return S.LASH


## Özel durumda (hazırlık, atılış, havada, dil) bu karede ne yapılır. Dönüş: yeni konum.
func act(i: int, state: ZombieRules.State, p: Vector2, dir: Vector2, delta: float, target: Vector2, target_vel: Vector2) -> Vector2:
	var row: Dictionary = _m._rows[i]
	match state:
		S.WINDUP:
			_windup_tick(i, row, p, target, target_vel)
		S.LUNGE:
			_m._aim[i] = LungeRules.steer(_m._aim[i], dir, float(row["lunge_turn_rate"]) * delta)
			p += _m._aim[i] * float(row["lunge_speed"]) * delta
		S.JUMP:
			# Kalan süreye bölünerek doğrusal varış: son karede tam işaretli yerde olur.
			var dest: Vector2 = _m._aim[i]
			p += (dest - p) / maxf(_m._timer[i], delta) * delta
			_marker(i, dest, row, true)
		S.LASH:
			if Tuning.FEATURE_TONGUE_PULL:
				_tongue_flight(i, row, p, delta, target)
			else:
				_m._nodes[i].event.emit(&"tongue", {"to": _player_point(target)})
		S.PULL:
			_tongue_pull(i, row, p, delta, target)
		S.SPRINT, S.STRIKE:
			p = _sprint.act(i, state, p, dir, delta, target)
	return p


## Askerle temas çözümü (içine girmeme) bu karede uygulanır mı: havadaki zıplayan ve pençeden sonra geçip giden koşucu geçer.
func is_solid(i: int, state: ZombieRules.State) -> bool:
	return state != S.JUMP and _sprint.is_solid(i, state)


## Zombinin baktığı yön (özel durumlarda nişan yönü).
func facing(i: int, p: Vector2) -> Vector2:
	if _m._rows[i]["attack_kind"] == &"jump":
		return Steering.seek(p, _m._aim[i])
	return _m._aim[i]


## Hazırlık başlarken ilk nişan.
func begin_windup(i: int, p: Vector2, target: Vector2, target_vel: Vector2) -> void:
	_windup_tick(i, _m._rows[i], p, target, target_vel)


## Hazırlık bitti: saldırı başlar. Dönüş: girilen durum.
func end_windup(i: int, target: Vector2) -> ZombieRules.State:
	var row: Dictionary = _m._rows[i]
	match row["attack_kind"]:
		&"lunge":
			_m.lunge_starts += 1
			_m._enter(i, S.LUNGE, row["lunge_time"])
			return S.LUNGE
		&"sprint":
			return _sprint.begin(i)
		&"jump":
			_m._targetable[i] = 0
			_m._enter(i, S.JUMP, row["jump_time"])
			return S.JUMP
	if Tuning.FEATURE_TONGUE_PULL:
		return _shoot_tongue(i, row)
	return _fire_tongue(i, row, target)


## Atılış / sıçrama / dil süresi doldu. Dönüş: girilen durum.
func finish(i: int, state: ZombieRules.State, target: Vector2) -> ZombieRules.State:
	if state == S.STRIKE:
		return _sprint.end_strike(i)
	var row: Dictionary = _m._rows[i]
	var recover: float = row["attack_recover"]
	if state == S.JUMP:
		_land(i, row, target)
	elif state == S.LASH and Tuning.FEATURE_TONGUE_PULL:
		# Dil tam boya uçtu, kimseyi yakalamadı.
		recover = row["tongue_miss_recover"]
		_m._nodes[i].event.emit(&"tongue", {"off": true})
	elif state == S.LASH or state == S.PULL:
		if state == S.PULL:
			_m.tongue_timeouts += 1
		_release(i)
		_m._nodes[i].event.emit(&"tongue", {"off": true})
	_m._enter(i, S.RECOVER, recover)
	return S.RECOVER


## Atılan zombi askere değdi mi (her karede, LUNGE sırasında). Dönüş: yeni durum.
func lunge_contact(i: int, state: ZombieRules.State, p: Vector2, dist: float, reach: float, target: Vector2) -> ZombieRules.State:
	var row: Dictionary = _m._rows[i]
	if not _m.player.is_exposed() or not ZombieRules.strike_hits(dist, reach, row["lunge_hit_range"]):
		return state
	_m.lunge_hits += 1
	_m.player.take_hit(_m._damage[i], target - p)
	_m._enter(i, S.RECOVER, row["attack_recover"])
	return S.RECOVER


## Zombi ölürken ya da silinirken: bağ ve işaret temizlenir.
func on_removed(i: int) -> void:
	var node: Zombie = _m._nodes[i]
	if _m.latched == node:
		_release(i)
	var kind: StringName = _m._rows[i]["attack_kind"]
	if kind == &"jump":
		node.event.emit(&"marker", {"on": false})
	elif kind == &"tongue":
		node.event.emit(&"tongue", {"off": true})
	_m._targetable[i] = 0


func _windup_tick(i: int, row: Dictionary, p: Vector2, target: Vector2, target_vel: Vector2) -> void:
	var left: float = _m._timer[i]
	match row["attack_kind"]:
		&"lunge":
			if not LungeRules.is_aim_locked(left, float(row["lunge_lock_time"])):
				_m._aim[i] = LungeRules.aim_direction(p, target, target_vel, float(row["lunge_speed"]), float(row["lunge_lead"]))
		&"sprint":
			_sprint.scream_tick(i, p, target)
		&"jump":
			if not LungeRules.is_aim_locked(left, float(row["jump_lock_time"])):
				var ahead: float = left + float(row["jump_time"])
				_m._aim[i] = JumpRules.landing_point(p, target, target_vel, ahead, float(row["jump_lead"]), float(row["jump_max_range"]), _m._half)
			_marker(i, _m._aim[i], row, true)
		&"tongue":
			if not LungeRules.is_aim_locked(left, float(row["tongue_lock_time"])):
				var speed: float = float(row.get("tongue_speed", 16.0))
				_m._aim[i] = LungeRules.aim_direction(p, target, target_vel, speed, float(row.get("tongue_lead", 0.0)))


func _marker(i: int, dest: Vector2, row: Dictionary, on: bool) -> void:
	_m._nodes[i].event.emit(&"marker", {
		"on": on, "pos": Vector3(dest.x, 0.0, dest.y), "radius": row["land_radius"],
	})


func _land(i: int, row: Dictionary, target: Vector2) -> void:
	var dest: Vector2 = _m._aim[i]
	_m._pos[i] = dest
	_m._targetable[i] = 1
	_m._nodes[i].event.emit(&"marker", {"on": false})
	_m.jump_lands += 1
	if _m.player.is_exposed() and JumpRules.lands_on(target, dest, float(row["land_radius"]), Tuning.PLAYER_RADIUS):
		_m.jump_hits += 1
		_m.player.take_hit(_m._damage[i], target - dest)
	_m.jump_landed.emit(Vector3(dest.x, 0.1, dest.y), float(row["land_radius"]))


## Yeni mekanik: dil kilitli yönde görünür hızla uçar (LASH süresi = tam boya uçuş).
func _shoot_tongue(i: int, row: Dictionary) -> ZombieRules.State:
	var reach: float = _tongue_reach(row)
	var flight: float = TongueRules.flight_time(reach, float(row["tongue_speed"]))
	var end: Vector2 = _m._pos[i] + _m._aim[i] * reach
	_m.tongue_shots += 1
	_m._enter(i, S.LASH, flight)
	_m._nodes[i].event.emit(&"tongue", {"shoot": true, "to": _player_point(end), "time": flight})
	return S.LASH


## Uçan dilin ucu bu karede askere değdi mi; değdiyse yakalar ve çekişe geçer.
func _tongue_flight(i: int, row: Dictionary, p: Vector2, delta: float, target: Vector2) -> void:
	var reach: float = _tongue_reach(row)
	var speed: float = float(row["tongue_speed"])
	var elapsed: float = TongueRules.flight_time(reach, speed) - _m._timer[i]
	var from_d: float = TongueRules.tip_distance(elapsed - delta, speed, reach)
	var to_d: float = TongueRules.tip_distance(elapsed, speed, reach)
	var catch_radius: float = Tuning.PLAYER_RADIUS + float(row["tongue_hit_radius"])
	if not _m.player.is_exposed() or _m.player.is_rooted():
		return
	if not TongueRules.catches(p, _m._aim[i], from_d, to_d, target, catch_radius):
		return
	_m.tongue_hits += 1
	var pull_time: float = row["tongue_pull_time"]
	# Bağın süresini dilci yönetir (bırakınca release_root); askerdeki süre yalnız güvenlik payı.
	_m.player.root(pull_time + 1.0)
	_m.latched = _m._nodes[i]
	_m._enter(i, S.PULL, pull_time)
	_m._nodes[i].event.emit(&"tongue", {"attach": true, "to": _player_point(target)})


## Yakalanan asker dilciye doğru yavaşça çekilir; yakına gelince dilci ısırır ve bırakır.
func _tongue_pull(i: int, row: Dictionary, p: Vector2, delta: float, target: Vector2) -> void:
	var node: Zombie = _m._nodes[i]
	if _m.latched != node or not _m.player.is_rooted():
		# Asker öldü ya da bağ başka yoldan çözüldü.
		_release(i, true)
		node.event.emit(&"tongue", {"off": true})
		_m._enter(i, S.RECOVER, row["attack_recover"])
		return
	var stop: float = Tuning.PLAYER_RADIUS + _m._radius[i] + float(row["tongue_release_gap"])
	var reason: TongueRules.Release = TongueRules.release(p.distance_to(target), stop, _m._timer[i])
	if reason == TongueRules.Release.NEAR:
		_m.tongue_bites += 1
		_release(i, TongueRules.player_broke_free(reason))
		_m.player.take_hit(_m._damage[i], target - p)
		node.event.emit(&"tongue", {"off": true})
		_m._enter(i, S.RECOVER, row["attack_recover"])
		return
	_m.player.pull(TongueRules.pull_velocity(target, p, float(row["tongue_pull_speed"]), stop, delta))
	node.event.emit(&"tongue", {"to": _player_point(target)})


static func _tongue_reach(row: Dictionary) -> float:
	return float(row["tongue_range"]) + TONGUE_REACH_MARGIN


## Eski mekanik (7.3): anlık ışın; isabette root_time sn bağ.
func _fire_tongue(i: int, row: Dictionary, target: Vector2) -> ZombieRules.State:
	var p: Vector2 = _m._pos[i]
	var end: Vector2 = p + _m._aim[i] * (float(row["tongue_range"]) + TONGUE_REACH_MARGIN)
	var reach: float = Tuning.PLAYER_RADIUS + float(row["tongue_hit_radius"])
	var node: Zombie = _m._nodes[i]
	_m.tongue_shots += 1
	if _m.player.is_exposed() and CombatMath.segment_circle_t(p, end, target, reach) >= 0.0:
		_m.tongue_hits += 1
		_m.player.root(float(row["root_time"]))
		_m.latched = node
		_m._enter(i, S.LASH, row["root_time"])
		node.event.emit(&"tongue", {"shoot": true, "to": _player_point(target), "time": OLD_EXTEND_TIME})
		return S.LASH
	node.event.emit(&"tongue", {"shoot": true, "to": Vector3(end.x, 1.3, end.y), "time": OLD_EXTEND_TIME, "hold": Tuning.TONGUE_MISS_SHOW_TIME})
	_m._enter(i, S.RECOVER, row["tongue_miss_recover"])
	return S.RECOVER


func _release(i: int, broke_free: bool = true) -> void:
	if _m.latched == _m._nodes[i]:
		_m.latched = null
		_m.player.release_root(broke_free)


static func _player_point(target: Vector2) -> Vector3:
	return Vector3(target.x, Tuning.TONGUE_PLAYER_HEIGHT, target.y)
