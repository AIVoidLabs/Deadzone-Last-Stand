class_name Benchmark
extends Node
## Sürü ölçümü: `godot --path . -- --bench`. Asker ölümsüz ve daire çizerek yürür;
## her adımda zombi sayısı artar, FPS hedefin altına düşünce sonuç yazılıp çıkılır.
## Yalnız debug yapıda eklenir.
## Sabit sayı ölçümü: `-- --bench --bench-kind=tongue|walker --bench-count=40` → o türden count zombi askerin çevresine
## dizilir, ısınmadan sonra ortalama ve en kötü kare süresi `BENCH FIXED` satırında basılır.

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
var _fixed_kind: StringName = &""
var _fixed_count: int = 0
var _fixed_time: float = 0.0
var _fixed_sum: float = 0.0
var _fixed_worst: float = 0.0
var _fixed_frames: int = 0


static func requested() -> bool:
	return OS.get_cmdline_user_args().has("--bench")


## Ölçüm bayrağı: `--bench --bench-no-tongue` dil düğümü hiç oluşmaz; `--bench-no-tongue-mesh` halat çalışır ama ağ kurulmaz.
static func flag(flag_name: String) -> bool:
	return OS.is_debug_build() and OS.get_cmdline_user_args().has(flag_name)


func _ready() -> void:
	name = "Benchmark"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	player.god_mode = true
	player.use_input_override = true
	enemies.spawning_enabled = false
	_lines.append("Deadzone sürü ölçümü · profil %s · %s" % [Quality.current, Time.get_datetime_string_from_system()])
	_read_fixed_args()
	if _fixed_count > 0:
		_start_fixed()
		return
	_next_step()


func _process(delta: float) -> void:
	_angle += delta * Tuning.BENCH_TURN_RATE
	player.input_override = Vector2(-sin(_angle), cos(_angle))
	if _fixed_count > 0:
		_tick_fixed(delta)
		return
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


func _read_fixed_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--bench-kind="):
			_fixed_kind = StringName(arg.trim_prefix("--bench-kind="))
		elif arg.begins_with("--bench-count="):
			_fixed_count = arg.trim_prefix("--bench-count=").to_int()
	if _fixed_kind == &"":
		_fixed_kind = EnemyData.WALKER


func _start_fixed() -> void:
	for n in _fixed_count:
		var at: Vector2 = player.position_2d() + Vector2.from_angle(TAU * n / _fixed_count + 0.4) * Tuning.BENCH_FIXED_RING
		enemies.spawn(_fixed_kind, at)


func _tick_fixed(delta: float) -> void:
	_fixed_time += delta
	if _fixed_time > Tuning.BENCH_FIXED_WARMUP:
		_fixed_sum += delta
		_fixed_worst = maxf(_fixed_worst, delta)
		_fixed_frames += 1
	if _fixed_time < Tuning.BENCH_FIXED_WARMUP + Tuning.BENCH_FIXED_TIME:
		return
	var avg_ms: float = _fixed_sum / maxf(float(_fixed_frames), 1.0) * 1000.0
	print("BENCH FIXED kind=%s count=%d active=%d avg=%.3f ms fps=%.1f worst=%.2f ms frames=%d  TONGUE shots=%d hits=%d bites=%d" % [
		_fixed_kind, _fixed_count, enemies.active_count(), avg_ms, 1000.0 / maxf(avg_ms, 0.0001), _fixed_worst * 1000.0, _fixed_frames,
		enemies.tongue_shots, enemies.tongue_hits, enemies.tongue_bites])
	get_tree().quit()


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
