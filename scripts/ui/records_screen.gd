class_name RecordsScreen
extends MenuPanel
## Rekorlar: dört rekor, toplamlar, son 10 tur. Kayıt boşsa boş durum. KAYITLARI SIFIRLA onaylıdır.

const RECORD_TILES: Array[Dictionary] = [
	{"key": &"best_wave", "icon": &"icon_wave", "color": Color("E0241B")},
	{"key": &"most_kills", "icon": &"icon_kill", "color": Color("FF8A1E")},
	{"key": &"fastest_win", "icon": &"icon_time", "color": Color("5FA8E6")},
	{"key": &"best_level", "icon": &"icon_level", "color": Color("E0B43A")},
]
const TOTAL_KEYS: Array[StringName] = [&"runs", &"wins", &"kills", &"crystals", &"play_time"]
## Geçmiş sütunları: başlık anahtarı, genişlik, hizalama (0 sol, 1 orta, 2 sağ).
const HISTORY_COLUMNS: Array[Dictionary] = [
	{"title": "#", "width": 34, "align": 1},
	{"title": &"rec.col.result", "width": 112, "align": 0},
	{"title": &"common.wave", "width": 76, "align": 2},
	{"title": &"common.kills", "width": 104, "align": 2},
	{"title": &"common.level", "width": 90, "align": 2},
	{"title": &"common.time", "width": 74, "align": 2},
	{"title": &"rec.col.date", "width": 112, "align": 2},
]
const LEFT_WIDTH: float = 400.0
const TILE_HEIGHT: float = 96.0
const ROW_HEIGHT: float = 30.0
const ZEBRA: Color = Color(1, 1, 1, 0.045)
const TILE_BG: Color = Color(0.12, 0.095, 0.085, 0.92)
const ICON_SIZE: float = 44.0
const EMPTY_ICON_SIZE: float = 150.0
const SAMPLE_RUNS: int = 12

var _save: Dictionary = {}


static func open(parent: Node, on_closed: Callable = Callable()) -> RecordsScreen:
	var screen: RecordsScreen = RecordsScreen.new()
	screen._on_closed = on_closed
	parent.add_child(screen)
	return screen


func _title_key() -> StringName:
	return &"rec.title"


func _fill(column: VBoxContainer) -> void:
	var save: Dictionary = _save if not _save.is_empty() else SaveGame.data
	if not RecordsView.has_data(save):
		_fill_empty(column)
		return
	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 28)
	column.add_child(body)
	var left: VBoxContainer = VBoxContainer.new()
	left.custom_minimum_size = Vector2(LEFT_WIDTH, 0.0)
	left.add_theme_constant_override("separation", 12)
	body.add_child(left)
	left.add_child(_record_grid(save["records"]))
	left.add_child(_totals(save["totals"]))
	var right: VBoxContainer = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 4)
	body.add_child(right)
	_fill_history(right, save["history"])
	var reset: GrungeButton = GrungeButton.create(Loc.t(&"rec.reset"), &"danger")
	reset.custom_minimum_size = BUTTON_SIZE
	reset.pressed.connect(_ask_reset)
	UiSounds.hook(reset, true)
	column.add_child(_make_footer([reset]))


func _fill_empty(column: VBoxContainer) -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	column.add_child(box)
	var icon: TextureRect = TextureRect.new()
	icon.texture = Emblems.tex(&"menu_records")
	icon.custom_minimum_size = Vector2(EMPTY_ICON_SIZE, EMPTY_ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color(1, 1, 1, 0.5)
	box.add_child(icon)
	var title: Label = make_label(Loc.t(&"rec.empty.title"), UiFonts.heading(), 46, UiPalette.EMBER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var body: Label = make_label(Loc.t(&"rec.empty.body"), UiFonts.body(), 20, UiPalette.BONE)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(560.0, 0.0)
	body.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(body)
	column.add_child(_make_footer())


func _record_grid(records: Dictionary) -> GridContainer:
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for tile: Dictionary in RECORD_TILES:
		grid.add_child(_tile(tile, records[tile["key"]]))
	return grid


func _tile(spec: Dictionary, value: Variant) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2((LEFT_WIDTH - 10.0) * 0.5, TILE_HEIGHT)
	panel.add_theme_stylebox_override("panel", flat_box(TILE_BG, spec["color"], 5))
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var icon: TextureRect = TextureRect.new()
	icon.texture = Emblems.tex(spec["icon"])
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var text: VBoxContainer = VBoxContainer.new()
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_theme_constant_override("separation", -2)
	row.add_child(text)
	var shown: String = "-"
	if RecordsView.has_record(value):
		shown = Loc.clock(float(value)) if spec["key"] == &"fastest_win" else str(int(value))
	text.add_child(make_label(shown, UiFonts.heading(), 40, UiPalette.BONE if shown != "-" else UiPalette.ASH))
	text.add_child(make_label(Loc.t(StringName("rec.%s" % spec["key"])), UiFonts.bold(), 13, UiPalette.ASH))
	return panel


func _totals(totals: Dictionary) -> VBoxContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.add_child(make_label(Loc.t(&"rec.totals"), UiFonts.heading(), 22, UiPalette.EMBER))
	for key: StringName in TOTAL_KEYS:
		var row: HBoxContainer = HBoxContainer.new()
		var name_key: StringName = &"common.kills" if key == &"kills" else (&"common.crystals" if key == &"crystals" else StringName("rec.t.%s" % key))
		var label: Label = make_label(Loc.t(name_key), UiFonts.bold(), 16, UiPalette.ASH)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var shown: String = _duration_text(float(totals[key])) if key == &"play_time" else str(int(totals[key]))
		row.add_child(make_label(shown, UiFonts.bold(), 18, UiPalette.BONE))
		box.add_child(row)
	return box


func _duration_text(seconds: float) -> String:
	var parts: Dictionary = RecordsView.time_parts(seconds)
	if int(parts["h"]) > 0:
		return Loc.t(&"rec.hours", [int(parts["h"]), int(parts["m"])])
	return Loc.t(&"common.minutes_seconds", [int(parts["m"]), int(parts["s"])])


func _fill_history(box: VBoxContainer, history: Array) -> void:
	box.add_child(make_label(Loc.t(&"rec.history"), UiFonts.heading(), 22, UiPalette.EMBER))
	box.add_child(_history_row(null, true))
	for entry: Dictionary in RecordsView.rows(history):
		box.add_child(_history_row(entry, false))


func _history_row(entry: Variant, header: bool) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	var zebra: bool = not header and int((entry as Dictionary)["index"]) % 2 == 1
	var sb: StyleBoxFlat = flat_box(ZEBRA if zebra else Color(0, 0, 0, 0))
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", sb)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	panel.add_child(row)
	var cells: Array = _header_cells() if header else _entry_cells(entry)
	for i: int in HISTORY_COLUMNS.size():
		var spec: Dictionary = HISTORY_COLUMNS[i]
		var cell: Dictionary = cells[i]
		var label: Label = make_label(cell["text"], UiFonts.bold(), 13 if header else 16, cell["color"])
		label.custom_minimum_size = Vector2(float(spec["width"]), 0.0)
		label.horizontal_alignment = [HORIZONTAL_ALIGNMENT_LEFT, HORIZONTAL_ALIGNMENT_CENTER, HORIZONTAL_ALIGNMENT_RIGHT][int(spec["align"])]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL if i == 1 else Control.SIZE_FILL
		row.add_child(label)
	return panel


func _header_cells() -> Array:
	var cells: Array = []
	for spec: Dictionary in HISTORY_COLUMNS:
		var title: Variant = spec["title"]
		cells.append({"text": title if title is String else Loc.t(title), "color": UiPalette.ASH})
	return cells


func _entry_cells(entry: Dictionary) -> Array:
	var won: bool = bool(entry["won"])
	var bias: int = int(Time.get_time_zone_from_system()["bias"])
	var date: String = RecordsView.date_text(int(entry["stamp"]), bias)
	return [
		{"text": str(int(entry["index"])), "color": UiPalette.ASH},
		{"text": Loc.t(&"rec.win" if won else &"rec.loss"), "color": UiPalette.GOOD if won else UiPalette.BAD},
		{"text": str(int(entry["wave"])), "color": UiPalette.BONE},
		{"text": str(int(entry["kills"])), "color": UiPalette.BONE},
		{"text": str(int(entry["level"])), "color": UiPalette.BONE},
		{"text": Loc.clock(float(entry["time"])), "color": UiPalette.BONE},
		{"text": date if date != "" else "-", "color": UiPalette.ASH},
	]


func _ask_reset() -> void:
	GrungeConfirm.ask(self, &"confirm.reset.title", &"confirm.reset.body", _do_reset)


func _do_reset() -> void:
	if _save.is_empty():
		SaveGame.reset_all()
	else:
		_save = RunRecord.empty()
	_refresh()


## Görüntü aracı için örnek kayıt (dosyaya yazılmaz): karışık galibiyet ve yenilgiler.
static func sample_save() -> Dictionary:
	var save: Dictionary = RunRecord.empty()
	var now: int = int(Time.get_unix_time_from_system())
	for i: int in SAMPLE_RUNS:
		var won: bool = i % 5 == 3
		var wave: int = 20 if won else 6 + (i * 7) % 13
		save = RunRecord.apply_run(save, {
			"won": won, "wave": wave, "kills": 120 + wave * 38 + (i * 53) % 90, "crystals": 400 + wave * 25,
			"level": 5 + wave / 2, "time": 150.0 + wave * 31.0 + i * 9.0, "stamp": now - i * 7300,
		})["save"]
	return save


## Görüntü aracı (UiShot) için. tab=1: örnek kayıt; 0: gerçek (genelde boş) kayıt.
static func ui_shot(host: Node, opts: Dictionary) -> void:
	var screen: RecordsScreen = RecordsScreen.new()
	if int(opts.get("tab", 0)) == 1:
		screen._save = sample_save()
	host.add_child(screen)
