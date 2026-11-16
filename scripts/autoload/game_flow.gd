extends Node
## Oyun akışı ve duraklatma tek yerden. get_tree().paused'a yalnız burası dokunur.

signal game_over_started
signal run_started

enum State { PLAYING, GAME_OVER }

var state: State = State.PLAYING
## Bekleme sırasında yeniden başlatılırsa eski bekleyişi geçersiz kılar.
var _run_id: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(input_event: InputEvent) -> void:
	if state == State.GAME_OVER and input_event.is_action_pressed("restart"):
		restart()


func game_over() -> void:
	if state == State.GAME_OVER:
		return
	state = State.GAME_OVER
	_run_id += 1
	if Tuning.GAME_OVER_DELAY > 0.0:
		# Ölüm animasyonu oynasın diye dünya kısa süre akmaya devam eder.
		var run: int = _run_id
		await get_tree().create_timer(Tuning.GAME_OVER_DELAY).timeout
		if run != _run_id or state != State.GAME_OVER:
			return
	get_tree().paused = true
	game_over_started.emit()


func restart() -> void:
	state = State.PLAYING
	_run_id += 1
	get_tree().paused = false
	get_tree().reload_current_scene()
	run_started.emit()
