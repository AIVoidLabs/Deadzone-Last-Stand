extends Node
## Oyun akışı ve duraklatma tek yerden. get_tree().paused'a yalnız burası dokunur.

signal game_over_started
signal victory_started
signal run_started

enum State { PLAYING, GAME_OVER, VICTORY }

var state: State = State.PLAYING
## Bekleme sırasında yeniden başlatılırsa eski bekleyişi geçersiz kılar.
var _run_id: int = 0
var _hit_stop: HitStop = HitStop.new(Tuning.HIT_STOP_COOLDOWN)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if Engine.time_scale != 1.0 and not _hit_stop.is_active(_now()):
		Engine.time_scale = 1.0


## Vuruş duraksaması: oyun kısa süre yavaşlar (gerçek zamanla ölçülür). Engine.time_scale'e yalnız burası dokunur.
func hit_stop(duration: float) -> void:
	if not Tuning.FEATURE_HIT_STOP or state != State.PLAYING:
		return
	if _hit_stop.request(_now(), duration):
		Engine.time_scale = Tuning.HIT_STOP_TIME_SCALE


func _now() -> float:
	return Time.get_ticks_usec() / 1000000.0


func _clear_hit_stop() -> void:
	_hit_stop.reset()
	Engine.time_scale = 1.0


func _unhandled_input(input_event: InputEvent) -> void:
	if state != State.PLAYING and input_event.is_action_pressed("restart"):
		restart()


func game_over() -> void:
	if state == State.GAME_OVER:
		return
	state = State.GAME_OVER
	# Ölüm animasyonu oynasın diye dünya kısa süre akmaya devam eder.
	_end_run(Tuning.GAME_OVER_DELAY, game_over_started)


## Oyun içi menü (kart seçimi, ileride mağaza): dünya durur, menü ALWAYS düğümünde çalışır.
func open_menu() -> void:
	if state == State.PLAYING:
		get_tree().paused = true


func close_menu() -> void:
	if state == State.PLAYING:
		get_tree().paused = false


## Son dalga temizlendi: oyun durur, "hayatta kaldın" ekranı.
func victory() -> void:
	if state != State.PLAYING:
		return
	state = State.VICTORY
	# Son zombiler devrilip bitsin diye dünya kısa süre akmaya devam eder.
	_end_run(Tuning.VICTORY_DELAY, victory_started)


## delay saniye sonra oyunu durdurur ve done'ı yayar; arada yeniden başlatılırsa vazgeçer.
func _end_run(delay: float, done: Signal) -> void:
	var ending: State = state
	_run_id += 1
	_clear_hit_stop()
	if delay > 0.0:
		var run: int = _run_id
		await get_tree().create_timer(delay).timeout
		if run != _run_id or state != ending:
			return
	get_tree().paused = true
	done.emit()


func restart() -> void:
	state = State.PLAYING
	_run_id += 1
	_clear_hit_stop()
	get_tree().paused = false
	get_tree().reload_current_scene()
	run_started.emit()
