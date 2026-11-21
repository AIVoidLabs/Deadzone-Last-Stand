class_name ScreamAttack
extends RefCounted
## Çığlıkçı (attack_kind scream; SpecialAttacks'ın parçası): hazırlıkta (WINDUP, scream_time) askere döner; sonunda ses dalgası
## yayar ve çevresindeki halkada yürüyen zombi doğurur (kota ve genel üst sınır ScreamRules'ta), ardından scream_cooldown (RECOVER)
## boyunca mesafe korur (ChaseSteer). Çağrılan zombinin çağırana bağı `_tag`'da: çağıranın kimliği (> 0) ya da -çağıran kimliği.
## Görüntüye EnemyManager.scream_emitted sinyali ve zombi `scream` olayı ile haber verilir.

const S = ZombieRules.State
const SUMMON_KIND: StringName = EnemyData.WALKER

var _m: EnemyManager
## Örnek başına: çağıran kimliği (> 0), çağrılan ise -çağıran kimliği, 0 = bağsız.
var _tag: PackedInt32Array = PackedInt32Array()
## Çağıran kimliği -> yaşayan çağrı sayısı.
var _alive: Dictionary = {}
var _next_id: int = 1


func _init(manager: EnemyManager) -> void:
	_m = manager


## Sıkıştırmada son örneğin bağı i'ye taşınır (EnemyCompactor'ın paralel dizi takası).
func swap_from_last(i: int, last: int) -> void:
	if i >= _tag.size():
		return
	_tag[i] = _tag[last] if last < _tag.size() else 0


func shrink(last: int) -> void:
	if last < _tag.size():
		_tag.resize(last)


## Zombi ölürken: çağrıysa çağıranın sayacı düşer; çağıransa kaydı silinir.
func on_removed(i: int) -> void:
	if i >= _tag.size() or _tag[i] == 0:
		return
	var tag: int = _tag[i]
	if tag < 0:
		if _alive.has(-tag):
			_alive[-tag] = maxi(0, int(_alive[-tag]) - 1)
	else:
		_alive.erase(tag)
	_tag[i] = 0


## Hazırlıkta (ve başlarken) asker yönüne döner.
func aim_tick(i: int, p: Vector2, target: Vector2) -> void:
	var dir: Vector2 = Steering.seek(p, target)
	if dir != Vector2.ZERO:
		_m._aim[i] = dir


## Hazırlık bitti: ses dalgası + çağrı. Dönüş: RECOVER (bekleme).
func end_windup(i: int, row: Dictionary) -> ZombieRules.State:
	var at: Vector2 = _m._pos[i]
	_m.screams += 1
	_m._nodes[i].event.emit(&"scream", {})
	_m.scream_emitted.emit(Vector3(at.x, 0.1, at.y), float(row["scream_radius"]))
	_summon(i, row, at)
	_m._enter(i, S.RECOVER, row["scream_cooldown"])
	return S.RECOVER


func _summon(i: int, row: Dictionary, at: Vector2) -> void:
	_ensure()
	if _tag[i] == 0:
		_tag[i] = _next_id
		_next_id += 1
	var id: int = _tag[i]
	var cap: int = Quality.max_enemies()
	if _m.spawn_cap > 0:
		cap = mini(cap, _m.spawn_cap)
	var count: int = ScreamRules.allowed_count(int(row["scream_count"]), int(_alive.get(id, 0)), int(row["scream_max_alive"]), _m.active_count(), cap)
	var half: float = _m._half - Tuning.SPAWN_EDGE_INSET
	for point: Vector2 in ScreamRules.ring_points(at, float(row["scream_radius"]), count, _m._rng.randf() * TAU, half):
		_m.spawn(SUMMON_KIND, point)
		_ensure()
		_tag[_m._nodes.size() - 1] = -id
		_alive[id] = int(_alive.get(id, 0)) + 1
		_m.summoned += 1


func _ensure() -> void:
	if _tag.size() < _m._pos.size():
		_tag.resize(_m._pos.size())
