class_name Stride
extends RefCounted
## Adım sayacı: kat edilen yolu adımlara böler. İlk adım yarım adım boyunda gelir
## (harekete başlar başlamaz ses gecikmesin, ama ilk karede de patlamasın).

var stride: float
var _left: float


func _init(p_stride: float) -> void:
	stride = maxf(p_stride, 0.01)
	reset()


## distance kadar yol için atılan adım sayısı.
func advance(distance: float) -> int:
	var steps: int = 0
	_left -= distance
	while _left <= 0.0:
		_left += stride
		steps += 1
	return steps


## Durunca çağrılır: sonraki harekette ilk adım yine yarım boyda gelir.
func reset() -> void:
	_left = stride * 0.5
