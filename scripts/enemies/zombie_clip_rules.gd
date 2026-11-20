class_name ZombieClipRules
extends RefCounted
## Zombi klip hızı kuralları (saf; sahne ve autoload'a dokunmaz).


## Yürüme klibinin speed_scale'i: gerçek hız / (klibin anahtarlandığı hız * örnek boy ölçeği), [min, max] arası.
static func walk_speed_scale(speed: float, ref_speed: float, size_scale: float, min_scale: float, max_scale: float) -> float:
	var denom: float = maxf(ref_speed * size_scale, 0.0001)
	return clampf(speed / denom, min_scale, max_scale)
