class_name EnemyBurn
extends RefCounted
## EnemyManager'ın yanma işi: yanan zombiye süreli hasar. Diziler (_burn_*) manager'da kalır, bu sınıf işler.

var _m: EnemyManager


func _init(manager: EnemyManager) -> void:
	_m = manager


## Zombiyi yakar: duration sn boyunca saniyede dps hasar. Yanan zombi tekrar yakılırsa süre yenilenir, hasar yükselir.
func ignite(index: int, dps: float, duration: float) -> void:
	if not Tuning.FEATURE_BURN or _m._alive[index] == 0 or dps <= 0.0 or duration <= 0.0:
		return
	if _m._burn_left[index] <= 0.0:
		_m._burning += 1
		_m._burn_acc[index] = 0.0
		_m._nodes[index].notify_burn(true)
	_m._burn_left[index] = maxf(_m._burn_left[index], duration)
	_m._burn_dps[index] = maxf(_m._burn_dps[index], dps)


func tick(delta: float) -> void:
	for i in _m._pos.size():
		if _m._burn_left[i] <= 0.0 or _m._alive[i] == 0:
			continue
		var step: Dictionary = MeleeRules.burn_step(_m._burn_left[i], _m._burn_acc[i], delta, Tuning.BURN_TICK_INTERVAL)
		_m._burn_left[i] = step["left"]
		_m._burn_acc[i] = step["acc"]
		for _t in int(step["ticks"]):
			_m.damage(i, _m._burn_dps[i] * Tuning.BURN_TICK_INTERVAL, Vector2.from_angle(_m._rng.randf() * TAU), 0.0, true)
			if _m._alive[i] == 0:
				break
		if _m._alive[i] != 0 and _m._burn_left[i] <= 0.0:
			extinguish(i)


func extinguish(index: int) -> void:
	_m._burn_left[index] = 0.0
	_m._burn_dps[index] = 0.0
	_m._burning = maxi(0, _m._burning - 1)
	_m._nodes[index].notify_burn(false)
