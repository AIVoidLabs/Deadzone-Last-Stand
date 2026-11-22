class_name StatData
extends RefCounted
## İstatistik tablosu. Değerler kartlardan (ileride eşyalardan) PlayerStats'ta birikir.

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
const DASH_DISTANCE: StringName = &"dash_distance"

## Gösterim sırası da budur. category: kart/mağaza rengini seçer (UiPalette.category).
## Adlar ve biçimler Loc tablosunda (text_content.gd: stat.<id>, stat.<id>.format, stat.<id>.short).
const TABLE: Dictionary = {
	&"max_hp": {"category": &"survival"},
	&"damage": {"category": &"combat"},
	&"fire_rate": {"category": &"combat"},
	&"range": {"category": &"combat"},
	&"move_speed": {"category": &"motion"},
	&"armor": {"category": &"survival"},
	&"luck": {"category": &"loot"},
	&"hp_regen": {"category": &"survival"},
	&"pickup_range": {"category": &"loot"},
	&"dash_cooldown": {"category": &"motion"},
	&"dash_distance": {"category": &"motion"},
}


static func category_of(stat: StringName) -> StringName:
	return TABLE[stat]["category"]


static func describe(stat: StringName, value: float) -> String:
	return _signed(Loc.stat_format(stat), value)


static func short_value(stat: StringName, value: float) -> String:
	return _signed(Loc.stat_short(stat), value)


## Eksi değerde baştaki işaret ters çevrilir ("+%s can" → "-5 can", "-%s%% dash" → "+5% dash").
static func _signed(pattern: String, value: float) -> String:
	if value >= 0.0:
		return pattern % _number(value)
	var flipped: String = ("-" if pattern.begins_with("+") else "+") + pattern.substr(1)
	return flipped % _number(-value)


static func display_name(stat: StringName) -> String:
	return Loc.stat_name(stat)


static func _number(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else "%.1f" % value
