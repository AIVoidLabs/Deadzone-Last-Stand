class_name ChaseSteer
extends RefCounted
## Kovalarken düz "askere doğru" olmayan türlerin yönelimi (EnemyManager._move'un parçası). Satırdaki `steer` alanı türü seçer:
## &"armor" (zırhlı: armor_turn_rate ile yavaş döner, bakış yönünde yürür), &"scream" (çığlıkçı: ScreamRules mesafe davranışı;
## bekleme sırasında da yürür). Bakış yönü `_aim`'de tutulur. Hareket vektörü: uzunluk 0..1 × hız.

var _m: EnemyManager


func _init(manager: EnemyManager) -> void:
	_m = manager


## Bu türün yönelimi açık mı (bayrak kapalıysa yürüyen gibi doğrudan askere).
static func active(row: Dictionary) -> bool:
	match row.get("steer", &""):
		&"armor":
			return Tuning.FEATURE_ZOMBIE_ARMOR
		&"scream":
			return Tuning.FEATURE_ZOMBIE_SCREAM
	return false


## Toparlanma (bekleme) sırasında da yürür mü (çığlıkçı mesafe korur).
static func walks_recovering(row: Dictionary) -> bool:
	return row.get("steer", &"") == &"scream" and Tuning.FEATURE_ZOMBIE_SCREAM


## Bu karede hareket vektörü; bakış yönü _aim'e yazılır.
func heading(i: int, row: Dictionary, p: Vector2, target: Vector2, dir: Vector2, delta: float) -> Vector2:
	if row["steer"] == &"armor":
		var aim: Vector2 = LungeRules.steer(_m._aim[i], dir, float(row["armor_turn_rate"]) * delta)
		_m._aim[i] = aim
		return aim
	var move: Vector2 = ScreamRules.move_vector(p.distance_to(target), float(row["scream_range"]), float(row["scream_keep_min"]), dir)
	# Kaçarken yüz kaçış yönünde, aksi halde askerde.
	_m._aim[i] = move if move != Vector2.ZERO and move.dot(dir) < 0.0 else dir
	return move


## Bakış yönü.
func facing(i: int) -> Vector2:
	return _m._aim[i]
