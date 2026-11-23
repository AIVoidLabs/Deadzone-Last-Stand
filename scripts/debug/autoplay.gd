class_name Autoplay
extends Node
## Debug: botla tam turu baştan sona oynar ve dalga başına rapor yazar (denge ölçümü, 6.6).
## Bot zombilerden kaçar, yaklaşınca dash atar, kart seçer (1) ve mağazada elindeki parayla alır.
## Çalıştırma: godot --headless --path . --fixed-fps 60 -- --autoplay [--autoplay-weapons=4] [--autoplay-crystals=N] [--autoplay-strategy=default|guns|melee|tank] [--autoplay-out=ad]
## Ölümsüz değildir; zorluğun kaba göstergesi olarak ölürse hangi dalgada öldüğünü raporlar.

const FLEE_RANGE: float = 7.0
const DASH_RANGE: float = 1.6
const CENTER_PULL: float = 1.4
const KEY_DELAY: float = 0.1
const MAX_RUN_TIME: float = 900.0 # 10 dalga ~8 dk + aralar
const RESULT_FILE_DEFAULT: String = "autoplay_result"

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
var _wave_min_hp: float = 1.0
var _strategy: AutoplayStrategy = AutoplayStrategy.new()
var _wave_start_kills: int = 0
var _wave_start_crystals: int = 0
var _wave_start_spawns: Dictionary = {}
var _wave_started_at: float = 0.0
var _time: float = 0.0
var _done: bool = false
var _out_name: String = RESULT_FILE_DEFAULT


static func requested() -> bool:
	return OS.get_cmdline_user_args().has("--autoplay")


func _ready() -> void:
	name = "Autoplay"
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--autoplay-weapons="):
			_max_weapons = arg.trim_prefix("--autoplay-weapons=").to_int()
		elif arg.begins_with("--autoplay-out="):
			_out_name = arg.trim_prefix("--autoplay-out=").get_file().validate_filename()
		elif arg.begins_with("--autoplay-crystals="):
			loot.crystals += arg.trim_prefix("--autoplay-crystals=").to_int()
	_strategy = AutoplayStrategy.from_args()
	player.use_input_override = true
	_last_hp = player.health.current
	director.phase_changed.connect(_on_phase)
	GameFlow.game_over_started.connect(_finish.bind("LOSS"))
	GameFlow.victory_started.connect(_finish.bind("WIN"))


func _physics_process(delta: float) -> void:
	_time += delta
	if _done:
		return
	if player.health.current < _last_hp:
		_damage_taken += _last_hp - player.health.current
	_last_hp = player.health.current
	_wave_min_hp = minf(_wave_min_hp, player.health.current / maxf(player.health.maximum, 1.0))
	_steer()
	if _time > MAX_RUN_TIME:
		_log("TAKILDI faz %s kalan %.1f hold %s duraklatildi %s magaza %s bekleyen_seviye %d kristal_yerde %d" % [
			WaveRun.Phase.keys()[director.run.phase], director.run.phase_left, director.hold_break, get_tree().paused,
			shop.is_open(), loot.pending_levels, shop.pickups.count() if shop.pickups != null else -1])
		_finish("STUCK")


func _process(delta: float) -> void:
	if _done or not get_tree().paused:
		_key_wait = KEY_DELAY
		return
	if shop.is_open():
		if _strategy.is_default():
			shop.debug_autobuy(_max_weapons)
		else:
			_strategy_buy()
		return
	_key_wait -= delta
	if _key_wait > 0.0:
		return
	_key_wait = KEY_DELAY
	if not _strategy.is_default() and shop.level_up != null and shop.level_up.debug_is_open():
		shop.level_up.debug_choose(_strategy.best_card(shop.level_up.debug_offer()))
		return
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
		_wave_start_spawns = enemies.spawn_counts().duplicate()
		_wave_started_at = _time
		_damage_taken = 0.0
		_wave_min_hp = player.health.current / maxf(player.health.maximum, 1.0)
	elif phase == WaveRun.Phase.CLEAR:
		_report_wave(wave_index)


func _report_wave(wave_index: int, died: bool = false) -> void:
	var slots: PackedStringArray = PackedStringArray()
	for slot: Dictionary in weapons.slot_list():
		slots.append("%s%d" % [String(slot["id"]).substr(0, 1).to_upper(), slot["tier"]])
	var line: String = "WAVE %d  kills %d  crystals +%d (total %d)  damage_taken %d  hp %d/%d  level %d  weapons [%s]  alive_at_end %d  %.0fs  min_hp_pct %d" % [
		wave_index + 1, enemies.kills - _wave_start_kills, loot.crystals - _wave_start_crystals, loot.crystals,
		roundi(_damage_taken), roundi(player.health.current), roundi(player.health.maximum), loot.level,
		" ".join(slots), enemies.active_count(), _time - _wave_started_at, roundi(_wave_min_hp * 100.0),
	]
	if died:
		line += "  died"
	_log(line)
	_log("  SPAWNS %d: %s" % [wave_index + 1, _spawn_summary()])


## Dalgada doğan türler (tür:sayı); yeni türlerin dalga karışımında doğduğunu gösterir.
func _spawn_summary() -> String:
	var parts: PackedStringArray = PackedStringArray()
	var now: Dictionary = enemies.spawn_counts()
	for kind: StringName in now:
		parts.append("%s:%d" % [kind, int(now[kind]) - int(_wave_start_spawns.get(kind, 0))])
	return " ".join(parts)


## Strateji alışverişi: en yüksek puanlı alınabilir teklifi (puan > 0) sırayla alır, sonra mağazayı kapatır.
func _strategy_buy() -> void:
	while true:
		var best: int = -1
		var best_score: float = 0.0
		var offer: Array[Dictionary] = shop.debug_offer()
		for i: int in offer.size():
			var entry: Dictionary = offer[i]
			if shop.debug_state_of(entry) != "ok":
				continue
			var is_weapon: bool = entry["kind"] == ShopRules.WEAPON
			if is_weapon and weapons.count() >= _max_weapons and not weapons.preview_add(entry["id"])["merged"]:
				continue
			var score: float = _strategy.weapon_score(entry["id"]) if is_weapon else _strategy.item_score(entry["id"])
			if score > best_score:
				best = i
				best_score = score
		if best < 0:
			break
		shop.debug_buy(best)
	shop.debug_close()


## Alınan eşyalar: id:adet listesi.
func _items_text() -> String:
	var parts: PackedStringArray = PackedStringArray()
	var owned: Dictionary = shop.debug_owned()
	for id: StringName in owned:
		parts.append("%s:%d" % [id, owned[id]])
	return ",".join(parts) if not parts.is_empty() else "-"


func _finish(result: String) -> void:
	if _done:
		return
	if result == "LOSS" and director.run.phase == WaveRun.Phase.WAVE:
		_report_wave(director.run.index, true)
	_done = true
	_log("RESULT %s  wave %d/%d  kills %d  level %d  time %.0fs  strategy %s  items %s" % [result, director.run.index + 1, director.run.wave_count(), enemies.kills, loot.level, _time, _strategy.name, _items_text()])
	var file: FileAccess = FileAccess.open("user://%s.txt" % _out_name, FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(_lines) + "\n")
	get_tree().quit()


func _log(line: String) -> void:
	_lines.append(line)
	print("AUTOPLAY ", line)
