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
## Yay atışı (LobAttack): kind &"spit" / &"throw"; from/dest dünya konumu (from bırakış yüksekliğinde), flight sn,
## arc tepe yüksekliği, radius iniş yarıçapı (gölge işareti). İnince lob_landed; asit topu havuz bırakınca acid_pool_started.
signal lob_launched(kind: StringName, from: Vector3, dest: Vector3, flight: float, arc: float, radius: float, boss: bool)
signal lob_landed(kind: StringName, at: Vector3, radius: float)
signal acid_pool_started(at: Vector3, radius: float, time: float)
## Patlayıcı patladı (BloatAttack): at yerde, radius patlama yarıçapı (fx, sarsıntı ve ses için).
signal bloat_exploded(at: Vector3, radius: float)
## Çığlıkçı ses dalgası yaydı (fx ve sarsıntı); radius çağrı halkasının yarıçapı.
signal scream_emitted(at: Vector3, radius: float)
## Boss olayı (BossFx): slam / charge_marker / charge_start / charge_dust / stun / summon / roar; veri olaya göre (bkz. BossAttack).
signal boss_event(event_name: StringName, data: Dictionary)
## Zırhlıya önden gelen (azaltılmış) isabet; öldürmeyen vuruşlarda enemy_damaged yerine (kan yok: gri kıvılcım, küçük sayı).
signal enemy_blocked(at: Vector3, direction: Vector2, amount: float)

## Özel saldırı başladı (ses için): kind &"runner" / &"jump"; phase &"sprint" / &"lunge" / &"takeoff"; at yerde.
signal special_started(kind: StringName, phase: StringName, at: Vector3)
## Dilci olayı (ses için): kind &"shoot" / &"attach" / &"melee"; at dilcinin yerdeki konumu.
signal tongue_event(kind: StringName, at: Vector3)

const PHYSICS_PRIORITY: int = -10
## Bu hızın (karesi) altındaki itme sıfırlanır.
const KNOCK_REST_SQ: float = 0.0025

var player: Player
## Ana anahtar: kapalıyken hiçbir yönetici doğurmaz (ölçüm aracı kapatır).
var spawning_enabled: bool = true
var elapsed: float = 0.0
var kills: int = 0
## Özel saldırı sayaçları (ölçüm ve debug için; ölümsüz modda da isabet sayılır). Dil bitişleri: ısırdı / süre doldu / yakın vuruş.
var lunge_starts: int = 0
var lunge_hits: int = 0
var jump_lands: int = 0
var jump_hits: int = 0
var tongue_shots: int = 0
var tongue_hits: int = 0
var tongue_bites: int = 0
var tongue_timeouts: int = 0
var tongue_melees: int = 0
## Yay atışı sayaçları: atılan top, bırakılan havuz, asit tiki; atılan kaya, isabet eden kaya, yakın vuruş.
var spit_shots: int = 0
var spit_pools: int = 0
var spit_ticks: int = 0
var throw_shots: int = 0
var throw_hits: int = 0
var throw_melees: int = 0
## Zırhlı sayaçları: önden ve yandan/arkadan isabet.
var armor_front: int = 0
var armor_back: int = 0
## Patlayıcı sayaçları: şişmeye başlayan, patlayan, zincirle patlayan (başka patlama öldürdü), askere isabet eden patlama.
var bloat_primed: int = 0
var bloat_exploded_count: int = 0
var bloat_chains: int = 0
var bloat_player_hits: int = 0
## Çığlıkçı sayaçları: atılan çığlık, çağrılan zombi. spawn_cap: dalganın canlı üst sınırı (SpawnDirector; 0 = yok).
var screams: int = 0
var summoned: int = 0
var spawn_cap: int = 0
## Askeri dille bağlayan dilci (yoksa null); ölürse bağ çözülür.
var latched: Zombie
## Debug arenası: true iken canlı zombiler donar (hareket ve saldırı durur).
var debug_freeze: bool = false

var _grid: SpatialGrid
var _half: float
## Şehir bloklarının XZ dikdörtgenleri (FEATURE_CITY_GREYBOX); zombiler içine girmez, kenarda kayar.
var _blocks: Array[Rect2] = CityLayout.solid_rects(Tuning.ARENA_SIZE, Tuning.CITY_STREET_WIDTH, Tuning.FEATURE_CITY_PROPS)
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _max_radius: float = 0.0

var _pos: PackedVector2Array = PackedVector2Array()
var _hp: PackedFloat32Array = PackedFloat32Array()
var _speed: PackedFloat32Array = PackedFloat32Array()
var _damage: PackedFloat32Array = PackedFloat32Array()
## Doğan zombinin dalga hasar çarpanı (özel saldırı hasarları için) ve dalga çarpanları (yönetmen ayarlar).
var _dmg_mult: PackedFloat32Array = PackedFloat32Array()
var wave_row: Dictionary = {}
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
var _steer: ChaseSteer
var _nodes: Array[Zombie] = []
var _pool: EnemyPool
var _queries: EnemyQueries
var _burn: EnemyBurn
var _compactor: EnemyCompactor
var _spawner: EnemySpawner
var _combat: EnemyCombat
var _mover: EnemyMover
var _dead_count: int = 0
var _corpses: CorpseList = CorpseList.new()


func _ready() -> void:
	name = "Enemies"
	process_physics_priority = PHYSICS_PRIORITY
	_half = Tuning.ARENA_SIZE * 0.5
	_grid = SpatialGrid.new(Vector2(-_half, -_half), Vector2(Tuning.ARENA_SIZE, Tuning.ARENA_SIZE), Tuning.GRID_CELL_SIZE)
	_rng.randomize()
	_special = SpecialAttacks.new(self)
	_steer = ChaseSteer.new(self)
	_pool = EnemyPool.new(self)
	_queries = EnemyQueries.new(self)
	_burn = EnemyBurn.new(self)
	_compactor = EnemyCompactor.new(self)
	_spawner = EnemySpawner.new(self)
	_combat = EnemyCombat.new(self)
	_mover = EnemyMover.new(self)
	_pool.prewarm()


func _physics_process(delta: float) -> void:
	_compactor.run()
	for node: Zombie in _corpses.tick(delta):
		node.deactivate()
		_pool.give(node)
	elapsed += delta
	_grid.rebuild(_pos)
	_move(delta)
	_special.tick(delta)
	if _burning > 0:
		_burn.tick(delta)


## Boss Yığın'ın saldırı durumu ve sayaçları (BossAttack).
func boss() -> BossAttack:
	return _special.boss


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


func nearest_visible_enemy(from: Vector2, max_range: float, blocks: Array[Rect2]) -> int:
	return _queries.nearest_visible(from, max_range, blocks)


func count_kind(kind: StringName) -> int:
	return _queries.count_kind(kind)


func count_near(center: Vector2, radius: float) -> int:
	return _queries.count_near(center, radius)


func pick_near(center: Vector2, radius: float, roll: float) -> Vector2:
	return _queries.pick_near(center, radius, roll)


func query_arc(origin: Vector2, dir: Vector2, reach: float, arc_rad: float) -> PackedInt32Array:
	return _queries.query_arc(origin, dir, reach, arc_rad)


func query_circle(center: Vector2, radius: float) -> PackedInt32Array:
	return _queries.query_circle(center, radius)


func ignite(index: int, dps: float, duration: float) -> void:
	_burn.ignite(index, dps, duration)


func find_segment_hit(a: Vector2, b: Vector2, radius: float, exclude: PackedInt32Array = PackedInt32Array()) -> int:
	return _queries.find_segment_hit(a, b, radius, exclude)


## direction: vuruşun geldiği yön (itme bu yöne; zırhlıda kaynak yönü = -direction). knockback: ağırlığı 1 olana verilen ilk hız.
## dot: sürekli hasar (yanma); zırh uygulanmaz.
func damage(index: int, amount: float, direction: Vector2 = Vector2.ZERO, knockback: float = 0.0, dot: bool = false) -> void:
	_combat.damage(index, amount, direction, knockback, dot)


## Özel saldırı hasarları için zombinin dalga çarpanıyla ölçeklenmiş satır (çarpan 1 ise satırın kendisi).
func scaled_row(i: int, row: Dictionary) -> Dictionary:
	return WaveScaling.scaled_row(row, _dmg_mult[i])


func spawn(kind: StringName, at: Vector2) -> void:
	_spawner.spawn(kind, at)


## Debug: tür başına şimdiye dek doğan sayısı.
func spawn_counts() -> Dictionary:
	return _spawner.spawned


## Debug ve ölçüm için: üst sınıra bakmadan count kadar zombi doğurur.
func spawn_many(count: int, kind: StringName = EnemyData.WALKER) -> void:
	for _i in count:
		spawn(kind, pick_spawn_point())


## Dalga sonu: count kadar canlı zombiyi öldürme sayılmadan devirir (ölüm animasyonu + solma).
func dismiss(count: int) -> void:
	_combat.dismiss(count)


## Debug arenası: ilk canlı zombinin indeksi (yoksa -1), durumu ve öldürme.
func debug_alive_index() -> int:
	return _queries.first_alive()


func debug_state(index: int) -> ZombieRules.State:
	return _state[index] as ZombieRules.State


func debug_kill(index: int) -> void:
	if _alive[index] != 0:
		_combat.kill(index)


func pick_spawn_point() -> Vector2:
	return _spawner.pick_spawn_point()


func _move(delta: float) -> void:
	_mover.run(delta)


## Zombi doğma / iniş noktası bir engelin içine düşmüşse en yakın boş noktaya kaydırır (şehir kapalıyken aynen).
func free_point(p: Vector2, r: float) -> Vector2:
	if not Tuning.FEATURE_CITY_GREYBOX:
		return p
	return CityLayout.settle(p, r, _blocks, Tuning.OBSTACLE_SETTLE_PASSES)


## Debug ölçümü (StuckMeter): dizi uzunluğu, indeks canlı ve kovalıyor mu, sürü hızı ve düğüm.
func slot_count() -> int:
	return _pos.size()


func debug_chasing(index: int) -> bool:
	return _alive[index] != 0 and _state[index] == ZombieRules.State.CHASE


func debug_speed(index: int) -> float:
	return _speed[index]


func debug_node(index: int) -> Zombie:
	return _nodes[index]


func _enter(index: int, state: ZombieRules.State, duration: float, restart: bool = false) -> void:
	_state[index] = state
	_timer[index] = duration
	_nodes[index].enter_state(state, duration, restart)
