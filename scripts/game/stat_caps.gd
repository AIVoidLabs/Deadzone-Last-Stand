class_name StatCaps
extends RefCounted
## Üst sınırı olan istatistikler (saf): tavan tablosu, etkin değer, "tavanda mı", işe yarar artış.
## Bonus birimi PlayerStats.bonus ile aynıdır (yüzde puanı). Tavanı olmayan stat sınırsızdır.
## Oyuncuyu yanıltmama (FEATURE_STAT_CAP_HONESTY) kuralları bu tabloyu kullanır; hesap (PlayerStats) bayrağa bağlı değildir.

## stat -> en çok etkili bonus. Yeni tavan = yeni satır.
const CAPS: Dictionary = {
	&"move_speed": Tuning.MOVE_SPEED_BONUS_CAP,
	&"dash_cooldown": Tuning.DASH_COOLDOWN_CUT_CAP,
}


static func has_cap(stat: StringName) -> bool:
	return CAPS.has(stat)


## Tavana kırpılmış bonus (üstten). Tavansız statta aynen.
static func effective_bonus(stat: StringName, bonus: float) -> float:
	return minf(bonus, float(CAPS[stat])) if CAPS.has(stat) else bonus


## Bonus tavana ulaştı ya da aştı.
static func is_capped(stat: StringName, bonus: float) -> bool:
	return CAPS.has(stat) and bonus >= float(CAPS[stat])


## gain eklenince etkin bonusun gerçek değişimi (tavanda 0).
static func useful_gain(stat: StringName, bonus: float, gain: float) -> float:
	return effective_bonus(stat, bonus + gain) - effective_bonus(stat, bonus)


## effects ([{stat, value}]) içinde olumlu olup tavana dayanmış statlar.
static func capped_stats(effects: Array, bonus_of: Callable) -> Array[StringName]:
	var result: Array[StringName] = []
	for effect: Dictionary in effects:
		var stat: StringName = effect["stat"]
		if float(effect["value"]) > 0.0 and is_zero_approx(useful_gain(stat, float(bonus_of.call(stat)), float(effect["value"]))):
			result.append(stat)
	return result


## Olumlu etkisi var ve hepsi tavanda: teklif etmek oyuncuyu yanıltır.
static func is_wasted(effects: Array, bonus_of: Callable) -> bool:
	var positive: int = 0
	for effect: Dictionary in effects:
		if float(effect["value"]) > 0.0:
			positive += 1
	return positive > 0 and capped_stats(effects, bonus_of).size() == positive


## Havuzdan boşa giden öğeleri çıkarır; en az min_count kalmıyorsa elenenlerden (sırayla) tamamlar (kilitlenme olmasın).
## entries: öğe dizisi; effects_of(öğe) -> effects. Sıra korunur.
static func filter_wasted(entries: Array, effects_of: Callable, bonus_of: Callable, min_count: int) -> Array:
	var kept: Array = []
	var dropped: Array = []
	for entry: Variant in entries:
		if is_wasted(effects_of.call(entry), bonus_of):
			dropped.append(entry)
		else:
			kept.append(entry)
	var i: int = 0
	while kept.size() < min_count and i < dropped.size():
		kept.append(dropped[i])
		i += 1
	return kept
