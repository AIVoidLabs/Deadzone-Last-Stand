class_name ZombieSwell
extends RefCounted
## Patlayıcının şişme parıltısı (ZombieVisual'in yardımcısı): hazırlık boyunca turuncu parıltı (burn kanalı) giderek hızlanan
## yanıp sönmeyle artar. tick() parıltı gücünü (0..1) döner; durdurulunca -1.

## Parıltı gücü: başlangıç oranı ve titreşim payı (güç = lerp(BASE, 1, ilerleme) * (1 - WOBBLE + WOBBLE * sin)).
const BASE_GLOW: float = 0.35
const WOBBLE: float = 0.4

var _age: float = -1.0
var _total: float = 1.0
var _phase: float = 0.0


func start(duration: float) -> void:
	_age = 0.0
	_total = maxf(duration, 0.01)
	_phase = 0.0


func stop() -> void:
	_age = -1.0


func is_on() -> bool:
	return _age >= 0.0


func tick(delta: float) -> float:
	if _age < 0.0:
		return -1.0
	_age += delta
	var progress: float = clampf(_age / _total, 0.0, 1.0)
	_phase += delta * lerpf(Tuning.BLOAT_BLINK_START_HZ, Tuning.BLOAT_BLINK_END_HZ, progress) * TAU
	return lerpf(BASE_GLOW, 1.0, progress) * (1.0 - WOBBLE + WOBBLE * sin(_phase))
