class_name EndSummary
extends GrungePanel
## Tur sonu özet paneli: sayarak dolan sekiz satır, yeni rekor damgaları, en çok öldürülen türler, silah ve kart amblemleri.
## set_progress(t) sayacı sürer; finish() hepsini son haline getirir (animasyon atlanır).

const STAGGER: float = 0.11
const COUNT_TIME: float = 0.8
const CELL_ICON: float = 34.0
const CAPTION_SIZE: int = 13
const VALUE_SIZE: int = 29
const GRID_GAP: int = 30
const KIND_ROWS: int = 3
const TILE_SIZE: float = 46.0
const STAMP_SIZE: int = 12
const STAMP_TILT_DEG: float = -7.0
const STAMP_FROM_SCALE: float = 2.0
const STAMP_TIME: float = 0.22
## Satır tanımı: [özet anahtarı, başlık anahtarı, amblem, yedek simge]
const ROWS: Array[Array] = [
	[&"wave", &"end.stat.wave", &"icon_wave"],
	[&"time", &"end.stat.time", &"icon_time"],
	[&"kills", &"end.stat.kills", &"icon_kill"],
	[&"crystals", &"end.stat.crystals", &"icon_crystal"],
	[&"level", &"end.stat.level", &"icon_level"],
	[&"dealt", &"end.stat.dealt", &"stat_damage"],
	[&"taken", &"end.stat.taken", &"stat_max_hp"],
	[&"dashes", &"end.stat.dashes", &"stat_dash_distance"],
]

var _values: Dictionary = {}
var _targets: Dictionary = {}
var _shown: Dictionary = {}
var _stamps: Array[Control] = []
var _cells: Array[Control] = []
var _total_waves: int = 0


## Toplam süre (satır gecikmeleri dahil).
static func total_time() -> float:
	return STAGGER * float(ROWS.size()) + COUNT_TIME


func build(summary: Dictionary, flags: Dictionary, total_waves: int) -> void:
	_total_waves = total_waves
	_targets = {
		&"wave": int(summary.get("wave", 1)), &"time": int(summary.get("time", 0.0)), &"kills": int(summary.get("kills", 0)),
		&"crystals": int(summary.get("crystals", 0)), &"level": int(summary.get("level", 1)),
		&"dealt": roundi(float(summary.get("damage_dealt", 0.0))), &"taken": roundi(float(summary.get("damage_taken", 0.0))),
		&"dashes": int(summary.get("dashes", 0)),
	}
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	box.add_child(_build_grid(flags))
	box.add_child(_separator())
	var lower: HBoxContainer = HBoxContainer.new()
	lower.add_theme_constant_override("separation", GRID_GAP)
	lower.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(lower)
	lower.add_child(_build_kinds(summary.get("kills_by_kind", {})))
	lower.add_child(_build_gear(summary))
	set_progress(0.0)


func _build_grid(flags: Dictionary) -> GridContainer:
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", GRID_GAP)
	grid.add_theme_constant_override("v_separation", 8)
	for row: Array in ROWS:
		var cell: HBoxContainer = HBoxContainer.new()
		cell.add_theme_constant_override("separation", 10)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon: HudIcon = HudIcon.create(row[2], HudIcon.Glyph.BULLET, UiPalette.EMBER, CELL_ICON)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cell.add_child(icon)
		var texts: VBoxContainer = VBoxContainer.new()
		texts.add_theme_constant_override("separation", -3)
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_child(texts)
		texts.add_child(_label(Loc.t(row[1]), CAPTION_SIZE, UiPalette.ASH))
		var value: Label = _label("", VALUE_SIZE, UiPalette.BONE)
		texts.add_child(value)
		_values[row[0]] = value
		if flags.get(row[0], false):
			var stamp: Control = _make_stamp()
			stamp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			cell.add_child(stamp)
			_stamps.append(stamp)
		_cells.append(cell)
		grid.add_child(cell)
	return grid


func _make_stamp() -> Control:
	var holder: Control = Control.new()
	holder.custom_minimum_size = Vector2(92.0, 30.0)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.rotation_degrees = STAMP_TILT_DEG
	holder.resized.connect(func() -> void: holder.pivot_offset = holder.size * 0.5)
	var plate: TextureRect = UiAssets.brush_rect("band_c", UiPalette.BLOOD, 0.5)
	UiAssets.fill(plate)
	holder.add_child(plate)
	var text: Label = _label(Loc.t(&"end.record"), STAMP_SIZE, UiPalette.BONE)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiAssets.fill(text)
	holder.add_child(text)
	holder.modulate.a = 0.0
	return holder


func _separator() -> Control:
	var line: TextureRect = UiAssets.brush_rect("band_a", Color(UiPalette.ASH, 0.35), 0.4)
	line.custom_minimum_size = Vector2(0.0, 6.0)
	return line


func _label(text: String, font_size: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_override("font", UiFonts.heading())
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _section(title: String) -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(_label(title, CAPTION_SIZE, UiPalette.ASH))
	return column


func _build_kinds(kills_by_kind: Dictionary) -> VBoxContainer:
	var column: VBoxContainer = _section(Loc.t(&"end.top_kills"))
	var top: Array[Dictionary] = EndRules.top_kinds(kills_by_kind, KIND_ROWS)
	if top.is_empty():
		column.add_child(_label(Loc.t(&"end.none"), 16, UiPalette.ASH))
	var peak: float = float(top[0]["count"]) if not top.is_empty() else 1.0
	for entry: Dictionary in top:
		var line: HBoxContainer = HBoxContainer.new()
		line.add_child(_label(Loc.enemy_name(entry["id"]), 15, UiPalette.BONE))
		var count: Label = _label(_fmt(entry["count"]), 17, UiPalette.BONE)
		count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		line.add_child(count)
		column.add_child(line)
		var bar: GrungeBar = GrungeBar.new()
		bar.custom_minimum_size = Vector2(0.0, 7.0)
		bar.fill_color = UiPalette.BLOOD
		bar.set_value(float(entry["count"]), peak)
		column.add_child(bar)
	return column


func _build_gear(summary: Dictionary) -> VBoxContainer:
	var column: VBoxContainer = _section(Loc.t(&"end.weapons"))
	var weapons: HFlowContainer = HFlowContainer.new()
	weapons.add_theme_constant_override("h_separation", 6)
	weapons.add_theme_constant_override("v_separation", 6)
	column.add_child(weapons)
	for slot: Variant in summary.get("weapons", []):
		var id: StringName = StringName(slot.get("id", &"")) if slot is Dictionary else StringName(slot)
		var tier: int = int(slot.get("tier", 1)) if slot is Dictionary else 1
		weapons.add_child(EndTile.make(StringName("weapon_" + String(id)), 0, -1, tier))
	if weapons.get_child_count() == 0:
		weapons.add_child(_label(Loc.t(&"end.none"), 16, UiPalette.ASH))
	column.add_child(_label(Loc.t(&"end.cards"), CAPTION_SIZE, UiPalette.ASH))
	var cards: HFlowContainer = HFlowContainer.new()
	cards.add_theme_constant_override("h_separation", 6)
	cards.add_theme_constant_override("v_separation", 6)
	column.add_child(cards)
	for group: Dictionary in EndRules.card_groups(summary.get("cards", [])):
		cards.add_child(EndTile.make(StringName("stat_" + String(group["stat"])), group["count"], group["tier"]))
	if cards.get_child_count() == 0:
		cards.add_child(_label(Loc.t(&"end.none"), 16, UiPalette.ASH))
	return column


func _fmt(value: int) -> String:
	return EndRules.group_digits(value, "." if Loc.language == &"tr" else ",")


func _text_for(key: StringName, value: int) -> String:
	if key == &"wave":
		return "%d/%d" % [value, _total_waves] if _total_waves > 0 else str(value)
	if key == &"time":
		return Loc.clock(float(value))
	return _fmt(value)


## t: geçen saniye. Yalnız değişen satırın metnini günceller.
func set_progress(t: float) -> void:
	for i: int in ROWS.size():
		var key: StringName = ROWS[i][0]
		var target: int = _targets[key]
		var value: int = target if key == &"wave" else EndRules.counted(target, EndRules.row_progress(t, i, STAGGER, COUNT_TIME))
		if _shown.get(key, -1) != value:
			_shown[key] = value
			(_values[key] as Label).text = _text_for(key, value)


## Animasyonlu giriş: satırlar sırayla belirir.
func play_intro() -> void:
	for i: int in _cells.size():
		UiMotion.pop_in(_cells[i], float(i) * STAGGER)


## Sayaçlar bitti: damgalar vurulur.
func finish() -> void:
	set_progress(total_time())
	for stamp: Control in _stamps:
		stamp.modulate.a = 1.0
		if Tuning.FEATURE_UI_MOTION:
			stamp.scale = Vector2.ONE * STAMP_FROM_SCALE
			var tween: Tween = stamp.create_tween()
			tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tween.tween_property(stamp, "scale", Vector2.ONE, STAMP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Animasyon atlanınca hepsi anında son halinde (damgalar vuruşsuz).
func finish_now() -> void:
	set_progress(total_time())
	for cell: Control in _cells:
		cell.modulate.a = 1.0
		cell.scale = Vector2.ONE
	for stamp: Control in _stamps:
		stamp.modulate.a = 1.0
		stamp.scale = Vector2.ONE


class EndTile extends Control:
	var _emblem: StringName = &""
	var _count: int = 0
	var _tier: int = -1
	## Silah kademesi: alt kenarda bu kadar çizgi (0 = yok).
	var _bars: int = 0

	static func make(emblem: StringName, count: int, tier: int, bars: int = 0) -> EndTile:
		var tile: EndTile = EndTile.new()
		tile._emblem = emblem
		tile._count = count
		tile._tier = tier
		tile._bars = bars
		tile.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return tile

	func _draw() -> void:
		var rect: Rect2 = Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color(UiPalette.INK, 0.8))
		draw_rect(rect, Color(UiPalette.ASH, 0.4), false, 1.5)
		draw_texture_rect(Emblems.tex(_emblem), rect.grow(-3.0), false)
		if _tier >= 0:
			draw_rect(Rect2(3.0, size.y - 5.0, size.x - 6.0, 3.0), UiPalette.tier_color(_tier))
		for i: int in _bars:
			draw_rect(Rect2(4.0 + i * 7.0, size.y - 5.0, 5.0, 2.5), UiPalette.tier_color(clampi(_bars - 1, 0, 3)))
		if _count > 1:
			var font: Font = UiFonts.heading()
			var text: String = "x%d" % _count
			var w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			draw_string(font, Vector2(size.x - w - 3.0, size.y - 9.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiPalette.BONE)
