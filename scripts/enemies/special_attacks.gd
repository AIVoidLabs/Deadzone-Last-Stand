class_name SpecialAttacks
extends RefCounted
## Yürüyenden farklı saldırı düzenleri: koşucunun atılışı, zıplayanın sıçrayıp inişi, dilcinin dili.
## EnemyManager'ın paralel dizilerini onun adına işler (durum, süre ve nişan manager'da kalır;
## görüntüye yalnız zombi düğümünün `event` sinyaliyle haber verilir).

const S = ZombieRules.State
## Dil atışının erişimi tongue_range'in bu kadar ötesine uzanır (m).
const TONGUE_REACH_MARGIN: float = 1.0

var _m: EnemyManager


func _init(manager: EnemyManager) -> void:
	_m = manager


## Bu türün özel saldırısı açık mı (kapalıysa yürüyen gibi yaklaşıp vurur).
static func is_special(row: Dictionary) -> bool:
	match row["attack_kind"]:
		&"lunge":
			return Tuning.FEATURE_ZOMBIE_LUNGE
		&"jump":
			return Tuning.FEATURE_ZOMBIE_JUMP
		&"tongue":
			return Tuning.FEATURE_ZOMBIE_TONGUE
	return false


## Kovalarken saldırıyı başlatan mesafe payı (temasın üstüne).
static func start_range(row: Dictionary) -> float:
	if not is_special(row):
		return row["attack_range"]
	match row["attack_kind"]:
		&"lunge":
			return row["lunge_range"]
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
			_m._nodes[i].event.emit(&"tongue", {"to": _player_point(target), "hold": 0.0})
	return p


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
		&"jump":
			_m._targetable[i] = 0
			_m._enter(i, S.JUMP, row["jump_time"])
			return S.JUMP
	return _fire_tongue(i, row, target)


## Atılış / sıçrama / dil süresi doldu. Dönüş: girilen durum.
func finish(i: int, state: ZombieRules.State, target: Vector2) -> ZombieRules.State:
	var row: Dictionary = _m._rows[i]
	if state == S.JUMP:
		_land(i, row, target)
	elif state == S.LASH:
		_release(i)
		_m._nodes[i].event.emit(&"tongue", {"off": true})
	_m._enter(i, S.RECOVER, row["attack_recover"])
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
		&"jump":
			if not LungeRules.is_aim_locked(left, float(row["jump_lock_time"])):
				var ahead: float = left + float(row["jump_time"])
				_m._aim[i] = JumpRules.landing_point(p, target, target_vel, ahead, float(row["jump_lead"]), float(row["jump_max_range"]), _m._half)
			_marker(i, _m._aim[i], row, true)
		&"tongue":
			if not LungeRules.is_aim_locked(left, float(row["tongue_lock_time"])):
				_m._aim[i] = Steering.seek(p, target)


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
		node.event.emit(&"tongue", {"to": _player_point(target), "hold": 0.0})
		return S.LASH
	node.event.emit(&"tongue", {"to": Vector3(end.x, 1.3, end.y), "hold": Tuning.TONGUE_MISS_SHOW_TIME})
	_m._enter(i, S.RECOVER, row["tongue_miss_recover"])
	return S.RECOVER


func _release(i: int) -> void:
	if _m.latched == _m._nodes[i]:
		_m.latched = null
		_m.player.release_root()


static func _player_point(target: Vector2) -> Vector3:
	return Vector3(target.x, Tuning.TONGUE_PLAYER_HEIGHT, target.y)
