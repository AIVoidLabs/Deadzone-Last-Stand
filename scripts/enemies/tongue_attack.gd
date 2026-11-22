class_name TongueAttack
extends RefCounted
## Dilcinin saldırısı (SpecialAttacks'ın parçası): dil uçuşu, çekiş, bırakma, eski anlık ışın ve yakın vuruş.
## EnemyManager'ın dizilerini işler; kurallar TongueRules'ta. Görüntüye `tongue` / `melee` olaylarıyla haber verilir.

const S = ZombieRules.State
## Dil atışının erişimi tongue_range'in bu kadar ötesine uzanır (m).
const TONGUE_REACH_MARGIN: float = 1.0
## Eski anlık ışının görüntüde uzama süresi (sn).
const OLD_EXTEND_TIME: float = 0.12

var _m: EnemyManager
## Örnek başına: bu dilci hazırlığı yakın vuruş (1) mu, dil (0) mu.
var _melee: PackedByteArray = PackedByteArray()


func _init(manager: EnemyManager) -> void:
	_m = manager


## Sıkıştırmada son örneğin yakın vuruş bayrağı i'ye taşınır (EnemyCompactor'ın paralel dizi takası).
func swap_from_last(i: int, last: int) -> void:
	if i >= _melee.size():
		return
	_melee[i] = _melee[last] if last < _melee.size() else 0


## Sıkıştırmada dizi boyu manager'ınkine iner (kalan eski bayrak sonradan doğana geçmesin).
func shrink(last: int) -> void:
	if last < _melee.size():
		_melee.resize(last)


## Hazırlık süresi (sn). Temasa yakınsa yakın vuruşa karar verir (bayrak açıkken), değilse satırdaki attack_windup.
func windup_time(i: int, row: Dictionary, dist: float, contact: float) -> float:
	if i >= _melee.size():
		_melee.resize(_m._pos.size())
	_melee[i] = 0
	if Tuning.FEATURE_TONGUE_MELEE and TongueRules.wants_melee(dist, contact, float(row["tongue_melee_range"])):
		_melee[i] = 1
		return row["tongue_melee_windup"]
	return row["attack_windup"]


## Hazırlıkta nişan: kilit süresine kadar askerin önüne bakar.
func aim_tick(i: int, row: Dictionary, p: Vector2, target: Vector2, target_vel: Vector2) -> void:
	if not LungeRules.is_aim_locked(_m._timer[i], float(row["tongue_lock_time"])):
		var speed: float = float(row.get("tongue_speed", 16.0))
		_m._aim[i] = LungeRules.aim_direction(p, target, target_vel, speed, float(row.get("tongue_lead", 0.0)))


## LASH / PULL karesi. Dönüş: yeni konum (dilci yerinde durur).
func act(i: int, state: ZombieRules.State, row: Dictionary, p: Vector2, delta: float, target: Vector2) -> Vector2:
	if state == S.LASH:
		if Tuning.FEATURE_TONGUE_PULL:
			_tongue_flight(i, row, p, delta, target)
		else:
			_m._nodes[i].event.emit(&"tongue", {"to": _player_point(target)})
	else:
		_tongue_pull(i, row, p, delta, target)
	return p


## Hazırlık bitti: yakın vuruş ya da dil atışı. Dönüş: girilen durum.
func end_windup(i: int, row: Dictionary, target: Vector2) -> ZombieRules.State:
	if i < _melee.size() and _melee[i] == 1:
		return _melee_strike(i, row, target)
	if Tuning.FEATURE_TONGUE_PULL:
		return _shoot_tongue(i, row)
	return _fire_tongue(i, row, target)


## Dil süresi doldu (LASH ya da PULL). Dönüş: toparlanma süresi.
func finish(i: int, state: ZombieRules.State, row: Dictionary) -> float:
	var recover: float = row["attack_recover"]
	if state == S.LASH and Tuning.FEATURE_TONGUE_PULL:
		# Dil tam boya uçtu, kimseyi yakalamadı.
		recover = row["tongue_miss_recover"]
		_m._nodes[i].event.emit(&"tongue", {"off": true})
	else:
		if state == S.PULL:
			_m.tongue_timeouts += 1
		release(i)
		_m._nodes[i].event.emit(&"tongue", {"off": true})
	return recover


## Zombi ölürken ya da silinirken: bağ çözülür, dil toplanır.
func on_removed(i: int, node: Zombie, kind: StringName) -> void:
	if _m.latched == node:
		release(i)
	if kind == &"tongue":
		node.event.emit(&"tongue", {"off": true})
	if i < _melee.size():
		_melee[i] = 0


func release(i: int, broke_free: bool = true) -> void:
	if _m.latched == _m._nodes[i]:
		_m.latched = null
		_m.player.release_root(broke_free)


## Dilcinin yakın vuruşu: dil yok; asker hâlâ yakındaysa hasar, ardından kısa toparlanma.
func _melee_strike(i: int, row: Dictionary, target: Vector2) -> ZombieRules.State:
	_melee[i] = 0
	_m.tongue_melees += 1
	var p: Vector2 = _m._pos[i]
	var contact: float = Tuning.PLAYER_RADIUS + _m._radius[i]
	if _m.player.is_exposed() and ZombieRules.strike_hits(p.distance_to(target), contact, float(row["tongue_melee_hit_range"])):
		_m.player.take_hit(_m._damage[i], target - p)
	_m._enter(i, S.RECOVER, row["tongue_melee_recover"])
	_m._nodes[i].event.emit(&"melee", {})
	_m.tongue_event.emit(&"melee", _ground_point(p))
	return S.RECOVER


## Yeni mekanik: dil kilitli yönde görünür hızla uçar (LASH süresi = tam boya uçuş).
func _shoot_tongue(i: int, row: Dictionary) -> ZombieRules.State:
	var reach: float = _tongue_reach(row)
	var flight: float = TongueRules.flight_time(reach, float(row["tongue_speed"]))
	var end: Vector2 = _m._pos[i] + _m._aim[i] * reach
	_m.tongue_shots += 1
	_m._enter(i, S.LASH, flight)
	_m._nodes[i].event.emit(&"tongue", {"shoot": true, "to": _player_point(end), "time": flight})
	_m.tongue_event.emit(&"shoot", _ground_point(_m._pos[i]))
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
	_m.tongue_event.emit(&"attach", _ground_point(p))


## Yakalanan asker dilciye doğru yavaşça çekilir; yakına gelince dilci ısırır ve bırakır.
func _tongue_pull(i: int, row: Dictionary, p: Vector2, delta: float, target: Vector2) -> void:
	var node: Zombie = _m._nodes[i]
	if _m.latched != node or not _m.player.is_rooted():
		# Asker öldü ya da bağ başka yoldan çözüldü.
		release(i, true)
		node.event.emit(&"tongue", {"off": true})
		_m._enter(i, S.RECOVER, row["attack_recover"])
		return
	var stop: float = Tuning.PLAYER_RADIUS + _m._radius[i] + float(row["tongue_release_gap"])
	var reason: TongueRules.Release = TongueRules.release(p.distance_to(target), stop, _m._timer[i])
	if reason == TongueRules.Release.NEAR:
		_m.tongue_bites += 1
		release(i, TongueRules.player_broke_free(reason))
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
		_m.tongue_event.emit(&"shoot", _ground_point(p))
		return S.LASH
	node.event.emit(&"tongue", {"shoot": true, "to": Vector3(end.x, 1.3, end.y), "time": OLD_EXTEND_TIME, "hold": Tuning.TONGUE_MISS_SHOW_TIME})
	_m.tongue_event.emit(&"shoot", _ground_point(p))
	_m._enter(i, S.RECOVER, row["tongue_miss_recover"])
	return S.RECOVER


static func _ground_point(p: Vector2) -> Vector3:
	return Vector3(p.x, 0.1, p.y)


static func _player_point(target: Vector2) -> Vector3:
	return Vector3(target.x, Tuning.TONGUE_PLAYER_HEIGHT, target.y)
