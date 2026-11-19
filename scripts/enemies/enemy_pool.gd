class_name EnemyPool
extends RefCounted
## Zombie düğüm havuzu: tür -> boştaki düğümler (her düğümün modeli türüne göre sabit). Düğümler host'un çocuğudur.

var _host: Node3D
var _idle: Dictionary = {}


func _init(host: Node3D) -> void:
	_host = host


func grow(kind: StringName, count: int) -> void:
	for _i in count:
		give(_create(kind))


func take(kind: StringName) -> Zombie:
	var pool: Array = _idle.get(kind, [])
	return pool.pop_back() if not pool.is_empty() else _create(kind)


func give(node: Zombie) -> void:
	if not _idle.has(node.kind):
		_idle[node.kind] = []
	(_idle[node.kind] as Array).append(node)


func idle_count() -> int:
	var idle: int = 0
	for kind: StringName in _idle:
		idle += (_idle[kind] as Array).size()
	return idle


func _create(kind: StringName) -> Zombie:
	var z: Zombie = Zombie.new(kind)
	_host.add_child(z)
	return z
