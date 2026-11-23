class_name ShopFlow
extends Node
## Dalga arası mağaza: kart seçimleri bittikten sonra ara fazında açılır, oyun durur.
## "Sonraki dalga" ile kapanınca ara hemen biter. Kural hesapları ShopRules'ta; burası akış ve bağlantı.

const ITEM_COLOR: Color = Color(0.82, 0.84, 0.86)

var loot: RunLoot
var stats: PlayerStats
var director: SpawnDirector
var weapons: WeaponRig
## Kristaller kapalıyken null.
var pickups: Pickups
## Kart ekranı açıkken mağaza beklesin diye.
var level_up: LevelUpFlow

## MarketScreen (FEATURE_NEW_SHOP) ya da eski ShopScreen; ikisi de aynı sinyalleri sunar.
var _screen: Variant
var _offer: Array[Dictionary] = []
var _rerolls: int = 0
var _owned: Dictionary = {}
var _open: bool = false
## Mağazanın en son açıldığı dalga (her ara için bir kez).
var _shown_wave: int = -1
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	name = "ShopFlow"
	_rng.randomize()
	_screen = MarketScreen.new() if Tuning.FEATURE_NEW_SHOP else ShopScreen.new()
	add_child(_screen)
	_screen.buy_pressed.connect(_on_buy)
	_screen.lock_pressed.connect(_on_lock)
	_screen.reroll_pressed.connect(_on_reroll)
	_screen.sell_pressed.connect(_on_sell)
	_screen.next_pressed.connect(_close)


func _physics_process(_delta: float) -> void:
	var run: WaveRun = director.run
	if run == null or _open:
		return
	var waiting: bool = run.phase == WaveRun.Phase.BREAK and run.index != _shown_wave
	# Mağaza açılana kadar ara süresi akmasın (kristaller toplanıyor, kartlar seçiliyor olabilir).
	director.hold_break = waiting
	if waiting and _can_open():
		_open_shop(run.index)


func is_open() -> bool:
	return _open


## Debug (otomatik oyun botu): alınabilir silahları (en çok max_weapons yuva ya da birleşiyorsa), sonra eşyaları
## alır ve mağazayı kapatır.
func debug_autobuy(max_weapons: int) -> void:
	var bought: bool = true
	while bought:
		bought = false
		for i: int in _offer.size():
			var entry: Dictionary = _offer[i]
			if _state_of(entry) != "ok":
				continue
			if entry["kind"] == ShopRules.WEAPON and weapons.count() >= max_weapons and not weapons.preview_add(entry["id"])["merged"]:
				continue
			_on_buy(i)
			bought = true
			break
	_close()


func _can_open() -> bool:
	if GameFlow.state != GameFlow.State.PLAYING:
		return false
	if level_up != null and level_up.is_busy():
		return false
	return pickups == null or pickups.count() == 0


func _open_shop(wave_index: int) -> void:
	_open = true
	_shown_wave = wave_index
	_rerolls = 0
	_roll()
	GameFlow.open_menu()
	UiSounds.play(UiSoundData.CARD_OPEN)
	_refresh()


func _close() -> void:
	if not _open:
		return
	_open = false
	_screen.close()
	UiSounds.play(UiSoundData.CLICK)
	GameFlow.close_menu()
	director.skip_break()


func _roll() -> void:
	var pool: Dictionary = WeaponData.shop_pool(_wave_index() + 1)
	_offer = ShopRules.roll_offer(_rng, ItemData.ids(), pool.keys(), Tuning.SHOP_OFFER_COUNT, Tuning.SHOP_WEAPON_CHANCE, _offer, pool)


func _wave_index() -> int:
	return maxi(0, _shown_wave)


func _price(entry: Dictionary) -> int:
	var base: int = ItemData.get_row(entry["id"])["price"] if entry["kind"] == ShopRules.ITEM else WeaponData.get_row(entry["id"])["price"]
	return ShopRules.price(base, _wave_index(), Tuning.SHOP_PRICE_WAVE_GROWTH)


func _reroll_cost() -> int:
	return ShopRules.reroll_cost(_rerolls, Tuning.SHOP_REROLL_BASE, Tuning.SHOP_REROLL_STEP)


func _on_buy(index: int) -> void:
	if not _open or index >= _offer.size():
		return
	var entry: Dictionary = _offer[index]
	if entry["sold"] or _state_of(entry) != "ok" or not loot.spend(_price(entry)):
		UiSounds.play(UiSoundData.DENY)
		return
	var merged: bool = false
	if entry["kind"] == ShopRules.ITEM:
		_apply_item(entry["id"])
	else:
		merged = weapons.preview_add(entry["id"])["merged"]
		weapons.add_weapon(entry["id"])
	UiSounds.play(UiSoundData.MERGE if merged else UiSoundData.BUY)
	entry["sold"] = true
	entry["locked"] = false
	_refresh()


func _apply_item(id: StringName) -> void:
	for effect: Dictionary in ItemData.get_row(id)["effects"]:
		stats.add(effect["stat"], effect["value"])
	_owned[id] = int(_owned.get(id, 0)) + 1
	GameFlow.run_stats.add_item(id)


func _on_lock(index: int) -> void:
	if not _open or index >= _offer.size() or _offer[index]["sold"]:
		return
	_offer[index]["locked"] = not _offer[index]["locked"]
	UiSounds.play(UiSoundData.CLICK)
	_refresh()


func _on_reroll() -> void:
	var cost: int = _reroll_cost()
	if not _open:
		return
	if not loot.spend(cost):
		UiSounds.play(UiSoundData.DENY)
		return
	UiSounds.play(UiSoundData.CLICK)
	_rerolls += 1
	_roll()
	_refresh()


func _on_sell(index: int) -> void:
	var slots: Array[Dictionary] = weapons.slot_list()
	if not _open or index >= slots.size():
		return
	var slot: Dictionary = slots[index]
	if not weapons.remove_at(index):
		return
	loot.refund(_sell_value(slot))
	UiSounds.play(UiSoundData.SELL)
	_refresh()


func _sell_value(slot: Dictionary) -> int:
	var base: int = WeaponData.get_row(slot["id"])["price"]
	return ShopRules.sell_value(base, slot["tier"], Tuning.SHOP_SELL_FRACTION)


## "ok" alınabilir, "poor" kristal yetmez, "full" yuva dolu ve birleşmez, "sold" satın alındı.
func _state_of(entry: Dictionary) -> String:
	if entry["sold"]:
		return "sold"
	if entry["kind"] == ShopRules.WEAPON and not weapons.preview_add(entry["id"])["ok"]:
		return "full"
	return "ok" if loot.crystals >= _price(entry) else "poor"


func _refresh() -> void:
	var run: WaveRun = director.run
	var entries: Array = []
	for entry: Dictionary in _offer:
		entries.append(_entry_view(entry))
	var weapon_views: Array = []
	var slots: Array[Dictionary] = weapons.slot_list()
	for slot: Dictionary in slots:
		var row: Dictionary = WeaponData.get_row(slot["id"])
		weapon_views.append({
			"text": "%s  K%d" % [row["name"], slot["tier"]],
			"color": WeaponData.tier_row(slot["tier"])["tint"],
			"sell": _sell_value(slot),
			"sellable": slots.size() > 1,
			"id": slot["id"],
			"tier": slot["tier"],
		})
	var cost: int = _reroll_cost()
	_screen.show_view({
		"title": "MAĞAZA  ·  Dalga %d/%d tamamlandı" % [run.index + 1, run.wave_count()],
		"crystals": loot.crystals,
		"entries": entries,
		"reroll_text": "Yenile  %d kristal  [R]" % cost,
		"can_reroll": loot.crystals >= cost,
		"weapons": weapon_views,
		"wave": run.index + 1,
		"wave_total": run.wave_count(),
		"reroll_cost": cost,
		"owned": _owned.duplicate(),
		"stats": stats,
		"owned_text": "%s\n%s" % [_owned_text(), CardScreen.stats_text(stats)],
	})


func _entry_view(entry: Dictionary) -> Dictionary:
	var view: Dictionary = {"state": _state_of(entry), "locked": entry["locked"], "price": _price(entry), "lines": [], "kind": entry["kind"], "id": entry["id"], "merged": false, "tier": 1, "owned": int(_owned.get(entry["id"], 0))}
	if entry["kind"] == ShopRules.ITEM:
		var row: Dictionary = ItemData.get_row(entry["id"])
		view["title"] = row["name"]
		view["color"] = ITEM_COLOR
		var owned: int = int(_owned.get(entry["id"], 0))
		view["subtitle"] = "EŞYA" if owned == 0 else "EŞYA  ·  sende ×%d" % owned
		for effect: Dictionary in row["effects"]:
			view["lines"].append({"text": StatData.describe(effect["stat"], effect["value"]), "good": _is_good(effect)})
		return view
	var weapon: Dictionary = WeaponData.get_row(entry["id"])
	var plan: Dictionary = weapons.preview_add(entry["id"])
	var tier: int = _new_tier(plan, entry["id"])
	view["merged"] = plan["merged"]
	view["tier"] = tier
	view["title"] = weapon["name"]
	view["color"] = WeaponData.tier_row(tier)["tint"]
	view["subtitle"] = "SİLAH" if not plan["merged"] else "SİLAH  ·  BİRLEŞİR → K%d" % tier
	view["lines"] = _weapon_lines(weapon, tier)
	return view


## Eşyanın etkisi oyuncu lehine mi (dash bekleme düşüşü de lehinedir).
static func _is_good(effect: Dictionary) -> bool:
	var value: float = effect["value"]
	return value > 0.0


func _weapon_lines(row: Dictionary, tier: int) -> Array:
	var tier_row: Dictionary = WeaponData.tier_row(tier)
	var damage: float = float(row["damage"]) * float(tier_row["damage_mult"])
	var pellets: int = row["pellets"]
	var damage_text: String = "Hasar %d" % roundi(damage) if pellets == 1 else "Hasar %d × %d" % [roundi(damage), pellets]
	var rate: float = float(tier_row["rate_mult"]) / float(row["fire_interval"])
	return [
		{"text": damage_text, "good": true},
		{"text": "%.1f atış/sn" % rate, "good": true},
		{"text": "Menzil %d m" % roundi(row["max_range"]), "good": true},
	]


## Eklemede yeni oluşan yuvanın kademesi (birleşmede üst kademe, yoksa 1).
func _new_tier(plan: Dictionary, id: StringName) -> int:
	if not plan["ok"]:
		return 1
	var remaining: Array[Dictionary] = weapons.slot_list()
	for slot: Dictionary in plan["slots"]:
		var found: int = remaining.find(slot)
		if found >= 0:
			remaining.remove_at(found)
		elif slot["id"] == id:
			return slot["tier"]
	return 1


func _owned_text() -> String:
	if _owned.is_empty():
		return "Henüz eşyan yok"
	var parts: PackedStringArray = PackedStringArray()
	for id: StringName in _owned:
		parts.append("%s ×%d" % [ItemData.get_row(id)["name"], _owned[id]])
	return "Eşyalar: " + "   ·   ".join(parts)
