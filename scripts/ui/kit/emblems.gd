class_name Emblems
extends RefCounted
## Amblem dokuları: assets/textures/ui/emblems/<id>.png; yoksa yer tutucu (hata basmaz).

const DIR: String = "res://assets/textures/ui/emblems/"
const PLACEHOLDER: String = "res://assets/textures/ui/emblem_placeholder.png"

static var _cache: Dictionary = {}
static var _warmed: bool = false


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


## Bilinen tüm amblemleri arka planda yüklemeye başlar (mağaza/kart ilk açılışında takılma olmasın).
## Yalnız bir kez; yüklenenler tex() çağrısında hazır bulunur.
static func warm() -> void:
	if _warmed:
		return
	_warmed = true
	var ids: Array[StringName] = []
	for stat: StringName in StatData.TABLE:
		ids.append(StringName("stat_" + stat))
	for item: StringName in ItemData.ids():
		ids.append(StringName("item_" + item))
	for weapon: StringName in WeaponData.ids():
		ids.append(StringName("weapon_" + weapon))
	for id: StringName in ids:
		var path: String = DIR + String(id) + ".png"
		if ResourceLoader.exists(path):
			ResourceLoader.load_threaded_request(path)


static func has(id: StringName) -> bool:
	return ResourceLoader.exists(DIR + String(id) + ".png")
