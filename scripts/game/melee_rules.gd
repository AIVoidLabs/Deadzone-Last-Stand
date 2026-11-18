class_name MeleeRules
extends RefCounted
## Yakın dövüş kuralları (saf): savurma yayının içinde kalma ve yanma sayacı.


## Hedef (target, yarıçapı radius) origin'den dir yönüne açılan yayın içinde mi?
## reach: yay yarıçapı (m); arc_rad: yayın toplam açısı. Hedefin gövdesi de sayılır:
## merkezi dışarıda kalsa bile gövdesi menzile giriyorsa vurulur, açıyı da gövde genişliği kadar esnetir.
static func in_arc(origin: Vector2, dir: Vector2, target: Vector2, radius: float, reach: float, arc_rad: float) -> bool:
	var offset: Vector2 = target - origin
	var dist: float = offset.length()
	if dist > reach + radius:
		return false
	if dist <= radius:
		return true
	var angle: float = absf(dir.angle_to(offset))
	var slack: float = asin(clampf(radius / dist, 0.0, 1.0))
	return angle <= arc_rad * 0.5 + slack


## Yanma sayacını bir adım ilerletir. left: kalan yanma süresi, acc: son vuruştan beri biriken süre,
## interval: iki yanma vuruşu arası. Dönüş: {"left", "acc", "ticks"} (ticks: bu adımda uygulanacak vuruş sayısı).
static func burn_step(left: float, acc: float, delta: float, interval: float) -> Dictionary:
	var active: float = minf(delta, left)
	acc += active
	var ticks: int = 0
	while acc >= interval:
		acc -= interval
		ticks += 1
	return {"left": maxf(0.0, left - delta), "acc": acc, "ticks": ticks}
