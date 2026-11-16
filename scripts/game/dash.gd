class_name Dash
extends RefCounted
## Dash zamanlayıcısı: süre ve bekleme. Bekleme, dash başladığı anda işlemeye başlar.

var duration: float
var cooldown: float
var time_left: float = 0.0
var cooldown_left: float = 0.0


func _init(dash_duration: float, dash_cooldown: float) -> void:
	duration = dash_duration
	cooldown = dash_cooldown


func can_start() -> bool:
	return time_left <= 0.0 and cooldown_left <= 0.0


## Başlayabildiyse true.
func start() -> bool:
	if not can_start():
		return false
	time_left = duration
	cooldown_left = cooldown
	return true


## Dash bu adımda bittiyse true.
func tick(delta: float) -> bool:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if time_left <= 0.0:
		return false
	time_left = maxf(0.0, time_left - delta)
	return time_left <= 0.0


func is_active() -> bool:
	return time_left > 0.0


## 1: hazır, 0: yeni kullanıldı.
func readiness() -> float:
	if cooldown <= 0.0:
		return 1.0
	return 1.0 - cooldown_left / cooldown
