class_name MainMenu
extends Control
## Ana menü: canlı 3B şehir arka planı (MenuBackdrop), başlık, dört kart (OYNA / REKORLAR / AYARLAR / ÇIKIŞ),
## küçük düğmeler (emeği geçenler, dil, sürüm). Klavye: ok tuşları + Enter, Esc = çıkış onayı.
## Alt ekranlar (rekorlar, emeği geçenler, ayarlar) üstte açılır; menü odağı o sırada kapanır.

const MARGIN: int = 36
const MARGIN_BOTTOM: int = 20
const CARD_GAP: int = 16
const PLAY_SIZE: Vector2 = Vector2(236, 352)
const CARD_SIZE: Vector2 = Vector2(208, 322)
const BAR_HEIGHT: float = 42.0
const BAR_GAP: int = 10
const LANG_BUTTON: Vector2 = Vector2(64, 40)
const CREDITS_BUTTON: Vector2 = Vector2(236, 40)
const INTRO_STEP: float = 0.07
const VIGNETTE_DIM: float = 0.18

## Kart sırası: kimlik, kategori rengi, amblem.
const CARDS: Array[Dictionary] = [
	{"id": &"play", "category": &"combat", "emblem": &"menu_play"},
	{"id": &"records", "category": &"loot", "emblem": &"menu_records"},
	{"id": &"settings", "category": &"motion", "emblem": &"menu_settings"},
	{"id": &"quit", "category": &"survival", "emblem": &"menu_quit"},
]

var _ui: Control = null
var _logo: MenuLogo = null
var _overlay_open: bool = false
var _focusables: Array[Control] = []
var _start_focus: int = 0
var _intro: bool = true


func _ready() -> void:
	name = "MainMenu"
	theme = UiTheme.get_theme()
	UiAssets.fill(self)
	add_child(MenuBackdrop.new())
	add_child(MenuAtmosphere.shades())
	add_child(ScreenBackdrop.create(false, VIGNETTE_DIM))
	MenuAtmosphere.ash(self)
	_build_ui()
	Settings.changed.connect(_on_setting_changed)
	_focus_start.call_deferred()


func _focus_start() -> void:
	if _focusables.is_empty():
		return
	_focusables[clampi(_start_focus, 0, _focusables.size() - 1)].grab_focus()


# ------------------------------------------------------------------ arayüz
func _build_ui() -> void:
	_focusables.clear()
	_ui = MarginContainer.new()
	UiAssets.fill(_ui)
	_ui.add_theme_constant_override("margin_left", MARGIN)
	_ui.add_theme_constant_override("margin_right", MARGIN)
	_ui.add_theme_constant_override("margin_top", MARGIN)
	_ui.add_theme_constant_override("margin_bottom", MARGIN_BOTTOM)
	add_child(_ui)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", BAR_GAP)
	_ui.add_child(column)
	_logo = MenuLogo.new()
	_logo.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(_logo)
	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(spacer)
	column.add_child(_build_cards())
	column.add_child(_build_bar())


func _build_cards() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", CARD_GAP)
	for i: int in CARDS.size():
		var spec: Dictionary = CARDS[i]
		var card: GrungeCard = GrungeCard.new()
		card.card_size = PLAY_SIZE if spec["id"] == &"play" else CARD_SIZE
		card.custom_minimum_size = card.card_size
		card.size_flags_vertical = Control.SIZE_SHRINK_END
		card.setup(_card_data(spec))
		card.set_meta(&"fid", spec["id"])
		card.pressed.connect(_on_card.bind(spec["id"]))
		UiSounds.hook(card, true)
		row.add_child(card)
		_focusables.append(card)
		if _intro:
			card.play_intro.call_deferred(INTRO_STEP * i)
	return row


func _card_data(spec: Dictionary) -> Dictionary:
	var id: StringName = spec["id"]
	var info: Array[Dictionary] = [
		{"text": Loc.t(StringName("menu.%s.desc" % id)), "bold": true},
		{"text": _live_info(id), "color": UiPalette.AMBER},
	]
	var title_key: StringName = &"common.play" if id == &"play" else StringName("menu.%s.title" % id)
	return {
		"category_id": spec["category"], "category": Loc.t(StringName("menu.%s.cat" % id)),
		"title": Loc.t(title_key), "emblem": spec["emblem"], "lines": info, "hint": "",
	}


## Kartların altındaki kısa canlı bilgi (kayıttan ve ayarlardan).
func _live_info(id: StringName) -> String:
	match id:
		&"play":
			var last: Dictionary = RecordsView.last_run(SaveGame.data)
			if last.is_empty():
				return Loc.t(&"menu.play.fresh")
			return Loc.t(&"menu.play.last", [int(last["wave"]), int(last["kills"])])
		&"records":
			var best: int = int(SaveGame.records()["best_wave"])
			return Loc.t(&"menu.records.best", [best]) if RecordsView.has_record(best) else Loc.t(&"menu.records.none")
		&"settings":
			var quality: String = Loc.t(StringName("menu.quality.%s" % Settings.get_value(&"graphics/quality")))
			return Loc.t(&"menu.settings.live", [quality, Loc.t(StringName("lang.%s" % Settings.get_value(&"game/language")))])
		_:
			return Loc.t(&"menu.quit.live")


func _build_bar() -> HBoxContainer:
	var bar: HBoxContainer = HBoxContainer.new()
	bar.custom_minimum_size = Vector2(0.0, BAR_HEIGHT)
	bar.add_theme_constant_override("separation", BAR_GAP)
	var credits: GrungeButton = _small_button(Loc.t(&"menu.credits"), CREDITS_BUTTON, &"credits", &"small")
	credits.pressed.connect(_on_credits)
	bar.add_child(credits)
	var grow: Control = Control.new()
	grow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(grow)
	for lang: StringName in (Loc.LANGS if Tuning.FEATURE_LANGUAGE else [] as Array[StringName]):
		var active: bool = Loc.language == lang
		var button: GrungeButton = _small_button(String(lang).to_upper(), LANG_BUTTON, StringName("lang_%s" % lang), &"primary" if active else &"small")
		button.pressed.connect(func() -> void: Settings.set_value(&"game/language", lang))
		bar.add_child(button)
	var version: Label = Label.new()
	version.text = Loc.t(&"menu.version", [str(ProjectSettings.get_setting("application/config/version", "0.0.1"))])
	version.add_theme_font_override("font", UiFonts.bold())
	version.add_theme_font_size_override("font_size", 14)
	version.add_theme_color_override("font_color", UiPalette.ASH)
	version.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	version.add_theme_constant_override("outline_size", 4)
	version.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(version)
	return bar


func _small_button(text: String, min_size: Vector2, fid: StringName, variant: StringName) -> GrungeButton:
	var button: GrungeButton = GrungeButton.create(text, variant)
	button.custom_minimum_size = min_size
	button.set_meta(&"fid", fid)
	UiSounds.hook(button, true)
	_focusables.append(button)
	return button


# ------------------------------------------------------------------ eylemler
func _on_card(id: StringName) -> void:
	match id:
		&"play":
			GameFlow.start_run()
		&"records":
			_open_overlay(RecordsScreen.open(self, _on_overlay_closed))
		&"settings":
			_open_settings()
		&"quit":
			GrungeConfirm.ask(self, &"confirm.quit.title", &"confirm.quit.body", GameFlow.quit_game)


func _on_credits() -> void:
	_open_overlay(CreditsScreen.open(self, _on_overlay_closed))


func _open_settings() -> void:
	_set_menu_focus(false)
	_overlay_open = true
	SettingsMenu.open(self, _on_overlay_closed)


func _open_overlay(_panel: Control) -> void:
	_set_menu_focus(false)
	_overlay_open = true


func _on_overlay_closed() -> void:
	_overlay_open = false
	_set_menu_focus(true)
	_rebuild()


## Alt ekran açıkken menü kontrolleri odak almaz (oklar altta kalan kartlara kaçmasın).
func _set_menu_focus(enabled: bool) -> void:
	for control: Control in _focusables:
		control.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE


func _on_setting_changed(key: StringName, _value: Variant) -> void:
	# Alt ekran (ayarlar) açıkken yeniden kurma: kapanınca zaten kurulur; aksi hâlde menü ekranın üstüne çıkıp fareyi yakalar.
	if _overlay_open:
		return
	if key == &"game/language" or key == &"graphics/quality":
		_rebuild()


## Metinler yeniden kurulur (dil ya da canlı bilgi değişti); odak aynı kontrole döner.
func _rebuild() -> void:
	var focus_id: StringName = &""
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused != null and focused.has_meta(&"fid"):
		focus_id = focused.get_meta(&"fid")
	var index: int = _ui.get_index()
	_ui.queue_free()
	remove_child(_ui)
	_intro = false
	_build_ui()
	# Eski sırasına: sonradan eklenen alt ekranların altında kalsın.
	move_child(_ui, index)
	if _overlay_open:
		_set_menu_focus(false)
		return
	for control: Control in _focusables:
		if control.get_meta(&"fid", &"") == focus_id:
			control.grab_focus.call_deferred()
			return
	_focus_start.call_deferred()


func _input(event: InputEvent) -> void:
	if _overlay_open or not event.is_action_pressed(&"ui_cancel"):
		return
	if get_tree().get_nodes_in_group(&"grunge_confirm").size() > 0:
		return
	get_viewport().set_input_as_handled()
	_on_card(&"quit")


## Görüntü aracı (UiShot) için: ekranı host içinde kurar. tab=1: örnek kayıtla (dosyaya yazılmaz); tab=2: ek olarak çıkış onayı açık.
static func ui_shot(host: Node, opts: Dictionary) -> void:
	var tab: int = int(opts.get("tab", 0))
	if tab >= 1 and not SaveGame.persistent:
		SaveGame.data = RecordsScreen.sample_save()
	var menu: MainMenu = MainMenu.new()
	menu._start_focus = maxi(int(opts.get("focus", -1)), 0)
	host.add_child(menu)
	if tab == 2:
		menu._on_card.call_deferred(&"quit")
