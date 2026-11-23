class_name PauseSummaryPanel
extends GrungePanel
## Duraklatma menüsünün sağ paneli: tur sayaçları, alınan istatistik artışları, silahlar (kademe çizikleriyle).
## data: {counters, gains, weapons} (PauseSummary çıktıları).

const PANEL_WIDTH: float = 640.0
const HEAD_SIZE: int = 24
const SUB_SIZE: int = 15
const VALUE_SIZE: int = 36
const CAPTION_SIZE: int = 13
const ICON_SIZE: float = 30.0
const CHIP_ICON: float = 26.0
const WEAPON_ICON: float = 64.0
const WEAPON_CELL: float = 100.0
const TICK_HEIGHT: float = 11.0
const TICK_STEP: float = 9.0

var _data: Dictionary = {}


func setup(data: Dictionary) -> void:
	_data = data


func _ready() -> void:
	content_margin = 26
	super._ready()
	custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	box.add_child(_heading(Loc.t(&"pause.summary"), HEAD_SIZE, UiPalette.EMBER))
	box.add_child(_counters())
	box.add_child(_rule())
	box.add_child(_heading(Loc.t(&"pause.perks"), SUB_SIZE, UiPalette.AMBER))
	box.add_child(_gains())
	box.add_child(_rule())
	box.add_child(_heading(Loc.t(&"pause.weapons"), SUB_SIZE, UiPalette.AMBER))
	box.add_child(_weapons())


func _heading(text: String, size: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_override("font", UiFonts.heading())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _rule() -> ColorRect:
	var r: ColorRect = ColorRect.new()
	r.color = Color(UiPalette.ASH, 0.22)
	r.custom_minimum_size = Vector2(0, 1)
	return r


func _icon(id: StringName, px: float) -> TextureRect:
	var t: TextureRect = TextureRect.new()
	t.texture = Emblems.tex(id)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(px, px)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _counters() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for c: Dictionary in _data.get("counters", []):
		var tile: VBoxContainer = VBoxContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.alignment = BoxContainer.ALIGNMENT_CENTER
		if Emblems.has(c["icon"]):
			var icon: TextureRect = _icon(c["icon"], ICON_SIZE)
			icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			tile.add_child(icon)
		var value: Label = _heading(c["value"], VALUE_SIZE, UiPalette.BONE)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.add_child(value)
		var cap: Label = _heading(Loc.t(c["key"]), CAPTION_SIZE, UiPalette.ASH)
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.add_child(cap)
		row.add_child(tile)
	return row


func _gains() -> Control:
	var rows: Array = _data.get("gains", [])
	if rows.is_empty():
		return _heading(Loc.t(&"pause.perks.none"), SUB_SIZE, UiPalette.ASH)
	var flow: HFlowContainer = HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	for g: Dictionary in rows:
		flow.add_child(_chip(g))
	return flow


func _chip(g: Dictionary) -> PanelContainer:
	var hot: Color = UiPalette.category(g["category"])["hot"]
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.045, 0.035, 0.03, 0.92)
	sb.border_color = Color(hot, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 8
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	var chip: PanelContainer = PanelContainer.new()
	chip.add_theme_stylebox_override("panel", sb)
	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", 7)
	h.add_child(_icon(StringName("stat_" + g["stat"]), CHIP_ICON))
	var l: Label = Label.new()
	l.text = StatData.describe(g["stat"], g["value"]) + (" " + Loc.t(&"run.cap.max") if g.get("capped", false) else "")
	l.add_theme_font_override("font", UiFonts.bold())
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", hot.lerp(UiPalette.BONE, 0.55))
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	chip.add_child(h)
	return chip


func _weapons() -> Control:
	var rows: Array = _data.get("weapons", [])
	if rows.is_empty():
		return _heading(Loc.t(&"pause.weapons.none"), SUB_SIZE, UiPalette.ASH)
	var flow: HFlowContainer = HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	for w: Dictionary in rows:
		flow.add_child(_weapon_cell(w))
	return flow


func _weapon_cell(w: Dictionary) -> VBoxContainer:
	var cell: VBoxContainer = VBoxContainer.new()
	cell.custom_minimum_size = Vector2(WEAPON_CELL, 0)
	cell.add_theme_constant_override("separation", 2)
	var icon: TextureRect = _icon(StringName("weapon_" + w["id"]), WEAPON_ICON)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cell.add_child(icon)
	var ticks: Control = Control.new()
	ticks.custom_minimum_size = Vector2(0, TICK_HEIGHT + 3.0)
	ticks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ticks.draw.connect(_draw_ticks.bind(ticks, int(w["tier"]), UiPalette.tier_color(int(w["tier_index"]))))
	cell.add_child(ticks)
	var name_l: Label = _heading(Loc.weapon_name(w["id"]), CAPTION_SIZE, UiPalette.BONE)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.add_child(name_l)
	return cell


func _draw_ticks(c: Control, count: int, color: Color) -> void:
	var total: float = TICK_STEP * (count - 1)
	var x0: float = (c.size.x - total) * 0.5
	for i: int in count:
		var x: float = x0 + i * TICK_STEP
		c.draw_line(Vector2(x - 2.5, TICK_HEIGHT), Vector2(x + 2.5, 1.0), color, 2.5, true)
