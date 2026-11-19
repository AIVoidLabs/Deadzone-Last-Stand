class_name EnemyQueries
extends RefCounted
## EnemyManager'ın uzamsal sorguları (ızgara tabanlı; tüm listeyi taramaz). Dizileri manager'dan okur;
## herkese açık çağrılar EnemyManager üzerinden yapılır.

const HIT_QUERY_MARGIN: float = 1.0

var _m: EnemyManager


func _init(manager: EnemyManager) -> void:
	_m = manager


## Menzildeki en yakın canlı zombi; yoksa -1.
func nearest_enemy(from: Vector2, max_range: float) -> int:
	return _m._grid.nearest(from, max_range, _m._pos, _m._targetable)


## center çevresinde radius içindeki canlı zombi sayısı.
func count_near(center: Vector2, radius: float) -> int:
	var count: int = 0
	for i in _m._grid.query_radius(center, radius, _m._pos):
		if i < _m._alive.size() and _m._alive[i] != 0:
			count += 1
	return count


## origin'den dir yönüne açılan yayın (arc_rad, reach) içindeki canlı zombiler (yakın dövüş savurması).
func query_arc(origin: Vector2, dir: Vector2, reach: float, arc_rad: float) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	var span: float = reach + _m._max_radius
	for i in _m._grid.query_rect(origin - Vector2(span, span), origin + Vector2(span, span)):
		if i < _m._targetable.size() and _m._targetable[i] != 0 and MeleeRules.in_arc(origin, dir, _m._pos[i], _m._radius[i], reach, arc_rad):
			out.append(i)
	return out


## center çevresinde radius içindeki (zombi gövdesi dahil) canlı zombilerin indeksleri (patlama alanı).
func query_circle(center: Vector2, radius: float) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	var span: float = radius + _m._max_radius
	for i in _m._grid.query_rect(center - Vector2(span, span), center + Vector2(span, span)):
		if i < _m._targetable.size() and _m._targetable[i] != 0 and _m._pos[i].distance_to(center) <= radius + _m._radius[i]:
			out.append(i)
	return out


## a→b yolunda ilk değilen canlı zombi; yoksa -1.
func find_segment_hit(a: Vector2, b: Vector2, radius: float, exclude: PackedInt32Array) -> int:
	var margin: float = radius + _m._max_radius + HIT_QUERY_MARGIN
	var lo: Vector2 = Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(margin, margin)
	var hi: Vector2 = Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2(margin, margin)
	var best: int = -1
	var best_t: float = 2.0
	for i in _m._grid.query_rect(lo, hi):
		if i >= _m._targetable.size() or _m._targetable[i] == 0 or (not exclude.is_empty() and exclude.has(i)):
			continue
		var t: float = CombatMath.segment_circle_t(a, b, _m._pos[i], _m._radius[i] + radius)
		if t >= 0.0 and t < best_t:
			best_t = t
			best = i
	return best
