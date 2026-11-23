class_name WaveHealRules
extends RefCounted
## Dalga sonu nefes payı: kalan can WAVE_END_HEAL_FACTOR katına çıkar, üst sınırı geçmez (25/100 → 50/100).


## Eklenecek can miktarı (ölüyse 0).
static func bonus(current: float, maximum: float, factor: float) -> float:
	if current <= 0.0:
		return 0.0
	return clampf(current * factor, current, maximum) - current
