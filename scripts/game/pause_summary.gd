class_name PauseSummary
extends RefCounted
## Duraklatma menüsündeki tur özetinin saf verisi (sahneden bağımsız, GUT testli).


## Alınan istatistik artışları: StatData sırasıyla, sıfır olmayanlar. bonus_of(stat) -> float.
## Satır: {stat, value, category}.
static func gains(bonus_of: Callable) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for stat: StringName in StatData.TABLE:
		var value: float = bonus_of.call(stat)
		if not is_zero_approx(value):
			var capped: bool = Tuning.FEATURE_STAT_CAP_HONESTY and StatCaps.is_capped(stat, value)
			if Tuning.FEATURE_STAT_CAP_HONESTY:
				value = StatCaps.effective_bonus(stat, value)
			rows.append({"stat": stat, "value": value, "category": StatData.category_of(stat), "capped": capped})
	return rows


## Silah satırı: {id, tier (1 tabanlı), tier_index (UiPalette.tier_color için, 0 tabanlı)}.
static func weapon_rows(slots: Array) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for slot: Dictionary in slots:
		var tier: int = clampi(int(slot.get("tier", 1)), 1, WeaponData.max_tier())
		rows.append({"id": slot["id"], "tier": tier, "tier_index": tier - 1})
	return rows


## Beş sayaç: [{key (Loc), icon (amblem), value (metin)}] sırası dalga, süre, öldürme, seviye, kristal.
static func counters(wave: int, time: float, kills: int, level: int, crystals: int) -> Array[Dictionary]:
	return [
		{"key": &"pause.stat.wave", "icon": &"icon_wave", "value": str(wave)},
		{"key": &"pause.stat.time", "icon": &"icon_time", "value": Loc.clock(time)},
		{"key": &"pause.stat.kills", "icon": &"icon_kill", "value": str(kills)},
		{"key": &"pause.stat.level", "icon": &"icon_level", "value": str(level)},
		{"key": &"pause.stat.crystals", "icon": &"icon_crystal", "value": str(crystals)},
	]
