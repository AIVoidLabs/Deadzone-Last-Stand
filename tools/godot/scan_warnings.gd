# Tüm .gd dosyalarını yükler; `godot --headless --path . -d res://tools/godot/scan_warnings.tscn` ile GDScript uyarılarını basar.
extends Node
func _ready() -> void:
	var files: Array[String] = []
	_walk("res://", files)
	for f in files:
		var _s: Resource = load(f)
	print("SCANNED ", files.size())
	get_tree().quit()

func _walk(dir: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for sub in d.get_directories():
		if sub.begins_with(".") or sub == "addons" or sub == "build":
			continue
		_walk(dir.path_join(sub), out)
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
