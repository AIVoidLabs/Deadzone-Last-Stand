class_name PauseMenu
extends CanvasLayer
## Duraklatma menüsü: solda düğme sütunu, sağda tur özeti. Yalnız GameFlow "pause" nedeniyle açıkken görünür.
## Esc/P'yi GameFlow yönetir (aç/kapat); alt paneller (ayarlar, onay) Esc'i kendi _input'unda tüketir.
## Veri kaynakları main.gd'den atanır (PauseMenu.attach); boşsa ilgili bölüm boş görünür.

const LAYER: int = 30
const BACKDROP_DIM: float = 0.62
const MARGIN: Vector2i = Vector2i(64, 36)
const COLUMN_WIDTH: float = 330.0
const TITLE_SIZE: int = 46
const BUTTON_GAP: int = 14
const BUTTON_SIZE: Vector2 = Vector2(330, 58)
const STAGGER: float = 0.045
const COLUMN_GAP: int = 56
const TITLE_GAP: float = 16.0
const HINT_SIZE: int = 14

var stats: PlayerStats = null
var weapons: WeaponRig = null
var loot: RunLoot = null
## Görüntü aracı / sahte veri: doluysa gerçek kaynakların yerine kullanılır.
var fake_data: Dictionary = {}

var _root: Control = null
var _settings: SettingsMenu = null
var _resume: GrungeButton = null


## Ana sahneye duraklatma menüsünü ekler (FEATURE_PAUSE_MENU).
static func attach(parent: Node, player_stats: PlayerStats, rig: WeaponRig, run_loot: RunLoot) -> PauseMenu:
	var menu: PauseMenu = PauseMenu.new()
	menu.stats = player_stats
	menu.weapons = rig
	menu.loot = run_loot
	parent.add_child(menu)
	return menu


func _ready() -> void:
	name = "PauseMenu"
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	GameFlow.paused_changed.connect(_on_paused_changed)
	Settings.changed.connect(_on_setting_changed)


func _on_paused_changed(_paused: bool) -> void:
	if GameFlow.is_paused_by(GameFlow.REASON_PAUSE):
		_open()
	else:
		_close()


func _on_setting_changed(key: StringName, _value: Variant) -> void:
	if key == &"game/language" and visible and _settings == null:
		_build.call_deferred()


func _open() -> void:
	visible = true
	UiSounds.play(UiSoundData.CARD_OPEN)
	_build()


func _close() -> void:
	if _settings != null and is_instance_valid(_settings):
		_settings.queue_free()
	_settings = null
	visible = false
	if _root != null:
		_root.queue_free()
		_root = null


## Gösterilen tur verisi: gerçek kaynaklardan ya da sahte veriden.
func collect() -> Dictionary:
	if not fake_data.is_empty():
		return fake_data
	var run: RunStats = GameFlow.run_stats
	var bonus_of: Callable = func(stat: StringName) -> float: return stats.bonus(stat) if stats != null else 0.0
	return {
		"counters": PauseSummary.counters(run.wave, run.time, run.kills, loot.level if loot != null else run.level, run.crystals),
		"gains": PauseSummary.gains(bonus_of),
		"weapons": PauseSummary.weapon_rows(weapons.slot_list() if weapons != null else []),
	}


func _build() -> void:
	if _root != null:
		_root.queue_free()
	_root = Control.new()
	_root.theme = UiTheme.get_theme()
	UiAssets.fill(_root)
	add_child(_root)
	_root.add_child(ScreenBackdrop.create(true, BACKDROP_DIM))
	var margin: MarginContainer = MarginContainer.new()
	UiAssets.fill(margin)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", MARGIN.x)
	margin.add_theme_constant_override("margin_right", MARGIN.x)
	margin.add_theme_constant_override("margin_top", MARGIN.y)
	margin.add_theme_constant_override("margin_bottom", MARGIN.y)
	_root.add_child(margin)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", COLUMN_GAP)
	margin.add_child(row)
	row.add_child(_build_menu_column())
	var side: CenterContainer = CenterContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(side)
	var summary: PauseSummaryPanel = PauseSummaryPanel.new()
	summary.setup(collect())
	summary.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	side.add_child(summary)
	UiMotion.pop_in(summary, 0.12)
	_resume.grab_focus.call_deferred()


func _build_menu_column() -> Control:
	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size = Vector2(COLUMN_WIDTH, 0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", BUTTON_GAP)
	var title: GrungeTitle = GrungeTitle.new()
	title.font_size = TITLE_SIZE
	title.alignment = BoxContainer.ALIGNMENT_BEGIN
	title.set_text(Loc.t(&"pause.title"), "")
	column.add_child(title)
	var gap: Control = Control.new()
	gap.custom_minimum_size = Vector2(0, TITLE_GAP)
	column.add_child(gap)
	_resume = _button(column, &"pause.resume", &"primary", GameFlow.resume, 0)
	_button(column, &"pause.settings", &"normal", _open_settings, 1)
	_button(column, &"pause.restart", &"normal", _ask.bind(&"pause.restart", GameFlow.restart), 2)
	_button(column, &"pause.home", &"normal", _ask.bind(&"pause.home", GameFlow.to_main_menu), 3)
	_button(column, &"pause.quit", &"danger", _ask.bind(&"pause.quit", GameFlow.quit_game), 4)
	var hint: Label = Label.new()
	hint.text = Loc.t(&"pause.hint")
	hint.add_theme_font_size_override("font_size", HINT_SIZE)
	hint.add_theme_color_override("font_color", UiPalette.ASH)
	column.add_child(hint)
	return column


func _button(column: Control, key: StringName, variant: StringName, action: Callable, index: int) -> GrungeButton:
	var b: GrungeButton = GrungeButton.create(Loc.t(key), variant)
	b.custom_minimum_size = BUTTON_SIZE
	UiSounds.hook(b, true)
	b.pressed.connect(action)
	column.add_child(b)
	UiMotion.pop_in(b, STAGGER * index)
	return b


## Onaylı eylem: başlık anahtarı eylemle aynı, gövde "<anahtar>.body".
func _ask(key: StringName, action: Callable) -> void:
	GrungeConfirm.ask(self, key, StringName(String(key) + ".body"), action)


func _open_settings() -> void:
	_root.visible = false
	_settings = SettingsMenu.open(self, _on_settings_closed)


func _on_settings_closed() -> void:
	_settings = null
	# Ayarlarda dil değişmiş olabilir; menü metinleri baştan kurulur.
	if visible and GameFlow.is_paused_by(GameFlow.REASON_PAUSE):
		_build()


## Görüntü aracı (UiShot): sahte veriyle menüyü açar (oyun yok).
static func ui_shot(host: Node, opts: Dictionary) -> void:
	var back: ColorRect = ColorRect.new()
	back.color = Color(0.2, 0.17, 0.15)
	UiAssets.fill(back)
	host.add_child(back)
	var menu: PauseMenu = PauseMenu.new()
	menu.fake_data = {
		"counters": PauseSummary.counters(7, 412.0, 538, 9, 1240),
		"gains": PauseSummary.gains(func(stat: StringName) -> float: return {&"max_hp": 30.0, &"damage": 16.0, &"fire_rate": 10.0, &"armor": 3.0, &"move_speed": 8.0, &"luck": 5.0, &"dash_cooldown": 12.0}.get(stat, 0.0)),
		"weapons": PauseSummary.weapon_rows([{"id": &"pistol", "tier": 3}, {"id": &"shotgun", "tier": 2}, {"id": &"smg", "tier": 1}, {"id": &"katana", "tier": 4}]),
	}
	host.add_child(menu)
	menu._open()
	if int(opts.get("focus", -1)) == 1:
		menu._open_settings.call_deferred()
