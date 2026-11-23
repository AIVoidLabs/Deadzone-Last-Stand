class_name CreditsScreen
extends MenuPanel
## Emeği geçenler: CREDITS.md özeti (motor, araçlar, yazı tipi, animasyon, model, ses). Kişisel bilgi yok.

const COLUMNS: Array = [
	[
		{"section": &"credits.s.engine", "entries": [
			{"name": "Godot Engine 4.7", "role": &"credits.role.godot", "license": "MIT"},
			{"name": "GUT 9.7", "role": &"credits.role.gut", "license": "MIT"},
			{"name": "Inter", "role": &"credits.role.inter", "license": "SIL OFL 1.1"},
		]},
		{"section": &"credits.s.sound", "entries": [
			{"name": &"credits.name.cc0", "role": &"credits.role.cc0", "license": "CC0 1.0"},
		]},
	],
	[
		{"section": &"credits.s.art", "entries": [
			{"name": "Quaternius", "role": &"credits.role.quaternius", "license": "CC0 1.0"},
			{"name": "Kenney", "role": &"credits.role.kenney", "license": "CC0 1.0"},
			{"name": "Tripo", "role": &"credits.role.tripo", "license": &"credits.license.tripo"},
			{"name": "Deadzone Last Stand", "role": &"credits.role.own", "license": &"credits.license.own"},
		]},
	],
]
const COLUMN_GAP_X: int = 36
const ENTRY_GAP: int = 14
const ENTRY_BG: Color = Color(0.12, 0.095, 0.085, 0.92)
const ACCENT: Color = Color("F08A24")


static func open(parent: Node, on_closed: Callable = Callable()) -> CreditsScreen:
	var screen: CreditsScreen = CreditsScreen.new()
	screen._on_closed = on_closed
	parent.add_child(screen)
	return screen


func _title_key() -> StringName:
	return &"credits.title"


func _fill(column: VBoxContainer) -> void:
	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", COLUMN_GAP_X)
	column.add_child(body)
	for sections: Array in COLUMNS:
		var side: VBoxContainer = VBoxContainer.new()
		side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		side.add_theme_constant_override("separation", ENTRY_GAP)
		body.add_child(side)
		for section: Dictionary in sections:
			side.add_child(make_label(Loc.t(section["section"]), UiFonts.heading(), 24, UiPalette.EMBER))
			for entry: Dictionary in section["entries"]:
				side.add_child(_entry(entry))
	var note: Label = make_label(Loc.t(&"credits.note"), UiFonts.body(), 16, UiPalette.ASH)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(note)
	var made: Label = make_label(Loc.t(&"credits.made"), UiFonts.bold(), 16, UiPalette.BONE)
	made.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(made)
	column.add_child(_make_footer())


func _entry(entry: Dictionary) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", flat_box(ENTRY_BG, ACCENT, 4))
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", -1)
	panel.add_child(box)
	var head: HBoxContainer = HBoxContainer.new()
	box.add_child(head)
	var title: Variant = entry["name"]
	var name_label: Label = make_label(title if title is String else Loc.t(title), UiFonts.bold(), 21, UiPalette.BONE)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_label)
	var license: Variant = entry["license"]
	head.add_child(make_label(license if license is String else Loc.t(license), UiFonts.bold(), 15, ACCENT))
	var role: Label = make_label(Loc.t(entry["role"]), UiFonts.body(), 16, UiPalette.ASH)
	role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(role)
	return panel


## Görüntü aracı (UiShot) için.
static func ui_shot(host: Node, _opts: Dictionary) -> void:
	host.add_child(CreditsScreen.new())
