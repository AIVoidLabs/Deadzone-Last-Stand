class_name MarketFx
extends RefCounted
## Mağaza efektleri: SATILDI damgası ve yetersiz bakiye sallanması. FEATURE_UI_MOTION kapalıysa hiçbiri çalışmaz.

const STAMP_FROM: float = 2.4
const STAMP_TIME: float = 0.22
const PUNCH_SCALE: float = 1.05
const WOBBLE_TILT: float = 0.045
const WOBBLE_STEPS: int = 4
const WOBBLE_TIME: float = 0.26


static func _tween(node: Node) -> Tween:
	var t: Tween = node.create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	return t


## Plaka büyükten çarparak yerine oturur, kart küçük bir vuruş yer.
static func stamp(card: GrungeCard) -> void:
	if not Tuning.FEATURE_UI_MOTION:
		return
	var stamp_plate: Control = card.state_plate()
	if stamp_plate != null:
		stamp_plate.scale = Vector2.ONE * STAMP_FROM
		stamp_plate.modulate.a = 0.0
		var t: Tween = _tween(card)
		t.set_parallel(true)
		t.tween_property(stamp_plate, "scale", Vector2.ONE, STAMP_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_property(stamp_plate, "modulate:a", 1.0, STAMP_TIME * 0.6)
	card.pivot_offset = card.size * 0.5
	var punch: Tween = _tween(card)
	punch.tween_interval(STAMP_TIME)
	punch.tween_property(card, "scale", Vector2.ONE * PUNCH_SCALE, 0.06)
	punch.tween_property(card, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Kısa sağ-sol sallanma (konum elle/konteynerde olduğundan döndürerek).
static func wobble(target: Control) -> void:
	if not Tuning.FEATURE_UI_MOTION:
		return
	target.pivot_offset = target.size * 0.5
	var t: Tween = _tween(target)
	for i: int in WOBBLE_STEPS:
		var k: float = 1.0 - float(i) / WOBBLE_STEPS
		t.tween_property(target, "rotation", WOBBLE_TILT * k * (1.0 if i % 2 == 0 else -1.0), WOBBLE_TIME / WOBBLE_STEPS)
	t.tween_property(target, "rotation", 0.0, 0.04)
