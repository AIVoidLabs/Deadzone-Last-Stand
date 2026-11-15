extends Node
## Pencere modu: oyun tam ekran açılır; F11 veya Alt+Enter ile pencere/tam ekran arası geçilir.
## Tek sabitle kapanır: Tuning.FEATURE_START_FULLSCREEN.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Tuning.FEATURE_START_FULLSCREEN and _has_real_window():
		set_fullscreen(true)


func _unhandled_input(input_event: InputEvent) -> void:
	if input_event.is_action_pressed(&"toggle_fullscreen"):
		set_fullscreen(not is_fullscreen())
		get_viewport().set_input_as_handled()


func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN


func set_fullscreen(value: bool) -> void:
	if not _has_real_window():
		return
	var mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


func _has_real_window() -> bool:
	return DisplayServer.get_name() != "headless"
