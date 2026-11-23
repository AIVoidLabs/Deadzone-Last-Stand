class_name CombatMath
extends RefCounted
## Hasar ve çarpışma hesapları.


## Zırh indirimi (azalan verimli yüzde; eksi zırh en çok +%50 hasar); sonuç MIN_DAMAGE_AFTER_ARMOR altına inmez.
## FEATURE_ARMOR_PERCENT kapalıysa eski düz çıkarma.
static func mitigate(damage: float, armor: float) -> float:
	if damage <= 0.0:
		return 0.0
	var result: float = damage - armor
	if Tuning.FEATURE_ARMOR_PERCENT:
		result = damage * armor_multiplier(armor)
	return maxf(Tuning.MIN_DAMAGE_AFTER_ARMOR, result)


## Zırhın hasar çarpanı: a >= 0 ise 100 / (100 + yüzde x a); eksi ise 1 + puan x |a| / 100 (üst sınırlı).
static func armor_multiplier(armor: float) -> float:
	if armor >= 0.0:
		return 100.0 / (100.0 + Tuning.ARMOR_PERCENT_PER_POINT * armor)
	return 1.0 + minf(Tuning.ARMOR_NEGATIVE_MAX_BONUS, Tuning.ARMOR_NEGATIVE_PER_POINT * absf(armor) / 100.0)


## a→b doğru parçasının c merkezli r yarıçaplı daireye ilk değdiği t (0..1); değmezse -1.
static func segment_circle_t(a: Vector2, b: Vector2, c: Vector2, r: float) -> float:
	var f: Vector2 = a - c
	var cc: float = f.length_squared() - r * r
	if cc <= 0.0:
		return 0.0
	var d: Vector2 = b - a
	var aa: float = d.length_squared()
	if aa < 1e-10:
		return -1.0
	var bb: float = 2.0 * f.dot(d)
	var disc: float = bb * bb - 4.0 * aa * cc
	if disc < 0.0:
		return -1.0
	var t: float = (-bb - sqrt(disc)) / (2.0 * aa)
	if t < 0.0 or t > 1.0:
		return -1.0
	return t
