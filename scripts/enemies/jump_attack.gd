class_name JumpAttack
extends RefCounted
## Zıplayanın iniş işareti ve inişi (SpecialAttacks'ın parçası; EnemyManager'ın dizilerini işler). Havadaki hareket
## SpecialAttacks.act'te, kurallar JumpRules'ta. Görüntüye zombi `marker` olayıyla, efektlere `jump_landed` sinyaliyle haber verilir.
## Seri zıplama (FEATURE_JUMPER_CHAIN): kalan ek zıplama sayısı örnek başına tutulur; inişten sonra kaldıysa kısa
## hazırlık (chain_pause, işaret yeniden görünür) ve yeni zıplama, bittiyse normal toparlanma.

const S = ZombieRules.State

var _m: EnemyManager
## Örnek başına: bu seride kalan ek zıplama sayısı.
var _hops: PackedByteArray = PackedByteArray()


func _init(manager: EnemyManager) -> void:
	_m = manager


## Sıkıştırmada son örneğin kalan zıplaması i'ye taşınır.
func swap_from_last(i: int, last: int) -> void:
	if i >= _hops.size():
		return
	_hops[i] = _hops[last] if last < _hops.size() else 0


func shrink(last: int) -> void:
	if last < _hops.size():
		_hops.resize(last)


func on_removed(i: int) -> void:
	if i < _hops.size():
		_hops[i] = 0


## Yeni zıplama hazırlığı başladı: seri uzunluğu seçilir (bayrak kapalıysa ek zıplama yok).
func begin_chain(i: int) -> void:
	if i >= _hops.size():
		_hops.resize(_m._pos.size())
	_hops[i] = JumpRules.extra_hops(randf(), Tuning.JUMPER_CHAIN_MIN, Tuning.JUMPER_CHAIN_MAX) if Tuning.FEATURE_JUMPER_CHAIN else 0


## Kalan ek zıplama var mı; varsa birini harcar.
func take_hop(i: int) -> bool:
	if i >= _hops.size() or _hops[i] == 0:
		return false
	_hops[i] -= 1
	return true


## İniş işaretini (yerdeki daire) açar/günceller (on) ya da kapatır.
func marker(i: int, dest: Vector2, row: Dictionary, on: bool) -> void:
	_m._nodes[i].event.emit(&"marker", {
		"on": on, "pos": Vector3(dest.x, 0.0, dest.y), "radius": row["land_radius"],
	})


## Sıçrama süresi doldu: işaretli yere iner, askerin altındaysa hasar verir. Dönüş: girilen durum
## (seri sürüyorsa kısa hazırlık WINDUP, yoksa toparlanma RECOVER).
func land(i: int, row: Dictionary, target: Vector2) -> ZombieRules.State:
	var dest: Vector2 = _m.free_point(_m._aim[i], float(row["radius"]))
	_m._pos[i] = dest
	_m._targetable[i] = 1
	_m._nodes[i].event.emit(&"marker", {"on": false})
	_m.jump_lands += 1
	if _m.player.is_exposed() and JumpRules.lands_on(target, dest, float(row["land_radius"]), Tuning.PLAYER_RADIUS):
		_m.jump_hits += 1
		_m.player.take_hit(_m._damage[i], target - dest)
	_m.jump_landed.emit(Vector3(dest.x, 0.1, dest.y), float(row["land_radius"]))
	if take_hop(i):
		_m._enter(i, S.WINDUP, float(row["chain_pause"]))
		return S.WINDUP
	_m._enter(i, S.RECOVER, row["attack_recover"])
	return S.RECOVER
