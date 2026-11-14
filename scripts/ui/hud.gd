class_name Hud
extends CanvasLayer
## Prototip HUD: can çubuğu, süre, öldürme; ölünce özet. Aşama 7'de son hali.

const MARGIN: int = 16
const BAR_SIZE: Vector2 = Vector2(260.0, 22.0)
const BAR_CORNER_RADIUS: int = 4
const HP_FILL_COLOR: Color = Color(0.85, 0.22, 0.2)
const HP_BACK_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
const OVERLAY_COLOR: Color = Color(0.0, 0.0, 0.0, 0.55)
const TITLE_FONT_SIZE: int = 48
const TEXT_FONT_SIZE: int = 20

var _player: Player
var _enemies: EnemyManager
var _hp_bar: ProgressBar
var _stats_label: Label
var _over: Control
var _over_label: Label


func setup(player: Player, enemies: EnemyManager) -> void:
	_player = player
	_enemies = enemies


func _ready() -> void:
	name = "Hud"
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_top_bar()
	_build_game_over()
	GameFlow.game_over_started.connect(_show_game_over)


func _process(_delta: float) -> void:
	_hp_bar.max_value = _player.health.maximum
	_hp_bar.value = _player.health.current
	_stats_label.text = "%s   ·   %d öldürme" % [_format_time(_enemies.elapsed), _enemies.kills]


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
	row.add_child(_hp_bar)
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", TEXT_FONT_SIZE)
	row.add_child(_stats_label)


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
	var title: Label = Label.new()
	title.text = "ÖLDÜN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	box.add_child(title)
	_over_label = Label.new()
	_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_over_label.add_theme_font_size_override("font_size", TEXT_FONT_SIZE)
	box.add_child(_over_label)


func _show_game_over() -> void:
	_over_label.text = "Hayatta kalma: %s\nÖldürme: %d\n\nR — yeniden başla" % [_format_time(_enemies.elapsed), _enemies.kills]
	_over.visible = true


static func _flat_box(color: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(BAR_CORNER_RADIUS)
	return box


static func _format_time(seconds: float) -> String:
	var total: int = floori(seconds)
	return "%d:%02d" % [floori(seconds / 60.0), total % 60]
