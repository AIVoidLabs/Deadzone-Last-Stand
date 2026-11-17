class_name CardRules
extends RefCounted
## Kart sunumu: kademe olasılığı, kademe çekilişi, birbirinden farklı istatistiklerle n kart.
## Sahneden bağımsız; tablolar parametreyle gelir.


## Bu kademenin (ya da üstünün) çıkma olasılığı.
static func tier_chance(tier: Dictionary, level: int, luck: float) -> float:
	var from_level: int = tier["from_level"]
	if level < from_level:
		return 0.0
	var per_level: float = tier["per_level"]
	var chance: float = per_level * float(level - from_level + 1) * maxf(0.0, 1.0 + luck / 100.0)
	return clampf(chance, 0.0, tier["max_chance"])


## En üst kademeden başlayarak dener; hiçbiri tutmazsa ilk kademe (0).
static func roll_tier(rng: RandomNumberGenerator, tiers: Array, level: int, luck: float) -> int:
	for t in range(tiers.size() - 1, 0, -1):
		if rng.randf() < tier_chance(tiers[t], level, luck):
			return t
	return 0


## count kart: her biri farklı istatistik. Öğeler: {stat, tier, value}.
static func roll_offer(rng: RandomNumberGenerator, cards: Array, tiers: Array, count: int, level: int, luck: float) -> Array[Dictionary]:
	var order: Array = range(cards.size())
	# Karıştırma rng ile (tekrarlanabilir testler için Array.shuffle kullanılmaz).
	for i in range(order.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = order[i]
		order[i] = order[j]
		order[j] = tmp
	var offer: Array[Dictionary] = []
	for k in mini(count, order.size()):
		var card: Dictionary = cards[order[k]]
		var tier: int = roll_tier(rng, tiers, level, luck)
		offer.append({"stat": card["stat"], "tier": tier, "value": (card["values"] as Array)[tier]})
	return offer
