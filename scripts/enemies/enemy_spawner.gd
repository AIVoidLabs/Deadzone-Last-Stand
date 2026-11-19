class_name EnemySpawner
extends RefCounted
## EnemyManager'a yeni zombi ekler (paralel dizilere satır + havuzdan düğüm) ve doğma noktası seçer.

var _m: EnemyManager


func _init(manager: EnemyManager) -> void:
	_m = manager


func spawn(kind: StringName, at: Vector2) -> void:
	var row: Dictionary = EnemyData.get_row(kind)
	var z: Zombie = _m._pool.take(kind)
	z.configure(row)
	var r: float = row["radius"]
	_m._max_radius = maxf(_m._max_radius, r)
	_m._pos.append(at)
	_m._hp.append(row["max_hp"])
	_m._speed.append(row["speed"])
	_m._damage.append(row["contact_damage"])
	_m._radius.append(r)
	_m._alive.append(1)
	_m._targetable.append(1)
	_m._state.append(ZombieRules.State.INACTIVE)
	_m._timer.append(0.0)
	_m._rows.append(row)
	_m._knock.append(Vector2.ZERO)
	_m._aim.append(Vector2.DOWN)
	_m._burn_left.append(0.0)
	_m._burn_dps.append(0.0)
	_m._burn_acc.append(0.0)
	_m._nodes.append(z)
	z.activate(Vector3(at.x, 0.0, at.y))
	var index: int = _m._nodes.size() - 1
	z.rotation.y = _yaw_towards(at, _m.player.position_2d())
	if Tuning.FEATURE_ZOMBIE_SPAWN_RISE:
		_m._enter(index, ZombieRules.State.SPAWN, row["spawn_time"])
	else:
		_m._enter(index, ZombieRules.State.CHASE, 0.0)


## Ekranın hemen dışında (FEATURE_SPAWN_OFFSCREEN) ya da arena kenarında, askerden uzak bir nokta.
func pick_spawn_point() -> Vector2:
	var half: float = _m._half - Tuning.SPAWN_EDGE_INSET
	var from: Vector2 = _m.player.position_2d()
	if not Tuning.FEATURE_SPAWN_OFFSCREEN:
		return SpawnRules.pick_edge_point(_m._rng, half, from, Tuning.SPAWN_MIN_PLAYER_DIST, Tuning.SPAWN_TRIES)
	var size: Vector2 = _m.get_viewport().get_visible_rect().size
	var view: Rect2 = SpawnRules.ground_view_rect(Tuning.CAMERA_PITCH_DEG, Tuning.CAMERA_DISTANCE, Tuning.CAMERA_FOV, size.x / maxf(size.y, 1.0), Tuning.SPAWN_VIEW_MIN_RAY_DEG)
	return SpawnRules.pick_offscreen_point(_m._rng, half, from, view, Tuning.SPAWN_OFFSCREEN_MARGIN, Tuning.SPAWN_TRIES)


static func _yaw_towards(from: Vector2, to: Vector2) -> float:
	var dir: Vector2 = Steering.seek(from, to)
	return atan2(dir.x, dir.y)
