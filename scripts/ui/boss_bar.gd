class_name BossBar
extends CanvasLayer
## Boss can çubuğu: ekranın üst ortasında geniş çubuk + ad ("YIĞIN"), öfke eşiğinde (%50) çentik; hasar alınca kısa beyaz parlama,
## öfkede çubuk kızıl. Boss yokken gizli. Anchor + container ile kurulur (her pencere boyutunda çalışır). Durum EnemyManager.boss().status().

const NAME_TEXT: String = "YIĞIN"
const LAYER_INDEX: int = 1
## Çubuk ekranın ortasında bu oranlar arasında (genişlik), üstten bu kadar piksel aşağıda (dalga yazısının altı).
const LEFT_RATIO: float = 0.25
const RIGHT_RATIO: float = 0.75
const TOP_OFFSET: float = 78.0
const BAR_HEIGHT: float = 22.0
const NAME_FONT_SIZE: int = 22
const BACK_COLOR: Color = Color(0.0, 0.0, 0.0, 0.6)
const FILL_COLOR: Color = Color(0.9, 0.55, 0.2)
const RAGE_COLOR: Color = Color(0.95, 0.12, 0.1)
const NAME_COLOR: Color = Color(1.0, 0.86, 0.7)
const NOTCH_COLOR: Color = Color(1.0, 1.0, 1.0, 0.85)
const FLASH_TIME: float = 0.12
const FLASH_ALPHA: float = 0.7

var enemies: EnemyManager

var _root: Control
var _bar: ProgressBar
var _fill: StyleBoxFlat
var _flash: ColorRect
var _notch: ColorRect
var _flash_left: float = 0.0
var _last_hp: float = -1.0
var _view: HudBossView = null


func _ready() -> void:
	name = "BossBar"
	layer = LAYER_INDEX
	if Tuning.FEATURE_NEW_HUD:
		_build_new_view()
		return
	_root = Control.new()
	_root.anchor_left = LEFT_RATIO
	_root.anchor_right = RIGHT_RATIO
	_root.offset_top = TOP_OFFSET
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(box)
	var title: Label = Label.new()
	title.text = NAME_TEXT
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	title.add_theme_color_override("font_color", NAME_COLOR)
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.7))
	box.add_child(title)
	var holder: Control = Control.new()
	holder.custom_minimum_size = Vector2(0.0, BAR_HEIGHT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(holder)
	_bar = ProgressBar.new()
	_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bar.show_percentage = false
	_bar.max_value = 1.0
	_fill = _flat_box(FILL_COLOR)
	_bar.add_theme_stylebox_override("background", _flat_box(BACK_COLOR))
	_bar.add_theme_stylebox_override("fill", _fill)
	holder.add_child(_bar)
	_flash = ColorRect.new()
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1.0, 1.0, 1.0, 0.0)
	holder.add_child(_flash)
	_notch = ColorRect.new()
	_notch.set_anchors_preset(Control.PRESET_FULL_RECT)
	_notch.offset_left = -1.0
	_notch.offset_right = 1.0
	_notch.color = NOTCH_COLOR
	_notch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(_notch)


## Yeni görünüm (FEATURE_NEW_HUD): kit çubuğu; eski kurulum atlanır.
func _build_new_view() -> void:
	_view = HudBossView.new()
	_view.set_name_text(Loc.enemy_name(EnemyDataBoss.ID))
	add_child(_view)
	_view.apply_scale(float(Settings.get_value(&"game/hud_scale")))
	Settings.changed.connect(_on_setting_changed)


func _on_setting_changed(key: StringName, _value: Variant) -> void:
	if key == &"game/hud_scale":
		_view.apply_scale(float(Settings.get_value(&"game/hud_scale")))
	elif key == &"game/language":
		_view.set_name_text(Loc.enemy_name(EnemyDataBoss.ID))


func _process(delta: float) -> void:
	var status: Dictionary = enemies.boss().status()
	if _view != null:
		_view.visible = status["alive"]
		if status["alive"]:
			_view.set_status(float(status["hp"]) / maxf(float(status["max_hp"]), 1.0), status["raged"], float(status["threshold"]))
		return
	_root.visible = status["alive"]
	if not status["alive"]:
		_last_hp = -1.0
		return
	var hp: float = status["hp"]
	if _last_hp >= 0.0 and hp < _last_hp:
		_flash_left = FLASH_TIME
	_last_hp = hp
	_flash_left = maxf(_flash_left - delta, 0.0)
	_flash.color.a = FLASH_ALPHA * _flash_left / FLASH_TIME
	_bar.value = hp / maxf(float(status["max_hp"]), 1.0)
	_fill.bg_color = RAGE_COLOR if status["raged"] else FILL_COLOR
	# Çentik eşik oranında (çubuk tam genişlikte anchor ile).
	var at: float = float(status["threshold"])
	_notch.anchor_left = at
	_notch.anchor_right = at


static func _flat_box(color: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(3)
	return box
