class_name Emblems
extends RefCounted
## Amblem dokuları: assets/textures/ui/emblems/<id>.png; yoksa yer tutucu (hata basmaz).

const DIR: String = "res://assets/textures/ui/emblems/"
const PLACEHOLDER: String = "res://assets/textures/ui/emblem_placeholder.png"

static var _cache: Dictionary = {}


static func tex(id: StringName) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var path: String = DIR + String(id) + ".png"
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path) as Texture2D
	if t == null:
		t = load(PLACEHOLDER) as Texture2D
	_cache[id] = t
	return t


static func has(id: StringName) -> bool:
	return ResourceLoader.exists(DIR + String(id) + ".png")
