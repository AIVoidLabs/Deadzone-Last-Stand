class_name MarketScreen
extends CanvasLayer
## Dalga arası mağaza: dört afiş kartı, kilit düğmeleri, silah yuvaları (tıkla: sat, ikinci tıkla onay), istatistik paneli.
## ShopScreen ile aynı sinyaller; ShopFlow her değişiklikte show_view çağırır, kartlar yeniden kurulmaz, fark güncellenir.
## Tuşlar: 1-4 satın al, R yenile, Enter/Boşluk sonraki dalga (odak sonraki dalga düğmesinde başlar), ok tuşlarıyla gezilir.

signal buy_pressed(index: int)
signal lock_pressed(index: int)
signal reroll_pressed
signal sell_pressed(index: int)
signal next_pressed

const LAYER: int = 6
const BACKDROP_DIM: float = 0.66
const MARGIN: int = 22
const SIDE_WIDTH: float = 236.0
const COLUMN_GAP: int = 18
const SECTION_GAP: int = 10
const TITLE_SIZE: int = 42
const CARD_ASPECT: float = 0.68
const CARD_MAX_W: float = 252.0
const CARD_GAP: float = 14.0
const LOCK_HEIGHT: float = 36.0
const LOCK_GAP: float = 6.0
const REROLL_SIZE: Vector2 = Vector2(236.0, 56.0)
const NEXT_SIZE: Vector2 = Vector2(290.0, 64.0)
const BUTTON_GAP: int = 14
const DIM_BUTTON_ALPHA: float = 0.6
const INTRO_STEP: float = 0.08
var _root: Control
var _title: GrungeTitle
var _counter: CrystalCounter
var _stage: Control
var _cards: Array[GrungeCard] = []
var _locks: Array[MarketLock] = []
var _card_data: Array[Dictionary] = []
var _entry_ids: Array[StringName] = []
var _states: Array[String] = []
var _slot_bar: MarketSlotBar
var _tooltip: WeaponTooltip = null
var _side: MarketSide
var _reroll: GrungeButton
var _next: GrungeButton
var _view: Dictionary = {}
var _opened: bool = false


func _ready() -> void:
	name = "MarketScreen"
	Emblems.warm()
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()
	Settings.changed.connect(_on_setting_changed)
	GameFlow.paused_changed.connect(_on_paused_changed)


func close() -> void:
	visible = false
	_opened = false
	_slot_bar.disarm()
	_on_slot_unhovered()


## view: {wave, wave_total, crystals, entries: [{kind, id, state, price, locked, merged, tier, owned}],
## reroll_cost, can_reroll, weapons: [{id, tier, sell, sellable}], owned: {id: adet}, stats: PlayerStats}.
## state: "ok" alınabilir, "poor" kristal yetmez, "full" yuva dolu, "sold" satıldı.
func show_view(view: Dictionary) -> void:
	_view = view
	var first: bool = not _opened
	var entries: Array = view["entries"]
	_ensure_cards(entries.size())
	for i: int in entries.size():
		_update_card(i, entries[i], first)
	_title.set_text(Loc.t(&"run.shop.title"), Loc.t(&"run.shop.wave", [view["wave"], view["wave_total"]]))
	_counter.set_value(int(view["crystals"]), not first)
	_reroll.text = Loc.t(&"run.shop.reroll", [view["reroll_cost"], KeyHint.of(&"restart")])
	_reroll.modulate.a = 1.0 if view["can_reroll"] else DIM_BUTTON_ALPHA
	_next.text = Loc.t(&"run.shop.next")
	_slot_bar.set_texts()
	_slot_bar.sync(view["weapons"])
	_side.refresh(view["stats"], view["owned"])
	visible = true
	_layout()
	if first:
		_opened = true
		_next.grab_focus.call_deferred()


## Görüntü aracı: i. silah yuvasının ipucunu açar.
func hover_slot(index: int) -> void:
	_slot_bar.hover_for_shot(index)


func focus_card(index: int) -> void:
	if index >= 0 and index < _cards.size():
		_cards[index].grab_focus.call_deferred()


# ------------------------------------------------------------------ kurulum
func _build() -> void:
	_root = Control.new()
	UiAssets.fill(_root)
	_root.theme = UiTheme.get_theme()
	add_child(_root)
	_root.add_child(ScreenBackdrop.create(true, BACKDROP_DIM))
	var margin: MarginContainer = MarginContainer.new()
	UiAssets.fill(margin)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, MARGIN)
	_root.add_child(margin)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", COLUMN_GAP)
	margin.add_child(columns)
	_side = MarketSide.new()
	_side.custom_minimum_size.x = SIDE_WIDTH
	_side.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	columns.add_child(_side)
	var center: VBoxContainer = VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", SECTION_GAP)
	columns.add_child(center)
	center.add_child(_build_header())
	_stage = Control.new()
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.resized.connect(_layout)
	center.add_child(_stage)
	center.add_child(_build_bottom())
	if Tuning.FEATURE_WEAPON_TOOLTIP:
		_tooltip = WeaponTooltip.new()
		_root.add_child(_tooltip)


func _build_header() -> HBoxContainer:
	var header: HBoxContainer = HBoxContainer.new()
	_title = GrungeTitle.new()
	_title.font_size = TITLE_SIZE
	_title.alignment = BoxContainer.ALIGNMENT_BEGIN
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	_counter = CrystalCounter.new()
	header.add_child(_counter)
	return header


func _build_bottom() -> HBoxContainer:
	var bottom: HBoxContainer = HBoxContainer.new()
	bottom.add_theme_constant_override("separation", BUTTON_GAP)
	_slot_bar = MarketSlotBar.new()
	_slot_bar.sell_pressed.connect(sell_pressed.emit)
	_slot_bar.slot_hovered.connect(_on_slot_hovered)
	_slot_bar.slot_unhovered.connect(_on_slot_unhovered)
	bottom.add_child(_slot_bar)
	_reroll = GrungeButton.create("")
	_reroll.custom_minimum_size = REROLL_SIZE
	_reroll.pressed.connect(_on_reroll_pressed)
	UiSounds.hook(_reroll)
	bottom.add_child(_reroll)
	_next = GrungeButton.create("", &"primary")
	_next.custom_minimum_size = NEXT_SIZE
	_next.pressed.connect(next_pressed.emit)
	UiSounds.hook(_next)
	bottom.add_child(_next)
	return bottom


func _ensure_cards(count: int) -> void:
	while _cards.size() > count:
		var card: GrungeCard = _cards.pop_back()
		var lock: MarketLock = _locks.pop_back()
		card.queue_free()
		lock.queue_free()
		_card_data.pop_back()
		_entry_ids.pop_back()
		_states.pop_back()
	while _cards.size() < count:
		var index: int = _cards.size()
		var card: GrungeCard = GrungeCard.new()
		card.pressed.connect(_on_card_pressed.bind(index))
		UiSounds.hook(card)
		_stage.add_child(card)
		var lock: MarketLock = MarketLock.new()
		lock.pressed.connect(lock_pressed.emit.bind(index))
		UiSounds.hook(lock)
		_stage.add_child(lock)
		_cards.append(card)
		_locks.append(lock)
		_card_data.append({})
		_entry_ids.append(&"")
		_states.append("")


## Yalnız değişen kart yeniden kurulur; yeni ürün gelince (yenileme) o kart kısa bir giriş oynar.
func _update_card(index: int, entry: Dictionary, first: bool) -> void:
	var card: GrungeCard = _cards[index]
	var data: Dictionary = MarketCards.card_data(entry, index)
	var id: StringName = StringName(String(entry["kind"]) + ":" + String(entry["id"]))
	if data != _card_data[index]:
		card.setup(data)
		_card_data[index] = data
	if first:
		card.play_intro(index * INTRO_STEP)
	elif id != _entry_ids[index]:
		card.play_intro(0.0)
	elif _states[index] != "sold" and entry["state"] == "sold":
		MarketFx.stamp(card)
	_entry_ids[index] = id
	_states[index] = entry["state"]
	_locks[index].set_state(entry["locked"], entry["state"] != "sold")


## Kartlar sahnede elle dizilir: kart + altında kilit düğmesi, ortalı.
func _layout() -> void:
	var n: int = _cards.size()
	if n == 0 or _stage.size.x < 1.0:
		return
	var width: float = minf(CARD_MAX_W, (_stage.size.x - CARD_GAP * (n - 1)) / n)
	var height: float = width / CARD_ASPECT
	var room: float = _stage.size.y - LOCK_HEIGHT - LOCK_GAP
	if height > room:
		height = room
		width = height * CARD_ASPECT
	var total: float = width * n + CARD_GAP * (n - 1)
	var origin: Vector2 = Vector2((_stage.size.x - total) * 0.5, (_stage.size.y - (height + LOCK_GAP + LOCK_HEIGHT)) * 0.5)
	for i: int in n:
		var x: float = origin.x + i * (width + CARD_GAP)
		_cards[i].card_size = Vector2(width, height)
		_cards[i].size = Vector2(width, height)
		_cards[i].position = Vector2(x, origin.y)
		_locks[i].size = Vector2(width, LOCK_HEIGHT)
		_locks[i].position = Vector2(x, origin.y + height + LOCK_GAP)


## Açık satış onayı Esc ile kapanır; duraklatma menüsü açılmaz.
func _input(input_event: InputEvent) -> void:
	if _slot_bar.is_armed() and visible and input_event.is_action_pressed(&"pause"):
		_slot_bar.disarm()
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ eylemler ve efektler
func _on_card_pressed(index: int) -> void:
	var state: String = _states[index]
	if state == "sold":
		return
	if state != "ok":
		MarketFx.wobble(_cards[index])
		_counter.pulse(UiPalette.BAD)
	buy_pressed.emit(index)


func _on_slot_hovered(slot: MarketSlot, id: StringName, tier: int) -> void:
	if _tooltip != null:
		_tooltip.show_for(slot, id, tier)


func _on_slot_unhovered() -> void:
	if _tooltip != null:
		_tooltip.hide_tip()


func _on_reroll_pressed() -> void:
	if not _view.get("can_reroll", false):
		MarketFx.wobble(_reroll)
		_counter.pulse(UiPalette.BAD)
	reroll_pressed.emit()


func _unhandled_input(input_event: InputEvent) -> void:
	if not visible or not (input_event is InputEventKey) or not input_event.is_pressed() or input_event.is_echo():
		return
	if GameFlow.is_paused_by(&"pause"):
		return
	var code: Key = (input_event as InputEventKey).physical_keycode
	var index: int = code - KEY_1
	if index >= 0 and index < _cards.size():
		get_viewport().set_input_as_handled()
		_on_card_pressed(index)
	elif input_event.is_action_pressed(&"restart"):
		get_viewport().set_input_as_handled()
		_on_reroll_pressed()
	elif code == KEY_ENTER or code == KEY_KP_ENTER or code == KEY_SPACE:
		get_viewport().set_input_as_handled()
		next_pressed.emit()


func _on_setting_changed(key: StringName, _value: Variant) -> void:
	if key == &"game/language" and not _view.is_empty():
		show_view(_view)


## Duraklatma menüsü açıkken bu ekran girdi almaz.
func _on_paused_changed(_paused: bool) -> void:
	process_mode = Node.PROCESS_MODE_DISABLED if GameFlow.is_paused_by(&"pause") else Node.PROCESS_MODE_ALWAYS


## Görüntü aracı (UiShot): sahte veriyle kurar (MarketShot).
static func ui_shot(host: Node, opts: Dictionary) -> void:
	MarketShot.build(host, opts)
