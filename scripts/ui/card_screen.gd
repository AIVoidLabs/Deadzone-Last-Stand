class_name CardScreen
extends CanvasLayer
## Seviye kartı seçimi: 3 kart (fare ya da 1/2/3), altında güncel istatistikler. İşlevsel ve sade;
## son görünüm Aşama 9.4'te. Oyun durmuşken çalışır (GameFlow.open_menu).

signal chosen(index: int)

const LAYER: int = 5
const OVERLAY_COLOR: Color = Color(0.0, 0.0, 0.0, 0.6)
const CARD_SIZE: Vector2 = Vector2(250.0, 190.0)
const CARD_GAP: int = 24
const CARD_BG: Color = Color(0.1, 0.11, 0.13, 0.95)
const CARD_BG_HOVER: Color = Color(0.17, 0.18, 0.21, 0.98)
const CARD_BORDER: int = 3
const CARD_CORNER: int = 8
const TITLE_FONT_SIZE: int = 40
const SUB_FONT_SIZE: int = 18
const TIER_FONT_SIZE: int = 16
const VALUE_FONT_SIZE: int = 28
const KEY_FONT_SIZE: int = 14
const STATS_FONT_SIZE: int = 15
const TEXT_DIM: Color = Color(0.75, 0.76, 0.8)
const SECTION_GAP: int = 22

var _cards_row: HBoxContainer
var _subtitle: Label
var _stats_label: Label
var _count: int = 0


func _ready() -> void:
	name = "CardScreen"
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var overlay: ColorRect = ColorRect.new()
	overlay.color = OVERLAY_COLOR
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", SECTION_GAP)
	center.add_child(box)
	box.add_child(_label("SEVİYE ATLADIN", TITLE_FONT_SIZE, Color.WHITE))
	_subtitle = _label("", SUB_FONT_SIZE, TEXT_DIM)
	box.add_child(_subtitle)
	_cards_row = HBoxContainer.new()
	_cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_row.add_theme_constant_override("separation", CARD_GAP)
	box.add_child(_cards_row)
	_stats_label = _label("", STATS_FONT_SIZE, TEXT_DIM)
	box.add_child(_stats_label)


## offer: CardRules.roll_offer çıktısı. pending: bu seçim dahil kalan seçim sayısı.
func show_offer(offer: Array[Dictionary], pending: int, stats: PlayerStats) -> void:
	for child in _cards_row.get_children():
		child.queue_free()
	_count = offer.size()
	for i in offer.size():
		_cards_row.add_child(_build_card(i, offer[i]))
	_subtitle.text = "Bir kart seç" if pending <= 1 else "Bir kart seç   ·   %d seçim daha var" % (pending - 1)
	_stats_label.text = stats_text(stats)
	visible = true


func close() -> void:
	visible = false


func _unhandled_input(input_event: InputEvent) -> void:
	if not visible or not (input_event is InputEventKey) or not input_event.is_pressed() or input_event.is_echo():
		return
	var index: int = (input_event as InputEventKey).physical_keycode - KEY_1
	if index >= 0 and index < _count:
		get_viewport().set_input_as_handled()
		chosen.emit(index)


func _build_card(index: int, card: Dictionary) -> Button:
	var tier: Dictionary = CardData.TIERS[card["tier"]]
	var color: Color = tier["color"]
	var button: Button = Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _card_box(CARD_BG, color))
	button.add_theme_stylebox_override("hover", _card_box(CARD_BG_HOVER, color.lightened(0.25)))
	button.add_theme_stylebox_override("pressed", _card_box(CARD_BG_HOVER, Color.WHITE))
	button.pressed.connect(func() -> void: chosen.emit(index))
	UiSounds.hook(button)
	var inner: VBoxContainer = VBoxContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(inner)
	inner.add_child(_label(tier["name"], TIER_FONT_SIZE, color))
	inner.add_child(_label(StatData.display_name(card["stat"]), SUB_FONT_SIZE, Color.WHITE))
	inner.add_child(_label(StatData.short_value(card["stat"], card["value"]), VALUE_FONT_SIZE, color))
	inner.add_child(_label("[%d]" % (index + 1), KEY_FONT_SIZE, TEXT_DIM))
	return button


## Sıfırdan farklı artışlar tek satırda (debug paneli de kullanır).
static func stats_text(stats: PlayerStats) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for stat: StringName in StatData.TABLE:
		var value: float = stats.bonus(stat)
		if value != 0.0:
			parts.append(StatData.describe(stat, value))
	if parts.is_empty():
		return "Henüz artış yok"
	return "   ·   ".join(parts)


static func _label(text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


static func _card_box(bg: Color, border: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(CARD_BORDER)
	box.set_corner_radius_all(CARD_CORNER)
	return box
