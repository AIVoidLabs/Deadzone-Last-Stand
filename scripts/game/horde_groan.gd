class_name HordeGroan
extends RefCounted
## Sürü homurtusu kuralı: yakındaki zombi sayısından yoğunluk, yoğunluktan homurtu aralığı ve düzeyi.
## Değerler parametreyle gelir (saf kural).


## 0: sessiz (min_count altı), 1: en yoğun (full_count ve üstü).
static func intensity(count: int, min_count: int, full_count: int) -> float:
	if count < min_count:
		return 0.0
	if full_count <= min_count:
		return 1.0
	return clampf(float(count - min_count) / float(full_count - min_count), 0.0, 1.0)


## Sonraki homurtuya kadar süre (sn). roll [0, 1): ± jitter oranında rastgele pay.
static func interval(level: float, sparse: float, dense: float, jitter: float, roll: float) -> float:
	var base: float = lerpf(sparse, dense, clampf(level, 0.0, 1.0))
	return base * (1.0 + jitter * (roll * 2.0 - 1.0))


## Tablo düzeyine eklenecek dB: seyrekte sparse_db, en yoğunda 0.
static func volume_offset(level: float, sparse_db: float) -> float:
	return lerpf(sparse_db, 0.0, clampf(level, 0.0, 1.0))
