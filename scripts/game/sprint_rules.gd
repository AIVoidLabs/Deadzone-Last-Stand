class_name SprintRules
extends RefCounted
## Koşucunun durmadan koşu saldırısının saf kuralları (Tuning.FEATURE_RUNNER_SPRINT). Değerler satırdan parametreyle gelir.
## Tetik: temas + trigger_range içinde bir kez çığlık; koşu: dönüşü sınırlı (yana kaçan asker ıskalatır, zombi yay
## çizip geri döner); vuruş: STRIKE başladıktan hit_time sn sonra; asker çok uzaklaşınca koşu biter.


## Kovalarken çığlığı (ve ardından koşuyu) başlatır mı.
static func triggers(distance: float, contact: float, trigger_range: float) -> bool:
	return distance <= contact + trigger_range


## Koşu yönü: current, desired'a en çok turn_rate * delta radyan döner (hız sabit, durmaz).
static func run_direction(current: Vector2, desired: Vector2, turn_rate: float, delta: float) -> Vector2:
	return LungeRules.steer(current, desired, turn_rate * delta)


## Asker temas + strike_range içinde ve koşu yönü askere dönük (aim · askere yön >= face_dot): pençe başlar.
## Geçip gidip sırtı dönük koşucu, yay çizip yeniden yönelene dek pençelemez.
static func wants_strike(distance: float, contact: float, strike_range: float, aim: Vector2, to_target: Vector2, face_dot: float) -> bool:
	return distance <= contact + strike_range and aim.dot(to_target) >= face_dot


## Pençe indikten sonra (kalan süre <= recover) koşucu geçip gider: dönmez, askerle temas çözümü uygulanmaz.
static func is_passing(left: float, recover: float) -> bool:
	return left <= recover


## STRIKE süresi: vuruşa kadar + toparlanma.
static func strike_duration(hit_time: float, recover: float) -> float:
	return hit_time + recover


## Kalan süre bu karede vuruş anından geçti mi (STRIKE süresi strike_duration; vuruş, kalan = recover olduğunda).
static func is_hit_moment(left: float, delta: float, recover: float) -> bool:
	return left <= recover and left + delta > recover


## STRIKE sırasında koşu hızı: vuruşa kadar move_factor, vuruştan sonra (toparlanma) recover_factor ile çarpılır.
static func strike_speed(sprint_speed: float, left: float, recover: float, move_factor: float, recover_factor: float) -> float:
	return sprint_speed * (move_factor if left > recover else recover_factor)


## Asker trigger_range × give_up_factor'dan uzaklaştı: koşu biter, yeniden kovalar.
static func gives_up(distance: float, contact: float, trigger_range: float, give_up_factor: float) -> bool:
	return distance > contact + trigger_range * give_up_factor
