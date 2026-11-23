class_name HudRules
extends RefCounted
## HUD'ın saf kuralları (sahneden bağımsız): son saniye sayacı, düşük can nabzı, sayı biçimi.

## Dalga süresinde "vuruşlu kırmızı" sayılan son saniye sayısı.
const FINAL_SECONDS: int = 5


## Kalan süre son FINAL_SECONDS içindeyse kalan tam saniye (5..1), değilse 0.
static func final_second(left: float) -> int:
	if left <= 0.0 or left > float(FINAL_SECONDS):
		return 0
	return ceili(left)


## Dalga süresi etiketi için tam saniye (yukarı yuvarlanır, eksi olmaz).
static func clock_seconds(left: float) -> int:
	return maxi(0, ceili(left))


## Saat etiketlerinin değişip değişmediğini anlamak için tek tamsayı anahtarı (dize üretmeden).
static func clock_key(number: int, total: int, last: bool, seconds: int, final_n: int, cleared: bool) -> int:
	var key: int = clampi(number, 0, 255) * 256 + clampi(total, 0, 255)
	key = key * 2 + (1 if last else 0)
	key = key * 100000 + clampi(seconds, 0, 99999)
	key = key * 8 + clampi(final_n, 0, 7)
	return key * 2 + (1 if cleared else 0)


## Düşük can nabzı: 0..1 (hz kez/sn), zaman t saniye.
static func pulse(t: float, hz: float) -> float:
	return 0.5 + 0.5 * sin(t * TAU * hz)


## Zıplama sönümü: pop 1'den 0'a delta * hız ile iner.
static func decay(pop: float, delta: float, rate: float) -> float:
	return maxf(0.0, pop - delta * rate)
