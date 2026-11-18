class_name Autoplay
extends Node
## Debug: botla tam turu baştan sona oynar ve dalga başına rapor yazar (denge ölçümü, 6.6).
## Bot zombilerden kaçar, yaklaşınca dash atar, kart seçer (1) ve mağazada elindeki parayla alır.
## Çalıştırma: godot --headless --path . --fixed-fps 60 -- --autoplay [--autoplay-weapons=4] [--autoplay-crystals=N]
## Ölümsüz değildir; zorluğun kaba göstergesi olarak ölürse hangi dalgada öldüğünü raporlar.

const FLEE_RANGE: float = 7.0
const DASH_RANGE: float = 1.6
const CENTER_PULL: float = 1.4
const KEY_DELAY: float = 0.1
const MAX_RUN_TIME: float = 420.0
const RESULT_FILE: String = "user://autoplay_result.txt"

var player: Player
var enemies: EnemyManager
var director: SpawnDirector
var loot: RunLoot
var weapons: WeaponRig
var shop: ShopFlow

var _max_weapons: int = 4
var _lines: PackedStringArray = PackedStringArray()
var _key_wait: float = 0.0
var _last_hp: float = 0.0
var _damage_taken: float = 0.0
var _wave_start_kills: int = 0
var _wave_start_crystals: int = 0
var _wave_started_at: float = 0.0
var _time: float = 0.0
var _done: bool = false


static func requested() -> bool:
	return OS.get_cmdline_user_args().has("--autoplay")


func _ready() -> void:
	name = "Autoplay"
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--autoplay-weapons="):
			_max_weapons = arg.trim_prefix("--autoplay-weapons=").to_int()
		elif arg.begins_with("--autoplay-crystals="):
			loot.crystals += arg.trim_prefix("--autoplay-crystals=").to_int()
	player.use_input_override = true
	_last_hp = player.health.current
	director.phase_changed.connect(_on_phase)
	GameFlow.game_over_started.connect(_finish.bind(false))
	GameFlow.victory_started.connect(_finish.bind(true))


func _physics_process(delta: float) -> void:
	_time += delta
	if _done:
		return
	if player.health.current < _last_hp:
		_damage_taken += _last_hp - player.health.current
	_last_hp = player.health.current
	_steer()
	if _time > MAX_RUN_TIME:
		_log("TAKILDI faz %s kalan %.1f hold %s duraklatildi %s magaza %s bekleyen_seviye %d kristal_yerde %d" % [
			WaveRun.Phase.keys()[director.run.phase], director.run.phase_left, director.hold_break, get_tree().paused,
			shop.is_open(), loot.pending_levels, shop.pickups.count() if shop.pickups != null else -1])
		_finish(false)


func _process(delta: float) -> void:
	if _done or not get_tree().paused:
		_key_wait = KEY_DELAY
		return
	if shop.is_open():
		shop.debug_autobuy(_max_weapons)
		return
	_key_wait -= delta
	if _key_wait > 0.0:
		return
	_key_wait = KEY_DELAY
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_1
	key.pressed = true
	Input.parse_input_event(key)


## En yakın zombiden uzaklaşır, arena merkezine doğru hafif çekilir; yakına gelirse dash.
func _steer() -> void:
	var origin: Vector2 = player.position_2d()
	var direction: Vector2 = Vector2.ZERO
	var nearest: int = enemies.nearest_enemy(origin, FLEE_RANGE)
	if nearest >= 0:
		var offset: Vector2 = origin - enemies.enemy_position(nearest)
		direction += offset.normalized()
		if offset.length() < DASH_RANGE:
			player.request_dash()
	var half: float = Tuning.ARENA_SIZE * 0.5
	direction += -origin.normalized() * clampf(origin.length() / half, 0.0, 1.0) * CENTER_PULL
	player.input_override = direction.limit_length(1.0)


func _on_phase(phase: WaveRun.Phase, wave_index: int) -> void:
	if phase == WaveRun.Phase.WAVE:
		_wave_start_kills = enemies.kills
		_wave_start_crystals = loot.crystals
		_wave_started_at = _time
		_damage_taken = 0.0
	elif phase == WaveRun.Phase.CLEAR:
		_report_wave(wave_index)


func _report_wave(wave_index: int) -> void:
	var slots: PackedStringArray = PackedStringArray()
	for slot: Dictionary in weapons.slot_list():
		slots.append("%s%d" % [String(slot["id"]).substr(0, 1).to_upper(), slot["tier"]])
	var line: String = "WAVE %d  kills %d  crystals +%d (total %d)  damage_taken %d  hp %d/%d  level %d  weapons [%s]  alive_at_end %d  %.0fs" % [
		wave_index + 1, enemies.kills - _wave_start_kills, loot.crystals - _wave_start_crystals, loot.crystals,
		roundi(_damage_taken), roundi(player.health.current), roundi(player.health.maximum), loot.level,
		" ".join(slots), enemies.active_count(), _time - _wave_started_at,
	]
	_log(line)


func _finish(won: bool) -> void:
	if _done:
		return
	_done = true
	_log("RESULT %s  wave %d/%d  kills %d  level %d  time %.0fs" % ["WIN" if won else "LOSS", director.run.index + 1, director.run.wave_count(), enemies.kills, loot.level, _time])
	var file: FileAccess = FileAccess.open(RESULT_FILE, FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(_lines) + "\n")
	get_tree().quit()


func _log(line: String) -> void:
	_lines.append(line)
	print("AUTOPLAY ", line)
