class_name ShockRing
extends RefCounted
## Boss yer dövmesinin genişleyen şok halkası (saf kural, görüntü BossFx'te). Halkanın ön kenarı `front` m/sn ile büyür,
## kalınlığı `width`; arkasında kalan (içeride) ve önünde kalan (dışarıda) güvenlidir. Ön kenar askerin üstünden geçerken
## (kare içinde süpürülen bant gövdeyle kesişirse) asker açıktaysa BİR kez vurur; dash dokunulmazlığı geçişi kaçırır.

var origin: Vector2
var speed: float
var max_radius: float
var width: float
## Ön kenarın şimdiki yarıçapı (m).
var front: float = 0.0
## Asker bu halkadan vuruldu mu (bir halka en çok bir kez vurur).
var hit: bool = false


func _init(center: Vector2, ring_speed: float, ring_max: float, ring_width: float) -> void:
	origin = center
	speed = ring_speed
	max_radius = ring_max
	width = ring_width


## Halka son yarıçapına ulaştı (ömrü bitti).
func is_done() -> bool:
	return front >= max_radius


## Halkayı delta kadar büyütür. Dönüş: bu karede asker (target, yarıçap target_radius) vuruldu mu.
## exposed: asker vurulabilir mi (dash dokunulmazlığı ya da dokunulmazlık payında false: vuruş sayılmaz, halka üstünden geçilmiş olur).
func step(delta: float, target: Vector2, target_radius: float, exposed: bool) -> bool:
	var prev: float = front
	front = minf(front + speed * delta, max_radius)
	if hit or not exposed:
		return false
	hit = BossRules.sweep_hits(prev, front, width, origin.distance_to(target), target_radius)
	return hit
