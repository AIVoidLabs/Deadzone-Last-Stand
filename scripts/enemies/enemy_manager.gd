class_name EnemyManager
extends Node3D
## Tüm zombileri tek döngüde yürütür. Durum paralel dizilerde (veri odaklı);
## Zombie düğümleri havuzdan gelir ve yalnız konum + görüntü taşır.
## Ölenler kare içinde işaretlenir, bir sonraki karenin başında diziden çıkarılır
## (böylece aynı kare içinde indeksler kaymaz).

signal enemy_killed(at: Vector3)

const PHYSICS_PRIORITY: int = -10
const HIT_QUERY_MARGIN: float = 1.0

var player: Player
var spawning_enabled: bool = true
var elapsed: float = 0.0
var kills: int = 0

var _grid: SpatialGrid
var _half: float
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _spawn_timer: float = 0.0
var _max_radius: float = 0.0

var _pos: PackedVector2Array = PackedVector2Array()
var _hp: PackedFloat32Array = PackedFloat32Array()
var _speed: PackedFloat32Array = PackedFloat32Array()
var _damage: PackedFloat32Array = PackedFloat32Array()
var _radius: PackedFloat32Array = PackedFloat32Array()
var _alive: PackedByteArray = PackedByteArray()
var _state: PackedByteArray = PackedByteArray()
## Süreli durumda kalan süre (sn).
var _timer: PackedFloat32Array = PackedFloat32Array()
var _rows: Array[Dictionary] = []
var _nodes: Array[Zombie] = []
var _pool: Array[Zombie] = []
var _dead_count: int = 0


func _ready() -> void:
	name = "Enemies"
	process_physics_priority = PHYSICS_PRIORITY
	_half = Tuning.ARENA_SIZE * 0.5
	_grid = SpatialGrid.new(Vector2(-_half, -_half), Vector2(Tuning.ARENA_SIZE, Tuning.ARENA_SIZE), Tuning.GRID_CELL_SIZE)
	_rng.randomize()
	_spawn_timer = SpawnRules.interval_at(0.0)
	_grow_pool(Quality.max_enemies())


func _physics_process(delta: float) -> void:
	_compact()
	elapsed += delta
	_tick_spawning(delta)
	_grid.rebuild(_pos)
	_move(delta)


func active_count() -> int:
	return _nodes.size() - _dead_count


func pool_size() -> int:
	return _nodes.size() + _pool.size()


func enemy_position(index: int) -> Vector2:
	return _pos[index]


## Menzildeki en yakın canlı zombi; yoksa -1.
func nearest_enemy(from: Vector2, max_range: float) -> int:
	return _grid.nearest(from, max_range, _pos, _alive)


## a→b yolunda ilk değilen canlı zombi; yoksa -1.
func find_segment_hit(a: Vector2, b: Vector2, radius: float) -> int:
	var margin: float = radius + _max_radius + HIT_QUERY_MARGIN
	var lo: Vector2 = Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(margin, margin)
	var hi: Vector2 = Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2(margin, margin)
	var best: int = -1
	var best_t: float = 2.0
	for i in _grid.query_rect(lo, hi):
		if i >= _alive.size() or _alive[i] == 0:
			continue
		var t: float = CombatMath.segment_circle_t(a, b, _pos[i], _radius[i] + radius)
		if t >= 0.0 and t < best_t:
			best_t = t
			best = i
	return best


func damage(index: int, amount: float) -> void:
	if _alive[index] == 0 or not ZombieRules.can_take_damage(_state[index] as ZombieRules.State):
		return
	_hp[index] -= amount
	_nodes[index].notify_hit(amount)
	if _hp[index] <= 0.0:
		_kill(index)


func spawn(kind: StringName, at: Vector2) -> void:
	var row: Dictionary = EnemyData.get_row(kind)
	if _pool.is_empty():
		_grow_pool(1)
	var z: Zombie = _pool.pop_back()
	z.configure(row)
	var r: float = row["radius"]
	_max_radius = maxf(_max_radius, r)
	_pos.append(at)
	_hp.append(row["max_hp"])
	_speed.append(row["speed"])
	_damage.append(row["contact_damage"])
	_radius.append(r)
	_alive.append(1)
	_state.append(ZombieRules.State.INACTIVE)
	_timer.append(0.0)
	_rows.append(row)
	_nodes.append(z)
	z.activate(Vector3(at.x, 0.0, at.y))
	var index: int = _nodes.size() - 1
	z.rotation.y = _yaw_towards(at, player.position_2d())
	if Tuning.FEATURE_ZOMBIE_SPAWN_RISE:
		_enter(index, ZombieRules.State.SPAWN, row["spawn_time"])
	else:
		_enter(index, ZombieRules.State.CHASE, 0.0)


## Debug ve ölçüm için: üst sınıra bakmadan count kadar zombi doğurur.
func spawn_many(count: int) -> void:
	for _i in count:
		spawn(EnemyData.WALKER, _pick_spawn_point())


func _tick_spawning(delta: float) -> void:
	if not spawning_enabled:
		return
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	_spawn_timer = SpawnRules.interval_at(elapsed)
	var cap: int = Quality.max_enemies()
	for _i in SpawnRules.batch_at(elapsed):
		if active_count() >= cap:
			break
		spawn(EnemyData.WALKER, _pick_spawn_point())


func _pick_spawn_point() -> Vector2:
	var half: float = _half - Tuning.SPAWN_EDGE_INSET
	return SpawnRules.pick_edge_point(_rng, half, player.position_2d(), Tuning.SPAWN_MIN_PLAYER_DIST, Tuning.SPAWN_TRIES)


func _move(delta: float) -> void:
	var target: Vector2 = player.position_2d()
	var hittable: bool = player.is_hittable()
	var solid: bool = not (Tuning.FEATURE_DASH_PASS_THROUGH and player.is_dashing())
	var windup_attack: bool = Tuning.FEATURE_ZOMBIE_WINDUP_ATTACK
	for i in _pos.size():
		if _alive[i] == 0:
			continue
		var state: ZombieRules.State = _state[i] as ZombieRules.State
		if ZombieRules.is_timed(state):
			_timer[i] -= delta
			if _timer[i] <= 0.0:
				state = _on_timer(i, state, target)
		var p: Vector2 = _pos[i]
		var dir: Vector2 = Steering.seek(p, target)
		var speed: float = _speed[i]
		if ZombieRules.can_move(state):
			var vel: Vector2 = dir * speed
			if Tuning.FEATURE_SEPARATION:
				vel += Steering.separation(i, _pos, _grid, _radius[i] * 2.0) * Tuning.ENEMY_SEPARATION_STRENGTH
			p += vel.limit_length(speed * Tuning.ENEMY_MAX_SPEED_FACTOR) * delta
		# Askerle temas: içine girmez.
		var reach: float = Tuning.PLAYER_RADIUS + _radius[i]
		var away: Vector2 = p - target
		var dist: float = away.length()
		if solid and dist < reach:
			if hittable and not windup_attack:
				player.take_hit(_damage[i])
				hittable = player.is_hittable()
			p = target + (away / dist if dist > 0.0001 else -dir) * reach
			dist = reach
		var lim: float = _half - _radius[i]
		p = p.clamp(Vector2(-lim, -lim), Vector2(lim, lim))
		_pos[i] = p
		var node: Zombie = _nodes[i]
		node.position = Vector3(p.x, 0.0, p.y)
		if state != ZombieRules.State.CHASE:
			continue
		# Yalnız kovalarken döner; hazırlanırken yönü kilitlidir, yana kaçan asker ıskalatır.
		if dir != Vector2.ZERO:
			node.rotation.y = atan2(dir.x, dir.y)
		if windup_attack and ZombieRules.wants_attack(dist, reach, _rows[i]["attack_range"]):
			_enter(i, ZombieRules.State.WINDUP, _rows[i]["attack_windup"])


## Süresi dolan durumdan çıkar; hazırlık bittiyse vuruşu uygular. Dönüş: yeni durum.
func _on_timer(index: int, state: ZombieRules.State, target: Vector2) -> ZombieRules.State:
	var row: Dictionary = _rows[index]
	var next: ZombieRules.State = ZombieRules.after_timer(state)
	if state == ZombieRules.State.WINDUP:
		var contact: float = Tuning.PLAYER_RADIUS + _radius[index]
		if ZombieRules.strike_hits(_pos[index].distance_to(target), contact, row["attack_hit_range"]):
			player.take_hit(_damage[index])
		_enter(index, next, row["attack_recover"])
	else:
		_enter(index, next, 0.0)
	return next


func _enter(index: int, state: ZombieRules.State, duration: float) -> void:
	_state[index] = state
	_timer[index] = duration
	_nodes[index].enter_state(state, duration)


static func _yaw_towards(from: Vector2, to: Vector2) -> float:
	var dir: Vector2 = Steering.seek(from, to)
	return atan2(dir.x, dir.y)


func _kill(index: int) -> void:
	_alive[index] = 0
	_dead_count += 1
	kills += 1
	var node: Zombie = _nodes[index]
	enemy_killed.emit(node.position)
	node.deactivate()


## Ölenleri sondan takasla çıkarır. Sondan başa gidildiği için takaslanan hep canlıdır.
func _compact() -> void:
	if _dead_count == 0:
		return
	var i: int = _nodes.size() - 1
	while i >= 0:
		if _alive[i] == 0:
			var last: int = _nodes.size() - 1
			_pool.append(_nodes[i])
			if i != last:
				_pos[i] = _pos[last]
				_hp[i] = _hp[last]
				_speed[i] = _speed[last]
				_damage[i] = _damage[last]
				_radius[i] = _radius[last]
				_alive[i] = _alive[last]
				_state[i] = _state[last]
				_timer[i] = _timer[last]
				_rows[i] = _rows[last]
				_nodes[i] = _nodes[last]
			_pos.resize(last)
			_hp.resize(last)
			_speed.resize(last)
			_damage.resize(last)
			_radius.resize(last)
			_alive.resize(last)
			_state.resize(last)
			_timer.resize(last)
			_rows.resize(last)
			_nodes.resize(last)
		i -= 1
	_dead_count = 0


func _grow_pool(count: int) -> void:
	for _i in count:
		var z: Zombie = Zombie.new()
		add_child(z)
		_pool.append(z)
