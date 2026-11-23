class_name KeepDialog
extends Control
## "Bu ayarı koru?" penceresi: 10 sn geri sayım, süre dolunca ya da Esc ile eski ayar geri gelir.
## Gerçek zamanla sayar (duraklatmada ve ekran modu geçişinde de akar).

signal decided(keep: bool)

const PANEL_WIDTH: float = 520.0
const TITLE_SIZE: int = 40
const BODY_SIZE: int = 20
const BAR_HEIGHT: float = 12.0
const DIM: Color = Color(0.0, 0.0, 0.0, 0.62)

var _start_msec: int = 0
var _body: Label = null
var _bar: GrungeBar = null
var _keep_btn: GrungeButton = null
var _revert_btn: GrungeButton = null
var _done: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiAssets.fill(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim: ColorRect = ColorRect.new()
	dim.color = DIM
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiAssets.fill(dim)
	add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiAssets.fill(center)
	add_child(center)
	var panel: GrungePanel = GrungePanel.new()
	panel.content_margin = 30
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	center.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var title: GrungeTitle = GrungeTitle.new()
	title.font_size = TITLE_SIZE
	title.set_text(Loc.t(&"set.keep.title"), "")
	box.add_child(title)
	_body = Label.new()
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_theme_font_size_override("font_size", BODY_SIZE)
	box.add_child(_body)
	_bar = GrungeBar.new()
	_bar.custom_minimum_size = Vector2(0, BAR_HEIGHT)
	_bar.fill_color = UiPalette.EMBER
	box.add_child(_bar)
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	box.add_child(row)
	_keep_btn = GrungeButton.create(Loc.t(&"set.keep.yes"), &"primary")
	_revert_btn = GrungeButton.create(Loc.t(&"set.keep.no"), &"normal")
	for b: GrungeButton in [_keep_btn, _revert_btn]:
		b.custom_minimum_size.x = 210
		UiSounds.hook(b, true)
		row.add_child(b)
	_keep_btn.pressed.connect(_finish.bind(true))
	_revert_btn.pressed.connect(_finish.bind(false))
	_lock_focus()
	_start_msec = Time.get_ticks_msec()
	_update()
	_keep_btn.grab_focus.call_deferred()
	UiMotion.pop_in(panel)


## Odak iki düğme dışına çıkamaz (arkadaki satırlara kaçmaz).
func _lock_focus() -> void:
	_keep_btn.focus_neighbor_left = _keep_btn.get_path()
	_keep_btn.focus_neighbor_top = _keep_btn.get_path()
	_keep_btn.focus_neighbor_bottom = _keep_btn.get_path()
	_keep_btn.focus_neighbor_right = _revert_btn.get_path()
	_revert_btn.focus_neighbor_right = _revert_btn.get_path()
	_revert_btn.focus_neighbor_top = _revert_btn.get_path()
	_revert_btn.focus_neighbor_bottom = _revert_btn.get_path()
	_revert_btn.focus_neighbor_left = _keep_btn.get_path()


func elapsed() -> float:
	return (Time.get_ticks_msec() - _start_msec) / 1000.0


func _process(_delta: float) -> void:
	if _done:
		return
	if SettingsUiRules.expired(elapsed()):
		_finish(false)
		return
	_update()


func _update() -> void:
	_body.text = Loc.t(&"set.keep.body", [SettingsUiRules.seconds_left(elapsed())])
	_bar.set_value(maxf(SettingsUiRules.KEEP_SECONDS - elapsed(), 0.0), SettingsUiRules.KEEP_SECONDS)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		_finish(false)
		get_viewport().set_input_as_handled()


func _finish(keep: bool) -> void:
	if _done:
		return
	_done = true
	decided.emit(keep)
	queue_free()
