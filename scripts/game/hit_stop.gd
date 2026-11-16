class_name HitStop
extends RefCounted
## Vuruş duraksaması (hit-stop) kuralı: oyun çok kısa süre yavaşlar. Sürüde art arda öldürmeler
## oyunu sürekli kesmesin diye iki duraksama arasında bekleme süresi vardır. Zaman dışarıdan gelir.

var cooldown: float
var _ends_at: float = -1.0
var _ready_at: float = 0.0


func _init(p_cooldown: float) -> void:
	cooldown = p_cooldown


## now anında duration süreli duraksama ister. Dönüş: başladı mı.
func request(now: float, duration: float) -> bool:
	if duration <= 0.0 or now < _ready_at:
		return false
	_ends_at = now + duration
	_ready_at = _ends_at + cooldown
	return true


func is_active(now: float) -> bool:
	return now < _ends_at


func reset() -> void:
	_ends_at = -1.0
	_ready_at = 0.0
