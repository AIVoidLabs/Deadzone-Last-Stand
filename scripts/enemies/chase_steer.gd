class_name ChaseSteer
extends RefCounted
## Kovalarken düz "askere doğru" olmayan türlerin yönelimi (EnemyManager._move'un parçası). Satırdaki `steer` alanı türü seçer:
## &"armor" (zırhlı: armor_turn_rate ile yavaş döner, bakış yönünde yürür). Bakış yönü `_aim`'de tutulur.
## Dönüş: hareket vektörü (uzunluk 0..1 × hız) ve bakış yönü.

var _m: EnemyManager


func _init(manager: EnemyManager) -> void:
	_m = manager


## Bu türün yönelimi açık mı (bayrak kapalıysa yürüyen gibi doğrudan askere).
static func active(row: Dictionary) -> bool:
	match row.get("steer", &""):
		&"armor":
			return Tuning.FEATURE_ZOMBIE_ARMOR
	return false


## Bu karede hareket yönü (CHASE).
func heading(i: int, row: Dictionary, dir: Vector2, delta: float) -> Vector2:
	if row["steer"] == &"armor":
		var aim: Vector2 = LungeRules.steer(_m._aim[i], dir, float(row["armor_turn_rate"]) * delta)
		_m._aim[i] = aim
		return aim
	return dir


## Bakış yönü (CHASE).
func facing(i: int) -> Vector2:
	return _m._aim[i]
