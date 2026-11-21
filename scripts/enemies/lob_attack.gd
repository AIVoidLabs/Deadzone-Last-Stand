class_name LobAttack
extends RefCounted
## Yay atışı saldırıları (SpecialAttacks'ın parçası): tükürücünün asit topu (attack_kind spit) ve taş fırlatanın kayası
## (attack_kind throw; yakındaysa dev kolla yakın vuruş = swat). Kurallar LobRules'ta. Satır alanları ön ek + son ek:
## <spit|throw>_range / _lock / _lead / _flight / _arc. WINDUP'ta hedef noktası _aim'de (kilide dek askerin önünde),
## WINDUP sonunda bırakış: uçan top/kaya ve asit havuzları burada yürür (zombi ölse de sürer).
## Görüntüye EnemyManager sinyalleri (lob_launched, lob_landed, acid_pool_started) ve zombi `lob` / `swat` / `melee`
## olaylarıyla haber verilir.

const S = ZombieRules.State

var _m: EnemyManager
## Örnek başına: bu taş fırlatan hazırlığı yakın vuruş (1) mu, atış (0) mı.
var _melee: PackedByteArray = PackedByteArray()
## Uçan toplar ve kayalar: başlangıç, iniş noktası, kalan süre, satır.
var _lob_from: PackedVector2Array = PackedVector2Array()
var _lob_dest: PackedVector2Array = PackedVector2Array()
var _lob_left: PackedFloat32Array = PackedFloat32Array()
var _lob_row: Array[Dictionary] = []
## Asit havuzları: merkez, kalan süre, tik birikimi, satır.
var _pool_pos: PackedVector2Array = PackedVector2Array()
var _pool_left: PackedFloat32Array = PackedFloat32Array()
var _pool_acc: PackedFloat32Array = PackedFloat32Array()
var _pool_row: Array[Dictionary] = []


func _init(manager: EnemyManager) -> void:
	_m = manager


## Sıkıştırmada son örneğin yakın vuruş bayrağı i'ye taşınır (EnemyCompactor'ın paralel dizi takası).
func swap_from_last(i: int, last: int) -> void:
	if i >= _melee.size():
		return
	_melee[i] = _melee[last] if last < _melee.size() else 0


func shrink(last: int) -> void:
	if last < _melee.size():
		_melee.resize(last)


func on_removed(i: int) -> void:
	if i < _melee.size():
		_melee[i] = 0


## Hazırlık süresi (sn). Taş fırlatan temasa yakınsa yakın vuruşa karar verir (bayrak açıkken), değilse satırdaki attack_windup.
func windup_time(i: int, row: Dictionary, dist: float, contact: float) -> float:
	if i >= _melee.size():
		_melee.resize(_m._pos.size())
	_melee[i] = 0
	if row["attack_kind"] == &"throw" and Tuning.FEATURE_THROW_MELEE and LobRules.wants_swat(dist, contact, float(row["throw_melee_range"])):
		_melee[i] = 1
		return row["throw_melee_windup"]
	return row["attack_windup"]


## Hazırlık başladı: ilk nişan; yakın vuruşsa görüntüye swat klibi için haber.
func begin_windup(i: int, row: Dictionary, p: Vector2, target: Vector2, target_vel: Vector2) -> void:
	aim_tick(i, row, p, target, target_vel)
	if _is_melee(i):
		_m._nodes[i].event.emit(&"swat", {})


## Hazırlıkta nişan: kilit süresine kadar askerin önüne bakar (yakın vuruşta doğrudan askere).
func aim_tick(i: int, row: Dictionary, p: Vector2, target: Vector2, target_vel: Vector2) -> void:
	if _is_melee(i):
		_m._aim[i] = target
		return
	if LungeRules.is_aim_locked(_m._timer[i], _f(row, "lock")):
		return
	var reach: float = _f(row, "range") + Tuning.PLAYER_RADIUS + _m._radius[i]
	_m._aim[i] = LobRules.target_point(p, target, target_vel, _f(row, "lead"), reach, _m._half)


## Hazırlık bitti: yakın vuruş ya da bırakış. Dönüş: girilen durum (RECOVER).
func end_windup(i: int, row: Dictionary, target: Vector2) -> ZombieRules.State:
	if _is_melee(i):
		_swat(i, row, target)
	else:
		_launch(i, row)
		_m._enter(i, S.RECOVER, row["attack_recover"])
	return S.RECOVER


## Her fizik karesi: uçanlar ilerler/iner, havuzlar askere tik vurur.
func tick(delta: float) -> void:
	if _lob_left.is_empty() and _pool_left.is_empty():
		return
	var target: Vector2 = _m.player.position_2d()
	var k: int = _lob_left.size() - 1
	while k >= 0:
		_lob_left[k] -= delta
		if _lob_left[k] <= 0.0:
			_land(k, target)
			_remove_lob(k)
		k -= 1
	k = _pool_left.size() - 1
	while k >= 0:
		_pool_left[k] -= delta
		if _pool_left[k] <= 0.0:
			_remove_pool(k)
		else:
			_pool_tick(k, delta, target)
		k -= 1


## Dibindeki / yakın asker: yürüyenin vuruşu gibi hasar (temas + throw_melee_hit_range içindeyse), kısa toparlanma.
func _swat(i: int, row: Dictionary, target: Vector2) -> void:
	_melee[i] = 0
	_m.throw_melees += 1
	var p: Vector2 = _m._pos[i]
	var contact: float = Tuning.PLAYER_RADIUS + _m._radius[i]
	if _m.player.is_exposed() and ZombieRules.strike_hits(p.distance_to(target), contact, float(row["throw_melee_hit_range"])):
		_m.player.take_hit(_m._damage[i], target - p)
	_m._enter(i, S.RECOVER, row["throw_melee_recover"])
	_m._nodes[i].event.emit(&"melee", {})


## Bırakış: top/kaya iniş noktasına (kilitli _aim) uçar.
func _launch(i: int, row: Dictionary) -> void:
	var kind: StringName = row["attack_kind"]
	var from: Vector2 = _m._pos[i]
	var dest: Vector2 = _m._aim[i]
	var flight: float = _f(row, "flight")
	if Tuning.FEATURE_OBSTACLE_STEER and Tuning.FEATURE_CITY_GREYBOX:
		# Bina ya da engel araya girerse top/kaya engelin kenarına iner (kısalan yolla orantılı süre).
		var shot: Vector3 = CityLayout.clip_shot(from, dest, Tuning.OBSTACLE_SHOT_RADIUS, Tuning.OBSTACLE_SHOT_MARGIN, _m._blocks)
		dest = Vector2(shot.x, shot.y)
		flight *= maxf(shot.z, 0.25)
	_lob_from.append(from)
	_lob_dest.append(dest)
	_lob_left.append(flight)
	_lob_row.append(row)
	var radius: float = float(row["acid_radius"]) if kind == &"spit" else float(row["throw_radius"])
	if kind == &"spit":
		_m.spit_shots += 1
	else:
		_m.throw_shots += 1
	var origin: Vector3 = Vector3(from.x, Tuning.LOB_RELEASE_HEIGHT, from.y)
	if kind == &"spit" and row.has("spit_mouth"):
		origin = _m._nodes[i].mouth_position()
	_m.lob_launched.emit(kind, origin, Vector3(dest.x, 0.0, dest.y), flight, _f(row, "arc"), radius)
	_m._nodes[i].event.emit(&"lob", {"kind": kind})


## İniş: kaya askeri kapsıyorsa vurur; asit topu havuz bırakır.
func _land(k: int, target: Vector2) -> void:
	var row: Dictionary = _lob_row[k]
	var dest: Vector2 = _lob_dest[k]
	var at: Vector3 = Vector3(dest.x, 0.1, dest.y)
	if row["attack_kind"] == &"spit":
		_m.lob_landed.emit(&"spit", at, float(row["acid_radius"]))
		_add_pool(dest, row)
		return
	var radius: float = row["throw_radius"]
	_m.lob_landed.emit(&"throw", at, radius)
	if _m.player.is_exposed() and LobRules.hits(target, dest, radius, Tuning.PLAYER_RADIUS):
		_m.throw_hits += 1
		_m.player.take_hit(float(row["contact_damage"]), target - dest)


func _add_pool(at: Vector2, row: Dictionary) -> void:
	if _pool_left.size() >= Tuning.ACID_POOL_MAX:
		_remove_pool(0)
	_pool_pos.append(at)
	_pool_left.append(row["acid_time"])
	_pool_acc.append(0.0)
	_pool_row.append(row)
	_m.spit_pools += 1
	_m.acid_pool_started.emit(Vector3(at.x, 0.0, at.y), row["acid_radius"], row["acid_time"])


## Havuzun içindeki (açıktaki) askere her acid_tick sn'de acid_damage: dokunulmazlık vermez, vurulma animasyonu yok.
func _pool_tick(k: int, delta: float, target: Vector2) -> void:
	var row: Dictionary = _pool_row[k]
	if not _m.player.is_exposed() or not LobRules.in_pool(target, _pool_pos[k], float(row["acid_radius"])):
		return
	var step: Vector2 = LobRules.advance_tick(_pool_acc[k], delta, float(row["acid_tick"]))
	_pool_acc[k] = step.x
	for _t in int(step.y):
		_m.spit_ticks += 1
		_m.player.take_dot(float(row["acid_damage"]))


func _remove_lob(k: int) -> void:
	_lob_from.remove_at(k)
	_lob_dest.remove_at(k)
	_lob_left.remove_at(k)
	_lob_row.remove_at(k)


func _remove_pool(k: int) -> void:
	_pool_pos.remove_at(k)
	_pool_left.remove_at(k)
	_pool_acc.remove_at(k)
	_pool_row.remove_at(k)


func _is_melee(i: int) -> bool:
	return i < _melee.size() and _melee[i] == 1


## Satırdaki <ön ek>_<son ek> alanı (ön ek = saldırı türü: spit / throw).
static func _f(row: Dictionary, suffix: String) -> float:
	return float(row["%s_%s" % [row["attack_kind"], suffix]])
