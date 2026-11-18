class_name StatData
extends RefCounted
## İstatistik tablosu. Değerler kartlardan (ileride eşyalardan) PlayerStats'ta birikir.
## format: listede gösterim; short: kartta adın altındaki değer (%s yerine sayı).

const MAX_HP: StringName = &"max_hp"
const DAMAGE: StringName = &"damage"
const FIRE_RATE: StringName = &"fire_rate"
const RANGE: StringName = &"range"
const MOVE_SPEED: StringName = &"move_speed"
const ARMOR: StringName = &"armor"
const LUCK: StringName = &"luck"
const HP_REGEN: StringName = &"hp_regen"
const PICKUP_RANGE: StringName = &"pickup_range"
const DASH_COOLDOWN: StringName = &"dash_cooldown"

## Gösterim sırası da budur.
const TABLE: Dictionary = {
	&"max_hp": {"name": "Can", "format": "+%s can", "short": "+%s"},
	&"damage": {"name": "Hasar", "format": "+%s%% hasar", "short": "+%s%%"},
	&"fire_rate": {"name": "Atış hızı", "format": "+%s%% atış hızı", "short": "+%s%%"},
	&"range": {"name": "Menzil", "format": "+%s%% menzil", "short": "+%s%%"},
	&"move_speed": {"name": "Hareket hızı", "format": "+%s%% hareket hızı", "short": "+%s%%"},
	&"armor": {"name": "Zırh", "format": "+%s zırh", "short": "+%s"},
	&"luck": {"name": "Şans", "format": "+%s şans", "short": "+%s"},
	&"hp_regen": {"name": "Can yenileme", "format": "+%s can yenileme", "short": "+%s"},
	&"pickup_range": {"name": "Toplama menzili", "format": "+%s%% toplama menzili", "short": "+%s%%"},
	&"dash_cooldown": {"name": "Dash bekleme süresi", "format": "-%s%% dash bekleme", "short": "-%s%%"},
}


static func describe(stat: StringName, value: float) -> String:
	return _signed(TABLE[stat]["format"], value)


static func short_value(stat: StringName, value: float) -> String:
	return _signed(TABLE[stat]["short"], value)


## Eksi değerde baştaki işaret ters çevrilir ("+%s can" → "-5 can", "-%s%% dash" → "+5% dash").
static func _signed(pattern: String, value: float) -> String:
	if value >= 0.0:
		return pattern % _number(value)
	var flipped: String = ("-" if pattern.begins_with("+") else "+") + pattern.substr(1)
	return flipped % _number(-value)


static func display_name(stat: StringName) -> String:
	return TABLE[stat]["name"]


static func _number(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else "%.1f" % value
