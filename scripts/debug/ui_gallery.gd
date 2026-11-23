extends Control
## UI kiti galerisi (yalnız debug): 12 kart, hero kartlar, düğme / çubuk / ayar satırları.
## Aç: godot --path . res://scenes/debug/ui_gallery.tscn [-- --view=cards|hero|kit --capture=build/shots/x.png --capture-seconds=2]

const DEFAULT_CAPTURE_SECONDS: float = 2.0
const GRID_CARD_SIZE: Vector2 = Vector2(184, 272)
const HERO_CARD_SIZE: Vector2 = Vector2(300, 446)
const GAP: int = 12
const CARDS: Array = [
	{"category_id": &"combat", "category": "SAVAŞ", "title": "HASAR", "emblem": &"stat_damage", "tier": 0, "tier_name": "SIRADAN", "hint": "1", "lines": [{"text": "Hasar", "bold": true}, {"text": "+5 > +8"}]},
	{"category_id": &"combat", "category": "SAVAŞ", "title": "ATEŞ HIZI", "emblem": &"stat_fire_rate", "tier": 1, "tier_name": "NADİR", "hint": "2", "lines": [{"text": "Ateş hızı", "bold": true}, {"text": "%0 > %12,5"}]},
	{"category_id": &"survival", "category": "DİRENİŞ", "title": "ÇELİK YÜREK", "emblem": &"stat_max_hp", "tier": 2, "tier_name": "DESTANSI", "hint": "3", "lines": [{"text": "Azami can", "bold": true}, {"text": "100 > 130"}]},
	{"category_id": &"survival", "category": "DİRENİŞ", "title": "ZIRH", "emblem": &"stat_armor", "tier": 3, "tier_name": "EFSANEVİ", "hint": "4", "lines": [{"text": "Zırh", "bold": true}, {"text": "+4 hasar emilir", "color": UiPalette.GOOD}]},
	{"category_id": &"motion", "category": "HAREKET", "title": "ÇEVİKLİK", "emblem": &"stat_move_speed", "tier": 1, "tier_name": "NADİR", "lines": [{"text": "Hareket hızı", "bold": true}, {"text": "%0 > %8"}]},
	{"category_id": &"motion", "category": "HAREKET", "title": "TAKLA MESAFESİ", "emblem": &"stat_dash_distance", "tier": 0, "tier_name": "SIRADAN", "lines": [{"text": "Takla mesafesi", "bold": true}, {"text": "%0 > %16"}]},
	{"category_id": &"loot", "category": "GANİMET", "title": "ŞANS", "emblem": &"stat_luck", "tier": 2, "tier_name": "DESTANSI", "lines": [{"text": "Şans", "bold": true}, {"text": "+15"}]},
	{"category_id": &"loot", "category": "GANİMET", "title": "MIKNATIS", "emblem": &"stat_pickup_range", "tier": 0, "tier_name": "SIRADAN", "lines": [{"text": "Toplama alanı", "bold": true}, {"text": "%0 > %30"}]},
	{"category_id": &"weapon", "category": "SİLAH", "title": "POMPALI", "emblem": &"weapon_shotgun", "price": 120, "hint": "5", "lines": [{"text": "Yakın mesafede yıkıcı", "bold": true}, {"text": "Hasar 8x6   Menzil kısa"}]},
	{"category_id": &"weapon", "category": "SİLAH", "title": "KESKİN NİŞANCI TÜFEĞİ", "emblem": &"weapon_smg", "price": 480, "state": &"poor", "state_text": "YETERSİZ", "lines": [{"text": "Delici mermi", "bold": true}, {"text": "Hasar 60  Yavaş ateş"}]},
	{"category_id": &"loot", "category": "GANİMET", "title": "KRİSTAL PAYI", "emblem": &"weapon_plasma_rifle", "price": 75, "price_color": UiPalette.GOLD, "tier": 1, "tier_name": "NADİR", "lines": [{"text": "Her kristal %10 fazla", "bold": true}, {"text": "Yalnız bu tur", "color": UiPalette.ASH}]},
	{"category_id": &"survival", "category": "DİRENİŞ", "title": "ZIRHLI YELEK", "emblem": &"stat_armor", "price": 90, "state": &"sold", "state_text": "SATILDI", "lines": [{"text": "Zırh +3", "bold": true}]},
]

var _capture_path: String = ""
var _capture_seconds: float = DEFAULT_CAPTURE_SECONDS
var _time: float = 0.0
var _view: String = "cards"


func _ready() -> void:
	if not OS.is_debug_build():
		get_tree().quit()
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			_capture_path = arg.trim_prefix("--capture=")
		elif arg.begins_with("--capture-seconds="):
			_capture_seconds = arg.trim_prefix("--capture-seconds=").to_float()
		elif arg.begins_with("--view="):
			_view = arg.trim_prefix("--view=")
	theme = UiTheme.get_theme()
	_add_scene_underlay()
	add_child(ScreenBackdrop.create(true, 0.62))
	match _view:
		"hero":
			_build_hero()
		"kit":
			_build_kit()
		_:
			_build_cards()


## Bulanıklığı sınamak için arkada renkli, parlak bir "sahne".
func _add_scene_underlay() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.22, 0.2, 0.18)
	add_child(bg)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5
	for i: int in 40:
		var r: ColorRect = ColorRect.new()
		r.size = Vector2(rng.randf_range(30, 160), rng.randf_range(30, 120))
		r.position = Vector2(rng.randf_range(0, 1500), rng.randf_range(0, 800))
		r.color = [Color(0.9, 0.5, 0.15), Color(0.2, 0.4, 0.8), Color(0.15, 0.15, 0.15), Color(0.7, 0.1, 0.1)][i % 4]
		add_child(r)


func _title(accent: String, rest: String) -> GrungeTitle:
	var t: GrungeTitle = GrungeTitle.new()
	t.font_size = 40
	t.set_text(accent, rest)
	t.set_anchors_preset(Control.PRESET_TOP_WIDE)
	t.offset_top = 6
	t.offset_bottom = 60
	add_child(t)
	return t


func _build_cards() -> void:
	_title("SEÇİM", "YAP")
	var grid: GridContainer = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", GAP)
	grid.add_theme_constant_override("v_separation", GAP)
	grid.set_anchors_preset(Control.PRESET_CENTER)
	grid.grow_horizontal = Control.GROW_DIRECTION_BOTH
	grid.grow_vertical = Control.GROW_DIRECTION_BOTH
	grid.offset_top = 40
	add_child(grid)
	for i: int in CARDS.size():
		var c: GrungeCard = GrungeCard.new()
		c.card_size = GRID_CARD_SIZE
		grid.add_child(c)
		c.setup(CARDS[i])
		c.play_intro(i * 0.03)
	(grid.get_child(1) as Control).grab_focus.call_deferred()


func _build_hero() -> void:
	_title("SEÇİM", "YAP")
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.set_anchors_preset(Control.PRESET_CENTER)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	row.offset_top = 40
	add_child(row)
	for i: int in [0, 2, 4]:
		var c: GrungeCard = GrungeCard.new()
		c.card_size = HERO_CARD_SIZE
		row.add_child(c)
		c.setup(CARDS[i])
	(row.get_child(1) as Control).grab_focus.call_deferred()


func _build_kit() -> void:
	var panel: GrungePanel = GrungePanel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var t: GrungeTitle = GrungeTitle.new()
	t.font_size = 42
	t.set_text("AYARLAR", "ve SES")
	box.add_child(t)
	var sl: SliderRow = SliderRow.new()
	sl.setup("Ana ses", 0.7)
	box.add_child(sl)
	var tg: ToggleRow = ToggleRow.new()
	tg.setup("Ekran sarsıntısı", true, "AÇIK", "KAPALI")
	box.add_child(tg)
	var ch: ChoiceRow = ChoiceRow.new()
	ch.setup("Kalite", ["DÜŞÜK", "ORTA", "YÜKSEK"], 1)
	box.add_child(ch)
	var hp: GrungeBar = GrungeBar.new()
	hp.notch = 0.1
	box.add_child(hp)
	hp.set_value(70.0, 100.0)
	for v: StringName in [&"primary", &"normal", &"danger", &"small"]:
		var b: GrungeButton = GrungeButton.create("OYNA" if v == &"primary" else ("AYARLAR" if v == &"normal" else ("ÇIKIŞ" if v == &"danger" else "GERİ")), v)
		box.add_child(b)
	(box.get_child(5) as Control).grab_focus.call_deferred()


func _process(delta: float) -> void:
	if _capture_path == "":
		return
	_time += delta
	if _time < _capture_seconds:
		return
	var path: String = ProjectSettings.globalize_path("res://").path_join(_capture_path)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURE ", _capture_path)
	get_tree().quit()
