class_name RunLoot
extends RefCounted
## Tur içinde toplanan kristaller: her kristal hem para hem XP sayılır (Brotato'daki gibi tek kaynak).
## Seviye için gereken XP: XP_LEVEL_SCALE x (seviye + XP_LEVEL_OFFSET)^XP_LEVEL_POWER. Sahneden bağımsız.

var crystals: int = 0
var level: int = 1
## Bu seviyede toplanan XP (seviye atlayınca sıfırdan sayar).
var xp: int = 0
## Kart seçimi bekleyen seviye sayısı (LevelUpFlow azaltır).
var pending_levels: int = 0


static func xp_needed(at_level: int) -> int:
	return maxi(1, roundi(Tuning.XP_LEVEL_SCALE * pow(float(at_level + Tuning.XP_LEVEL_OFFSET), Tuning.XP_LEVEL_POWER)))


## value kadar kristal ekler. Dönüş: atlanan seviye sayısı.
func add(value: int) -> int:
	crystals += value
	return add_xp(value)


## Yalnız para (para çantası): kristal artar, XP değişmez.
func add_money(value: int) -> void:
	crystals += value


## Yalnız XP (XP çantası): para değişmez. Dönüş: atlanan seviye sayısı.
func add_xp(value: int) -> int:
	xp += value
	var gained: int = 0
	while xp >= xp_needed(level):
		xp -= xp_needed(level)
		level += 1
		gained += 1
	pending_levels += gained
	return gained


## Mağazada harcama (6.5). Yetmezse false, kristal değişmez.
func spend(amount: int) -> bool:
	if amount > crystals:
		return false
	crystals -= amount
	return true


## Satıştan geri ödeme: yalnız para, XP değil.
func refund(amount: int) -> void:
	crystals += amount


## Bu seviyedeki ilerleme (0..1).
func level_progress() -> float:
	return float(xp) / float(xp_needed(level))
