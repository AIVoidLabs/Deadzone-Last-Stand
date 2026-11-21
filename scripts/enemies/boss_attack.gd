class_name BossAttack
extends RefCounted
## Boss "Yığın" saldırı düzeni (SpecialAttacks'ın parçası; kurallar BossRules, halka ShockRing, durum BossMind).
## Akış: CHASE'de boss_pause dolunca saldırı seçilir -> WINDUP (yer dövme / hücum hazırlığı / çağrı) -> RECOVER;
## hücumda WINDUP -> CHARGE -> RECOVER (duvara çarparsa STUN -> CHASE). Öfke eşiğinde (bir kez) ROAR -> CHASE, sonra çarpanlar.
## Tek boss örneği vardır (indeks `_i`; sıkıştırmada swap_from_last izler). Görüntüye zombi `boss_attack` / `slam` /
## `charge_start` / `stun` / `summon` / `roar` / `rage` olaylarıyla, efektlere EnemyManager.boss_event sinyaliyle haber verilir.

const S = ZombieRules.State
const A = BossRules.Attack
const _WINDUP_KEYS: Dictionary = {A.SLAM: "slam_windup", A.CHARGE: "charge_windup", A.SUMMON: "summon_windup"}

## Sayaçlar (ölçüm ve debug için; ölümsüz modda da isabet sayılır).
var slams: int = 0
var ring_hits: int = 0
var center_hits: int = 0
var charges: int = 0
var charge_hits: int = 0
var stuns: int = 0
var summons: int = 0
var rage_count: int = 0

var _m: EnemyManager
var _i: int = -1
var _mind: BossMind
var _rings: Array[ShockRing] = []


func _init(manager: EnemyManager) -> void:
	_m = manager


## Yeni doğan boss (indeks i) kaydedilir; zaten canlı bir boss varsa ikincisi yalnız yürür.
func register(i: int, row: Dictionary) -> void:
	if _i >= 0:
		return
	_i = i
	_mind = BossMind.new(row)
	_rings.clear()


## Arayüz için durum: canlı mı, can, öfke (kükreme bekliyor ya da başladı) ve eşik oranı.
func status() -> Dictionary:
	if _i < 0:
		return {"alive": false}
	var row: Dictionary = _m._rows[_i]
	return {"alive": true, "hp": _m._hp[_i], "max_hp": float(row["max_hp"]), "raged": _mind.raged or _mind.rage_pending,
			"threshold": float(row["rage_threshold"])}


## Sıkıştırmada son örnek i'ye taşındı.
func swap_from_last(i: int, last: int) -> void:
	if _i == last:
		_i = i


## Boss ölürken ya da silinirken: halkalar ve işaret kapanır.
func on_removed(i: int) -> void:
	if i != _i:
		return
	_i = -1
	_rings.clear()
	_m.boss_event.emit(&"charge_marker", {"on": false})


## Her fizik karesi: bekleme süreleri, öfke eşiği, şok halkaları.
func tick(delta: float) -> void:
	if _i < 0:
		return
	var row: Dictionary = _m._rows[_i]
	_mind.summon_left = maxf(_mind.summon_left - delta, 0.0)
	if BossRules.should_rage(_m._hp[_i], float(row["max_hp"]), _mind.raged or _mind.rage_pending, row):
		_mind.rage_pending = true
	_tick_rings(delta, row)


## CHASE karesi: bekleme dolunca öfke kükremesi ya da seçilen saldırının hazırlığı başlar.
func try_start(i: int, p: Vector2, target: Vector2, dist: float, delta: float) -> void:
	if i != _i:
		return
	_mind.pause_left -= delta
	if _mind.pause_left > 0.0:
		return
	var row: Dictionary = _m._rows[i]
	if _mind.rage_pending:
		_roar(i, p, row)
		return
	var attack: A = BossRules.pick(dist, _mind.last, _mind.summon_left, row, _m._rng.randf())
	if attack == A.NONE:
		return
	_mind.attack = attack
	_mind.last = attack
	var face: Vector2 = Steering.seek(p, target)
	if face != Vector2.ZERO:
		_m._aim[i] = face
	if attack == A.SUMMON:
		_mind.summon_left = float(row["summon_cooldown"])
	_m._nodes[i].event.emit(&"boss_attack", {"kind": BossRules.attack_name(attack)})
	_m._enter(i, S.WINDUP, BossRules.windup(float(row[_WINDUP_KEYS[attack]]), _mind.raged, row))


## Hazırlıkta asker yönüne döner; hücumda son charge_lock_time sn yön kilitlidir ve yerde şerit işareti çizilir.
func windup_tick(i: int, p: Vector2, target: Vector2) -> void:
	if i != _i:
		return
	var face: Vector2 = Steering.seek(p, target)
	if _mind.attack != A.CHARGE:
		if face != Vector2.ZERO:
			_m._aim[i] = face
		return
	var row: Dictionary = _m._rows[i]
	var locked: bool = LungeRules.is_aim_locked(_m._timer[i], float(row["charge_lock_time"]))
	if not locked and face != Vector2.ZERO:
		_m._aim[i] = face
	var lim: float = _m._half - _m._radius[i]
	var length: float = minf(float(row["charge_speed"]) * float(row["charge_time"]), BossRules.wall_distance(p, _m._aim[i], lim))
	if Tuning.FEATURE_OBSTACLE_STEER:
		length *= maxf(_charge_block(p, p + _m._aim[i] * length, _m._radius[i]).x, 0.0)
	_m.boss_event.emit(&"charge_marker", {
		"on": true, "from": Vector3(p.x, 0.0, p.y), "dir": _m._aim[i], "length": length, "half_width": _m._radius[i], "locked": locked,
	})


## Hazırlık bitti: yer dövmesi iner / hücum başlar / çağrı doğar. Dönüş: girilen durum.
func end_windup(i: int, row: Dictionary) -> ZombieRules.State:
	if i != _i:
		_m._enter(i, S.RECOVER, 0.0)
		return S.RECOVER
	_mind.pause_left = float(row["boss_pause"])
	match _mind.attack:
		A.CHARGE:
			return _begin_charge(i, row)
		A.SLAM:
			_slam(i, row)
			_m._enter(i, S.RECOVER, float(row["slam_recover"]))
		_:
			_summon(i, row)
			_m._enter(i, S.RECOVER, float(row["summon_recover"]))
	return S.RECOVER


## CHARGE karesi: kilitli yönde koşar, yolundaki askere ve zombilere çarpar, duvara çarparsa sersemler. Dönüş: yeni konum.
func charge_step(i: int, p: Vector2, delta: float, target: Vector2) -> Vector2:
	if i != _i:
		return p
	var row: Dictionary = _m._rows[i]
	var lim: float = _m._half - _m._radius[i]
	var reach: Vector2 = p + _m._aim[i] * float(row["charge_speed"]) * delta
	var np: Vector2 = reach.clamp(Vector2(-lim, -lim), Vector2(lim, lim))
	var blocked: bool = false
	if Tuning.FEATURE_OBSTACLE_STEER:
		var hit: Vector3 = _charge_block(p, np, _m._radius[i])
		if hit.x < 1.0:
			np = p.lerp(np, hit.x)
			blocked = true
	_charge_hits(i, row, p, np, target)
	_mind.dust_left -= delta
	if _mind.dust_left <= 0.0:
		_mind.dust_left = Tuning.BOSS_CHARGE_DUST_STEP
		_m.boss_event.emit(&"charge_dust", {"at": Vector3(np.x, 0.1, np.y)})
	if blocked or BossRules.hits_wall(reach, lim):
		stuns += 1
		_m._nodes[i].event.emit(&"stun", {})
		_m.boss_event.emit(&"stun", {"at": Vector3(np.x, 0.1, np.y)})
		_m._enter(i, S.STUN, float(row["charge_stun_time"]))
	return np


## Hücum / sersem / kükreme süresi doldu. Dönüş: girilen durum.
func finish(i: int, state: ZombieRules.State) -> ZombieRules.State:
	var row: Dictionary = _m._rows[i]
	if i == _i:
		_mind.pause_left = float(row["boss_pause"])
	if state == S.CHARGE:
		_m._enter(i, S.RECOVER, float(row["charge_recover"]))
		return S.RECOVER
	if state == S.ROAR:
		_m._speed[i] = BossRules.rage_speed(_m._speed[i], row)
	_m._enter(i, S.CHASE, 0.0)
	return S.CHASE


## Hücum adımı a→b bir engele (bina, prop) çarpar mı: Vector3(oran 0..1, -, -); çarpmazsa oran 1.
func _charge_block(a: Vector2, b: Vector2, radius: float) -> Vector3:
	var hit: Vector3 = CityLayout.first_hit(a, b, radius, _m._blocks)
	return Vector3(1.0 if hit.x < 0.0 else hit.x, hit.y, hit.z)


func _begin_charge(i: int, row: Dictionary) -> ZombieRules.State:
	charges += 1
	_mind.charge_hit_player = false
	_mind.charge_hit_nodes.clear()
	_mind.dust_left = 0.0
	var at: Vector2 = _m._pos[i]
	_m.boss_event.emit(&"charge_marker", {"on": false})
	_m.boss_event.emit(&"charge_start", {"at": Vector3(at.x, 0.1, at.y)})
	_m._nodes[i].event.emit(&"charge_start", {})
	_m._enter(i, S.CHARGE, float(row["charge_time"]))
	return S.CHARGE


## Yer dövmesi indi: merkez hasarı, ilk şok halkası; öfkede ikinci halka tick'te gelir.
func _slam(i: int, row: Dictionary) -> void:
	slams += 1
	var at: Vector2 = _m._pos[i]
	var target: Vector2 = _m.player.position_2d()
	_m._nodes[i].event.emit(&"slam", {})
	if _m.player.is_exposed() and BossRules.center_hit(at.distance_to(target), row):
		center_hits += 1
		_m.player.take_hit(float(row["slam_center_damage"]), target - at)
	_add_ring(at, row, 0)
	_mind.rings_left = BossRules.ring_count(_mind.raged) - 1
	_mind.ring_gap_left = float(row["slam_ring_gap"])


func _add_ring(at: Vector2, row: Dictionary, index: int) -> void:
	_rings.append(ShockRing.new(at, float(row["slam_ring_speed"]), float(row["slam_ring_max"]), float(row["slam_ring_width"])))
	_m.boss_event.emit(&"slam", {
		"at": Vector3(at.x, 0.1, at.y), "index": index, "speed": row["slam_ring_speed"], "max": row["slam_ring_max"], "width": row["slam_ring_width"],
	})


func _tick_rings(delta: float, row: Dictionary) -> void:
	var target: Vector2 = _m.player.position_2d()
	var exposed: bool = _m.player.is_exposed()
	var k: int = _rings.size() - 1
	while k >= 0:
		var ring: ShockRing = _rings[k]
		if ring.step(delta, target, Tuning.PLAYER_RADIUS, exposed):
			ring_hits += 1
			_m.player.take_hit(float(row["slam_damage"]), target - ring.origin)
			exposed = _m.player.is_exposed()
		if ring.is_done():
			_rings.remove_at(k)
		k -= 1
	if _mind.rings_left > 0:
		_mind.ring_gap_left -= delta
		if _mind.ring_gap_left <= 0.0:
			_mind.rings_left -= 1
			_add_ring(_m._pos[_i], row, 1)


func _charge_hits(i: int, row: Dictionary, a: Vector2, b: Vector2, target: Vector2) -> void:
	var radius: float = _m._radius[i]
	var dir: Vector2 = Steering.seek(a, b)
	if not _mind.charge_hit_player and _m.player.is_exposed() and BossRules.sweep_capsule_hits(a, b, radius, target, Tuning.PLAYER_RADIUS):
		_mind.charge_hit_player = true
		charge_hits += 1
		_m.player.take_hit(float(row["charge_damage"]), dir)
		_m.player.shove(dir * Tuning.BOSS_CHARGE_PLAYER_KNOCK)
	for j in _m.query_circle(b, radius):
		var node: Zombie = _m._nodes[j]
		if j == i or _mind.charge_hit_nodes.has(node):
			continue
		_mind.charge_hit_nodes[node] = true
		var away: Vector2 = Steering.seek(b, _m._pos[j])
		_m.damage(j, float(row["charge_zombie_damage"]), away if away != Vector2.ZERO else dir.orthogonal(), Tuning.BOSS_CHARGE_ZOMBIE_KNOCK)


## Öfke kükremesi: ses dalgası halkası + sarsıntı (BossFx), göğüs parıltısı artar (zombi `rage` olayı).
func _roar(i: int, p: Vector2, row: Dictionary) -> void:
	_mind.rage_pending = false
	_mind.raged = true
	rage_count += 1
	_m._nodes[i].event.emit(&"rage", {})
	_m._nodes[i].event.emit(&"roar", {})
	_m.boss_event.emit(&"roar", {"at": Vector3(p.x, 0.1, p.y), "radius": row["roar_radius"]})
	_m._enter(i, S.ROAR, float(row["rage_roar"]))


## Çağrı: çevresindeki halkada summon_kind doğar (kota genel üst sınıra uyar; ScreamRules'taki kural).
func _summon(i: int, row: Dictionary) -> void:
	summons += 1
	var at: Vector2 = _m._pos[i]
	_m._nodes[i].event.emit(&"summon", {})
	_m.boss_event.emit(&"summon", {"at": Vector3(at.x, 0.1, at.y)})
	var cap: int = Quality.max_enemies()
	if _m.spawn_cap > 0:
		cap = mini(cap, _m.spawn_cap)
	var want: int = int(row["summon_count"])
	var count: int = ScreamRules.allowed_count(want, 0, want, _m.active_count(), cap)
	var radius: float = _m._radius[i] + float(row["summon_ring_gap"])
	var half: float = _m._half - Tuning.SPAWN_EDGE_INSET
	for point: Vector2 in ScreamRules.ring_points(at, radius, count, _m._rng.randf() * TAU, half):
		_m.spawn(row["summon_kind"], point)
