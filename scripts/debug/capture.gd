class_name Capture
extends Node
## Ekran görüntüsü: `godot --path . -- --capture=build/shots/a.png [--capture-seconds=8]
## [--capture-spawn=150] [--autopilot] [--debug-panel] [--capture-dash=0.15]`. Yalnız debug yapıda eklenir.
## --capture-dash=S: görüntüden S saniye önce dash attırır.
## --capture-kill=S: görüntüden S saniye önce askeri öldürür (ölüm animasyonu denetimi).
## --capture-focus: kamera ilk canlı zombiyi izler (arena ile yakın görüntü).
## --camera-fov=DEG: kamera görüş açısını dener (lens karşılaştırması).
## --camera-distance=M: kamera uzaklığını dener (karşılaştırma görüntüleri için).
## --weapons=N: toplam N silahla başlar (debug silahı eklenir). --no-weapons: silahlar ateş etmez (saldırı ölçümü).
## --levels=N: N seviye atlatır (kart seçimi dalga arasında açılır). --capture-pick: açılan kart ekranında 1'e basar. --wave=N: N. dalgadan başlar. --capture-wave-end=S: görüntüden S saniye önce dalgayı bitirir.
## --capture-player=x,z: askeri bu konuma koyar (köşe bina görüntüsü için).
## --autopilot: asker ölümsüz, daire çizerek yürür. --god: asker ölümsüz ama yerinde durur.
## --capture-kind=<tür id> (runner, tank, spitter, thrower ...): --capture-spawn ile bu türden doğurur (varsayılan walker).
## --capture-root=S: görüntüden S saniye önce askeri 1 sn bağlar (S<1: çırpınma, S 1.1–1.4: kurtulma karesi).
## --capture-near=M: --capture-spawn zombilerini askerin M metre çevresine dizer (özel saldırıları hızlı görmek için).
## --capture-boss=S: S sn sonra boss Yığın'ı hemen doğurur (--capture-near ile o mesafede). Sonda BOSS satırı sayaçları.
## --circle: asker (ölümsüz değil) daire çizerek yürür. --zigzag=S: S saniyede bir yön değiştirerek yürür.
## Sonda tür başına atılış istatistiği basılır (LUNGE starts/hits): koşucu kaçış ayarı denetimi; SPIT/THROW satırı yay atışı sayaçları.

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
var _root_lead: float = -1.0
var _near: float = 0.0
var _zigzag: float = 0.0
## --capture-boss: boss'un doğacağı an (sn; < 0 yok) ve öldüğü an (< 0 henüz yaşıyor).
var _boss_at: float = -1.0
var _boss_died_at: float = -1.0
## --capture-focus: kamera ilk canlı zombiyi izler (yakın görüntü).
var _focus: Node3D


static func requested() -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			return true
	return false


## Komut satırı kullanıcı argümanından sayı okur; yoksa varsayılan.
func _arg_float(prefix: String, fallback: float) -> float:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix).to_float()
	return fallback


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
		elif arg.begins_with("--camera-fov=") and camera != null:
			camera.fov = arg.trim_prefix("--camera-fov=").to_float()
		elif arg.begins_with("--camera-pitch=") and camera != null:
			camera.set_pitch(arg.trim_prefix("--camera-pitch=").to_float(), _arg_float("--camera-distance=", Tuning.CAMERA_DISTANCE))
		elif arg == "--autopilot":
			_autopilot = true
		elif arg.begins_with("--capture-player="):
			var xz: PackedStringArray = arg.trim_prefix("--capture-player=").split(",")
			if xz.size() == 2:
				player.global_position = Vector3(xz[0].to_float(), 0.0, xz[1].to_float())
		elif arg == "--no-weapons":
			weapons.process_mode = Node.PROCESS_MODE_DISABLED
		elif arg.begins_with("--weapons="):
			for _i in arg.trim_prefix("--weapons=").to_int() - weapons.count():
				weapons.add_debug_weapon()
		elif arg.begins_with("--tiers="):
			weapons.debug_set_slots(arg.trim_prefix("--tiers="))
		elif arg == "--god":
			player.god_mode = true
		elif arg.begins_with("--capture-kind="):
			_kind = StringName(arg.trim_prefix("--capture-kind="))
		elif arg.begins_with("--capture-root="):
			_root_lead = arg.trim_prefix("--capture-root=").to_float()
		elif arg.begins_with("--capture-near="):
			_near = arg.trim_prefix("--capture-near=").to_float()
		elif arg == "--capture-focus" and camera != null:
			_focus = Node3D.new()
			add_child(_focus)
			camera.target = _focus
		elif arg == "--circle":
			_circle = true
		elif arg.begins_with("--capture-boss="):
			_boss_at = arg.trim_prefix("--capture-boss=").to_float()
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
	if _spawn > 0 and _near > 0.0:
		for n in _spawn:
			var at: Vector2 = player.position_2d() + Vector2.from_angle(TAU * n / _spawn + 0.4) * _near
			enemies.spawn(_kind, at)
	elif _spawn > 0:
		enemies.spawn_many(_spawn, _kind)
	if _show_panel and debug_panel != null:
		debug_panel.set_panel_visible(true)
	enemies.enemy_killed.connect(func(_at: Vector3, row: Dictionary) -> void:
		if row.get("boss", false):
			_boss_died_at = _time)


func _process(delta: float) -> void:
	if _autopilot:
		_angle += delta * Tuning.BENCH_TURN_RATE
		player.input_override = Vector2(-sin(_angle), cos(_angle))
	elif _circle:
		_angle += delta * Tuning.BENCH_TURN_RATE
		player.input_override = Vector2(-sin(_angle), cos(_angle))
	elif _zigzag > 0.0:
		player.input_override = Vector2(1.0, 0.0) if int(_time / _zigzag) % 2 == 0 else Vector2(-1.0, 0.0)
	if _focus != null:
		var index: int = enemies.debug_alive_index()
		if index >= 0:
			var at: Vector2 = enemies.enemy_position(index)
			_focus.global_position = Vector3(at.x, 0.9, at.y)
	_time += delta
	if _dash_lead >= 0.0 and _time >= _seconds - _dash_lead:
		_dash_lead = -1.0
		player.request_dash()
	if _root_lead >= 0.0 and _time >= _seconds - _root_lead:
		_root_lead = -1.0
		player.root(1.0)
	if _kill_lead >= 0.0 and _time >= _seconds - _kill_lead:
		_kill_lead = -1.0
		player.take_hit(Tuning.PLAYER_MAX_HP * 1000.0)
	if _merge_lead >= 0.0 and _time >= _seconds - _merge_lead:
		_merge_lead = -1.0
		weapons.add_weapon(WeaponData.PISTOL)
	if _wave_end_lead >= 0.0 and _time >= _seconds - _wave_end_lead:
		_wave_end_lead = -1.0
		director.end_wave()
	if _boss_at >= 0.0 and _time >= _boss_at:
		_boss_at = -1.0
		_spawn_boss()
	if _auto_pick:
		_tick_auto_pick(delta)
	if _time < _seconds:
		return
	print("%s starts=%d hits=%d  JUMP lands=%d hits=%d  TONGUE shots=%d hits=%d bites=%d timeouts=%d melee=%d" % [
		"SPRINT(strike)" if Tuning.FEATURE_RUNNER_SPRINT else "LUNGE", enemies.lunge_starts, enemies.lunge_hits, enemies.jump_lands, enemies.jump_hits, enemies.tongue_shots, enemies.tongue_hits,
		enemies.tongue_bites, enemies.tongue_timeouts, enemies.tongue_melees])
	print("ARMOR front=%d back=%d" % [enemies.armor_front, enemies.armor_back])
	print("BLOAT primed=%d exploded=%d chain=%d player_hits=%d" % [enemies.bloat_primed, enemies.bloat_exploded_count, enemies.bloat_chains, enemies.bloat_player_hits])
	print("SCREAM screams=%d summoned=%d" % [enemies.screams, enemies.summoned])
	var boss: BossAttack = enemies.boss()
	var status: Dictionary = boss.status()
	print("BOSS slams=%d ring_hits=%d center_hits=%d charges=%d charge_hits=%d stuns=%d summons=%d rage=%d alive=%s hp=%d died_at=%.1f" % [
		boss.slams, boss.ring_hits, boss.center_hits, boss.charges, boss.charge_hits, boss.stuns, boss.summons, boss.rage_count,
		status["alive"], int(status.get("hp", 0.0)), _boss_died_at])
	if director.run != null:
		print("RUN wave=%d phase=%s boss_stage=%s phase_left=%.1f kills=%d" % [director.run.index + 1, WaveRun.Phase.keys()[director.run.phase],
			WaveRun.BossStage.keys()[director.run.boss_stage], director.run.phase_left, enemies.kills])
	print("SPIT shots=%d pools=%d ticks=%d  THROW shots=%d hits=%d melee=%d" % [
		enemies.spit_shots, enemies.spit_pools, enemies.spit_ticks, enemies.throw_shots, enemies.throw_hits, enemies.throw_melees])
	# Headless (dummy renderer) görüntü dokusu yoktur; get_image "Parameter t is null" hatası basar.
	var image: Image = null if DisplayServer.get_name() == "headless" else get_viewport().get_texture().get_image()
	if image != null:
		var path: String = ProjectSettings.globalize_path("res://").path_join(_out)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		image.save_png(path)
		print("CAPTURE ", _out)
	get_tree().quit()


func _spawn_boss() -> void:
	var at: Vector2 = enemies.pick_spawn_point()
	if _near > 0.0:
		at = player.position_2d() + Vector2.from_angle(0.4) * _near
	director.debug_spawn_boss(at)


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
