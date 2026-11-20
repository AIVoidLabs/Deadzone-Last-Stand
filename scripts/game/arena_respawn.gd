class_name ArenaRespawn
extends RefCounted
## Debug arenasının yeniden doğma sayacı: sahnede zombi yokken delay saniye sonra true döner.

var delay: float
var _left: float


func _init(respawn_delay: float) -> void:
	delay = respawn_delay
	_left = respawn_delay


## Her karede çağrılır; zombi yoksa sayar, süre dolunca true (sayaç yeniden kurulur).
func tick(has_enemy: bool, delta: float) -> bool:
	if has_enemy:
		_left = delay
		return false
	_left -= delta
	if _left > 0.0:
		return false
	_left = delay
	return true


## Bir sonraki tick'te (zombi yoksa) hemen doğurt: arena açılışında boş bekleme olmasın.
func fire_next() -> void:
	_left = 0.0


## Hemen doğurma isteği sonrası sayacı sıfırlar.
func reset() -> void:
	_left = delay
