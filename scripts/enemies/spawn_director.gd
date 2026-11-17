class_name SpawnDirector
extends Node
## Zombi doğmasını yönetir: dalgalar (FEATURE_WAVES) ya da Aşama 1'deki sonsuz artış.
## Dalga kuralları WaveRun'da; burası yalnız zamanlayıp EnemyManager'a doğurtur.

## Dalga fazı değişti (dalgalar kapalıyken hiç yayılmaz).
signal phase_changed(phase: WaveRun.Phase, wave_index: int)

var enemies: EnemyManager
## Dalgalar kapalıyken null.
var run: WaveRun

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _spawn_timer: float = 0.0


func _ready() -> void:
	name = "SpawnDirector"
	# Zombiler yürümeden önce doğsun.
	process_physics_priority = EnemyManager.PHYSICS_PRIORITY - 1
	_rng.randomize()
	if Tuning.FEATURE_WAVES:
		run = WaveRun.new(WaveData.WAVES, Tuning.WAVE_CLEAR_TIME, Tuning.WAVE_BREAK_TIME)
		_announce.call_deferred()
	else:
		_spawn_timer = SpawnRules.interval_at(0.0)


func _physics_process(delta: float) -> void:
	# Ölçüm aracı doğmayı kapatınca dalga saati de durur.
	if not enemies.spawning_enabled:
		return
	if run == null:
		_tick_endless(delta)
		return
	if run.tick(delta) != WaveRun.NO_CHANGE:
		_on_phase_entered()
	match run.phase:
		WaveRun.Phase.WAVE:
			_tick_wave(delta)
		WaveRun.Phase.CLEAR:
			_tick_clear(delta)


## Debug: süren dalgayı hemen bitirir.
func end_wave() -> void:
	if run != null and run.phase == WaveRun.Phase.WAVE:
		run.end_wave()
		_on_phase_entered()


## Debug: i. dalgadan (0 tabanlı) başlatır.
func start_at(i: int) -> void:
	if run != null:
		run.start_at(i)
		_on_phase_entered()


func _announce() -> void:
	phase_changed.emit(run.phase, run.index)


func _on_phase_entered() -> void:
	_spawn_timer = 0.0
	if run.phase == WaveRun.Phase.BREAK or run.phase == WaveRun.Phase.WON:
		enemies.dismiss(enemies.active_count())
	_announce()
	if run.phase == WaveRun.Phase.WON:
		GameFlow.victory()


func _tick_wave(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	var row: Dictionary = run.current()
	var t: float = run.progress()
	_spawn_timer = SpawnRules.wave_interval(row, t)
	var cap: int = mini(row["max_alive"], Quality.max_enemies())
	for _i in SpawnRules.wave_batch(row, t):
		if enemies.active_count() >= cap:
			break
		enemies.spawn(SpawnRules.pick_kind(_rng, row["mix"]), enemies.pick_spawn_point())


## Kalanlar temizlik süresine yayılarak devrilir; son karede hepsi.
func _tick_clear(delta: float) -> void:
	var count: int = enemies.active_count()
	if count > 0:
		enemies.dismiss(ceili(count * delta / maxf(run.phase_left, delta)))


func _tick_endless(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	_spawn_timer = SpawnRules.interval_at(enemies.elapsed)
	var cap: int = Quality.max_enemies()
	for _i in SpawnRules.batch_at(enemies.elapsed):
		if enemies.active_count() >= cap:
			break
		enemies.spawn(EnemyData.WALKER, enemies.pick_spawn_point())
