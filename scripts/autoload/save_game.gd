extends Node
## Kalıcı kayıt (user://save.json): toplamlar, rekorlar, son turlar. Mantık saf RunRecord'da.
## Bozuk ya da daha yeni sürümlü dosya .bak'a alınır, kayıt sıfırdan başlar. Ölçüm argümanları varken
## dosyaya dokunulmaz (bellekte tutulur). Tek sabitle kapanır: Tuning.FEATURE_SAVE (kapalıyken de bellekte çalışır).

signal record_changed

const PATH: String = "user://save.json"
const BACKUP_PATH: String = "user://save.json.bak"
const TEMP_PATH: String = "user://save.json.tmp"

var data: Dictionary = RunRecord.empty()
## Dosyaya yazılıyor mu (ölçüm argümanı varken ya da kayıt kapalıyken false).
var persistent: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	persistent = Tuning.FEATURE_SAVE and not Settings.measurement
	if persistent:
		_load()


func totals() -> Dictionary:
	return data["totals"]


func records() -> Dictionary:
	return data["records"]


## En yeni başta, en çok RunRecord.HISTORY_MAX tur.
func history() -> Array:
	return data["history"]


## Turu kaydeder. Dönüş: kırılan rekor anahtarları (RunRecord.RECORD_KEYS).
func record(summary: Dictionary) -> Array[StringName]:
	var stamped: Dictionary = summary.duplicate()
	stamped["stamp"] = int(Time.get_unix_time_from_system())
	var result: Dictionary = RunRecord.apply_run(data, stamped)
	data = result["save"]
	_write()
	record_changed.emit()
	return result["new_records"]


func reset_all() -> void:
	data = RunRecord.empty()
	_write()
	record_changed.emit()


func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var text: String = FileAccess.get_file_as_string(PATH)
	# JSON.new().parse sessizce hata kodu döner (parse_string bozuk dosyada motor hatası basar).
	var json: JSON = JSON.new()
	var raw: Variant = json.data if json.parse(text) == OK else null
	if not RunRecord.is_readable(raw):
		push_warning("Kayıt okunamadı, yedeğe alındı: %s" % PATH)
		DirAccess.copy_absolute(PATH, BACKUP_PATH)
		DirAccess.remove_absolute(PATH)
		data = RunRecord.empty()
		return
	data = RunRecord.sanitize(raw)


func _write() -> void:
	if not persistent:
		return
	var file: FileAccess = FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Kayıt yazılamadı: %s" % TEMP_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	# Yarım yazılmış dosya asıl kaydı bozmasın diye önce geçici dosyaya yazılır.
	DirAccess.rename_absolute(TEMP_PATH, PATH)
