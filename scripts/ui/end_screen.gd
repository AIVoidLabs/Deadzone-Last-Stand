class_name EndScreen
extends Control
## Tur sonu ekranı (FEATURE_END_SUMMARY): solda büyük amblem kartı, sağda sayarak dolan özet, altta TEKRAR DENE / ANA MENÜ.
## Veri GameFlow.last_summary (RunStats.summary) ve last_new_records. Özet animasyonu herhangi bir tuş ya da tıkla atlanır.
## Kazanma: "HAYATTA KALDIN", turuncu-altın. Ölüm: "SON NEFES", kan kırmızı.

const LAYER_INDEX: int = 20
const BACKDROP_DIM: float = 0.7
const SIDE_MARGIN: int = 40
const VERTICAL_MARGIN: int = 22
const TITLE_SIZE: int = 76
const ROW_GAP: int = 34
const BOX_GAP: int = 10
const PANEL_SIZE: Vector2 = Vector2(700.0, 430.0)
const PANEL_MARGIN: int = 22
const CARD_SIZE: Vector2 = Vector2(290.0, 430.0)
const BUTTON_GAP: int = 26
const INTRO_FADE: float = 0.35
const CARD_DELAY: float = 0.15
const WIN_ACCENT: Color = Color("F08A24")
const LOSE_ACCENT: Color = Color("D01A22")
const SAMPLE: Dictionary = {
	"won": true, "time": 402.0, "kills": 1387, "kills_by_kind": {&"walker": 904, &"runner": 280, &"armored": 121, &"tank": 54, &"boss_heap": 1},
	"crystals": 2210, "damage_taken": 318.0, "damage_dealt": 41230.0, "dashes": 57, "level": 9, "wave": 5,
	"cards": [{"stat": &"damage", "tier": 1}, {"stat": &"fire_rate", "tier": 0}, {"stat": &"damage", "tier": 2}, {"stat": &"max_hp", "tier": 3}, {"stat": &"armor", "tier": 0}, {"stat": &"move_speed", "tier": 1}],
	"items": {}, "weapons": [{"id": &"pistol", "tier": 3}, {"id": &"shotgun", "tier": 2}, {"id": &"smg", "tier": 1}, {"id": &"katana", "tier": 4}],
}

var _won: bool = false
var _summary: Dictionary = {}
var _records: Array = []
var _present: bool = false
var _animating: bool = false
var _tween: Tween = null
var _summary_panel: EndSummary = null
var _retry: GrungeButton = null


## Ana sahneye ekler: tur bitince (game_over_started / victory_started) kendiliğinden açılır.
static func install(parent: Node) -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "EndLayer"
	layer.layer = LAYER_INDEX
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(EndScreen.new())
	parent.add_child(layer)


func _init() -> void:
	name = "EndScreen"
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiAssets.fill(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _ready() -> void:
	theme = UiTheme.get_theme()
	GameFlow.game_over_started.connect(show_result.bind(false))
	GameFlow.victory_started.connect(show_result.bind(true))
	Settings.changed.connect(_on_setting_changed)


func _on_setting_changed(key: StringName, _value: Variant) -> void:
	if key == &"game/language" and _present:
		_build(false)


## Özeti gösterir (veri GameFlow'dan; verilmezse son tur).
func show_result(won: bool, summary: Dictionary = {}, records: Array = []) -> void:
	_won = won
	_summary = summary if not summary.is_empty() else GameFlow.last_summary
	_records = records if not summary.is_empty() else GameFlow.last_new_records
	_build(true)


func _build(animate: bool) -> void:
	if _tween != null:
		_tween.kill()
	for child: Node in get_children():
		child.queue_free()
	visible = true
	_present = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(ScreenBackdrop.create(true, BACKDROP_DIM))
	var margin: MarginContainer = MarginContainer.new()
	UiAssets.fill(margin)
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, SIDE_MARGIN)
	margin.add_theme_constant_override("margin_top", VERTICAL_MARGIN)
	margin.add_theme_constant_override("margin_bottom", VERTICAL_MARGIN)
	add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", BOX_GAP)
	margin.add_child(box)
	var title: GrungeTitle = _make_title()
	box.add_child(title)
	box.add_child(_make_row())
	box.add_child(_make_buttons())
	_retry.grab_focus()
	if animate and Tuning.FEATURE_UI_MOTION:
		_start_intro(title)
	else:
		_summary_panel.finish_now()


func _make_title() -> GrungeTitle:
	var title: GrungeTitle = GrungeTitle.new()
	title.font_size = TITLE_SIZE
	title.set_text(Loc.t(&"end.win_a" if _won else &"end.lose_a"), Loc.t(&"end.win_b" if _won else &"end.lose_b"))
	title.set_colors(WIN_ACCENT if _won else LOSE_ACCENT, UiPalette.BONE)
	return title


func _make_row() -> Control:
	var center: CenterContainer = CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", ROW_GAP)
	center.add_child(row)
	row.add_child(_make_card())
	_summary_panel = EndSummary.new()
	_summary_panel.content_margin = PANEL_MARGIN
	_summary_panel.custom_minimum_size = PANEL_SIZE
	row.add_child(_summary_panel)
	var total: int = WaveData.WAVES.size() if Tuning.FEATURE_WAVES else 0
	_summary_panel.build(_summary, EndRules.record_flags(_records), total)
	return center


func _make_card() -> GrungeCard:
	var card: GrungeCard = GrungeCard.new()
	card.card_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_NONE
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var total: int = WaveData.WAVES.size() if Tuning.FEATURE_WAVES else 0
	var wave: int = int(_summary.get("wave", 1))
	card.setup({
		"category_id": &"survival" if _won else &"combat",
		"category": Loc.t(&"end.card_cat_win" if _won else &"end.card_cat_lose"),
		"title": Loc.t(&"hud.wave_fmt", [wave, total]) if total > 0 else Loc.t(&"hud.wave_n", [wave]),
		"emblem": &"end_victory" if _won else &"end_defeat",
		"lines": [{"text": Loc.t(&"end.card_win_line" if _won else &"end.card_lose_line"), "bold": true}],
	})
	if Tuning.FEATURE_UI_MOTION:
		card.play_intro(CARD_DELAY)
	return card


func _make_buttons() -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", BUTTON_GAP)
	_retry = GrungeButton.create(Loc.t(&"end.retry", [KeyHint.of(&"restart")]), &"primary")
	_retry.pressed.connect(GameFlow.restart)
	var menu: GrungeButton = GrungeButton.create(Loc.t(&"end.menu"), &"normal")
	menu.pressed.connect(GameFlow.to_main_menu)
	for button: GrungeButton in [_retry, menu]:
		UiSounds.hook(button, true)
		row.add_child(button)
	return row


func _start_intro(title: Control) -> void:
	UiMotion.pop_in(title)
	_summary_panel.play_intro()
	_animating = true
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_method(_summary_panel.set_progress, 0.0, EndSummary.total_time(), EndSummary.total_time())
	_tween.tween_callback(_on_count_done)


func _on_count_done() -> void:
	_animating = false
	_summary_panel.finish()


## Animasyon sürerken ilk tuş/tık özeti hemen tamamlar (R hâlâ yeniden başlatır).
func _input(input_event: InputEvent) -> void:
	if not _present or not _animating:
		return
	if input_event.is_action_pressed(&"restart"):
		return
	var pressed: bool = (input_event is InputEventKey and input_event.pressed and not input_event.echo) \
		or (input_event is InputEventMouseButton and input_event.pressed)
	if pressed:
		_tween.kill()
		_animating = false
		_summary_panel.finish_now()
		get_viewport().set_input_as_handled()


## Görüntü aracı: screen end_win / end_lose; sahte özet. tab 1: boş (hiç silah/kart/rekor yok).
static func ui_shot(host: Node, opts: Dictionary) -> void:
	ShotUnderlay.add(host)
	var screen: EndScreen = EndScreen.new()
	host.add_child(screen)
	var won: bool = String(opts.get("screen", "end_win")) != "end_lose"
	var summary: Dictionary = SAMPLE.duplicate(true)
	var records: Array = [&"most_kills", &"best_level"] if won else [&"best_wave"]
	if int(opts.get("tab", 0)) == 1:
		summary = {"won": won, "time": 31.0, "kills": 14, "wave": 1, "level": 1}
		records = []
	summary["won"] = won
	if not won:
		summary["wave"] = 3
		summary["time"] = 187.0
	screen.show_result(won, summary, records)
