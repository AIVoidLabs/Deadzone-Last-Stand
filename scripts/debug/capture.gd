class_name Capture
extends Node
## Ekran görüntüsü: `godot --path . -- --capture=build/shots/a.png [--capture-seconds=8]
## [--capture-spawn=150] [--autopilot] [--debug-panel] [--capture-dash=0.15]`. Yalnız debug yapıda eklenir.
## --capture-dash=S: görüntüden S saniye önce dash attırır.
## --capture-kill=S: görüntüden S saniye önce askeri öldürür (ölüm animasyonu denetimi).
## --camera-distance=M: kamera uzaklığını dener (karşılaştırma görüntüleri için).
## --weapons=N: toplam N silahla başlar (debug silahı eklenir).
## --levels=N: N seviye atlatır (kart seçimi dalga arasında açılır). --capture-pick: açılan kart ekranında 1'e basar. --wave=N: N. dalgadan başlar. --capture-wave-end=S: görüntüden S saniye önce dalgayı bitirir.
## --autopilot: asker ölümsüz, daire çizerek yürür. --god: asker ölümsüz ama yerinde durur.
## --capture-kind=runner|tank: --capture-spawn ile bu türden doğurur (varsayılan walker).
## --circle: asker (ölümsüz değil) daire çizerek yürür. --zigzag=S: S saniyede bir yön değiştirerek yürür.
## Sonda tür başına atılış istatistiği basılır (LUNGE starts/hits): koşucu kaçış ayarı denetimi.

var player: Player
var enemies: EnemyManager
var debug_panel: DebugPanel
var camera: FollowCamera
var weapons: WeaponRig
var director: SpawnDirector
var loot: RunLoot

var _out: String = ""
var _seconds: float = 6.0
var _spawn: int = 0
var _autopilot: bool = false
var _show_panel: bool = false
var _dash_lead: float = -1.0
var _kill_lead: float = -1.0
var _wave_end_lead: float = -1.0
var _merge_lead: float = -1.0
var _auto_pick: bool = false
## --capture-pick-key=Enter gibi: otomatik basılan tuş (varsayılan 1).
var _pick_key: Key = KEY_1
var _pick_wait: float = 0.0
var _time: float = 0.0
var _angle: float = 0.0
var _kind: StringName = EnemyData.WALKER
var _circle: bool = false
var _zigzag: float = 0.0


static func requested() -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			return true
	return false


func _ready() -> void:
	name = "Capture"
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			_out = arg.trim_prefix("--capture=")
		elif arg.begins_with("--capture-seconds="):
			_seconds = arg.trim_prefix("--capture-seconds=").to_float()
		elif arg.begins_with("--capture-spawn="):
			_spawn = arg.trim_prefix("--capture-spawn=").to_int()
		elif arg.begins_with("--capture-dash="):
			_dash_lead = arg.trim_prefix("--capture-dash=").to_float()
		elif arg.begins_with("--capture-kill="):
			_kill_lead = arg.trim_prefix("--capture-kill=").to_float()
		elif arg.begins_with("--camera-distance=") and camera != null:
			camera.set_distance(arg.trim_prefix("--camera-distance=").to_float())
		elif arg == "--autopilot":
			_autopilot = true
		elif arg.begins_with("--weapons="):
			for _i in arg.trim_prefix("--weapons=").to_int() - weapons.count():
				weapons.add_debug_weapon()
		elif arg.begins_with("--tiers="):
			weapons.debug_set_slots(arg.trim_prefix("--tiers="))
		elif arg == "--god":
			player.god_mode = true
		elif arg.begins_with("--capture-kind="):
			_kind = StringName(arg.trim_prefix("--capture-kind="))
		elif arg == "--circle":
			_circle = true
		elif arg.begins_with("--zigzag="):
			_zigzag = arg.trim_prefix("--zigzag=").to_float()
		elif arg == "--debug-panel":
			_show_panel = true
		elif arg == "--capture-pick":
			_auto_pick = true
		elif arg.begins_with("--levels="):
			for _i in arg.trim_prefix("--levels=").to_int():
				loot.add(RunLoot.xp_needed(loot.level) - loot.xp)
		elif arg.begins_with("--wave="):
			director.start_at.call_deferred(arg.trim_prefix("--wave=").to_int() - 1)
		elif arg.begins_with("--capture-pick-key="):
			_pick_key = OS.find_keycode_from_string(arg.trim_prefix("--capture-pick-key=")) as Key
		elif arg.begins_with("--crystals="):
			loot.crystals += arg.trim_prefix("--crystals=").to_int()
		elif arg.begins_with("--capture-merge="):
			_merge_lead = arg.trim_prefix("--capture-merge=").to_float()
		elif arg.begins_with("--capture-wave-end="):
			_wave_end_lead = arg.trim_prefix("--capture-wave-end=").to_float()
	if _autopilot:
		player.god_mode = true
		player.use_input_override = true
	if _circle or _zigzag > 0.0:
		player.use_input_override = true
	if _spawn > 0:
		enemies.spawn_many(_spawn, _kind)
	if _show_panel and debug_panel != null:
		debug_panel.set_panel_visible(true)


func _process(delta: float) -> void:
	if _autopilot:
		_angle += delta * Tuning.BENCH_TURN_RATE
		player.input_override = Vector2(-sin(_angle), cos(_angle))
	elif _circle:
		_angle += delta * Tuning.BENCH_TURN_RATE
		player.input_override = Vector2(-sin(_angle), cos(_angle))
	elif _zigzag > 0.0:
		player.input_override = Vector2(1.0, 0.0) if int(_time / _zigzag) % 2 == 0 else Vector2(-1.0, 0.0)
	_time += delta
	if _dash_lead >= 0.0 and _time >= _seconds - _dash_lead:
		_dash_lead = -1.0
		player.request_dash()
	if _kill_lead >= 0.0 and _time >= _seconds - _kill_lead:
		_kill_lead = -1.0
		player.take_hit(Tuning.PLAYER_MAX_HP * 1000.0)
	if _merge_lead >= 0.0 and _time >= _seconds - _merge_lead:
		_merge_lead = -1.0
		weapons.add_weapon(WeaponData.PISTOL)
	if _wave_end_lead >= 0.0 and _time >= _seconds - _wave_end_lead:
		_wave_end_lead = -1.0
		director.end_wave()
	if _auto_pick:
		_tick_auto_pick(delta)
	if _time < _seconds:
		return
	print("LUNGE starts=%d hits=%d" % [enemies.lunge_starts, enemies.lunge_hits])
	var image: Image = get_viewport().get_texture().get_image()
	if image != null:
		var path: String = ProjectSettings.globalize_path("res://").path_join(_out)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		image.save_png(path)
		print("CAPTURE ", _out)
	get_tree().quit()


## Oyun menü için durunca (kart ekranı) kısa aralıklarla 1 tuşuna basar.
func _tick_auto_pick(delta: float) -> void:
	if not get_tree().paused:
		_pick_wait = Tuning.CAPTURE_PICK_DELAY
		return
	_pick_wait -= delta
	if _pick_wait > 0.0:
		return
	_pick_wait = Tuning.CAPTURE_PICK_DELAY
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = _pick_key
	key.pressed = true
	Input.parse_input_event(key)
