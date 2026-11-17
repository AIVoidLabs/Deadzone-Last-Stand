class_name VoiceLimiter
extends RefCounted
## Aynı sesin üst üste binip kalabalıkta gürültüye dönmesini önler:
## aynı anda en çok N kopya, iki çalış arası en az süre. Zaman parametreyle gelir (saf kural).

var _last_play: Dictionary = {}


## İzin verirse çalışı kaydeder ve true döner.
func request(id: StringName, now: float, active: int, max_voices: int, min_interval: float) -> bool:
	if max_voices <= 0 or active >= max_voices:
		return false
	if _last_play.has(id) and now - float(_last_play[id]) < min_interval:
		return false
	_last_play[id] = now
	return true


func reset() -> void:
	_last_play.clear()


## roll [0, 1) -> 1 ± variance arası perde.
static func pitch(variance: float, roll: float) -> float:
	return 1.0 + variance * (roll * 2.0 - 1.0)
