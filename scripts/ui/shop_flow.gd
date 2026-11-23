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


## Debug uçları (yalnız otomatik oyun botu çağırır; oyun akışı kullanmaz).
func debug_offer() -> Array[Dictionary]:
	return _offer


func debug_state_of(entry: Dictionary) -> String:
	return _state_of(entry)


func debug_buy(index: int) -> void:
	_on_buy(index)


func debug_close() -> void:
	_close()


func debug_reroll() -> void:
	_on_reroll()


func debug_reroll_price() -> int:
	return _reroll_cost()


func debug_owned() -> Dictionary:
	return _owned


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
	return pickups == null or pickups.is_settled()


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
	return ShopRules.price(ShopRules.list_price(base, Tuning.SHOP_PRICE_MULT), _wave_index(), Tuning.SHOP_PRICE_WAVE_GROWTH)


func _reroll_cost() -> int:
	if Tuning.FEATURE_SHOP_REROLL_EXP:
		return ShopRules.reroll_cost_exp(_rerolls, Tuning.SHOP_REROLL_BASE, Tuning.SHOP_REROLL_FACTOR, Tuning.SHOP_REROLL_MAX_COST)
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
	# İade, ödenen (SHOP_PRICE_MULT uygulanmış) taban fiyatın kesri.
	return ShopRules.sell_value(ShopRules.list_price(base, Tuning.SHOP_PRICE_MULT), slot["tier"], Tuning.SHOP_SELL_FRACTION)


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
		"owned_text": "%s\n%s" % [ShopTexts.owned_text(_owned), CardScreen.stats_text(stats)],
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
			view["lines"].append({"text": StatData.describe(effect["stat"], effect["value"]), "good": ShopTexts.is_good(effect)})
		return view
	var weapon: Dictionary = WeaponData.get_row(entry["id"])
	var plan: Dictionary = weapons.preview_add(entry["id"])
	var tier: int = ShopTexts.new_tier(plan, entry["id"], weapons.slot_list())
	view["merged"] = plan["merged"]
	view["tier"] = tier
	view["title"] = weapon["name"]
	view["color"] = WeaponData.tier_row(tier)["tint"]
	view["subtitle"] = "SİLAH" if not plan["merged"] else "SİLAH  ·  BİRLEŞİR → K%d" % tier
	view["lines"] = ShopTexts.weapon_lines(weapon, tier)
	return view
