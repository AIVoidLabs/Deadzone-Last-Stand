extends Node
## Oyun akışı ve duraklatma tek yerden. get_tree().paused'a yalnız burası dokunur.

signal game_over_started
signal run_started

enum State { PLAYING, GAME_OVER }

var state: State = State.PLAYING


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(input_event: InputEvent) -> void:
	if state == State.GAME_OVER and input_event.is_action_pressed("restart"):
		restart()


func game_over() -> void:
	if state == State.GAME_OVER:
		return
	state = State.GAME_OVER
	get_tree().paused = true
	game_over_started.emit()


func restart() -> void:
	state = State.PLAYING
	get_tree().paused = false
	get_tree().reload_current_scene()
	run_started.emit()
