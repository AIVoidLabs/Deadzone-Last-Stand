class_name WeaponReadout
extends RefCounted
## Silah istatistik metinleri (saf hesap + Loc kabuğu): mağaza birleştirme önizlemesi (önce -> sonra) ve envanter ipucu satırları.
## Sayılar WeaponData satırı + kademe çarpanlarından gelir (MarketCards.weapon_stats); burada yeni değer uydurulmaz.

const STAT_DAMAGE: StringName = &"damage"
const STAT_RATE: StringName = &"rate"
const STAT_RANGE: StringName = &"range"


## Bir silahın bir kademedeki gösterilen sayıları.
static func stats(id: StringName, tier: int) -> Dictionary:
	var row: Dictionary = WeaponData.get_row(id)
	var result: Dictionary = MarketCards.weapon_stats(row, WeaponData.tier_row(tier))
	result["arc"] = roundi(float(row["melee_arc_deg"]))
	result["burn_dps"] = float(row["burn_dps"])
	result["burn_time"] = float(row["burn_time"])
	result["explode"] = float(row["explode_radius"])
	result["pierce"] = int(row["pierce"])
	return result


## Yalnız değişen değerler: [{stat, before, after}] (hasar, atış hızı, menzil sırasıyla).
static func changes(before: Dictionary, after: Dictionary) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	if before["damage"] != after["damage"]:
		list.append({"stat": STAT_DAMAGE, "before": before["damage"], "after": after["damage"]})
	if not is_equal_approx(float(before["rate"]), float(after["rate"])):
		list.append({"stat": STAT_RATE, "before": before["rate"], "after": after["rate"]})
	if before["range"] != after["range"]:
		list.append({"stat": STAT_RANGE, "before": before["range"], "after": after["range"]})
	return list


## Atış hızı artışı, yüzde olarak yuvarlanır (1,12 -> 1,25 = 12).
static func rate_gain_percent(before: float, after: float) -> int:
	if before <= 0.0:
		return 0
	return roundi((after / before - 1.0) * 100.0)


## "%12" (percent_prefix) ya da "12%".
static func percent_text(value: int, prefix: bool) -> String:
	return ("%" + str(value)) if prefix else (str(value) + "%")


## Birleşme önizlemesi: "Hasar 10 -> 15", "Atış hızı +%12". Hiçbir şey değişmiyorsa boş.
static func merge_lines(id: StringName, from_tier: int, to_tier: int) -> Array[String]:
	var pellets: int = int(stats(id, from_tier)["pellets"])
	var lines: Array[String] = []
	for change: Dictionary in changes(stats(id, from_tier), stats(id, to_tier)):
		lines.append(_change_text(change, pellets))
	return lines


static func _change_text(change: Dictionary, pellets: int) -> String:
	match change["stat"]:
		STAT_DAMAGE:
			if pellets > 1:
				return Loc.t(&"run.shop.merge_damage_pellets", [change["before"], change["after"], pellets])
			return Loc.t(&"run.shop.merge_damage", [change["before"], change["after"]])
		STAT_RATE:
			var gain: int = rate_gain_percent(float(change["before"]), float(change["after"]))
			return Loc.t(&"run.shop.merge_rate", [percent_text(gain, Loc.raw(&"run.fmt.percent_prefix") == "1")])
	return Loc.t(&"run.shop.merge_range", [change["before"], change["after"]])


## Envanter ipucu: hasar, atış hızı, menzil + silaha özgü satırlar (yay, yanma, patlama, delme).
static func tooltip_lines(id: StringName, tier: int) -> Array[String]:
	var s: Dictionary = stats(id, tier)
	var decimal: String = String(StatReadout.style()["decimal"])
	var lines: Array[String] = []
	if int(s["pellets"]) > 1:
		lines.append(Loc.t(&"run.shop.damage_pellets", [s["damage"], s["pellets"]]))
	else:
		lines.append(Loc.t(&"run.shop.damage", [s["damage"]]))
	lines.append(Loc.t(&"run.shop.rate", [StatReadout.number(float(s["rate"]), decimal)]))
	lines.append(Loc.t(&"run.shop.range", [s["range"]]))
	if int(s["arc"]) > 0:
		lines.append(Loc.t(&"run.tip.arc", [s["arc"]]))
	if float(s["burn_dps"]) > 0.0:
		lines.append(Loc.t(&"run.tip.burn", [StatReadout.number(float(s["burn_dps"]), decimal), StatReadout.number(float(s["burn_time"]), decimal)]))
	if float(s["explode"]) > 0.0:
		lines.append(Loc.t(&"run.tip.explode", [StatReadout.number(float(s["explode"]), decimal)]))
	if int(s["pierce"]) > 0:
		lines.append(Loc.t(&"run.tip.pierce", [s["pierce"]]))
	return lines
