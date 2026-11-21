class_name BrokenFlicker
extends RefCounted
## Bozuk lamba / neon titremesi: çoğu zaman tam yanar, rastgele aralıklarla kısa süre düzensiz söner-yanar.

var gap_min: float = 2.0
var gap_max: float = 6.0
var burst_min: float = 0.3
var burst_max: float = 0.8
var dim: float = 0.05
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _until_burst: float = 0.0
var _burst_left: float = 0.0
var _stutter: float = 0.0
var _on: bool = true


func _init(seed_value: int = 1) -> void:
	_rng.seed = seed_value
	_until_burst = _rng.randf_range(gap_min, gap_max)


## Çarpan 0..1 döndürür (1 = tam yanık).
func step(delta: float) -> float:
	if _burst_left > 0.0:
		_burst_left -= delta
		_stutter -= delta
		if _stutter <= 0.0:
			_on = not _on
			_stutter = _rng.randf_range(0.03, 0.14)
		if _burst_left <= 0.0:
			_on = true
			_until_burst = _rng.randf_range(gap_min, gap_max)
		return 1.0 if _on else dim
	_until_burst -= delta
	if _until_burst <= 0.0:
		_burst_left = _rng.randf_range(burst_min, burst_max)
		_stutter = 0.0
	return 1.0
