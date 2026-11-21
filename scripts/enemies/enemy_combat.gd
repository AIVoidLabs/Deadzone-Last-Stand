class_name EnemyCombat
extends RefCounted
## EnemyManager'ın soğuk kodu: hasar alma, durum süresi dolunca geçiş (hazırlık vuruşu dahil) ve öldürme.
## Dizilere yöneticinin üzerinden erişir; sinyalleri ve sayaçları yöneticide yayar.

var _m: EnemyManager
## Son _armor çağrısının hasar çarpanı.
var _armor_factor: float = 1.0


func _init(manager: EnemyManager) -> void:
	_m = manager


## direction: vuruşun geldiği yön (itme bu yöne). knockback: ağırlığı 1 olana verilen ilk hız.
func damage(index: int, amount: float, direction: Vector2, knockback: float, dot: bool = false) -> void:
	var state: ZombieRules.State = _m._state[index] as ZombieRules.State
	if _m._alive[index] == 0 or not ZombieRules.can_take_damage(state):
		return
	var row: Dictionary = _m._rows[index]
	var blocked: bool = false
	if not dot and Tuning.FEATURE_ZOMBIE_ARMOR and row.has("armor_front_factor"):
		blocked = _armor(index, row, direction)
		amount *= _armor_factor
	_m._hp[index] -= amount
	_m._nodes[index].notify_hit(amount)
	var at: Vector3 = Vector3(_m._pos[index].x, 0.0, _m._pos[index].y)
	if blocked and _m._hp[index] > 0.0:
		_m.enemy_blocked.emit(at, direction, amount)
	else:
		_m.enemy_damaged.emit(at, direction, amount, _m._hp[index] <= 0.0)
	if _m._hp[index] <= 0.0:
		kill(index, Knockback.impulse(direction, knockback * Tuning.ZOMBIE_DEATH_KNOCKBACK_FACTOR, row["weight"]))
		return
	if Tuning.FEATURE_KNOCKBACK:
		_m._knock[index] += Knockback.impulse(direction, knockback, row["weight"])
	if Tuning.FEATURE_STAGGER and float(row["stagger_time"]) > 0.0 and ZombieRules.can_stagger(state) and not BloatAttack.is_primed(row, state) 			and not (state == ZombieRules.State.RECOVER and SpecialAttacks.holds_recover(row)):
		_m._enter(index, ZombieRules.State.STAGGER, row["stagger_time"], true)


## CHASE'deki zombi saldırıyı başlatır mı: menzile girdiyse hazırlığa (WINDUP) geçer. Boss'ta saldırıyı BossAttack seçer.
func begin_attack(i: int, p: Vector2, target: Vector2, target_vel: Vector2, dist: float, reach: float, special: bool, delta: float) -> void:
	var row: Dictionary = _m._rows[i]
	if special and row["attack_kind"] == &"boss":
		_m._special.boss.try_start(i, p, target, dist, delta)
		return
	if not ZombieRules.wants_attack(dist, reach, SpecialAttacks.start_range(row)):
		return
	_m._enter(i, ZombieRules.State.WINDUP, _m._special.windup_time(i, dist, reach) if special else float(row["attack_windup"]))
	if special:
		_m._special.begin_windup(i, p, target, target_vel)


## Zırhlıya gelen vuruş: çarpanı _armor_factor'a yazar, önden mi döner; sayaçlar.
func _armor(index: int, row: Dictionary, direction: Vector2) -> bool:
	var half: float = deg_to_rad(float(row["armor_front_half_deg"]))
	var facing: Vector2 = _m._aim[index]
	var to_source: Vector2 = -direction
	_armor_factor = ArmorRules.factor(facing, to_source, half, float(row["armor_front_factor"]), float(row["armor_back_factor"]))
	var front: bool = ArmorRules.is_front(facing, to_source, half)
	if front:
		_m.armor_front += 1
	elif to_source != Vector2.ZERO:
		_m.armor_back += 1
	return front


## Süresi dolan durumdan çıkar; hazırlık bittiyse vuruşu uygular. Dönüş: yeni durum.
func on_timer(index: int, state: ZombieRules.State, target: Vector2) -> ZombieRules.State:
	var row: Dictionary = _m._rows[index]
	var special: bool = SpecialAttacks.is_special(row)
	if special and state == ZombieRules.State.WINDUP:
		return _m._special.end_windup(index, target)
	if special and SpecialAttacks.acts_in(state) and state != ZombieRules.State.WINDUP:
		return _m._special.finish(index, state, target)
	var next: ZombieRules.State = ZombieRules.after_timer(state)
	if state == ZombieRules.State.WINDUP:
		var contact: float = Tuning.PLAYER_RADIUS + _m._radius[index]
		if ZombieRules.strike_hits(_m._pos[index].distance_to(target), contact, row["attack_hit_range"]):
			_m.player.take_hit(_m._damage[index], target - _m._pos[index])
		_m._enter(index, next, row["attack_recover"])
	else:
		_m._enter(index, next, 0.0)
	return next


## push: öldüren vuruşun itmesi; ceset bu yöne düşer ve kayar.
## credit: öldürme sayılır ve enemy_killed yayılır (dalga sonu devrilmelerde kapalı).
## corpse: false ise düğüm hemen havuza döner (ceset yok). Silahla ölen patlayıcı (credit) cesetsiz kalıp fitille patlar.
func kill(index: int, push: Vector2 = Vector2.ZERO, credit: bool = true, corpse: bool = true) -> void:
	if _m._burn_left[index] > 0.0:
		_m._burn.extinguish(index)
	_m._special.on_removed(index)
	_m._alive[index] = 0
	_m._dead_count += 1
	var node: Zombie = _m._nodes[index]
	if credit:
		_m.kills += 1
		_m.enemy_killed.emit(node.position, _m._rows[index])
	if credit and BloatAttack.active(_m._rows[index]):
		_m._special.queue_death_fuse(index)
		corpse = false
	if not corpse or not Tuning.FEATURE_ZOMBIE_DEATH_ANIM:
		node.deactivate()
		return
	# Ölüm klipleri arkaya düşer: yüzü vuruşun geldiği yöne çevir, sırtüstü vuruş yönüne düşsün.
	if push != Vector2.ZERO:
		node.rotation.y = atan2(-push.x, -push.y)
	var duration: float = float(_m._rows[index].get("death_duration", Tuning.ZOMBIE_CORPSE_TIME + Tuning.ZOMBIE_FADE_TIME))
	node.enter_state(ZombieRules.State.DYING, duration)
	_m._corpses.add(node, push if Tuning.FEATURE_KNOCKBACK else Vector2.ZERO, duration)


## Dalga sonu: count kadar canlı zombiyi öldürme sayılmadan devirir (sondan başa).
func dismiss(count: int) -> void:
	var i: int = _m._pos.size() - 1
	while i >= 0 and count > 0:
		if _m._alive[i] != 0:
			kill(i, Vector2.ZERO, false)
			count -= 1
		i -= 1
