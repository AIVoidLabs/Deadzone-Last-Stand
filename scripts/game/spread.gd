class_name Spread
extends RefCounted
## Saçılan atış: saçmalar nişan yönünün çevresinde eşit aralıklı bir yelpazeye dağılır,
## her birine aralığın bir kesri kadar rastgele sapma eklenir (yelpaze her atışta aynı görünmesin).


## i. saçmanın nişandan sapma açısı (radyan). spread: yelpazenin toplam açısı.
static func angle_offset(index: int, pellets: int, spread: float) -> float:
	if pellets <= 1:
		return 0.0
	return -spread * 0.5 + spread * float(index) / float(pellets - 1)


## Rastgele sapma (radyan). jitter: komşu saçma aralığının kesri (0 = yok). roll [0, 1).
static func jitter(pellets: int, spread: float, jitter_fraction: float, roll: float) -> float:
	if pellets <= 1:
		return 0.0
	var gap: float = spread / float(pellets - 1)
	return gap * jitter_fraction * (roll - 0.5)
