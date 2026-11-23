class_name BossCharge
extends RefCounted
## Boss hücumu (BossAttack'in parçası; kurallar BossRules / BossTrail): hazırlıkta şerit işareti (son charge_lock_time sn
## yön kilitli), kilitli yönde koşu, yoldaki askere ve zombilere çarpma, duvara/engele çarpınca sersemleme.
## 11.F: öfkede zincir (hücum bitince kısa yeniden nişan + yeni hücum, BossRules.chain_*) ve arkada yanan yarık izi (BossTrail).
## Sayaçlar ölçüm içindir (BossAttack aynalar). Görüntüye boss_event: charge_marker / charge_start / charge_dust / stun / trail.

const S = ZombieRules.State

var charges: int = 0
var hits: int = 0
var stuns: int = 0

var _m: EnemyManager
var _trail: BossTrail


func _init(manager: EnemyManager) -> void:
	_m = manager


## Yeni boss satırı: yarık izi bayrağı açıksa (satırda trail_* varsa) iz kurulur.
func setup(row: Dictionary) -> void:
	_trail = BossTrail.new(row) if row.has("trail_step") else null


## Boss öldü: iz hasar vermez (parçalar yaşlanıp söner) ve görüntü kısa sürede söner.
func stop_trail() -> void:
	if _trail == null:
		return
	_trail.stop_burning()
	_m.boss_event.emit(&"trail_stop", {})


## Her fizik karesi (boss ölse de): iz parçaları yaşlanır, üstünde duran asker yanar (zırh ve dokunulmazlık take_dot'ta).
func tick_trail(delta: float) -> void:
	if _trail == null or _trail.count() == 0:
		return
	var burn: float = _trail.tick(delta, _m.player.position_2d(), _m.player.is_exposed())
	if burn > 0.0:
		_m.player.take_dot(burn)


## Hazırlıkta şerit işareti: son charge_lock_time sn yön kilitli, işaret kilitle parlar.
func aim_tick(i: int, p: Vector2, target: Vector2, row: Dictionary) -> void:
	var face: Vector2 = Steering.seek(p, target)
	var locked: bool = LungeRules.is_aim_locked(_m._timer[i], float(row["charge_lock_time"]))
	if not locked and face != Vector2.ZERO:
		_m._aim[i] = face
	var lim: float = _m._half - _m._radius[i]
	var length: float = minf(float(row["charge_speed"]) * float(row["charge_time"]), BossRules.wall_distance(p, _m._aim[i], lim))
	if Tuning.FEATURE_OBSTACLE_STEER:
		length *= maxf(_block(p, p + _m._aim[i] * length, _m._radius[i]).x, 0.0)
	_m.boss_event.emit(&"charge_marker", {
		"on": true, "from": Vector3(p.x, 0.0, p.y), "dir": _m._aim[i], "length": length, "half_width": _m._radius[i], "locked": locked,
	})


## Hücum başlar (zincirin her hücumu): isabet kayıtları sıfırlanır, iz yeni hücuma hazırlanır.
func begin(i: int, row: Dictionary, mind: BossMind) -> ZombieRules.State:
	charges += 1
	mind.begin_charge()
	if _trail != null:
		_trail.begin()
	var at: Vector2 = _m._pos[i]
	_m.boss_event.emit(&"charge_marker", {"on": false})
	_m.boss_event.emit(&"charge_start", {"at": Vector3(at.x, 0.1, at.y)})
	_m._nodes[i].event.emit(&"charge_start", {})
	_m._enter(i, S.CHARGE, float(row["charge_time"]))
	return S.CHARGE


## CHARGE karesi: kilitli yönde koşar, yolundaki askere ve zombilere çarpar, duvara çarparsa sersemler. Dönüş: yeni konum.
func step(i: int, p: Vector2, delta: float, target: Vector2, row: Dictionary, mind: BossMind) -> Vector2:
	var lim: float = _m._half - _m._radius[i]
	var reach: Vector2 = p + _m._aim[i] * float(row["charge_speed"]) * delta
	var np: Vector2 = reach.clamp(Vector2(-lim, -lim), Vector2(lim, lim))
	var blocked: bool = false
	if Tuning.FEATURE_OBSTACLE_STEER:
		var hit: Vector3 = _block(p, np, _m._radius[i])
		if hit.x < 1.0:
			np = p.lerp(np, hit.x)
			blocked = true
	_hits(i, row, p, np, target, mind)
	_drop_trail(p, np)
	mind.dust_left -= delta
	if mind.dust_left <= 0.0:
		mind.dust_left = Tuning.BOSS_CHARGE_DUST_STEP
		_m.boss_event.emit(&"charge_dust", {"at": Vector3(np.x, 0.1, np.y)})
	if blocked or BossRules.hits_wall(reach, lim):
		stuns += 1
		mind.stun()
		_m._nodes[i].event.emit(&"stun", {})
		_m.boss_event.emit(&"stun", {"at": Vector3(np.x, 0.1, np.y)})
		_m._enter(i, S.STUN, float(row["charge_stun_time"]))
	return np


## Hücum süresi doldu (duvara çarpmadan): zincir sürüyorsa kısa yeniden nişan, yoksa toparlanma. Dönüş: girilen durum.
func finish(i: int, row: Dictionary, mind: BossMind) -> ZombieRules.State:
	if mind.finish_charge(row):
		_m._enter(i, S.WINDUP, float(row["charge_chain_windup"]))
		return S.WINDUP
	_m._enter(i, S.RECOVER, float(row["charge_recover"]))
	return S.RECOVER


## Hücum adımı a→b bir engele (bina, prop) çarpar mı: Vector3(oran 0..1, -, -); çarpmazsa oran 1.
func _block(a: Vector2, b: Vector2, radius: float) -> Vector3:
	var hit: Vector3 = CityLayout.first_hit(a, b, radius, _m._blocks)
	return Vector3(1.0 if hit.x < 0.0 else hit.x, hit.y, hit.z)


func _drop_trail(a: Vector2, b: Vector2) -> void:
	if _trail == null:
		return
	for point: Vector2 in _trail.points_along(a, b):
		var slot: int = _trail.add(point)
		_m.boss_event.emit(&"trail", {
			"slot": slot, "at": Vector3(point.x, 0.0, point.y), "radius": _trail.radius(), "life": _trail.life(), "fade": _trail.fade_time(),
		})


func _hits(i: int, row: Dictionary, a: Vector2, b: Vector2, target: Vector2, mind: BossMind) -> void:
	var radius: float = _m._radius[i]
	var dir: Vector2 = Steering.seek(a, b)
	if not mind.charge_hit_player and _m.player.is_exposed() and BossRules.sweep_capsule_hits(a, b, radius, target, Tuning.PLAYER_RADIUS):
		mind.charge_hit_player = true
		hits += 1
		_m.player.take_hit(float(row["charge_damage"]), dir)
		_m.player.shove(dir * Tuning.BOSS_CHARGE_PLAYER_KNOCK)
	for j in _m.query_circle(b, radius):
		var node: Zombie = _m._nodes[j]
		if j == i or mind.charge_hit_nodes.has(node):
			continue
		mind.charge_hit_nodes[node] = true
		var away: Vector2 = Steering.seek(b, _m._pos[j])
		_m.damage(j, float(row["charge_zombie_damage"]), away if away != Vector2.ZERO else dir.orthogonal(), Tuning.BOSS_CHARGE_ZOMBIE_KNOCK)
