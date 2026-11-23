class_name MarketShot
extends RefCounted
## Mağaza görüntü aracı örneği (sahte veri). --ui-tab=1: tek silah, eşyasız.

const STATS: Array = [[&"armor", 2.0], [&"move_speed", -3.0], [&"damage", 12.5], [&"max_hp", 20.0], [&"luck", 5.0]]
const OWNED: Dictionary = {&"armor_plate": 2, &"magnet": 1, &"sharp_rounds": 1}
const SLOTS: Array = [[&"pistol", 1, 15], [&"shotgun", 2, 55], [&"katana", 1, 20], [&"smg", 3, 40]]
const ENTRIES: Array = [
	{"kind": &"item", "id": &"armor_plate", "state": "ok", "price": 25, "locked": false, "owned": 2},
	{"kind": &"weapon", "id": &"smg", "state": "ok", "price": 60, "locked": false, "merged": true, "tier": 4},
	{"kind": &"item", "id": &"drum_mag", "state": "poor", "price": 220, "locked": true},
	{"kind": &"item", "id": &"energy_drink", "state": "sold", "price": 20, "locked": false},
]


const CAPPED_ENTRIES: Array = [
	{"kind": &"item", "id": &"light_boots", "state": "ok", "price": 22, "locked": false},
	{"kind": &"item", "id": &"adrenaline", "state": "ok", "price": 45, "locked": false},
	{"kind": &"item", "id": &"sprint_spikes", "state": "ok", "price": 15, "locked": false},
	{"kind": &"item", "id": &"blitz_core", "state": "ok", "price": 60, "locked": false},
]


static func build(host: Node, opts: Dictionary) -> void:
	ShotUnderlay.add(host)
	var stats: PlayerStats = PlayerStats.new()
	for pair: Array in STATS:
		stats.add(pair[0], pair[1])
	var entries: Array = ENTRIES
	if UiShot.arg("--ui-capped=", "") == "1":
		entries = _capped_entries(stats)
	var weapons: Array = []
	for slot: Array in SLOTS:
		weapons.append({"id": slot[0], "tier": slot[1], "sell": slot[2], "sellable": true})
	var lean: bool = int(opts.get("tab", 0)) != 0
	var screen: MarketScreen = MarketScreen.new()
	host.add_child(screen)
	screen.show_view({
		"wave": 3, "wave_total": 10, "crystals": 148, "entries": entries, "reroll_cost": 7, "can_reroll": true,
		"weapons": weapons.slice(0, 1) if lean else weapons, "owned": {} if lean else OWNED, "stats": stats,
	})
	screen.focus_card(int(opts.get("focus", -1)))
	var hover: int = int(opts.get("hover", -1))
	if hover >= 0:
		host.get_tree().create_timer(Tuning.UI_SHOT_SETTLE_TIME, true, false, true).timeout.connect(screen.hover_slot.bind(hover))


## --ui-capped=1: hareket hızı tavanın üstünde, rafta hız satırı olan eşyalar (tavan etiketi görüntüsü).
static func _capped_entries(stats: PlayerStats) -> Array:
	stats.add(&"move_speed", Tuning.MOVE_SPEED_BONUS_CAP + 10.0 - stats.bonus(&"move_speed"))
	var entries: Array = []
	for source: Dictionary in CAPPED_ENTRIES:
		var entry: Dictionary = source.duplicate()
		if entry["kind"] == &"item":
			entry["capped"] = StatCaps.capped_stats(ItemData.get_row(entry["id"])["effects"], stats.bonus)
		entries.append(entry)
	return entries
