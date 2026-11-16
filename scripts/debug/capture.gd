class_name Capture
extends Node
## Ekran görüntüsü: `godot --path . -- --capture=build/shots/a.png [--capture-seconds=8]
## [--capture-spawn=150] [--autopilot] [--debug-panel] [--capture-dash=0.15]`. Yalnız debug yapıda eklenir.
## --capture-dash=S: görüntüden S saniye önce dash attırır.
## --camera-distance=M: kamera uzaklığını dener (karşılaştırma görüntüleri için).
## --autopilot: asker ölümsüz, daire çizerek yürür.

var player: Player
var enemies: EnemyManager
var debug_panel: DebugPanel
var camera: FollowCamera

var _out: String = ""
var _seconds: float = 6.0
var _spawn: int = 0
var _autopilot: bool = false
var _show_panel: bool = false
var _dash_lead: float = -1.0
var _time: float = 0.0
var _angle: float = 0.0


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
		elif arg.begins_with("--camera-distance=") and camera != null:
			camera.set_distance(arg.trim_prefix("--camera-distance=").to_float())
		elif arg == "--autopilot":
			_autopilot = true
		elif arg == "--debug-panel":
			_show_panel = true
	if _autopilot:
		player.god_mode = true
		player.use_input_override = true
	if _spawn > 0:
		enemies.spawn_many(_spawn)
	if _show_panel and debug_panel != null:
		debug_panel.set_panel_visible(true)


func _process(delta: float) -> void:
	if _autopilot:
		_angle += delta * Tuning.BENCH_TURN_RATE
		player.input_override = Vector2(-sin(_angle), cos(_angle))
	_time += delta
	if _dash_lead >= 0.0 and _time >= _seconds - _dash_lead:
		_dash_lead = -1.0
		player.request_dash()
	if _time < _seconds:
		return
	var path: String = ProjectSettings.globalize_path("res://").path_join(_out)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURE ", _out)
	get_tree().quit()
