class_name PerkScreen
extends CanvasLayer
## Kart (perk) seçim ekranı: üç büyük afiş kartı, kalan seçim sayısı, altta mevcut istatistik şeridi.
## Eski CardScreen ile aynı arayüz: signal chosen(index), show_offer, close. Tuşlar: 1/2/3, ok + Enter, fare.
## Seçim: kart patlar, diğerleri düşer (PICK_TIME), sonra chosen yayılır. FEATURE_UI_MOTION kapalıysa anında.

signal chosen(index: int)

const LAYER: int = 5
const BACKDROP_DIM: float = 0.62
const MARGIN: int = 20
const SECTION_GAP: int = 6
const TITLE_SIZE: int = 54
const COUNT_SIZE: int = 20
const STRIP_SIZE: int = 17
const STRIP_MAX_WIDTH: float = 1100.0
const CARD_ASPECT: float = 0.667
const CARD_MAX_H: float = 450.0
const CARD_GAP: float = 0.09
const INTRO_STEP: float = 0.09
const PICK_TIME: float = 0.35
const FALL_DISTANCE: float = 460.0
const FALL_TILT: float = 0.22
const FALL_STAGGER: float = 0.03
## Görüntü aracı örneği: [istatistik, artış] (şerit ve "şimdiki" değerler).
const SHOT_STATS: Array = [[&"damage", 12.5], [&"max_hp", 10.0], [&"move_speed", 4.0], [&"luck", 5.0]]
const SHOT_OFFERS: Array = [
	[{"stat": &"fire_rate", "tier": 1, "value": 10.0}, {"stat": &"max_hp", "tier": 2, "value": 30.0}, {"stat": &"move_speed", "tier": 0, "value": 4.0}],
	[{"stat": &"luck", "tier": 3, "value": 20.0}, {"stat": &"damage", "tier": 0, "value": 5.0}, {"stat": &"dash_cooldown", "tier": 1, "value": 12.0}],
]

var _root: Control
var _title: GrungeTitle
var _count: Label
var _stage: Control
var _strip: Label
var _cards: Array[GrungeCard] = []
var _offer: Array[Dictionary] = []
var _pending: int = 1
var _stats: PlayerStats
var _picking: bool = false
var _tween: Tween


func _ready() -> void:
	name = "PerkScreen"
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()
	Settings.changed.connect(_on_setting_changed)
	GameFlow.paused_changed.connect(_on_paused_changed)


## offer: CardRules.roll_offer çıktısı. pending: bu seçim dahil kalan seçim sayısı.
func show_offer(offer: Array[Dictionary], pending: int, stats: PlayerStats) -> void:
	_offer = offer
	_pending = pending
	_stats = stats
	_picking = false
	_kill_tween()
	for card: GrungeCard in _cards:
		_stage.remove_child(card)
		card.queue_free()
	_cards.clear()
	for i: int in offer.size():
		_cards.append(_make_card(i))
	_refresh_texts()
	visible = true
	_layout()
	for i: int in _cards.size():
		_cards[i].play_intro(i * INTRO_STEP)
	if not _cards.is_empty():
		_cards[0].grab_focus.call_deferred()


func close() -> void:
	_kill_tween()
	_picking = false
	visible = false


func focus_card(index: int) -> void:
	if index >= 0 and index < _cards.size():
		_cards[index].grab_focus.call_deferred()


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
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", SECTION_GAP)
	margin.add_child(column)
	_title = GrungeTitle.new()
	_title.font_size = TITLE_SIZE
	column.add_child(_title)
	_count = _make_label(UiFonts.heading(), COUNT_SIZE, UiPalette.ASH)
	column.add_child(_count)
	_stage = Control.new()
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.resized.connect(_layout)
	column.add_child(_stage)
	_strip = _make_label(UiFonts.body(), STRIP_SIZE, UiPalette.ASH)
	_strip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_strip.custom_minimum_size.x = STRIP_MAX_WIDTH
	_strip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_strip.material = UiAssets.mat("text_wear")
	column.add_child(_strip)


func _make_label(font: Font, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_card(index: int) -> GrungeCard:
	var card: GrungeCard = GrungeCard.new()
	card.pressed.connect(_pick.bind(index))
	UiSounds.hook(card)
	_stage.add_child(card)
	return card


func _refresh_texts() -> void:
	_title.set_text(Loc.t(&"run.perk.title_a"), Loc.t(&"run.perk.title_b"))
	_count.text = Loc.t(&"run.perk.left", [_pending])
	for i: int in _cards.size():
		_cards[i].setup(_card_data(i))
	_strip.text = StatReadout.strip(_stats) if _stats != null else ""


func _card_data(index: int) -> Dictionary:
	var card: Dictionary = _offer[index]
	var stat: StringName = card["stat"]
	var tier: int = card["tier"]
	var category: StringName = StatData.category_of(stat)
	var bonus: float = _stats.bonus(stat) if _stats != null else 0.0
	return {
		"category_id": category, "category": Loc.category_name(category), "title": Loc.card_title(stat),
		"emblem": StringName("stat_" + stat), "tier": tier, "tier_name": Loc.tier_name(tier), "hint": str(index + 1),
		"lines": [
			{"text": StatData.display_name(stat), "bold": true},
			{"text": "%s > %s" % [StatReadout.display(stat, bonus), StatReadout.display(stat, bonus + float(card["value"]))]},
		],
	}


## Kartlar sahnede elle dizilir (seçimde düşebilsinler); yükseklik ve genişliğe göre ölçeklenir.
func _layout() -> void:
	var n: int = _cards.size()
	if n == 0 or _picking or _stage.size.x < 1.0:
		return
	var height: float = minf(CARD_MAX_H, _stage.size.y)
	var width: float = height * CARD_ASPECT
	var gap: float = width * CARD_GAP
	var fit: float = (_stage.size.x - gap * (n - 1)) / n
	if fit < width:
		width = fit
		height = width / CARD_ASPECT
		gap = width * CARD_GAP
	var total: float = width * n + gap * (n - 1)
	var origin: Vector2 = Vector2((_stage.size.x - total) * 0.5, (_stage.size.y - height) * 0.5)
	for i: int in n:
		var card: GrungeCard = _cards[i]
		card.card_size = Vector2(width, height)
		card.size = Vector2(width, height)
		card.position = origin + Vector2(i * (width + gap), 0.0)


func _unhandled_input(input_event: InputEvent) -> void:
	if not visible or not (input_event is InputEventKey) or not input_event.is_pressed() or input_event.is_echo():
		return
	if GameFlow.is_paused_by(&"pause"):
		return
	var index: int = (input_event as InputEventKey).physical_keycode - KEY_1
	if index >= 0 and index < _cards.size():
		get_viewport().set_input_as_handled()
		_pick(index)


func _pick(index: int) -> void:
	if _picking or not visible or index < 0 or index >= _cards.size():
		return
	_picking = true
	if not Tuning.FEATURE_UI_MOTION:
		chosen.emit(index)
		return
	for i: int in _cards.size():
		_cards[i].release_focus()
		_cards[i].mouse_filter = Control.MOUSE_FILTER_IGNORE
		if i == index:
			_cards[i].play_picked()
		else:
			_fall(_cards[i], i)
	_kill_tween()
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_interval(PICK_TIME)
	_tween.tween_callback(chosen.emit.bind(index))


## Seçilmeyen kart eğilerek aşağı düşer ve kararır.
func _fall(card: GrungeCard, index: int) -> void:
	var side: float = -1.0 if index % 2 == 0 else 1.0
	card.pivot_offset = card.size * 0.5
	var t: Tween = create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.set_parallel(true)
	var delay: float = FALL_STAGGER * index
	var time: float = PICK_TIME - delay
	t.tween_property(card, "position:y", card.position.y + FALL_DISTANCE, time).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(card, "rotation", FALL_TILT * side, time).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(card, "modulate:a", 0.0, time * 0.8).set_delay(delay + time * 0.2)


func _kill_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null


func _on_setting_changed(key: StringName, _value: Variant) -> void:
	if key == &"game/language" and not _offer.is_empty():
		_refresh_texts()


## Duraklatma menüsü açıkken bu ekran girdi almaz (kart/mağaza arkada durur).
func _on_paused_changed(_paused: bool) -> void:
	process_mode = Node.PROCESS_MODE_DISABLED if GameFlow.is_paused_by(&"pause") else Node.PROCESS_MODE_ALWAYS


## Görüntü aracı (UiShot): sahte veriyle kurar. --ui-tab: 0 savaş/direniş/hareket, 1 ganimet/efsanevi.
static func ui_shot(host: Node, opts: Dictionary) -> void:
	ShotUnderlay.add(host)
	var stats: PlayerStats = PlayerStats.new()
	for pair: Array in SHOT_STATS:
		stats.add(pair[0], pair[1])
	var offer: Array[Dictionary] = []
	offer.assign(SHOT_OFFERS[int(opts.get("tab", 0)) % SHOT_OFFERS.size()])
	var screen: PerkScreen = PerkScreen.new()
	host.add_child(screen)
	screen.show_offer(offer, 2, stats)
	screen.focus_card(int(opts.get("focus", -1)))
