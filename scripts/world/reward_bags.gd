class_name RewardBags
extends Node3D
## Haritada süzülen ödül çantası (para / XP): dalga içinde takvime göre (BagSchedule) en çok bir çanta çıkar,
## asker BAG_COLLECT_RADIUS içine girince değer tek seferde ilgili kanala eklenir. Görünüm BagVisual'dan gelir.
## Süre yalnız dalga fazında ve duraklatma dışında akar (fizik karesi); CLEAR/BREAK'te çanta silinir.
## Debug: --capture-bag=money|xp çantayı askerin önünde hemen doğurur (ömrü dolmaz).

## Çanta alındı (tur özeti için).
signal collected(kind: StringName, value: int)

const DEBUG_ARG: String = "--capture-bag="

var player: Player
var director: SpawnDirector
var loot: RunLoot

var _schedule: BagSchedule = BagSchedule.new()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _rects: Array[Rect2] = CityLayout.solid_rects(Tuning.ARENA_SIZE, Tuning.CITY_STREET_WIDTH, Tuning.FEATURE_CITY_PROPS)
var _wave_index: int = -1
var _active: bool = false
var _immortal: bool = false
var _kind: StringName = BagRules.KIND_MONEY
var _value: int = 0
var _pos: Vector2 = Vector2.ZERO
var _age: float = 0.0
var _bob_time: float = 0.0
var _body: Node3D
var _marker: Node3D


## Düğümü host'a ekler (+ ekran dışı ok); ana bayrak kapalıyken ya da 1v1 arenada null döner.
static func install(host: Node, target: Player, spawn_director: SpawnDirector, run_loot: RunLoot) -> RewardBags:
	if not Tuning.FEATURE_REWARD_BAGS or DebugArena.active:
		return null
	var bags: RewardBags = RewardBags.new()
	bags.player = target
	bags.director = spawn_director
	bags.loot = run_loot
	host.add_child(bags)
	if Tuning.FEATURE_BAG_ARROW:
		var arrow: BagArrow = BagArrow.new()
		arrow.bags = bags
		host.add_child(arrow)
	return bags


func _ready() -> void:
	name = "RewardBags"
	_rng.randomize()
	if OS.is_debug_build():
		for arg: String in OS.get_cmdline_user_args():
			if arg.begins_with(DEBUG_ARG):
				_debug_spawn.call_deferred(StringName(arg.trim_prefix(DEBUG_ARG)))


func is_active() -> bool:
	return _active


func bag_kind() -> StringName:
	return _kind


## Çantanın dünya konumu (ok için).
func bag_world_position() -> Vector3:
	return Vector3(_pos.x, Tuning.BAG_HOVER_HEIGHT, _pos.y)


func _physics_process(delta: float) -> void:
	if _active:
		_tick_active(delta)
	var run: WaveRun = director.run if director != null else null
	if run == null or _immortal:
		return
	if GameFlow.state != GameFlow.State.PLAYING:
		_remove()  # ölüm/zafer gecikmesinde yeni çanta yok, toplama yok
		return
	if run.phase != WaveRun.Phase.WAVE:
		_remove()
		_wave_index = -1
		return
	if run.index != _wave_index:
		_wave_index = run.index
		_schedule.start_wave(run.index + 1)
		_remove()
	if _schedule.tick(delta, _active):
		_try_spawn()


func _process(delta: float) -> void:
	if not _active:
		return
	_bob_time += delta
	var shown: bool = BagRules.is_shown(_age) or _immortal
	_body.visible = shown
	_marker.visible = shown
	_body.position.y = Tuning.BAG_HOVER_HEIGHT + sin(_bob_time * Tuning.BAG_BOB_SPEED) * Tuning.BAG_BOB_AMPLITUDE
	_body.rotation.y += Tuning.BAG_SPIN_SPEED * delta


func _tick_active(delta: float) -> void:
	_age += delta
	if BagRules.in_reach(_pos, player.position_2d()):
		_collect()
	elif BagRules.expired(_age) and not _immortal:
		_remove()


func _try_spawn() -> void:
	var at: Vector2 = BagRules.pick_point(player.position_2d(), _rects, _rng)
	if at == BagRules.NO_POINT:
		return  # bu sefer atlanır; takvim bir sonraki aralığı bekler
	var kind: StringName = BagRules.pick_kind(_schedule.money_count, _schedule.xp_count, _rng)
	_schedule.register(kind)
	_place(kind, at, BagRules.value_for_wave(_schedule.wave))


func _place(kind: StringName, at: Vector2, value: int) -> void:
	_remove()
	_active = true
	_kind = kind
	_value = value
	_pos = at
	_age = 0.0
	_bob_time = _rng.randf() * TAU
	_marker = BagVisual.build_marker(kind)
	_marker.position = Vector3(at.x, 0.0, at.y)
	add_child(_marker)
	_body = BagVisual.build(kind)
	_body.position = Vector3(at.x, Tuning.BAG_HOVER_HEIGHT, at.y)
	add_child(_body)


func _remove() -> void:
	if not _active:
		return
	_active = false
	_body.queue_free()
	_marker.queue_free()


func _collect() -> void:
	var kind: StringName = _kind
	var value: int = _value
	var color: Color = BagRules.color_of(kind)
	var at: Vector3 = Vector3(_pos.x, Tuning.BAG_HOVER_HEIGHT, _pos.y)
	_remove()
	_immortal = false  # debug çantası toplanınca takvim normal akar
	if kind == BagRules.KIND_MONEY:
		loot.add_money(value)
	elif loot.add_xp(value) > 0:
		UiSounds.play(UiSoundData.LEVEL_UP)
	if Tuning.FEATURE_SFX:
		Audio.play(SoundData.PICKUP_DARK if Tuning.FEATURE_SFX_PICKUP_DARK else SoundData.PICKUP)
	_play_burst(at, color)
	collected.emit(kind, value)


func _play_burst(at: Vector3, color: Color) -> void:
	var holder: Node3D = Node3D.new()
	holder.position = at
	add_child(holder)
	MergeBurst.play(holder, color)
	get_tree().create_timer(Tuning.BAG_BURST_HOLD_TIME).timeout.connect(holder.queue_free)


func _debug_spawn(kind_name: StringName) -> void:
	var kind: StringName = BagRules.KIND_XP if kind_name == BagRules.KIND_XP else BagRules.KIND_MONEY
	_immortal = true
	_place(kind, player.position_2d() + Tuning.BAG_DEBUG_OFFSET, BagRules.value_for_wave(1))
