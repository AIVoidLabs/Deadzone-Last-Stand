class_name Benchmark
extends Node
## Sürü ölçümü: `godot --path . -- --bench`. Asker ölümsüz ve daire çizerek yürür;
## her adımda zombi sayısı artar, FPS hedefin altına düşünce sonuç yazılıp çıkılır.
## Yalnız debug yapıda eklenir.

const RESULT_PATH: String = "user://bench_result.txt"

var player: Player
var enemies: EnemyManager

var _target_count: int = 0
var _step_time: float = 0.0
var _frames: int = 0
var _measure_time: float = 0.0
var _angle: float = 0.0
var _fail_steps: int = 0
var _best_passing: int = 0
var _lines: PackedStringArray = PackedStringArray()


static func requested() -> bool:
	return OS.get_cmdline_user_args().has("--bench")


func _ready() -> void:
	name = "Benchmark"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	player.god_mode = true
	player.use_input_override = true
	enemies.spawning_enabled = false
	_lines.append("Deadzone sürü ölçümü · profil %s · %s" % [Quality.current, Time.get_datetime_string_from_system()])
	_next_step()


func _process(delta: float) -> void:
	_angle += delta * Tuning.BENCH_TURN_RATE
	player.input_override = Vector2(-sin(_angle), cos(_angle))
	_step_time += delta
	if _step_time > Tuning.BENCH_STEP_TIME - Tuning.BENCH_MEASURE_TIME:
		_frames += 1
		_measure_time += delta
	if _step_time < Tuning.BENCH_STEP_TIME:
		return
	var fps: float = _frames / maxf(_measure_time, 0.0001)
	var count: int = enemies.active_count()
	var line: String = "zombi %4d   fps %6.1f   kare %5.2f ms" % [count, fps, 1000.0 / maxf(fps, 0.0001)]
	print("BENCH ", line)
	_lines.append(line)
	if fps >= Tuning.BENCH_TARGET_FPS:
		_best_passing = maxi(_best_passing, count)
		_fail_steps = 0
	else:
		_fail_steps += 1
	if _fail_steps >= Tuning.BENCH_FAIL_STEPS or _target_count >= Tuning.BENCH_MAX_ENEMIES:
		_finish()
	else:
		_next_step()


func _next_step() -> void:
	_target_count += Tuning.BENCH_STEP_ENEMIES
	enemies.spawn_many(maxi(0, _target_count - enemies.active_count()))
	_step_time = 0.0
	_frames = 0
	_measure_time = 0.0


func _finish() -> void:
	var summary: String = "SONUÇ: %d FPS üstünde en çok %d zombi" % [int(Tuning.BENCH_TARGET_FPS), _best_passing]
	print("BENCH ", summary)
	_lines.append(summary)
	var file: FileAccess = FileAccess.open(RESULT_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(_lines) + "\n")
		file.close()
	get_tree().quit()
