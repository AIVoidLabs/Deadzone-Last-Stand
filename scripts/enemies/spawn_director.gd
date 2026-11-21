class_name SpawnDirector
extends Node
## Zombi doğmasını yönetir: dalgalar (FEATURE_WAVES) ya da Aşama 1'deki sonsuz artış.
## Dalga kuralları WaveRun'da; burası yalnız zamanlayıp EnemyManager'a doğurtur.

## Dalga fazı değişti (dalgalar kapalıyken hiç yayılmaz).
signal phase_changed(phase: WaveRun.Phase, wave_index: int)
## Boss uyarısı başladı (arayüz: yazı + kırmızı kenar nabzı); boss uyarı süresi sonunda doğar.
signal boss_warning

var enemies: EnemyManager
## Dalgalar kapalıyken null.
var run: WaveRun
## true iken ara (BREAK) süresi akmaz: mağaza açılmayı bekler ya da açıktır.
var hold_break: bool = false

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _spawn_timer: float = 0.0


func _ready() -> void:
	name = "SpawnDirector"
	# Zombiler yürümeden önce doğsun.
	process_physics_priority = EnemyManager.PHYSICS_PRIORITY - 1
	_rng.randomize()
	if Tuning.FEATURE_WAVES and not DebugArena.active:
		run = WaveRun.new(WaveData.WAVES, Tuning.WAVE_CLEAR_TIME, Tuning.WAVE_BREAK_TIME, Tuning.FEATURE_BOSS, Tuning.BOSS_WARNING_TIME)
		enemies.enemy_killed.connect(_on_enemy_killed)
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
	if not (hold_break and run.phase == WaveRun.Phase.BREAK) and run.tick(delta) != WaveRun.NO_CHANGE:
		_on_phase_entered()
	match run.phase:
		WaveRun.Phase.WAVE:
			_tick_wave(delta)
		WaveRun.Phase.CLEAR:
			_tick_clear(delta)


## Arayı hemen bitirir (mağazadan "sonraki dalga"); bir sonraki karede yeni dalga başlar.
func skip_break() -> void:
	hold_break = false
	if run != null and run.phase == WaveRun.Phase.BREAK:
		run.phase_left = 0.0


## Debug: süren dalgayı hemen bitirir.
func end_wave() -> void:
	if run != null and run.phase == WaveRun.Phase.WAVE:
		run.end_wave()
		_on_phase_entered()


## Debug: boss'u at'te doğurur; dalga süresi durur, boss ölünce dalga biter (dalgalar kapalıyken yalnız doğurur).
func debug_spawn_boss(at: Vector2) -> void:
	enemies.spawn(EnemyData.BOSS_HEAP, at)
	if run != null:
		run.force_boss()


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


## Boss ölünce dalga biter (kısa temizlik: ölüm klibi oynasın, kristaller düşsün).
func _on_enemy_killed(_at: Vector3, row: Dictionary) -> void:
	if row.get("boss", false) and run.boss_defeated(Tuning.BOSS_DEATH_CLEAR_TIME):
		_on_phase_entered()


## Boss akışının olayları: uyarı ve doğma.
func _tick_boss_event() -> void:
	match run.boss_event:
		&"warn":
			boss_warning.emit()
		&"spawn":
			enemies.spawn(run.current()["boss"]["kind"], enemies.pick_spawn_point())
	run.boss_event = &""


func _tick_wave(delta: float) -> void:
	_tick_boss_event()
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	var row: Dictionary = run.current()
	var t: float = run.progress()
	_spawn_timer = SpawnRules.wave_interval(row, t) / run.horde_factor()
	var cap: int = mini(row["max_alive"], Quality.max_enemies())
	enemies.spawn_cap = cap
	var mix: Dictionary = WaveData.active_mix(row["mix"])
	var kind_caps: Dictionary = row.get("max_alive_kind", {})
	var alive: Dictionary = {}
	for capped: StringName in kind_caps:
		alive[capped] = enemies.count_kind(capped)
	for _i in SpawnRules.wave_batch(row, t):
		if enemies.active_count() >= cap:
			break
		var kind: StringName = SpawnRules.pick_kind_capped(_rng, mix, kind_caps, alive) if Tuning.FEATURE_ZOMBIE_VARIETY else EnemyData.WALKER
		if kind_caps.has(kind):
			alive[kind] += 1
		enemies.spawn(kind, enemies.pick_spawn_point())


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
