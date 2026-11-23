class_name ShopTexts
extends RefCounted
## Mağaza satırlarının metin ve görünüm yardımcıları (ShopFlow'un parçası; akıştan bağımsız).


## Eşyanın etkisi oyuncu lehine mi (dash bekleme düşüşü de lehinedir).
static func is_good(effect: Dictionary) -> bool:
	var value: float = effect["value"]
	return value > 0.0


static func weapon_lines(row: Dictionary, tier: int) -> Array:
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


## Eklemede yeni oluşan yuvanın kademesi (birleşmede üst kademe, yoksa 1). current: eldeki yuvalar.
static func new_tier(plan: Dictionary, id: StringName, current: Array[Dictionary]) -> int:
	if not plan["ok"]:
		return 1
	var remaining: Array[Dictionary] = current.duplicate()
	for slot: Dictionary in plan["slots"]:
		var found: int = remaining.find(slot)
		if found >= 0:
			remaining.remove_at(found)
		elif slot["id"] == id:
			return slot["tier"]
	return 1


static func owned_text(owned: Dictionary) -> String:
	if owned.is_empty():
		return "Henüz eşyan yok"
	var parts: PackedStringArray = PackedStringArray()
	for id: StringName in owned:
		parts.append("%s ×%d" % [ItemData.get_row(id)["name"], owned[id]])
	return "Eşyalar: " + "   ·   ".join(parts)
