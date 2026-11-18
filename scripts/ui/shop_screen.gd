class_name ShopScreen
extends CanvasLayer
## Dalga arası mağaza ekranı: yalnız görünüm. ShopFlow her değişiklikte show_view ile durumu verir,
## ekran seçimleri sinyalle bildirir. İşlevsel ve sade; son görünüm Aşama 9.4'te.
## Tuşlar: 1–4 satın al, R yenile, Enter/Boşluk sonraki dalga.

signal buy_pressed(index: int)
signal lock_pressed(index: int)
signal reroll_pressed
signal sell_pressed(index: int)
signal next_pressed

const LAYER: int = 6
const OVERLAY_COLOR: Color = Color(0.0, 0.0, 0.0, 0.65)
const CARD_SIZE: Vector2 = Vector2(230.0, 210.0)
const GAP: int = 18
const SECTION_GAP: int = 16
const BG: Color = Color(0.1, 0.11, 0.13, 0.95)
const BG_HOVER: Color = Color(0.17, 0.18, 0.21, 0.98)
const BG_OFF: Color = Color(0.07, 0.07, 0.08, 0.9)
const BORDER: int = 3
const CORNER: int = 8
const TITLE_SIZE: int = 36
const NAME_SIZE: int = 20
const BODY_SIZE: int = 15
const PRICE_SIZE: int = 22
const SMALL_SIZE: int = 14
const TEXT_DIM: Color = Color(0.75, 0.76, 0.8)
const GOOD: Color = Color(0.55, 0.95, 0.6)
const BAD: Color = Color(1.0, 0.5, 0.45)
const GOLD: Color = Color(0.8, 0.95, 1.0)
const LOCK_ON: Color = Color(1.0, 0.8, 0.3)

var _title: Label
var _cards_row: HBoxContainer
var _weapons_row: HBoxContainer
var _owned_label: Label
var _reroll_button: Button
var _count: int = 0
var _can_reroll: bool = false


func _ready() -> void:
	name = "ShopScreen"
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
	_title = _label("", TITLE_SIZE, Color.WHITE)
	box.add_child(_title)
	_cards_row = HBoxContainer.new()
	_cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_row.add_theme_constant_override("separation", GAP)
	box.add_child(_cards_row)
	var actions: HBoxContainer = HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", GAP)
	box.add_child(actions)
	_reroll_button = _button("", Vector2(220.0, 44.0))
	_reroll_button.pressed.connect(func() -> void: reroll_pressed.emit())
	actions.add_child(_reroll_button)
	var next_button: Button = _button("Sonraki dalga  [Enter]", Vector2(260.0, 44.0))
	next_button.pressed.connect(func() -> void: next_pressed.emit())
	actions.add_child(next_button)
	box.add_child(_label("SİLAHLARIN  (tıkla: sat)", SMALL_SIZE, TEXT_DIM))
	_weapons_row = HBoxContainer.new()
	_weapons_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_weapons_row.add_theme_constant_override("separation", 10)
	box.add_child(_weapons_row)
	_owned_label = _label("", SMALL_SIZE, TEXT_DIM)
	_owned_label.custom_minimum_size.x = 900.0
	box.add_child(_owned_label)


func close() -> void:
	visible = false


## view: {title, crystals, entries: [{title, subtitle, lines: [{text, good}], price, state, color, locked}],
## reroll_text, can_reroll, weapons: [{text, color, sell_text}], owned_text}.
## state: "ok" alınabilir, "poor" kristal yetmez, "full" yuva dolu, "sold" satıldı.
func show_view(view: Dictionary) -> void:
	_title.text = "%s      %d kristal" % [view["title"], view["crystals"]]
	_clear(_cards_row)
	var entries: Array = view["entries"]
	_count = entries.size()
	for i: int in entries.size():
		_cards_row.add_child(_build_entry(i, entries[i]))
	_reroll_button.text = view["reroll_text"]
	_can_reroll = view["can_reroll"]
	_reroll_button.disabled = not _can_reroll
	_clear(_weapons_row)
	var weapons: Array = view["weapons"]
	for i: int in weapons.size():
		_weapons_row.add_child(_build_weapon(i, weapons[i]))
	_owned_label.text = view["owned_text"]
	visible = true


func _unhandled_input(input_event: InputEvent) -> void:
	if not visible or not (input_event is InputEventKey) or not input_event.is_pressed() or input_event.is_echo():
		return
	var code: Key = (input_event as InputEventKey).physical_keycode
	var index: int = code - KEY_1
	if index >= 0 and index < _count:
		get_viewport().set_input_as_handled()
		buy_pressed.emit(index)
	elif code == KEY_R and _can_reroll:
		get_viewport().set_input_as_handled()
		reroll_pressed.emit()
	elif code == KEY_ENTER or code == KEY_KP_ENTER or code == KEY_SPACE:
		get_viewport().set_input_as_handled()
		next_pressed.emit()


func _build_entry(index: int, entry: Dictionary) -> Control:
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	var state: String = entry["state"]
	var color: Color = entry["color"]
	var button: Button = Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = state == "sold"
	var border: Color = color if state == "ok" else color.darkened(0.55)
	button.add_theme_stylebox_override("normal", _box(BG if state != "sold" else BG_OFF, border))
	button.add_theme_stylebox_override("hover", _box(BG_HOVER, border.lightened(0.25)))
	button.add_theme_stylebox_override("pressed", _box(BG_HOVER, Color.WHITE))
	button.add_theme_stylebox_override("disabled", _box(BG_OFF, border))
	button.pressed.connect(func() -> void: buy_pressed.emit(index))
	column.add_child(button)
	var inner: VBoxContainer = VBoxContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(inner)
	if state == "sold":
		inner.add_child(_label("SATIN ALINDI", NAME_SIZE, TEXT_DIM))
	else:
		inner.add_child(_label(entry["subtitle"], SMALL_SIZE, color))
		inner.add_child(_label(entry["title"], NAME_SIZE, Color.WHITE))
		for line: Dictionary in entry["lines"]:
			inner.add_child(_label(line["text"], BODY_SIZE, GOOD if line["good"] else BAD))
		inner.add_child(_label(_price_text(entry["price"], state), PRICE_SIZE, _price_color(state)))
		inner.add_child(_label("[%d]" % (index + 1), SMALL_SIZE, TEXT_DIM))
	var lock: Button = _button("Kilitli" if entry["locked"] else "Kilitle", Vector2(CARD_SIZE.x, 30.0))
	lock.disabled = state == "sold"
	if entry["locked"]:
		lock.add_theme_color_override("font_color", LOCK_ON)
	lock.pressed.connect(func() -> void: lock_pressed.emit(index))
	column.add_child(lock)
	return column


func _build_weapon(index: int, weapon: Dictionary) -> Button:
	var button: Button = _button("%s\nsat +%d" % [weapon["text"], weapon["sell"]], Vector2(130.0, 56.0))
	button.add_theme_color_override("font_color", weapon["color"])
	button.add_theme_stylebox_override("normal", _box(BG, (weapon["color"] as Color).darkened(0.3)))
	button.add_theme_stylebox_override("hover", _box(BG_HOVER, weapon["color"]))
	button.disabled = not weapon["sellable"]
	button.pressed.connect(func() -> void: sell_pressed.emit(index))
	return button


static func _price_text(price: int, state: String) -> String:
	if state == "full":
		return "YUVALAR DOLU"
	return "%d kristal" % price


static func _price_color(state: String) -> Color:
	return GOLD if state == "ok" else BAD


static func _clear(row: Control) -> void:
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()


static func _button(text: String, min_size: Vector2) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", SMALL_SIZE + 2)
	button.add_theme_stylebox_override("normal", _box(BG, TEXT_DIM.darkened(0.5)))
	button.add_theme_stylebox_override("hover", _box(BG_HOVER, TEXT_DIM))
	button.add_theme_stylebox_override("pressed", _box(BG_HOVER, Color.WHITE))
	button.add_theme_stylebox_override("disabled", _box(BG_OFF, TEXT_DIM.darkened(0.7)))
	return button


static func _label(text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


static func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(BORDER)
	box.set_corner_radius_all(CORNER)
	return box
