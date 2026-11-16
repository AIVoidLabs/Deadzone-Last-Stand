class_name CorpseList
extends RefCounted
## Ölmekte olan zombiler: oyun dizilerinden çıkmıştır (hedef alınmaz, çarpışmaz), yalnız ölüm
## animasyonu ve solma süresince sahnede kalır. Süre dolunca düğüm havuza geri verilir.

var _nodes: Array[Zombie] = []
var _left: PackedFloat32Array = PackedFloat32Array()
var _velocity: PackedVector2Array = PackedVector2Array()


func count() -> int:
	return _nodes.size()


## velocity: vuruşun verdiği itme; ceset bu yönde kayıp durur.
func add(node: Zombie, velocity: Vector2, duration: float) -> void:
	_nodes.append(node)
	_left.append(duration)
	_velocity.append(velocity)


## Kayanları ilerletir; süresi dolanları listeden çıkarıp döndürür.
func tick(delta: float) -> Array[Zombie]:
	var finished: Array[Zombie] = []
	var i: int = _nodes.size() - 1
	while i >= 0:
		_left[i] -= delta
		var velocity: Vector2 = _velocity[i]
		if velocity != Vector2.ZERO:
			_nodes[i].position += Vector3(velocity.x, 0.0, velocity.y) * delta
			_velocity[i] = Knockback.decay(velocity, Tuning.KNOCKBACK_DAMPING, delta)
		if _left[i] <= 0.0:
			finished.append(_nodes[i])
			var last: int = _nodes.size() - 1
			_nodes[i] = _nodes[last]
			_left[i] = _left[last]
			_velocity[i] = _velocity[last]
			_nodes.resize(last)
			_left.resize(last)
			_velocity.resize(last)
		i -= 1
	return finished
