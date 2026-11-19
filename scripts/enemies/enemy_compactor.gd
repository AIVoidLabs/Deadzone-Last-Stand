class_name EnemyCompactor
extends RefCounted
## Ölenleri EnemyManager'ın paralel dizilerinden sondan takasla çıkarır (yeni karenin başında çağrılır).

var _m: EnemyManager


func _init(manager: EnemyManager) -> void:
	_m = manager


## Sondan başa gidildiği için takaslanan hep canlıdır.
func run() -> void:
	if _m._dead_count == 0:
		return
	var i: int = _m._nodes.size() - 1
	while i >= 0:
		if _m._alive[i] == 0:
			var last: int = _m._nodes.size() - 1
			# Ölüm animasyonundaki düğüm CorpseList'te; havuza oradan döner.
			if _m._nodes[i].state == ZombieRules.State.INACTIVE:
				_m._pool.give(_m._nodes[i])
			if i != last:
				_swap_from_last(i, last)
			_shrink(last)
		i -= 1
	_m._dead_count = 0


func _swap_from_last(i: int, last: int) -> void:
	_m._pos[i] = _m._pos[last]
	_m._hp[i] = _m._hp[last]
	_m._speed[i] = _m._speed[last]
	_m._damage[i] = _m._damage[last]
	_m._radius[i] = _m._radius[last]
	_m._alive[i] = _m._alive[last]
	_m._targetable[i] = _m._targetable[last]
	_m._state[i] = _m._state[last]
	_m._timer[i] = _m._timer[last]
	_m._rows[i] = _m._rows[last]
	_m._knock[i] = _m._knock[last]
	_m._aim[i] = _m._aim[last]
	_m._burn_left[i] = _m._burn_left[last]
	_m._burn_dps[i] = _m._burn_dps[last]
	_m._burn_acc[i] = _m._burn_acc[last]
	_m._nodes[i] = _m._nodes[last]


func _shrink(last: int) -> void:
	_m._pos.resize(last)
	_m._hp.resize(last)
	_m._speed.resize(last)
	_m._damage.resize(last)
	_m._radius.resize(last)
	_m._alive.resize(last)
	_m._targetable.resize(last)
	_m._state.resize(last)
	_m._timer.resize(last)
	_m._rows.resize(last)
	_m._knock.resize(last)
	_m._aim.resize(last)
	_m._burn_left.resize(last)
	_m._burn_dps.resize(last)
	_m._burn_acc.resize(last)
	_m._nodes.resize(last)
