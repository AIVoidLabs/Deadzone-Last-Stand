class_name PlayerStats
extends RefCounted
## Askerin tur içi istatistikleri: kartlardan gelen artışlar birikir, temel değerler Tuning'de kalır.
## Yüzdeler çarpan olarak uygulanır; can ve zırh düz eklenir.

## Bir istatistik değişti (stat: StatData kimliği, amount: eklenen).
signal changed(stat: StringName, amount: float)

var _bonus: Dictionary = {}


func add(stat: StringName, amount: float) -> void:
	assert(StatData.TABLE.has(stat), "Bilinmeyen istatistik: %s" % stat)
	_bonus[stat] = bonus(stat) + amount
	changed.emit(stat, amount)


func bonus(stat: StringName) -> float:
	return _bonus.get(stat, 0.0)


func max_hp() -> float:
	return Tuning.PLAYER_MAX_HP + bonus(StatData.MAX_HP)


func armor() -> float:
	return Tuning.PLAYER_ARMOR + bonus(StatData.ARMOR)


func move_speed() -> float:
	return Tuning.PLAYER_SPEED * _percent(StatData.MOVE_SPEED)


## Saniyede yenilenen can.
func regen_per_second() -> float:
	return bonus(StatData.HP_REGEN) * Tuning.HP_REGEN_PER_POINT


func dash_cooldown() -> float:
	return dash_cooldown_for(bonus(StatData.DASH_COOLDOWN))


## Takla beklemesi (sn): bonus yüzde kısaltma (üst sınırlı), eksi bonus uzatır. Ekranlar da bunu gösterir.
static func dash_cooldown_for(cut_percent: float) -> float:
	return Tuning.DASH_COOLDOWN * (1.0 - minf(cut_percent, Tuning.DASH_COOLDOWN_CUT_CAP) / 100.0)


## Dash hızı (süre sabit, mesafe buna bağlı).
func dash_speed() -> float:
	return Tuning.DASH_SPEED * _percent(StatData.DASH_DISTANCE)


func pickup_radius() -> float:
	return Tuning.PICKUP_MAGNET_RADIUS * _percent(StatData.PICKUP_RANGE)


func luck() -> float:
	return bonus(StatData.LUCK)


func weapon_damage(base: float) -> float:
	return base * _percent(StatData.DAMAGE)


func fire_interval(base: float) -> float:
	return base / _percent(StatData.FIRE_RATE)


func weapon_range(base: float) -> float:
	return base * _percent(StatData.RANGE)


## 1 + yüzde/100; eksiye düşse bile en az MIN_STAT_MULTIPLIER.
func _percent(stat: StringName) -> float:
	return maxf(Tuning.MIN_STAT_MULTIPLIER, 1.0 + bonus(stat) / 100.0)
