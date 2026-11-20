class_name EnemyManager
extends Node3D
## Tüm zombileri tek döngüde yürütür. Durum paralel dizilerde (veri odaklı);
## Zombie düğümleri havuzdan gelir ve yalnız konum + görüntü taşır.
## Ölenler kare içinde işaretlenir, bir sonraki karenin başında diziden çıkarılır
## (böylece aynı kare içinde indeksler kaymaz).

## Öldürülen zombi (dalga sonu devrilmeleri hariç). row: tür satırı (drop_value vb.).
signal enemy_killed(at: Vector3, row: Dictionary)
## Her isabette (öldüren dahil). at: zombinin yerdeki konumu; direction: vuruş yönü.
signal enemy_damaged(at: Vector3, direction: Vector2, amount: float, killed: bool)
## Zıplayan indi (şok dalgası efekti ve kamera sarsıntısı için). at: yerde, radius: iniş yarıçapı.
signal jump_landed(at: Vector3, radius: float)

const PHYSICS_PRIORITY: int = -10
## Bu hızın (karesi) altındaki itme sıfırlanır.
const KNOCK_REST_SQ: float = 0.0025

var player: Player
## Ana anahtar: kapalıyken hiçbir yönetici doğurmaz (ölçüm aracı kapatır).
var spawning_enabled: bool = true
var elapsed: float = 0.0
var kills: int = 0
## Özel saldırı sayaçları (ölçüm ve debug için; ölümsüz modda da isabet sayılır).
var lunge_starts: int = 0
var lunge_hits: int = 0
var jump_lands: int = 0
var jump_hits: int = 0
var tongue_shots: int = 0
var tongue_hits: int = 0
## Yeni dil mekaniği: çekişin bitişi (yakında ısırdı / süre doldu).
var tongue_bites: int = 0
var tongue_timeouts: int = 0
## Askeri dille bağlayan dilci (yoksa null); ölürse bağ çözülür.
var latched: Zombie
## Debug arenası: true iken canlı zombiler donar (hareket ve saldırı durur).
var debug_freeze: bool = false

var _grid: SpatialGrid
var _half: float
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
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
## İtilme hızı (m/sn); kendiliğinden söner.
var _knock: PackedVector2Array = PackedVector2Array()
## Yanma: kalan süre (sn), saniye başına hasar, son vuruştan beri biriken süre.
var _burn_left: PackedFloat32Array = PackedFloat32Array()
var _burn_dps: PackedFloat32Array = PackedFloat32Array()
var _burn_acc: PackedFloat32Array = PackedFloat32Array()
var _burning: int = 0
## Özel saldırılarda nişan: atılış / dil yönü (birim vektör) ya da zıplamanın iniş noktası.
var _aim: PackedVector2Array = PackedVector2Array()
## Silahların hedef alabildiği (1) ya da alamadığı (0: ölü, havadaki) zombiler.
var _targetable: PackedByteArray = PackedByteArray()
var _special: SpecialAttacks
var _nodes: Array[Zombie] = []
var _pool: EnemyPool
var _queries: EnemyQueries
var _burn: EnemyBurn
var _compactor: EnemyCompactor
var _spawner: EnemySpawner
var _dead_count: int = 0
var _corpses: CorpseList = CorpseList.new()


func _ready() -> void:
	name = "Enemies"
	process_physics_priority = PHYSICS_PRIORITY
	_half = Tuning.ARENA_SIZE * 0.5
	_grid = SpatialGrid.new(Vector2(-_half, -_half), Vector2(Tuning.ARENA_SIZE, Tuning.ARENA_SIZE), Tuning.GRID_CELL_SIZE)
	_rng.randomize()
	_special = SpecialAttacks.new(self)
	_pool = EnemyPool.new(self)
	_queries = EnemyQueries.new(self)
	_burn = EnemyBurn.new(self)
	_compactor = EnemyCompactor.new(self)
	_spawner = EnemySpawner.new(self)
	for kind: StringName in EnemyData.TABLE:
		var prewarm: int = Quality.max_enemies() if kind == EnemyData.WALKER else int(EnemyData.TABLE[kind].get("prewarm", 0))
		_pool.grow(kind, prewarm)


func _physics_process(delta: float) -> void:
	_compactor.run()
	for node: Zombie in _corpses.tick(delta):
		node.deactivate()
		_pool.give(node)
	elapsed += delta
	_grid.rebuild(_pos)
	_move(delta)
	if _burning > 0:
		_burn.tick(delta)


func active_count() -> int:
	return _nodes.size() - _dead_count


func pool_size() -> int:
	return _nodes.size() + _pool.idle_count() + _corpses.count()


func enemy_position(index: int) -> Vector2:
	return _pos[index]


func enemy_radius(index: int) -> float:
	return _radius[index]


func nearest_enemy(from: Vector2, max_range: float) -> int:
	return _queries.nearest_enemy(from, max_range)


func count_near(center: Vector2, radius: float) -> int:
	return _queries.count_near(center, radius)


func query_arc(origin: Vector2, dir: Vector2, reach: float, arc_rad: float) -> PackedInt32Array:
	return _queries.query_arc(origin, dir, reach, arc_rad)


func query_circle(center: Vector2, radius: float) -> PackedInt32Array:
	return _queries.query_circle(center, radius)


func ignite(index: int, dps: float, duration: float) -> void:
	_burn.ignite(index, dps, duration)


func find_segment_hit(a: Vector2, b: Vector2, radius: float, exclude: PackedInt32Array = PackedInt32Array()) -> int:
	return _queries.find_segment_hit(a, b, radius, exclude)


## direction: vuruşun geldiği yön (itme bu yöne). knockback: ağırlığı 1 olana verilen ilk hız.
func damage(index: int, amount: float, direction: Vector2 = Vector2.ZERO, knockback: float = 0.0) -> void:
	var state: ZombieRules.State = _state[index] as ZombieRules.State
	if _alive[index] == 0 or not ZombieRules.can_take_damage(state):
		return
	_hp[index] -= amount
	_nodes[index].notify_hit(amount)
	var row: Dictionary = _rows[index]
	var at: Vector3 = Vector3(_pos[index].x, 0.0, _pos[index].y)
	enemy_damaged.emit(at, direction, amount, _hp[index] <= 0.0)
	if _hp[index] <= 0.0:
		_kill(index, Knockback.impulse(direction, knockback * Tuning.ZOMBIE_DEATH_KNOCKBACK_FACTOR, row["weight"]))
		return
	if Tuning.FEATURE_KNOCKBACK:
		_knock[index] += Knockback.impulse(direction, knockback, row["weight"])
	if Tuning.FEATURE_STAGGER and float(row["stagger_time"]) > 0.0 and ZombieRules.can_stagger(state):
		_enter(index, ZombieRules.State.STAGGER, row["stagger_time"], true)


func spawn(kind: StringName, at: Vector2) -> void:
	_spawner.spawn(kind, at)


## Debug ve ölçüm için: üst sınıra bakmadan count kadar zombi doğurur.
func spawn_many(count: int, kind: StringName = EnemyData.WALKER) -> void:
	for _i in count:
		spawn(kind, pick_spawn_point())


## Dalga sonu: count kadar canlı zombiyi öldürme sayılmadan devirir (ölüm animasyonu + solma).
func dismiss(count: int) -> void:
	var i: int = _pos.size() - 1
	while i >= 0 and count > 0:
		if _alive[i] != 0:
			_kill(i, Vector2.ZERO, false)
			count -= 1
		i -= 1


## Debug arenası: ilk canlı zombinin indeksi (yoksa -1), durumu ve öldürme.
func debug_alive_index() -> int:
	for i in _pos.size():
		if _alive[i] != 0:
			return i
	return -1


func debug_state(index: int) -> ZombieRules.State:
	return _state[index] as ZombieRules.State


func debug_kill(index: int) -> void:
	if _alive[index] != 0:
		_kill(index)


func pick_spawn_point() -> Vector2:
	return _spawner.pick_spawn_point()


func _move(delta: float) -> void:
	var target: Vector2 = player.position_2d()
	var hittable: bool = player.is_hittable()
	var solid: bool = not (Tuning.FEATURE_DASH_PASS_THROUGH and player.is_dashing())
	var windup_attack: bool = Tuning.FEATURE_ZOMBIE_WINDUP_ATTACK
	var target_vel: Vector2 = Vector2(player.velocity.x, player.velocity.z)
	for i in _pos.size():
		if _alive[i] == 0 or debug_freeze:
			continue
		var state: ZombieRules.State = _state[i] as ZombieRules.State
		if ZombieRules.is_timed(state):
			_timer[i] -= delta
			if _timer[i] <= 0.0:
				state = _on_timer(i, state, target)
		var p: Vector2 = _pos[i]
		var dir: Vector2 = Steering.seek(p, target)
		var speed: float = _speed[i]
		var special: bool = SpecialAttacks.is_special(_rows[i])
		if special and SpecialAttacks.acts_in(state):
			p = _special.act(i, state, p, dir, delta, target, target_vel)
		elif ZombieRules.can_move(state):
			var vel: Vector2 = dir * speed
			if Tuning.FEATURE_SEPARATION:
				vel += Steering.separation(i, _pos, _grid, _radius[i] * 2.0) * Tuning.ENEMY_SEPARATION_STRENGTH
			p += vel.limit_length(speed * Tuning.ENEMY_MAX_SPEED_FACTOR) * delta
		var knock: Vector2 = _knock[i]
		if knock != Vector2.ZERO:
			p += knock * delta
			knock = Knockback.decay(knock, Tuning.KNOCKBACK_DAMPING, delta)
			_knock[i] = knock if knock.length_squared() > KNOCK_REST_SQ else Vector2.ZERO
		# Askerle temas: içine girmez.
		var reach: float = Tuning.PLAYER_RADIUS + _radius[i]
		var away: Vector2 = p - target
		var dist: float = away.length()
		if state == ZombieRules.State.LUNGE:
			state = _special.lunge_contact(i, state, p, dist, reach, target)
			hittable = player.is_hittable()
		# Havadaki zıplayan askerin üstünden geçer; itişme yok.
		if solid and dist < reach and state != ZombieRules.State.JUMP:
			if hittable and not windup_attack:
				player.take_hit(_damage[i], -away)
				hittable = player.is_hittable()
			p = target + (away / dist if dist > 0.0001 else -dir) * reach
			dist = reach
		var lim: float = _half - _radius[i]
		p = p.clamp(Vector2(-lim, -lim), Vector2(lim, lim))
		_pos[i] = p
		var node: Zombie = _nodes[i]
		node.position = Vector3(p.x, 0.0, p.y)
		if special and (state == ZombieRules.State.WINDUP or state == ZombieRules.State.LUNGE or state == ZombieRules.State.JUMP):
			var face: Vector2 = _special.facing(i, p)
			if face != Vector2.ZERO:
				node.rotation.y = atan2(face.x, face.y)
		if state != ZombieRules.State.CHASE:
			continue
		# Yalnız kovalarken döner; hazırlanırken yönü kilitlidir, yana kaçan asker ıskalatır.
		if dir != Vector2.ZERO:
			node.rotation.y = atan2(dir.x, dir.y)
		if windup_attack and ZombieRules.wants_attack(dist, reach, SpecialAttacks.start_range(_rows[i])):
			_enter(i, ZombieRules.State.WINDUP, _rows[i]["attack_windup"])
			if special:
				_special.begin_windup(i, p, target, target_vel)


## Süresi dolan durumdan çıkar; hazırlık bittiyse vuruşu uygular. Dönüş: yeni durum.
func _on_timer(index: int, state: ZombieRules.State, target: Vector2) -> ZombieRules.State:
	var row: Dictionary = _rows[index]
	var special: bool = SpecialAttacks.is_special(row)
	if special and state == ZombieRules.State.WINDUP:
		return _special.end_windup(index, target)
	if special and SpecialAttacks.acts_in(state) and state != ZombieRules.State.WINDUP:
		return _special.finish(index, state, target)
	var next: ZombieRules.State = ZombieRules.after_timer(state)
	if state == ZombieRules.State.WINDUP:
		var contact: float = Tuning.PLAYER_RADIUS + _radius[index]
		if ZombieRules.strike_hits(_pos[index].distance_to(target), contact, row["attack_hit_range"]):
			player.take_hit(_damage[index], target - _pos[index])
		_enter(index, next, row["attack_recover"])
	else:
		_enter(index, next, 0.0)
	return next


func _enter(index: int, state: ZombieRules.State, duration: float, restart: bool = false) -> void:
	_state[index] = state
	_timer[index] = duration
	_nodes[index].enter_state(state, duration, restart)


## push: öldüren vuruşun itmesi; ceset bu yöne düşer ve kayar.
## credit: öldürme sayılır ve enemy_killed yayılır (dalga sonu devrilmelerde kapalı).
func _kill(index: int, push: Vector2 = Vector2.ZERO, credit: bool = true) -> void:
	if _burn_left[index] > 0.0:
		_burn.extinguish(index)
	_special.on_removed(index)
	_alive[index] = 0
	_dead_count += 1
	var node: Zombie = _nodes[index]
	if credit:
		kills += 1
		enemy_killed.emit(node.position, _rows[index])
	if not Tuning.FEATURE_ZOMBIE_DEATH_ANIM:
		node.deactivate()
		return
	# Ölüm klipleri arkaya düşer: yüzü vuruşun geldiği yöne çevir, sırtüstü vuruş yönüne düşsün.
	if push != Vector2.ZERO:
		node.rotation.y = atan2(-push.x, -push.y)
	var duration: float = Tuning.ZOMBIE_CORPSE_TIME + Tuning.ZOMBIE_FADE_TIME
	node.enter_state(ZombieRules.State.DYING, duration)
	_corpses.add(node, push if Tuning.FEATURE_KNOCKBACK else Vector2.ZERO, duration)
