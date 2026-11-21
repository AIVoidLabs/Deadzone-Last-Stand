class_name JumpAttack
extends RefCounted
## Zıplayanın iniş işareti ve inişi (SpecialAttacks'ın parçası; EnemyManager'ın dizilerini işler). Havadaki hareket
## SpecialAttacks.act'te, kurallar JumpRules'ta. Görüntüye zombi `marker` olayıyla, efektlere `jump_landed` sinyaliyle haber verilir.

var _m: EnemyManager


func _init(manager: EnemyManager) -> void:
	_m = manager


## İniş işaretini (yerdeki daire) açar/günceller (on) ya da kapatır.
func marker(i: int, dest: Vector2, row: Dictionary, on: bool) -> void:
	_m._nodes[i].event.emit(&"marker", {
		"on": on, "pos": Vector3(dest.x, 0.0, dest.y), "radius": row["land_radius"],
	})


## Sıçrama süresi doldu: işaretli yere iner, askerin altındaysa hasar verir.
func land(i: int, row: Dictionary, target: Vector2) -> void:
	var dest: Vector2 = _m._aim[i]
	_m._pos[i] = dest
	_m._targetable[i] = 1
	_m._nodes[i].event.emit(&"marker", {"on": false})
	_m.jump_lands += 1
	if _m.player.is_exposed() and JumpRules.lands_on(target, dest, float(row["land_radius"]), Tuning.PLAYER_RADIUS):
		_m.jump_hits += 1
		_m.player.take_hit(_m._damage[i], target - dest)
	_m.jump_landed.emit(Vector3(dest.x, 0.1, dest.y), float(row["land_radius"]))
