class_name Health
extends RefCounted
## Can değeri. Hasar canın altına inmez; iyileşme üst sınırı aşmaz.

var maximum: float
var current: float


func _init(max_hp: float) -> void:
	maximum = max_hp
	current = max_hp


## Gerçekten düşülen miktarı döndürür.
func take_damage(amount: float) -> float:
	var dealt: float = clampf(amount, 0.0, current)
	current -= dealt
	return dealt


## Üst sınırı amount kadar artırır; artan kadar can da dolar.
func raise_maximum(amount: float) -> void:
	maximum = maxf(1.0, maximum + amount)
	current = clampf(current + maxf(0.0, amount), 0.0, maximum)


## Gerçekten eklenen miktarı döndürür.
func heal(amount: float) -> float:
	var gained: float = clampf(amount, 0.0, maximum - current)
	current += gained
	return gained


func is_dead() -> bool:
	return current <= 0.0


func ratio() -> float:
	return current / maximum if maximum > 0.0 else 0.0
