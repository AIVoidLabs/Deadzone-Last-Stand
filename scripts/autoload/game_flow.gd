extends Node
## Oyun akışı ve duraklatma tek yerden. get_tree().paused'a yalnız burası dokunur.
## Duraklatma nedenleri kümesi: &"menu" (kart/mağaza), &"pause" (duraklatma menüsü), &"end" (tur sonu).
## Sahne geçişleri (menü <-> oyun, yeniden başlatma) SceneFade ile yapılır.

signal game_over_started
signal victory_started
signal run_started
## Neden kümesi değişince yayılır; paused: ağaç şu an duruyor mu.
signal paused_changed(paused: bool)

enum State { PLAYING, GAME_OVER, VICTORY, MENU }

const MAIN_SCENE: String = "res://scenes/main.tscn"
const MENU_SCENE: String = "res://scenes/main_menu.tscn"
const REASON_MENU: StringName = &"menu"
const REASON_PAUSE: StringName = &"pause"
const REASON_END: StringName = &"end"

var state: State = State.PLAYING
## Tur sayaçları (main.gd her turda yeni bir tane atar).
var run_stats: RunStats = RunStats.new()
## Son biten turun özeti ve kırdığı rekorlar (son ekran buradan okur; main.gd tur bitince doldurur).
var last_summary: Dictionary = {}
var last_new_records: Array[StringName] = []

## Bekleme sırasında yeniden başlatılırsa eski bekleyişi geçersiz kılar.
var _run_id: int = 0
var _reasons: PauseReasons = PauseReasons.new()
var _transitioning: bool = false
var _hit_stop: HitStop = HitStop.new(Tuning.HIT_STOP_COOLDOWN)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if Engine.time_scale != 1.0 and not _hit_stop.is_active(_now()):
		Engine.time_scale = 1.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and _focus_pause_wanted():
		pause()


func _focus_pause_wanted() -> bool:
	return Tuning.FEATURE_PAUSE_MENU and not Settings.measurement and Settings.get_value(&"game/pause_on_focus_loss")


## Vuruş duraksaması: oyun kısa süre yavaşlar (gerçek zamanla ölçülür). Engine.time_scale'e yalnız burası dokunur.
## force: FEATURE_HIT_STOP kapalıyken de uygular (boss ölümü, FEATURE_BOSS_HITSTOP).
func hit_stop(duration: float, force: bool = false) -> void:
	if not (Tuning.FEATURE_HIT_STOP or force) or state != State.PLAYING:
		return
	if _hit_stop.request(_now(), duration):
		Engine.time_scale = Tuning.HIT_STOP_TIME_SCALE


func _now() -> float:
	return Time.get_ticks_usec() / 1000000.0


func _clear_hit_stop() -> void:
	_hit_stop.reset()
	Engine.time_scale = 1.0


func _unhandled_input(input_event: InputEvent) -> void:
	if input_event.is_action_pressed(&"pause") and Tuning.FEATURE_PAUSE_MENU:
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif (state == State.GAME_OVER or state == State.VICTORY) and input_event.is_action_pressed(&"restart"):
		restart()


# --- Duraklatma ---

## Ağaç durmuş mu (herhangi bir nedenle).
func is_paused() -> bool:
	return _reasons.is_paused()


func is_paused_by(reason: StringName) -> bool:
	return _reasons.has(reason)


## Duraklatma menüsü: oyun sırasında açılır (kart/mağaza açıkken de; kapanınca o ekran durmaya devam eder).
func pause() -> void:
	if state != State.PLAYING or _reasons.has(REASON_PAUSE) or _reasons.has(REASON_END) or _transitioning:
		return
	_set_reason(REASON_PAUSE, true)


func resume() -> void:
	# Sahne geçişi sürerken devam ettirme: dünya geçiş bitene dek duraklı kalır.
	if _transitioning:
		return
	_set_reason(REASON_PAUSE, false)


func toggle_pause() -> void:
	if is_paused_by(REASON_PAUSE):
		resume()
	else:
		pause()


## Oyun içi menü (kart seçimi, mağaza): dünya durur, menü ALWAYS düğümünde çalışır.
func open_menu() -> void:
	if state == State.PLAYING:
		_set_reason(REASON_MENU, true)


func close_menu() -> void:
	if state == State.PLAYING:
		_set_reason(REASON_MENU, false)


func _set_reason(reason: StringName, on: bool) -> void:
	var changed: bool = _reasons.add(reason) if on else _reasons.remove(reason)
	if changed:
		_apply_pause()


func _apply_pause() -> void:
	var paused: bool = _reasons.is_paused()
	get_tree().paused = paused
	paused_changed.emit(paused)


# --- Tur sonu ---

func game_over() -> void:
	if state == State.GAME_OVER:
		return
	state = State.GAME_OVER
	# Ölüm animasyonu oynasın diye dünya kısa süre akmaya devam eder.
	_end_run(Tuning.GAME_OVER_DELAY, game_over_started)


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
	# Duraklatma menüsü açıksa kapanır (tur bitti).
	_reasons.remove(REASON_PAUSE)
	if delay > 0.0:
		var run: int = _run_id
		await get_tree().create_timer(delay).timeout
		if run != _run_id or state != ending:
			return
	_set_reason(REASON_END, true)
	done.emit()


# --- Sahne geçişleri ---

## Yeni tur: ana sahneyi yükler.
func start_run() -> void:
	_go(func() -> void: get_tree().change_scene_to_file(MAIN_SCENE), State.PLAYING)


## Aynı turu baştan başlatır (sahneyi yeniden yükler).
func restart() -> void:
	_go(func() -> void: get_tree().reload_current_scene(), State.PLAYING)


## Ana menüye döner (ana menü kapalıysa yeni tur başlar).
func to_main_menu() -> void:
	if not Tuning.FEATURE_MAIN_MENU:
		restart()
		return
	_go(func() -> void: get_tree().change_scene_to_file(MENU_SCENE), State.MENU)


func quit_game() -> void:
	Settings.flush()
	if not Tuning.FEATURE_SCENE_FADE or _transitioning:
		get_tree().quit()
		return
	_transitioning = true
	await SceneFade.transition(func() -> void: get_tree().quit())


## Geçiş sırasında dünya duraklı kalır; sahne değişince durum ve nedenler sıfırlanır.
func _go(change: Callable, next_state: State) -> void:
	if _transitioning:
		return
	_transitioning = true
	_run_id += 1
	_clear_hit_stop()
	state = next_state
	var swap: Callable = func() -> void:
		_reasons.clear()
		get_tree().paused = false
		paused_changed.emit(false)
		change.call()
	await SceneFade.transition(swap)
	_transitioning = false
	if next_state == State.PLAYING:
		run_started.emit()
