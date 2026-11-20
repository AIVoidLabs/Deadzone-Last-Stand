class_name EnemyCombat
extends RefCounted
## EnemyManager'ın soğuk kodu: hasar alma, durum süresi dolunca geçiş (hazırlık vuruşu dahil) ve öldürme.
## Dizilere yöneticinin üzerinden erişir; sinyalleri ve sayaçları yöneticide yayar.

var _m: EnemyManager


func _init(manager: EnemyManager) -> void:
	_m = manager


## direction: vuruşun geldiği yön (itme bu yöne). knockback: ağırlığı 1 olana verilen ilk hız.
func damage(index: int, amount: float, direction: Vector2, knockback: float) -> void:
	var state: ZombieRules.State = _m._state[index] as ZombieRules.State
	if _m._alive[index] == 0 or not ZombieRules.can_take_damage(state):
		return
	_m._hp[index] -= amount
	_m._nodes[index].notify_hit(amount)
	var row: Dictionary = _m._rows[index]
	var at: Vector3 = Vector3(_m._pos[index].x, 0.0, _m._pos[index].y)
	_m.enemy_damaged.emit(at, direction, amount, _m._hp[index] <= 0.0)
	if _m._hp[index] <= 0.0:
		kill(index, Knockback.impulse(direction, knockback * Tuning.ZOMBIE_DEATH_KNOCKBACK_FACTOR, row["weight"]))
		return
	if Tuning.FEATURE_KNOCKBACK:
		_m._knock[index] += Knockback.impulse(direction, knockback, row["weight"])
	if Tuning.FEATURE_STAGGER and float(row["stagger_time"]) > 0.0 and ZombieRules.can_stagger(state):
		_m._enter(index, ZombieRules.State.STAGGER, row["stagger_time"], true)


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
func kill(index: int, push: Vector2 = Vector2.ZERO, credit: bool = true) -> void:
	if _m._burn_left[index] > 0.0:
		_m._burn.extinguish(index)
	_m._special.on_removed(index)
	_m._alive[index] = 0
	_m._dead_count += 1
	var node: Zombie = _m._nodes[index]
	if credit:
		_m.kills += 1
		_m.enemy_killed.emit(node.position, _m._rows[index])
	if not Tuning.FEATURE_ZOMBIE_DEATH_ANIM:
		node.deactivate()
		return
	# Ölüm klipleri arkaya düşer: yüzü vuruşun geldiği yöne çevir, sırtüstü vuruş yönüne düşsün.
	if push != Vector2.ZERO:
		node.rotation.y = atan2(-push.x, -push.y)
	var duration: float = Tuning.ZOMBIE_CORPSE_TIME + Tuning.ZOMBIE_FADE_TIME
	node.enter_state(ZombieRules.State.DYING, duration)
	_m._corpses.add(node, push if Tuning.FEATURE_KNOCKBACK else Vector2.ZERO, duration)
