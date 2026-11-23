class_name ShopRules
extends RefCounted
## Mağaza kuralları (saf): fiyat, yenileme bedeli, satış değeri ve raf çekilişi. Tablolar parametreyle gelir.
## Raf öğesi: {"kind": &"item" | &"weapon", "id": StringName, "locked": bool, "sold": bool}.

const ITEM: StringName = &"item"
const WEAPON: StringName = &"weapon"


## Dalga ilerledikçe fiyat artar (wave_index 0 tabanlı).
static func price(base: int, wave_index: int, growth: float) -> int:
	return maxi(1, roundi(float(base) * (1.0 + growth * float(wave_index))))


## done: bu dalgada yapılmış yenileme sayısı.
static func reroll_cost(done: int, base: int, step: int) -> int:
	return base + step * done


## Üstel yenileme: base x factor^done (5, 25, 125, 625), max_cost'ta kesilir.
static func reroll_cost_exp(done: int, base: int, factor: int, max_cost: int) -> int:
	return roundi(minf(float(max_cost), float(base) * pow(float(factor), float(maxi(done, 0)))))


## Kademe başına bedel ikiye katlanır (iki parça birleşti), geri ödeme bunun fraction'ı.
static func sell_value(base_price: int, tier: int, fraction: float) -> int:
	return floori(float(base_price) * pow(2.0, float(tier - 1)) * fraction)


## weights: id → çıkma ağırlığı (silah nadirliği); boşsa ya da id'de yoksa ağırlık 1.
static func _pick_weighted(rng: RandomNumberGenerator, pool: Array, weights: Dictionary) -> StringName:
	var total: float = 0.0
	for id: StringName in pool:
		total += float(weights.get(id, 1.0))
	var roll: float = rng.randf() * total
	for id: StringName in pool:
		roll -= float(weights.get(id, 1.0))
		if roll <= 0.0:
			return id
	return pool[pool.size() - 1]


## count öğelik raf. Kilitli ve satılmamış öğeler yerinde kalır; kalan yerler rastgele dolar.
## Raf içinde aynı ürün tekrar etmez (havuz yetiyorsa). weapon_chance: dolan yerin silah olma olasılığı.
static func roll_offer(rng: RandomNumberGenerator, item_ids: Array, weapon_ids: Array, count: int, weapon_chance: float, previous: Array[Dictionary], weapon_weights: Dictionary = {}) -> Array[Dictionary]:
	var offer: Array[Dictionary] = []
	for entry: Dictionary in previous:
		if entry["locked"] and not entry["sold"] and offer.size() < count:
			offer.append(entry)
	var attempts: int = 0
	while offer.size() < count and attempts < count * 20:
		attempts += 1
		var kind: StringName = WEAPON if not weapon_ids.is_empty() and (item_ids.is_empty() or rng.randf() < weapon_chance) else ITEM
		var pool: Array = weapon_ids if kind == WEAPON else item_ids
		if pool.is_empty():
			break
		var id: StringName = _pick_weighted(rng, pool, weapon_weights) if kind == WEAPON else pool[rng.randi_range(0, pool.size() - 1)]
		if _contains(offer, kind, id):
			continue
		offer.append({"kind": kind, "id": id, "locked": false, "sold": false})
	return offer


static func _contains(offer: Array[Dictionary], kind: StringName, id: StringName) -> bool:
	for entry: Dictionary in offer:
		if entry["kind"] == kind and entry["id"] == id:
			return true
	return false
