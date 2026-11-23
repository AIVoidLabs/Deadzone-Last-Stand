class_name KeyBindRow
extends SettingRowBase
## Tuş atama satırı: solda eylem adı, sağda tuş başlığı. Enter / tık: tuş beklenir, Esc iptal eder.
## Sonuç Settings.rebind ile işlenir (çakışmada takas). Beklerken tuşlar bu satırda tüketilir (Esc duraklatmaz).

signal bound(action: StringName, swapped: StringName)
signal rejected(action: StringName)
signal cancelled(action: StringName)

const CAP_SIZE: Vector2 = Vector2(150, 32)
const CAP_FONT: int = 17
const WAIT_BLINK: float = 0.5

var action: StringName = &""
var _listening: bool = false


func _init() -> void:
	super._init()
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_entered.connect(_refresh)
	focus_exited.connect(_on_focus_exited)
	set_process_input(false)


func setup(action_id: StringName, label_text: String) -> void:
	action = action_id
	set_label(label_text)
	queue_redraw()


func refresh_label(label_text: String) -> void:
	set_label(label_text)
	queue_redraw()


func is_listening() -> bool:
	return _listening


func _has_focus_inside() -> bool:
	return has_focus() or _listening


func start_listening() -> void:
	_listening = true
	set_process_input(true)
	UiSounds.play(UiSoundData.CLICK)
	queue_redraw()


func stop_listening() -> void:
	_listening = false
	set_process_input(false)
	queue_redraw()


func _on_focus_exited() -> void:
	if _listening:
		stop_listening()
		cancelled.emit(action)
	_refresh()


func _gui_input(event: InputEvent) -> void:
	if _listening:
		return
	var hit: bool = event.is_action_pressed("ui_accept")
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		hit = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if hit:
		start_listening()
		accept_event()


## Bekleme: ilk tuş ya da fare tıklaması karar verir. Hepsi tüketilir.
func _input(event: InputEvent) -> void:
	if not _listening:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		stop_listening()
		cancelled.emit(action)
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey):
		return
	var key: InputEventKey = event
	get_viewport().set_input_as_handled()
	if not key.pressed or key.echo:
		return
	var code: int = key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	stop_listening()
	if code == KEY_ESCAPE:
		cancelled.emit(action)
		return
	var result: Dictionary = Settings.rebind(action, code)
	if result["ok"]:
		bound.emit(action, result["swapped"])
	else:
		rejected.emit(action)
	queue_redraw()


func _draw() -> void:
	super._draw()
	var cap: Rect2 = Rect2(Vector2(size.x - SettingRowBase.SIDE_PAD - CAP_SIZE.x, (size.y - CAP_SIZE.y) * 0.5), CAP_SIZE)
	var edge: Color = UiPalette.EMBER if _listening else Color(UiPalette.ASH, 0.55)
	draw_rect(cap, Color(0.03, 0.025, 0.022, 0.95))
	draw_rect(cap, edge, false, 1.5)
	var text: String = Loc.t(&"set.key.waiting") if _listening else SettingsUiRules.key_label(int(Settings.bindings().get(action, 0)))
	var color: Color = UiPalette.EMBER if _listening else UiPalette.BONE
	var font: Font = UiFonts.heading()
	var ts: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, CAP_FONT)
	draw_string(font, cap.position + Vector2((cap.size.x - ts.x) * 0.5, (cap.size.y + ts.y * 0.6) * 0.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, CAP_FONT, color)
