class_name EndRules
extends RefCounted
## Tur sonu özetinin saf kuralları: en çok öldürülen türler, kart toplamları, rekor işaretleri, sayarak dolma.

## Rekor anahtarı -> özet satırı (RunRecord.RECORD_KEYS).
const RECORD_ROWS: Dictionary = {
	&"best_wave": &"wave", &"most_kills": &"kills", &"fastest_win": &"time", &"best_level": &"level",
}


## kills_by_kind'dan en çok öldürülen limit tür: [{id, count}] (çoktan aza, eşitlikte kimliğe göre).
static func top_kinds(kills_by_kind: Dictionary, limit: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for id: Variant in kills_by_kind:
		var count: int = int(kills_by_kind[id])
		if count > 0:
			rows.append({"id": StringName(id), "count": count})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["count"] != b["count"]:
			return a["count"] > b["count"]
		return String(a["id"]) < String(b["id"]))
	return rows.slice(0, maxi(limit, 0))


## Alınan kartları özelliğe göre toplar: [{stat, count, tier}] (tier = en yüksek). İlk görülme sırası korunur.
static func card_groups(cards: Array) -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	var index: Dictionary = {}
	for card: Variant in cards:
		if not (card is Dictionary):
			continue
		var stat: StringName = StringName(card.get("stat", &""))
		var tier: int = int(card.get("tier", 0))
		if index.has(stat):
			var group: Dictionary = groups[index[stat]]
			group["count"] += 1
			group["tier"] = maxi(group["tier"], tier)
		else:
			index[stat] = groups.size()
			groups.append({"stat": stat, "count": 1, "tier": tier})
	return groups


## Kırılan rekorları özet satırlarına çevirir: {wave: bool, kills: bool, time: bool, level: bool}.
static func record_flags(new_records: Array) -> Dictionary:
	var flags: Dictionary = {}
	for row: Variant in RECORD_ROWS.values():
		flags[row] = false
	for key: Variant in new_records:
		var row: StringName = RECORD_ROWS.get(StringName(key), &"")
		if row != &"":
			flags[row] = true
	return flags


## Sayarak dolma: p (0..1) ilerlemede target'ın gösterilecek değeri (başta hızlı, sonda yavaş).
static func counted(target: int, p: float) -> int:
	var k: float = clampf(p, 0.0, 1.0)
	return roundi(float(target) * (1.0 - pow(1.0 - k, 3.0)))


## Satır i'nin ilerlemesi: genel t saniyede, satır başına stagger gecikme, dur süre.
static func row_progress(t: float, index: int, stagger: float, dur: float) -> float:
	return clampf((t - float(index) * stagger) / maxf(dur, 0.0001), 0.0, 1.0)


## Binlik ayraçlı sayı ("12.345" ya da "12,345").
static func group_digits(value: int, separator: String) -> String:
	var digits: String = str(absi(value))
	var out: String = ""
	for i: int in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			out += separator
		out += digits[i]
	return ("-" if value < 0 else "") + out
