class_name AutoplayStrategy
extends RefCounted
## Debug: bot stratejileri (denge ölçümü). Yalnız mağaza ve kart seçimini etkiler.
## Tercih tabloları veridir: stat ağırlıkları + silah sınıfı ağırlıkları. Eşya ve kartlar etkilerindeki
## stat'lara göre puanlanır (value × ağırlık), bu yüzden yeni eşyalar kendiliğinden sınıflanır.

const DEFAULT: StringName = &"default"

const STRATEGIES: Dictionary = {
	&"guns": {
		"stats": {&"damage": 1.0, &"fire_rate": 1.0, &"range": 0.7, &"armor": 0.5, &"max_hp": 0.1, &"luck": 0.05, &"pickup_range": 0.02},
		"weapons": {"ranged": 10.0, "melee": 0.0},
	},
	&"melee": {
		"stats": {&"damage": 1.0, &"fire_rate": 0.7, &"move_speed": 0.4, &"armor": 1.0, &"max_hp": 0.3, &"hp_regen": 1.0, &"range": 0.2, &"dash_cooldown": 0.2},
		"weapons": {"ranged": 2.0, "melee": 10.0},
	},
	&"tank": {
		"stats": {&"armor": 6.0, &"max_hp": 0.6, &"hp_regen": 4.0, &"move_speed": 0.15, &"damage": 0.3, &"dash_cooldown": 0.2},
		"weapons": {"ranged": 5.0, "melee": 3.0},
	},
}

var name: StringName = DEFAULT


static func from_args() -> AutoplayStrategy:
	var strategy: AutoplayStrategy = AutoplayStrategy.new()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--autoplay-strategy="):
			strategy.name = StringName(arg.trim_prefix("--autoplay-strategy="))
	if strategy.name != DEFAULT and not STRATEGIES.has(strategy.name):
		push_warning("Bilinmeyen strateji: %s (default kullanılıyor)" % strategy.name)
		strategy.name = DEFAULT
	return strategy


func is_default() -> bool:
	return name == DEFAULT


func stat_score(stat: StringName, value: float) -> float:
	var weights: Dictionary = STRATEGIES[name]["stats"]
	return value * float(weights.get(stat, 0.0))


func item_score(id: StringName) -> float:
	var score: float = 0.0
	for effect: Dictionary in ItemData.get_row(id)["effects"]:
		score += stat_score(effect["stat"], effect["value"])
	return score


func weapon_score(id: StringName) -> float:
	var weights: Dictionary = STRATEGIES[name]["weapons"]
	var melee: bool = WeaponData.get_row(id)["behavior"] == &"melee"
	return float(weights["melee" if melee else "ranged"])


func card_score(card: Dictionary) -> float:
	return stat_score(card["stat"], card["value"])


## Kart tekliflerinden en yüksek puanlının indeksi.
func best_card(offer: Array[Dictionary]) -> int:
	var best: int = 0
	for i: int in offer.size():
		if card_score(offer[i]) > card_score(offer[best]):
			best = i
	return best
