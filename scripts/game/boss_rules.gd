class_name BossRules
extends RefCounted
## Boss "Yığın" kuralları (saf; sayılar EnemyDataBoss satırından parametreyle gelir): saldırı seçimi (mesafe aralığı,
## ağırlık, tekrarsız kural, çağrı bekleme süresi), şok halkası ve merkez isabeti, hücum yolunda isabet, duvara çarpma,
## öfke eşiği ve çarpanları. Rastgelelik `roll` (0..1) parametresiyle gelir.

enum Attack { NONE, SLAM, CHARGE, SUMMON }

const _NAMES: Dictionary = {Attack.SLAM: &"slam", Attack.CHARGE: &"charge", Attack.SUMMON: &"summon"}


static func attack_name(attack: Attack) -> StringName:
	return _NAMES.get(attack, &"")


## Bu mesafede yapılabilen saldırılar: yer dövme yakında (slam_range), hücum aralıkta (charge_min..charge_max), çağrı bekleme bitince her yerde.
static func available(dist: float, summon_cooldown_left: float, row: Dictionary) -> Array[int]:
	var out: Array[int] = []
	if dist <= float(row["slam_range"]):
		out.append(Attack.SLAM)
	if dist >= float(row["charge_min"]) and dist <= float(row["charge_max"]):
		out.append(Attack.CHARGE)
	if summon_cooldown_left <= 0.0:
		out.append(Attack.SUMMON)
	return out


## Ağırlıklı ve tekrarsız seçim: aynı saldırı üst üste seçilmez (last hariç tutulur); hariç tutunca hiçbiri kalmazsa
## (örneğin yakında slam sonrası çağrı beklerken) tekrar serbesttir. Hiçbiri yapılamıyorsa NONE (boss yürümeye devam eder).
static func pick(dist: float, last: Attack, summon_cooldown_left: float, row: Dictionary, roll: float) -> Attack:
	var options: Array[int] = available(dist, summon_cooldown_left, row)
	var fresh: Array[int] = []
	for a: int in options:
		if a != last:
			fresh.append(a)
	if not fresh.is_empty():
		options = fresh
	if options.is_empty():
		return Attack.NONE
	var weights: Dictionary = row["attack_weights"]
	var total: float = 0.0
	for a: int in options:
		total += float(weights[attack_name(a as Attack)])
	var at: float = clampf(roll, 0.0, 0.999999) * total
	for a: int in options:
		at -= float(weights[attack_name(a as Attack)])
		if at < 0.0:
			return a as Attack
	return options[options.size() - 1] as Attack


## Hazırlık süresi: öfkedeyse rage_windup_factor ile kısalır.
static func windup(base: float, raged: bool, row: Dictionary) -> float:
	return base * float(row["rage_windup_factor"]) if raged else base


## Yer dövmesinde halka sayısı: öfkede iki.
static func ring_count(raged: bool) -> int:
	return 2 if raged else 1


## Can eşiğin altına indi ve öfke daha başlamadı mı.
static func should_rage(hp: float, max_hp: float, raged: bool, row: Dictionary) -> bool:
	return not raged and hp > 0.0 and hp < max_hp * float(row["rage_threshold"])


## Öfkede yürüme hızı.
static func rage_speed(speed: float, row: Dictionary) -> float:
	return speed * float(row["rage_speed_factor"])


## Süpürülen halka bandı [prev_front - width, front] asker gövdesiyle [dist - r, dist + r] kesişiyor mu
## (kare içinde ön kenar askerin üstünden geçtiyse; dışarıdaki ve içeride kalan asker kesişmez).
static func sweep_hits(prev_front: float, front: float, width: float, dist: float, target_radius: float) -> bool:
	return dist + target_radius >= prev_front - width and dist - target_radius <= front


## Yer dövmesinin merkez hasarı: asker merkeze slam_center_radius içinde mi.
static func center_hit(dist: float, row: Dictionary) -> bool:
	return dist <= float(row["slam_center_radius"])


## Hücum yolu: a→b süpürülen kapsül (boss yarıçapı + asker yarıçapı) askeri kapsıyor mu.
static func sweep_capsule_hits(a: Vector2, b: Vector2, boss_radius: float, target: Vector2, target_radius: float) -> bool:
	return Geometry2D.get_closest_point_to_segment(target, a, b).distance_to(target) <= boss_radius + target_radius


## Hedef konum arena duvarını aştı mı (lim: merkezden izin verilen en uzak koordinat); duvara paralel gidiş çarpma sayılmaz.
static func hits_wall(p: Vector2, lim: float) -> bool:
	return absf(p.x) > lim or absf(p.y) > lim


## p'den dir yönüne (birim) duvara (±lim kare) kadar uzaklık.
static func wall_distance(p: Vector2, dir: Vector2, lim: float) -> float:
	var best: float = INF
	for axis in 2:
		if absf(dir[axis]) > 0.0001:
			best = minf(best, ((lim if dir[axis] > 0.0 else -lim) - p[axis]) / dir[axis])
	return maxf(best, 0.0)
