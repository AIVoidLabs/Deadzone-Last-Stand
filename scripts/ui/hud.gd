class_name Hud
extends CanvasLayer
## Prototip HUD: can çubuğu, dalga ve süre, öldürme; ölünce ya da kazanınca özet. Aşama 9'da son hali.

const MARGIN: int = 16
const BAR_SIZE: Vector2 = Vector2(260.0, 22.0)
const BAR_CORNER_RADIUS: int = 4
const HP_FILL_COLOR: Color = Color(0.85, 0.22, 0.2)
const HP_BACK_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const DASH_BAR_HEIGHT: float = 6.0
const DASH_BAR_GAP: int = 4
const DASH_READY_COLOR: Color = Color(0.35, 0.8, 1.0)
const DASH_CHARGING_COLOR: Color = Color(0.35, 0.8, 1.0, 0.45)
const XP_BAR_HEIGHT: float = 8.0
const XP_FILL_COLOR: Color = Color(0.2, 0.95, 0.8)
const LEVEL_FONT_SIZE: int = 16
const BANNER_LEVEL_HOLD: float = 0.9
const OVERLAY_COLOR: Color = Color(0.0, 0.0, 0.0, 0.55)
const TITLE_FONT_SIZE: int = 48
const TEXT_FONT_SIZE: int = 20
const WAVE_FONT_SIZE: int = 26
const WAVE_COLOR: Color = Color(1.0, 0.93, 0.8)
const WAVE_LAST_COLOR: Color = Color(1.0, 0.55, 0.3)
const CLEARED_COLOR: Color = Color(0.6, 1.0, 0.65)
## Ortadaki yazıların ekranda kalma süresi (sn).
const BANNER_WAVE_HOLD: float = 1.2
const BANNER_CLEARED_HOLD: float = 1.4

var _player: Player
var _enemies: EnemyManager
## Dalgalar kapalıyken run null.
var _director: SpawnDirector
var _loot: RunLoot
var _xp_bar: ProgressBar
var _level_label: Label
var _shown_level: int = 1
var _wave_label: Label
var _banner: WaveBanner
var _over_title: Label
var _hp_bar: ProgressBar
var _dash_bar: ProgressBar
var _dash_fill: StyleBoxFlat
var _stats_label: Label
var _over: Control
var _over_label: Label


func setup(player: Player, enemies: EnemyManager, director: SpawnDirector, loot: RunLoot) -> void:
	_loot = loot
	_player = player
	_enemies = enemies
	_director = director


func _ready() -> void:
	name = "Hud"
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_top_bar()
	_build_wave_widgets()
	_build_game_over()
	GameFlow.game_over_started.connect(_show_end.bind(false))
	GameFlow.victory_started.connect(_show_end.bind(true))
	_director.phase_changed.connect(_on_wave_phase)


func _process(_delta: float) -> void:
	_hp_bar.max_value = _player.health.maximum
	_hp_bar.value = _player.health.current
	var readiness: float = _player.dash.readiness()
	_dash_bar.value = readiness
	_dash_fill.bg_color = DASH_READY_COLOR if readiness >= 1.0 else DASH_CHARGING_COLOR
	_update_loot()
	var run: WaveRun = _director.run
	if run == null:
		_stats_label.text = "%s   ·   %s" % [_format_time(_enemies.elapsed), _loot_text()]
		return
	_stats_label.text = _loot_text()
	var status: String = _format_time(ceilf(run.phase_left)) if run.phase == WaveRun.Phase.WAVE else "temizlendi"
	_wave_label.text = "DALGA %d/%d   ·   %s" % [run.index + 1, run.wave_count(), status]


func _build_top_bar() -> void:
	var root: MarginContainer = MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top"]:
		root.add_theme_constant_override("margin_%s" % side, MARGIN)
	add_child(root)
	var row: HBoxContainer = HBoxContainer.new()
	root.add_child(row)
	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = BAR_SIZE
	_hp_bar.show_percentage = false
	_hp_bar.add_theme_stylebox_override("background", _flat_box(HP_BACK_COLOR))
	_hp_bar.add_theme_stylebox_override("fill", _flat_box(HP_FILL_COLOR))
	var bars: VBoxContainer = VBoxContainer.new()
	bars.add_theme_constant_override("separation", DASH_BAR_GAP)
	row.add_child(bars)
	bars.add_child(_hp_bar)
	_dash_bar = ProgressBar.new()
	_dash_bar.custom_minimum_size = Vector2(BAR_SIZE.x, DASH_BAR_HEIGHT)
	_dash_bar.max_value = 1.0
	_dash_bar.show_percentage = false
	_dash_bar.visible = Tuning.FEATURE_DASH
	_dash_fill = _flat_box(DASH_READY_COLOR)
	_dash_bar.add_theme_stylebox_override("background", _flat_box(HP_BACK_COLOR))
	_dash_bar.add_theme_stylebox_override("fill", _dash_fill)
	bars.add_child(_dash_bar)
	var xp_row: HBoxContainer = HBoxContainer.new()
	xp_row.visible = Tuning.FEATURE_PICKUPS
	bars.add_child(xp_row)
	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(BAR_SIZE.x, XP_BAR_HEIGHT)
	_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_xp_bar.max_value = 1.0
	_xp_bar.show_percentage = false
	_xp_bar.add_theme_stylebox_override("background", _flat_box(HP_BACK_COLOR))
	_xp_bar.add_theme_stylebox_override("fill", _flat_box(XP_FILL_COLOR))
	xp_row.add_child(_xp_bar)
	_level_label = Label.new()
	_level_label.add_theme_font_size_override("font_size", LEVEL_FONT_SIZE)
	_level_label.add_theme_color_override("font_color", XP_FILL_COLOR)
	xp_row.add_child(_level_label)
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", TEXT_FONT_SIZE)
	row.add_child(_stats_label)


func _update_loot() -> void:
	_xp_bar.value = _loot.level_progress()
	_level_label.text = "Sv. %d" % _loot.level
	if _loot.level > _shown_level:
		_shown_level = _loot.level
		_banner.flash("SEVİYE %d" % _loot.level, XP_FILL_COLOR, BANNER_LEVEL_HOLD)


func _loot_text() -> String:
	if not Tuning.FEATURE_PICKUPS:
		return "%d öldürme" % _enemies.kills
	return "%d kristal   ·   %d öldürme" % [_loot.crystals, _enemies.kills]


func _build_wave_widgets() -> void:
	_wave_label = Label.new()
	_wave_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_wave_label.offset_top = MARGIN
	_wave_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_label.add_theme_font_size_override("font_size", WAVE_FONT_SIZE)
	_wave_label.add_theme_color_override("font_color", WAVE_COLOR)
	_wave_label.visible = _director.run != null
	add_child(_wave_label)
	_banner = WaveBanner.new()
	add_child(_banner)


func _on_wave_phase(phase: WaveRun.Phase, wave_index: int) -> void:
	var run: WaveRun = _director.run
	if phase == WaveRun.Phase.WAVE:
		if run.is_last():
			_banner.flash("SON DALGA", WAVE_LAST_COLOR, BANNER_WAVE_HOLD)
		else:
			_banner.flash("DALGA %d" % (wave_index + 1), WAVE_COLOR, BANNER_WAVE_HOLD)
	elif phase == WaveRun.Phase.CLEAR and not run.is_last():
		_banner.flash("DALGA TEMİZLENDİ", CLEARED_COLOR, BANNER_CLEARED_HOLD)


func _build_game_over() -> void:
	_over = ColorRect.new()
	(_over as ColorRect).color = OVERLAY_COLOR
	_over.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_over.visible = false
	add_child(_over)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_over.add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)
	_over_title = Label.new()
	_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_over_title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	box.add_child(_over_title)
	_over_label = Label.new()
	_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_over_label.add_theme_font_size_override("font_size", TEXT_FONT_SIZE)
	box.add_child(_over_label)


## won: son dalga temizlendi; değilse asker öldü.
func _show_end(won: bool) -> void:
	_over_title.text = "HAYATTA KALDIN" if won else "ÖLDÜN"
	var lines: PackedStringArray = PackedStringArray()
	var run: WaveRun = _director.run
	if run != null:
		lines.append("Dalga: %d/%d" % [run.wave_count() if won else run.index + 1, run.wave_count()])
	lines.append("Süre: %s" % _format_time(_enemies.elapsed))
	lines.append("Öldürme: %d" % _enemies.kills)
	if Tuning.FEATURE_PICKUPS:
		lines.append("Kristal: %d   ·   Seviye: %d" % [_loot.crystals, _loot.level])
	lines.append("")
	lines.append("R — yeniden başla")
	_over_label.text = "\n".join(lines)
	_wave_label.visible = false
	_over.visible = true


static func _flat_box(color: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(BAR_CORNER_RADIUS)
	return box


static func _format_time(seconds: float) -> String:
	var total: int = floori(seconds)
	return "%d:%02d" % [floori(seconds / 60.0), total % 60]
