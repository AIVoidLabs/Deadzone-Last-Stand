class_name SpecialAttacks
extends RefCounted
## Yürüyenden farklı saldırı düzenleri: koşucunun atılışı ya da durmadan koşusu (SprintAttack), zıplayanın sıçrayıp inişi,
## dilcinin dili ve yakın vuruşu (TongueAttack), tükürücünün asit topu ve taş fırlatanın kayası (LobAttack). Yönlendirici: tür satırına göre ilgili sınıfa devreder.
## EnemyManager'ın paralel dizilerini onun adına işler (durum, süre ve nişan manager'da kalır;
## görüntüye yalnız zombi düğümünün `event` sinyaliyle haber verilir).

const S = ZombieRules.State
## Dil atışının erişimi tongue_range'in bu kadar ötesine uzanır (m).
const TONGUE_REACH_MARGIN: float = TongueAttack.TONGUE_REACH_MARGIN

var _m: EnemyManager
var _sprint: SprintAttack
var _tongue: TongueAttack
var _lob: LobAttack


func _init(manager: EnemyManager) -> void:
	_m = manager
	_sprint = SprintAttack.new(manager)
	_tongue = TongueAttack.new(manager)
	_lob = LobAttack.new(manager)


## Bu türün özel saldırısı açık mı (kapalıysa yürüyen gibi yaklaşıp vurur).
static func is_special(row: Dictionary) -> bool:
	match row["attack_kind"]:
		&"lunge", &"sprint":
			return Tuning.FEATURE_ZOMBIE_LUNGE
		&"jump":
			return Tuning.FEATURE_ZOMBIE_JUMP
		&"tongue":
			return Tuning.FEATURE_ZOMBIE_TONGUE
		&"spit":
			return Tuning.FEATURE_ZOMBIE_SPIT
		&"throw":
			return Tuning.FEATURE_ZOMBIE_THROW
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
		&"spit":
			return row["spit_range"]
		&"throw":
			return row["throw_range"]
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
		&"spit", &"throw":
			return S.RECOVER
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
		S.LASH, S.PULL:
			p = _tongue.act(i, state, row, p, delta, target)
		S.SPRINT, S.STRIKE:
			p = _sprint.act(i, state, p, dir, delta, target)
	return p


## Askerle temas çözümü (içine girmeme) bu karede uygulanır mı: havadaki zıplayan ve pençeden sonra geçip giden koşucu geçer.
func is_solid(i: int, state: ZombieRules.State) -> bool:
	return state != S.JUMP and _sprint.is_solid(i, state)


## Zombinin baktığı yön (özel durumlarda nişan yönü).
func facing(i: int, p: Vector2) -> Vector2:
	if _is_aimed_at_point(_m._rows[i]["attack_kind"]):
		return Steering.seek(p, _m._aim[i])
	return _m._aim[i]


## Hazırlık süresi (sn). Dilci / taş fırlatan temasa yakınsa yakın vuruşa karar verir (bayrak açıkken), değilse satırdaki attack_windup.
func windup_time(i: int, dist: float, contact: float) -> float:
	var row: Dictionary = _m._rows[i]
	match row["attack_kind"]:
		&"tongue":
			return _tongue.windup_time(i, row, dist, contact)
		&"throw":
			return _lob.windup_time(i, row, dist, contact)
	return row["attack_windup"]


## Hazırlık başlarken ilk nişan.
func begin_windup(i: int, p: Vector2, target: Vector2, target_vel: Vector2) -> void:
	var row: Dictionary = _m._rows[i]
	if row["attack_kind"] == &"spit" or row["attack_kind"] == &"throw":
		_lob.begin_windup(i, row, p, target, target_vel)
		return
	_windup_tick(i, row, p, target, target_vel)


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
		&"spit", &"throw":
			return _lob.end_windup(i, row, target)
	return _tongue.end_windup(i, row, target)


## Atılış / sıçrama / dil süresi doldu. Dönüş: girilen durum.
func finish(i: int, state: ZombieRules.State, target: Vector2) -> ZombieRules.State:
	if state == S.STRIKE:
		return _sprint.end_strike(i)
	var row: Dictionary = _m._rows[i]
	var recover: float = row["attack_recover"]
	if state == S.JUMP:
		_land(i, row, target)
	elif state == S.LASH or state == S.PULL:
		recover = _tongue.finish(i, state, row)
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


## Sıkıştırma: örneğe bağlı özel diziler paralel dizilerle birlikte kayar.
func swap_from_last(i: int, last: int) -> void:
	_tongue.swap_from_last(i, last)
	_lob.swap_from_last(i, last)


func shrink(last: int) -> void:
	_tongue.shrink(last)
	_lob.shrink(last)


## Her fizik karesi: uçan top/kayalar ve asit havuzları.
func tick(delta: float) -> void:
	_lob.tick(delta)


## Zombi ölürken ya da silinirken: bağ ve işaret temizlenir.
func on_removed(i: int) -> void:
	var node: Zombie = _m._nodes[i]
	var kind: StringName = _m._rows[i]["attack_kind"]
	if kind == &"jump":
		node.event.emit(&"marker", {"on": false})
	_tongue.on_removed(i, node, kind)
	_lob.on_removed(i)
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
			_tongue.aim_tick(i, row, p, target, target_vel)
		&"spit", &"throw":
			_lob.aim_tick(i, row, p, target, target_vel)


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


## Nişan alanı bir yön değil yerdeki nokta olan türler (iniş / atış noktası).
static func _is_aimed_at_point(kind: StringName) -> bool:
	return kind == &"jump" or kind == &"spit" or kind == &"throw"
