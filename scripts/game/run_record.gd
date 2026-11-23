class_name RunRecord
extends RefCounted
## Kayıt dosyasının saf mantığı: toplamlar, rekorlar, son turlar, sürüm ve bozuk veri onarımı.
## Kayıt: {version, totals:{runs, wins, kills, crystals, play_time}, records:{best_wave, most_kills, fastest_win, best_level}, history:[...]}.

const VERSION: int = 1
const HISTORY_MAX: int = 10
const TOTAL_KEYS: Array[StringName] = [&"runs", &"wins", &"kills", &"crystals", &"play_time"]
## fastest_win 0 = henüz galibiyet yok.
const RECORD_KEYS: Array[StringName] = [&"best_wave", &"most_kills", &"fastest_win", &"best_level"]


static func empty() -> Dictionary:
	var totals: Dictionary = {}
	for key: StringName in TOTAL_KEYS:
		totals[key] = 0
	totals[&"play_time"] = 0.0
	var records: Dictionary = {}
	for key: StringName in RECORD_KEYS:
		records[key] = 0
	records[&"fastest_win"] = 0.0
	return {"version": VERSION, "totals": totals, "records": records, "history": []}


## Okunabilir mi: sözlük ve desteklenen sürüm (daha yeni sürüm okunmaz, yedeğe alınır).
static func is_readable(raw: Variant) -> bool:
	if not (raw is Dictionary):
		return false
	var version: Variant = raw.get("version", null)
	return (version is int or version is float) and int(version) >= 1 and int(version) <= VERSION


## Okunabilir kaydı tam ve tipli hale getirir; eksik/bozuk alan varsayılana döner. Okunamazsa boş kayıt.
static func sanitize(raw: Variant) -> Dictionary:
	var out: Dictionary = empty()
	if not is_readable(raw):
		return out
	var totals: Variant = raw.get("totals", {})
	var records: Variant = raw.get("records", {})
	if totals is Dictionary:
		for key: StringName in TOTAL_KEYS:
			out["totals"][key] = _number(totals.get(String(key), totals.get(key, 0)), key == &"play_time")
	if records is Dictionary:
		for key: StringName in RECORD_KEYS:
			out["records"][key] = _number(records.get(String(key), records.get(key, 0)), key == &"fastest_win")
	var history: Variant = raw.get("history", [])
	if history is Array:
		for entry: Variant in history:
			if entry is Dictionary and out["history"].size() < HISTORY_MAX:
				out["history"].append(_entry(entry))
	return out


static func _number(value: Variant, as_float: bool) -> Variant:
	var n: float = float(value) if (value is int or value is float) else 0.0
	if is_nan(n) or is_inf(n) or n < 0.0:
		n = 0.0
	return (n as Variant) if as_float else int(n)


static func _entry(source: Dictionary) -> Dictionary:
	return {
		"won": bool(source.get("won", false)), "wave": _number(source.get("wave", 0), false),
		"kills": _number(source.get("kills", 0), false), "crystals": _number(source.get("crystals", 0), false),
		"level": _number(source.get("level", 0), false), "time": _number(source.get("time", 0.0), true),
		"stamp": _number(source.get("stamp", 0), false),
	}


## Turu kayda işler. Dönüş: {save: yeni kayıt, new_records: Array[StringName] (kırılan rekor anahtarları)}.
## summary: RunStats.summary() (+ isteğe bağlı "stamp": unix zamanı).
static func apply_run(save: Dictionary, summary: Dictionary) -> Dictionary:
	var out: Dictionary = sanitize(save)
	var entry: Dictionary = _entry(summary)
	var won: bool = entry["won"]
	var totals: Dictionary = out["totals"]
	# İlk turda kıyaslanacak bir şey yok: rekor kaydedilir ama "yeni rekor" sayılmaz.
	var first_run: bool = int(totals[&"runs"]) == 0
	totals[&"runs"] += 1
	totals[&"wins"] += 1 if won else 0
	totals[&"kills"] += entry["kills"]
	totals[&"crystals"] += entry["crystals"]
	totals[&"play_time"] += entry["time"]
	var records: Dictionary = out["records"]
	var broken: Array[StringName] = []
	_raise(records, &"best_wave", entry["wave"], broken)
	_raise(records, &"most_kills", entry["kills"], broken)
	_raise(records, &"best_level", entry["level"], broken)
	var fastest: float = records[&"fastest_win"]
	if won and entry["time"] > 0.0 and (fastest <= 0.0 or entry["time"] < fastest):
		records[&"fastest_win"] = entry["time"]
		broken.append(&"fastest_win")
	var history: Array = out["history"]
	history.push_front(entry)
	while history.size() > HISTORY_MAX:
		history.pop_back()
	var reported: Array[StringName] = []
	if not first_run:
		reported = broken
	return {"save": out, "new_records": reported}


static func _raise(records: Dictionary, key: StringName, value: int, broken: Array[StringName]) -> void:
	if value > int(records[key]):
		records[key] = value
		broken.append(key)
