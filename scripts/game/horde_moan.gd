class_name HordeMoan
extends RefCounted
## Kalabalık inleme katmanı kuralı: sürü yeterince büyükse tek zombinin inlemesi, sayıya göre sıklaşan aralıkla.
## Değerler parametreyle gelir (saf kural). Yoğunluk eşlemesi HordeGroan ile aynıdır.


static func active(count: int, min_count: int) -> bool:
	return count >= min_count


## Sonraki inlemeye kadar süre (sn): min_count'ta sparse, full_count ve üstünde dense; roll [0, 1) ile ± jitter oranı.
static func interval(count: int, min_count: int, full_count: int, sparse: float, dense: float, jitter: float, roll: float) -> float:
	var level: float = HordeGroan.intensity(count, min_count, full_count)
	return HordeGroan.interval(level, sparse, dense, jitter, roll)