class_name LevelUpFlow
extends Node
## Bekleyen seviyeler için kart seçimi. Dalgalar açıkken dalga arasında, yerdeki kristaller
## toplandıktan sonra açılır; dalgalar kapalıyken seviye atlar atlamaz. Seçim sırasında oyun durur.

var loot: RunLoot
var stats: PlayerStats
var director: SpawnDirector
## Kristaller kapalıyken null.
var pickups: Pickups

## PerkScreen (FEATURE_NEW_CARDS) ya da eski CardScreen; ikisi de aynı arayüzü sunar.
var _screen: Variant
var _offer: Array[Dictionary] = []
var _open: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	name = "LevelUpFlow"
	_rng.randomize()
	_screen = PerkScreen.new() if Tuning.FEATURE_NEW_CARDS else CardScreen.new()
	add_child(_screen)
	_screen.chosen.connect(_on_chosen)


func _physics_process(_delta: float) -> void:
	if _open or loot.pending_levels <= 0 or not _can_open():
		return
	_open = true
	GameFlow.open_menu()
	UiSounds.play(UiSoundData.CARD_OPEN)
	_show_next()


## Kart ekranı açık ya da seçim bekleyen seviye var (mağaza bunu bekler).
## Debug uçları (yalnız otomatik oyun botu çağırır).
func debug_is_open() -> bool:
	return _open


func debug_offer() -> Array[Dictionary]:
	return _offer


func debug_choose(index: int) -> void:
	_on_chosen(index)


func is_busy() -> bool:
	return _open or loot.pending_levels > 0


func _can_open() -> bool:
	if GameFlow.state != GameFlow.State.PLAYING:
		return false
	if director.run == null:
		return true
	if director.run.phase != WaveRun.Phase.BREAK:
		return false
	return pickups == null or pickups.count() == 0


func _show_next() -> void:
	_offer = CardRules.roll_offer(_rng, CardData.CARDS, CardData.TIERS, Tuning.CARD_OFFER_COUNT, loot.level, stats.luck())
	_screen.show_offer(_offer, loot.pending_levels, stats)


func _on_chosen(index: int) -> void:
	if not _open:
		return
	UiSounds.play(UiSoundData.CARD_PICK)
	var card: Dictionary = _offer[index]
	stats.add(card["stat"], card["value"])
	GameFlow.run_stats.add_card(card["stat"], card["tier"])
	loot.pending_levels -= 1
	if loot.pending_levels > 0:
		_show_next()
		return
	_open = false
	_screen.close()
	GameFlow.close_menu()
