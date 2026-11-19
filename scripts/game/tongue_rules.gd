class_name TongueRules
extends RefCounted
## Dilcinin dil kuralları (saf, Aşama V.4): dil görünür hızla düz uçar, ucun süpürdüğü yol askerin
## dairesine değerse yakalar; yakalanan asker dilciye doğru yavaşça çekilir, yakına gelince ya da
## süre bitince bırakılır. Sayılar tür satırından (EnemyData) parametreyle gelir.

enum Release { NONE, NEAR, TIMEOUT }


## Dilin tam boya (reach) uçma süresi (sn).
static func flight_time(reach: float, speed: float) -> float:
	return reach / maxf(speed, 0.001)


## Atıştan elapsed sn sonra ucun ağızdan uzaklığı (m); reach'te durur.
static func tip_distance(elapsed: float, speed: float, reach: float) -> float:
	return clampf(elapsed * speed, 0.0, reach)


## Uç bu karede from_d'den to_d'ye ilerlerken (origin'den dir yönünde) target dairesine değdi mi.
## catch_radius: asker yarıçapı + dilin yakalama payı. Süpürme sayesinde hızlı uç askerin içinden atlamaz.
static func catches(origin: Vector2, dir: Vector2, from_d: float, to_d: float, target: Vector2, catch_radius: float) -> bool:
	var a: Vector2 = origin + dir * from_d
	var b: Vector2 = origin + dir * maxf(to_d, from_d + 0.0001)
	return CombatMath.segment_circle_t(a, b, target, catch_radius) >= 0.0


## Çekilen askerin bu karedeki hızı: dilciye doğru speed m/sn, stop_dist'in içine geçmeden.
static func pull_velocity(player: Vector2, zombie: Vector2, speed: float, stop_dist: float, delta: float) -> Vector2:
	var to_zombie: Vector2 = zombie - player
	var dist: float = to_zombie.length()
	var room: float = dist - stop_dist
	if room <= 0.0 or dist < 0.0001:
		return Vector2.ZERO
	return to_zombie / dist * minf(speed, room / maxf(delta, 0.0001))


## Çekiş bitti mi: asker stop_dist'e geldiyse NEAR (dilci ısırır), süre dolduysa TIMEOUT.
static func release(dist: float, stop_dist: float, time_left: float) -> Release:
	if dist <= stop_dist + 0.01:
		return Release.NEAR
	if time_left <= 0.0:
		return Release.TIMEOUT
	return Release.NONE
