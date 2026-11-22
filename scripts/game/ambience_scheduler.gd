class_name AmbienceScheduler
extends RefCounted
## Uzak ses zamanlayıcısı (saf kural): rastgele aralıklarla bir satır ve bir yön seçer.
## Sahneden bağımsız: süre (delta) ve tohum dışarıdan gelir.

var interval_min: float
var interval_max: float
## Son seçilen sesin yönü (radyan, XZ düzleminde).
var last_angle: float = 0.0
var _weights: Array[float]
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _left: float = 0.0
var _last_index: int = -1


func _init(weights: Array[float], min_interval: float, max_interval: float, seed_value: int) -> void:
	_weights = weights
	interval_min = min_interval
	interval_max = maxf(min_interval, max_interval)
	_rng.seed = seed_value
	_left = _next_interval()


## delta sn ilerler; çalma zamanı geldiyse satır indeksini, yoksa -1 döndürür.
func step(delta: float) -> int:
	if _weights.is_empty():
		return -1
	_left -= delta
	if _left > 0.0:
		return -1
	_left = _next_interval()
	_last_index = _pick()
	last_angle = _rng.randf() * TAU
	return _last_index


## Bir sonraki sese kalan süre (test ve debug için).
func time_left() -> float:
	return _left


func _next_interval() -> float:
	return _rng.randf_range(interval_min, interval_max)


## Ağırlıklı seçim; birden çok satır varsa art arda aynı ses gelmez.
func _pick() -> int:
	var total: float = 0.0
	for i: int in _weights.size():
		if i != _last_index or _weights.size() == 1:
			total += _weights[i]
	var roll: float = _rng.randf() * total
	for i: int in _weights.size():
		if i == _last_index and _weights.size() > 1:
			continue
		roll -= _weights[i]
		if roll <= 0.0:
			return i
	return _weights.size() - 1
