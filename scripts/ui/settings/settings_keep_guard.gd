class_name SettingsKeepGuard
extends Node
## Ekran modu / çözünürlük değişince "koru?" geri sayımını yönetir: eski değerleri saklar, süre dolarsa geri alır.
## SettingsMenu'nün çocuğudur; karar verilince settled sinyali yayılır (menü satırları tazeler).

signal settled

var _keep: KeepDialog = null
var _snapshot: Dictionary = {}


## action: ayarı değiştiren işlev. Ekran ayarı gerçekten değiştiyse geri sayım açılır.
func run(action: Callable) -> void:
	var before: Dictionary = {}
	for key: StringName in SettingsUiRules.KEEP_PROMPT_KEYS:
		before[key] = Settings.get_value(key)
	action.call()
	var changed: bool = false
	for key: StringName in before:
		changed = changed or Settings.get_value(key) != before[key]
	if changed:
		open(before)


func open(before: Dictionary) -> void:
	if _keep != null and is_instance_valid(_keep):
		# Açık geri sayımı yeni değerle yeniden başlat; eski anlık görüntü korunur.
		_keep.queue_free()
	else:
		_snapshot = before
	_keep = KeepDialog.new()
	_keep.decided.connect(_on_decided)
	add_child(_keep)


func _on_decided(keep: bool) -> void:
	_keep = null
	if not keep:
		for key: StringName in _snapshot:
			Settings.set_value(key, _snapshot[key])
	_snapshot = {}
	settled.emit()
