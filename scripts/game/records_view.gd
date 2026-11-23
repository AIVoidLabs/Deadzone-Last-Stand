class_name RecordsView
extends RefCounted
## Rekor ekranının saf kuralları: süre parçalama, tarih biçimi, satırlar. Sahneye ve autoload'a dokunmaz.

const HOUR: int = 3600
const MINUTE: int = 60


## Saniyeyi {h, m, s} parçalarına böler (negatif 0 sayılır).
static func time_parts(seconds: float) -> Dictionary:
	var total: int = maxi(0, int(seconds))
	@warning_ignore("integer_division")
	return {"h": total / HOUR, "m": (total % HOUR) / MINUTE, "s": total % MINUTE}


## unix zamanı + saat dilimi sapması (dakika) -> "gg.aa ss:dd"; zaman yoksa boş.
static func date_text(unix: int, bias_minutes: int) -> String:
	if unix <= 0:
		return ""
	var d: Dictionary = Time.get_datetime_dict_from_unix_time(unix + bias_minutes * MINUTE)
	return "%02d.%02d %02d:%02d" % [d["day"], d["month"], d["hour"], d["minute"]]


## Kayıtta en az bir tur var mı.
static func has_data(save: Dictionary) -> bool:
	return int(save["totals"]["runs"]) > 0


## Son tur (en yeni başta) ya da boş sözlük.
static func last_run(save: Dictionary) -> Dictionary:
	var history: Array = save["history"]
	return history[0] if not history.is_empty() else {}


## Rekor değeri gösterilebilir mi (0 = henüz yok).
static func has_record(value: Variant) -> bool:
	return float(value) > 0.0


## Tur geçmişi satırları: 1'den başlayan sıra eklenir.
static func rows(history: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i: int in history.size():
		var row: Dictionary = (history[i] as Dictionary).duplicate()
		row["index"] = i + 1
		out.append(row)
	return out
