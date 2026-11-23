class_name BagRules
extends RefCounted
## Ödül çantası kuralları (saf): değer, tür dengesi, ömür/yanıp sönme, konum seçimi, ekran kenarı oku.

const KIND_MONEY: StringName = &"money"
const KIND_XP: StringName = &"xp"
## Uygun nokta bulunamadı.
const NO_POINT: Vector2 = Vector2(INF, INF)


## Dalga no (1'den) için çanta değeri.
static func value_for_wave(wave: int) -> int:
	return Tuning.BAG_VALUE_BASE + Tuning.BAG_VALUE_PER_WAVE * wave


static func color_of(kind: StringName) -> Color:
	return Tuning.BAG_MONEY_COLOR if kind == KIND_MONEY else Tuning.BAG_XP_COLOR


## Az çıkan tür seçilir; eşitlikte zar. Böylece iki ya da daha çok çantada iki tür de çıkar.
static func pick_kind(money_count: int, xp_count: int, rng: RandomNumberGenerator) -> StringName:
	if money_count != xp_count:
		return KIND_MONEY if money_count < xp_count else KIND_XP
	return KIND_MONEY if rng.randf() < 0.5 else KIND_XP


static func expired(age: float) -> bool:
	return age >= Tuning.BAG_LIFETIME


## Çanta bu yaşta çizilsin mi: son BAG_BLINK_TIME sn yanıp söner.
static func is_shown(age: float) -> bool:
	var blink_from: float = Tuning.BAG_LIFETIME - Tuning.BAG_BLINK_TIME
	if age < blink_from:
		return true
	return int((age - blink_from) * Tuning.BAG_BLINK_RATE * 2.0) % 2 == 0


## Nokta oyun alanında ve hiçbir bina/engele BAG_CLEARANCE'tan yakın değil mi.
static func is_walkable(p: Vector2, rects: Array[Rect2]) -> bool:
	var half: float = Tuning.ARENA_SIZE * 0.5 - Tuning.BAG_ARENA_MARGIN
	if absf(p.x) > half or absf(p.y) > half:
		return false
	return CityLayout.push_out(p, Tuning.BAG_CLEARANCE, rects) == p


## Askere BAG_MIN_DIST..BAG_MAX_DIST uzaklıkta yürünebilir nokta; denemeler biterse NO_POINT.
static func pick_point(origin: Vector2, rects: Array[Rect2], rng: RandomNumberGenerator) -> Vector2:
	for _i in Tuning.BAG_PLACE_TRIES:
		var p: Vector2 = origin + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(Tuning.BAG_MIN_DIST, Tuning.BAG_MAX_DIST)
		if is_walkable(p, rects):
			return p
	return NO_POINT


static func in_reach(bag: Vector2, player: Vector2) -> bool:
	return bag.distance_squared_to(player) <= Tuning.BAG_COLLECT_RADIUS * Tuning.BAG_COLLECT_RADIUS


## Ekran dışı ok: screen = çantanın ekran konumu. {visible, pos (kenara kıstırılmış), angle (rad)}.
static func arrow_placement(screen: Vector2, size: Vector2, margin: float) -> Dictionary:
	var inner: Rect2 = Rect2(Vector2(margin, margin), size - Vector2(margin, margin) * 2.0)
	if inner.has_point(screen):
		return {"visible": false, "pos": screen, "angle": 0.0}
	var center: Vector2 = size * 0.5
	var dir: Vector2 = (screen - center).normalized()
	var half: Vector2 = inner.size * 0.5
	var tx: float = half.x / absf(dir.x) if absf(dir.x) > 0.0001 else INF
	var ty: float = half.y / absf(dir.y) if absf(dir.y) > 0.0001 else INF
	return {"visible": true, "pos": center + dir * minf(tx, ty), "angle": dir.angle()}
