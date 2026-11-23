class_name StatReadout
extends RefCounted
## İstatistik değerlerinin okunur metni ("%0", "100", "0,5/sn", takla beklemesi "1,4 sn"). Saf: biçim (ondalık ayracı, yüzde yeri) style ile gelir.
## display() / strip() ekranların kullandığı, Loc'tan biçimi okuyan ince kabuktur.

const PERCENT_STATS: Array[StringName] = [
	StatData.DAMAGE, StatData.FIRE_RATE, StatData.RANGE, StatData.MOVE_SPEED,
	StatData.PICKUP_RANGE, StatData.DASH_DISTANCE,
]
const DEFAULT_STYLE: Dictionary = {"decimal": ".", "percent_prefix": false, "per_second": "/s", "seconds": "s"}
const STRIP_SEPARATOR: String = "     "


static func is_percent(stat: StringName) -> bool:
	return PERCENT_STATS.has(stat)


## Oyuncunun gerçek değeri: can/zırh temelle birlikte, yenileme saniyelik, yüzdeler artışın kendisi.
static func raw_value(stat: StringName, bonus: float) -> float:
	match stat:
		StatData.MAX_HP:
			return Tuning.PLAYER_MAX_HP + bonus
		StatData.ARMOR:
			return Tuning.PLAYER_ARMOR + bonus
		StatData.HP_REGEN:
			return bonus * Tuning.HP_REGEN_PER_POINT
	return bonus


## En çok bir ondalık, gereksiz ".0" yok.
static func number(value: float, decimal: String) -> String:
	var rounded: float = snappedf(value, 0.1)
	var text: String = str(int(rounded)) if is_equal_approx(rounded, roundf(rounded)) else "%.1f" % rounded
	return text.replace(".", decimal)


## İki ondalığa kadar, gereksiz sıfır yok ("1,4", "1,32"). Takla beklemesi gibi küçük süreler için.
static func number_fine(value: float, decimal: String) -> String:
	var text: String = "%.2f" % snappedf(value, 0.01)
	if text.contains("."):
		text = text.rstrip("0").rstrip(".")
	return text.replace(".", decimal)


static func format(stat: StringName, bonus: float, style: Dictionary = DEFAULT_STYLE) -> String:
	if stat == StatData.DASH_COOLDOWN:
		# Yüzde yerine gerçek süre: "1,4 sn".
		return number_fine(PlayerStats.dash_cooldown_for(bonus), style["decimal"]) + String(style.get("seconds", "s"))
	var value: float = raw_value(stat, bonus)
	var minus: bool = value < 0.0
	var body: String = number(absf(value), style["decimal"])
	var sign_text: String = "-" if minus and not is_zero_approx(snappedf(value, 0.1)) else ""
	if is_percent(stat):
		return sign_text + ("%" + body if style["percent_prefix"] else body + "%")
	if stat == StatData.HP_REGEN:
		return sign_text + body + String(style["per_second"])
	return sign_text + body


static func style() -> Dictionary:
	return {
		"decimal": Loc.t(&"run.fmt.decimal"),
		"percent_prefix": Loc.raw(&"run.fmt.percent_prefix") == "1",
		"per_second": Loc.t(&"run.fmt.per_second"),
		"seconds": Loc.t(&"run.fmt.seconds"),
	}


static func display(stat: StringName, bonus: float) -> String:
	return format(stat, bonus, style())


## Sıfırdan farklı istatistikler tek satırda ("Hasar %12,5     Can 110").
static func strip(stats: PlayerStats) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for stat: StringName in StatData.TABLE:
		var bonus: float = stats.bonus(stat)
		if not is_zero_approx(bonus):
			parts.append("%s %s" % [StatData.display_name(stat), display(stat, bonus)])
	if parts.is_empty():
		return Loc.t(&"run.perk.none")
	return STRIP_SEPARATOR.join(parts)
