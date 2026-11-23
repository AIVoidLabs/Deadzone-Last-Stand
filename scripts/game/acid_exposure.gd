class_name AcidExposure
extends RefCounted
## Asit havuzunda yavaşlama + yanma (saf kural). Havuz her karede touch() der; havuzdayken yavaşlama sürer ve havuzun kendi
## tik hasarı vurur. Havuzdan çıkınca linger sn boyunca hem yavaşlama hem yanma (saniyede dps; tick_every'de bir parça) sürer.

var _slow_percent: float
var _dps: float
var _linger: float
var _tick_every: float
var _left: float = 0.0
## Son tick'ten beri havuzdaydı (touch gelmişti): bu karede yanma yok, havuz zaten vuruyor.
var _fresh: bool = false
var _acc: float = 0.0


func _init(slow_percent: float, dps: float, linger: float, tick_every: float) -> void:
	_slow_percent = slow_percent
	_dps = dps
	_linger = linger
	_tick_every = tick_every


## Asker havuzun içinde (her fizik karesi).
func touch() -> void:
	_left = _linger
	_fresh = true


## Hareket hızı çarpanı: yavaşlıyorsa 1 - yüzde, değilse 1.
func speed_multiplier() -> float:
	return 1.0 - _slow_percent if _left > 0.0 else 1.0


func is_active() -> bool:
	return _left > 0.0


## Bir kare ilerler. Dönüş: bu karede yanmadan gelen hasar (havuzdayken 0; çıkınca linger süresince dps).
func tick(delta: float) -> float:
	if _left <= 0.0:
		_acc = 0.0
		_fresh = false
		return 0.0
	_left = maxf(0.0, _left - delta)
	if _fresh:
		_fresh = false
		_acc = 0.0
		return 0.0
	var step: Vector2 = LobRules.advance_tick(_acc, delta, _tick_every)
	_acc = step.x
	return step.y * _dps * _tick_every


func reset() -> void:
	_left = 0.0
	_fresh = false
	_acc = 0.0
