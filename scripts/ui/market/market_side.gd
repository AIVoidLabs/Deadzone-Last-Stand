class_name MarketSide
extends VBoxContainer
## Mağazanın yan sütunu: 11 istatistiğin şimdiki değeri + sahip olunan eşyalar (küçük amblem x adet).

const ROW_ICON: float = 20.0
const ROW_FONT: int = 14
const HEADER_FONT: int = 15
const PANEL_GAP: int = 10
const ROW_GAP: int = 3
const CHIP_SIZE: float = 38.0
const CHIP_GAP: int = 5
const COUNT_FONT: int = 13

var _stats_header: Label
var _rows: Dictionary = {}
var _owned_header: Label
var _owned_none: Label
var _owned_flow: HFlowContainer
var _owned_cache: Dictionary = {}


func _init() -> void:
	add_theme_constant_override("separation", PANEL_GAP)
	_build_stats_panel()
	_build_owned_panel()


func refresh(stats: PlayerStats, owned: Dictionary) -> void:
	_stats_header.text = Loc.t(&"run.shop.stats")
	_owned_header.text = Loc.t(&"run.shop.owned")
	_owned_none.text = Loc.t(&"run.shop.owned_none")
	for stat: StringName in _rows:
		var bonus: float = stats.bonus(stat) if stats != null else 0.0
		var row: Dictionary = _rows[stat]
		(row["name"] as Label).text = StatData.display_name(stat)
		var value: Label = row["value"]
		value.text = StatReadout.display(stat, bonus)
		value.add_theme_color_override("font_color", UiPalette.GOOD if bonus > 0.0 else (UiPalette.BAD if bonus < 0.0 else UiPalette.ASH))
	_refresh_owned(owned)


func _build_stats_panel() -> void:
	var panel: GrungePanel = GrungePanel.new()
	panel.content_margin = 14
	add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", ROW_GAP)
	panel.add_child(box)
	_stats_header = _header()
	box.add_child(_stats_header)
	for stat: StringName in StatData.TABLE:
		box.add_child(_build_row(stat))


func _build_row(stat: StringName) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var icon: TextureRect = TextureRect.new()
	icon.texture = Emblems.tex(StringName("stat_" + stat))
	icon.custom_minimum_size = Vector2(ROW_ICON, ROW_ICON)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var name_label: Label = _label(UiFonts.body(), UiPalette.BONE)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(name_label)
	var value_label: Label = _label(UiFonts.bold(), UiPalette.ASH)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	_rows[stat] = {"name": name_label, "value": value_label}
	return row


func _build_owned_panel() -> void:
	var panel: GrungePanel = GrungePanel.new()
	panel.content_margin = 14
	add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	_owned_header = _header()
	box.add_child(_owned_header)
	_owned_none = _label(UiFonts.body(), UiPalette.ASH)
	box.add_child(_owned_none)
	_owned_flow = HFlowContainer.new()
	_owned_flow.add_theme_constant_override("h_separation", CHIP_GAP)
	_owned_flow.add_theme_constant_override("v_separation", CHIP_GAP)
	box.add_child(_owned_flow)


func _refresh_owned(owned: Dictionary) -> void:
	_owned_none.visible = owned.is_empty()
	if owned == _owned_cache and _owned_flow.get_child_count() == owned.size():
		for chip: Node in _owned_flow.get_children():
			chip.tooltip_text = Loc.item_name(StringName(chip.name))
		return
	_owned_cache = owned.duplicate()
	for chip: Node in _owned_flow.get_children():
		_owned_flow.remove_child(chip)
		chip.queue_free()
	for id: StringName in owned:
		_owned_flow.add_child(_chip(id, int(owned[id])))


## Küçük eşya amblemi + sağ altta adet.
func _chip(id: StringName, count: int) -> Control:
	var chip: Control = Control.new()
	chip.name = String(id)
	chip.custom_minimum_size = Vector2(CHIP_SIZE, CHIP_SIZE)
	chip.tooltip_text = Loc.item_name(id)
	var icon: TextureRect = TextureRect.new()
	icon.texture = Emblems.tex(StringName("item_" + id))
	UiAssets.fill(icon)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_PASS
	chip.add_child(icon)
	if count > 1:
		var label: Label = _label(UiFonts.heading(), UiPalette.BONE)
		label.text = "x%d" % count
		label.add_theme_font_size_override("font_size", COUNT_FONT)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
		label.add_theme_constant_override("outline_size", 4)
		label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		label.grow_vertical = Control.GROW_DIRECTION_BEGIN
		chip.add_child(label)
	return chip


func _header() -> Label:
	var label: Label = _label(UiFonts.heading(), UiPalette.EMBER)
	label.add_theme_font_size_override("font_size", HEADER_FONT)
	return label


func _label(font: Font, color: Color) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", ROW_FONT)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
