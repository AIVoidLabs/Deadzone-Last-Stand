extends Node
## Pencere ve görüntü ayarları: kip (tam ekran / çerçevesiz / pencere), çözünürlük, dikey eşitleme, FPS sınırı, 3D çözünürlük.
## Değerler Settings'ten gelir (display/*) ve değişince canlı uygulanır; F11 / Alt+Enter tam ekran <-> pencere arası geçer.
## Tam ekran başlangıcı Tuning.FEATURE_START_FULLSCREEN ile Settings varsayılanından gelir.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Settings.changed.connect(_on_setting_changed)
	apply_all()


func _unhandled_input(input_event: InputEvent) -> void:
	if input_event.is_action_pressed(&"toggle_fullscreen"):
		set_fullscreen(not is_fullscreen())
		get_viewport().set_input_as_handled()


func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN


func set_fullscreen(value: bool) -> void:
	Settings.set_value(&"display/mode", &"fullscreen" if value else &"windowed")


func apply_all() -> void:
	_apply_mode()
	_apply_vsync()
	_apply_fps_cap()
	_apply_render_scale()


func _on_setting_changed(key: StringName, _value: Variant) -> void:
	match key:
		&"display/mode", &"display/resolution":
			_apply_mode()
		&"display/vsync":
			_apply_vsync()
		&"display/fps_cap":
			_apply_fps_cap()
		&"display/render_scale":
			_apply_render_scale()


func _apply_mode() -> void:
	if not _has_real_window():
		return
	var mode: StringName = Settings.get_value(&"display/mode")
	if mode == &"fullscreen":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if mode == &"borderless":
		var screen: int = DisplayServer.window_get_current_screen()
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		DisplayServer.window_set_size(DisplayServer.screen_get_size(screen))
		DisplayServer.window_set_position(DisplayServer.screen_get_position(screen))
		return
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	_apply_windowed_size()


## Pencere boyutu ayardakinden farklıysa değiştirir ve ekranın ortasına alır.
func _apply_windowed_size() -> void:
	var wanted: Vector2i = SettingsSchema.parse_resolution(Settings.get_value(&"display/resolution"))
	if DisplayServer.window_get_size() == wanted:
		return
	DisplayServer.window_set_size(wanted)
	var screen: int = DisplayServer.window_get_current_screen()
	var area: Rect2i = DisplayServer.screen_get_usable_rect(screen)
	DisplayServer.window_set_position(area.position + (area.size - wanted) / 2)


func _apply_vsync() -> void:
	if not _has_real_window():
		return
	var wanted: DisplayServer.VSyncMode = DisplayServer.VSYNC_ENABLED if Settings.get_value(&"display/vsync") else DisplayServer.VSYNC_DISABLED
	if DisplayServer.window_get_vsync_mode() != wanted:
		DisplayServer.window_set_vsync_mode(wanted)


func _apply_fps_cap() -> void:
	Engine.max_fps = int(Settings.get_value(&"display/fps_cap"))


func _apply_render_scale() -> void:
	var scale: float = Settings.get_value(&"display/render_scale")
	if not is_equal_approx(get_tree().root.scaling_3d_scale, scale):
		get_tree().root.scaling_3d_scale = scale


## Başsız çalışmada ve editörün içine gömülü oyun penceresinde pencere kipi değiştirilemez.
func _has_real_window() -> bool:
	return DisplayServer.get_name() != "headless" and not Engine.is_embedded_in_editor()
