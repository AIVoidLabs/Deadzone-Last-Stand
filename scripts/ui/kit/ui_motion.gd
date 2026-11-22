class_name UiMotion
extends RefCounted
## Arayüz hareketleri. Tween'ler duraklatmada da çalışır; FEATURE_UI_MOTION kapalıysa anında.

const POP_FROM_SCALE: float = 0.86
const POP_TIME: float = 0.28
const SHAKE_STEPS: int = 6


static func _tween(c: Node) -> Tween:
	var t: Tween = c.create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	return t


static func pop_in(c: Control, delay: float = 0.0) -> void:
	if not Tuning.FEATURE_UI_MOTION:
		return
	c.pivot_offset = c.size * 0.5
	c.scale = Vector2.ONE * POP_FROM_SCALE
	c.modulate.a = 0.0
	var t: Tween = _tween(c)
	t.set_parallel(true)
	t.tween_property(c, "scale", Vector2.ONE, POP_TIME).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "modulate:a", 1.0, POP_TIME * 0.7).set_delay(delay)


static func fade(c: CanvasItem, to: float, time: float = 0.2) -> Tween:
	if not Tuning.FEATURE_UI_MOTION:
		c.modulate.a = to
		return null
	var t: Tween = _tween(c)
	t.tween_property(c, "modulate:a", to, time)
	return t


static func shake(c: Control, strength: float = 8.0, time: float = 0.25) -> void:
	if not Tuning.FEATURE_UI_MOTION:
		return
	var rest: Vector2 = c.position
	var t: Tween = _tween(c)
	for i: int in SHAKE_STEPS:
		var k: float = 1.0 - float(i) / SHAKE_STEPS
		var off: Vector2 = Vector2(randf_range(-1.0, 1.0), randf_range(-0.4, 0.4)) * strength * k
		t.tween_property(c, "position", rest + off, time / SHAKE_STEPS)
	t.tween_property(c, "position", rest, 0.02)
