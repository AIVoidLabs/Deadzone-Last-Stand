class_name Loc
extends RefCounted
## Yerelleştirme: Loc.t(anahtar, [%s argümanları]). Tablolar scripts/data/text/text_*.gd; her satır {"tr", "en"}.
## Dil değişimini Settings yönetir (game/language); ekranlar Settings.changed dinleyip metni yeniden kurar.
## Eksik dil Türkçeye, eksik anahtar anahtarın kendisine düşer.

const _COMMON = preload("res://scripts/data/text/text_common.gd")
const _CONTENT = preload("res://scripts/data/text/text_content.gd")
const _MENU = preload("res://scripts/data/text/text_menu.gd")
const _SETTINGS = preload("res://scripts/data/text/text_settings.gd")
const _RUN = preload("res://scripts/data/text/text_run.gd")
const _HUD = preload("res://scripts/data/text/text_hud.gd")

const LANGS: Array[StringName] = [&"tr", &"en"]
const FALLBACK: StringName = &"tr"

static var language: StringName = &"tr"
static var _merged: Dictionary = {}


static func set_language(lang: StringName) -> void:
	language = lang if LANGS.has(lang) else FALLBACK


## Birleşik tablo (ilk kullanımda kurulur). Aynı anahtar iki dosyada varsa sonraki dosya kazanır.
static func table() -> Dictionary:
	if _merged.is_empty():
		for source: Dictionary in [_COMMON.TABLE, _CONTENT.TABLE, _MENU.TABLE, _SETTINGS.TABLE, _RUN.TABLE, _HUD.TABLE]:
			_merged.merge(source, true)
	return _merged


static func has(key: StringName) -> bool:
	return table().has(key)


## Biçimlenmemiş metin (%s yer tutucuları olduğu gibi); biçim kalıbı gerektiren yerler için.
static func raw(key: StringName) -> String:
	var row: Dictionary = table().get(key, {})
	if row.is_empty():
		return String(key)
	var text: String = row.get(language, "")
	return text if not text.is_empty() else row.get(FALLBACK, String(key))


static func t(key: StringName, args: Array = []) -> String:
	var text: String = raw(key)
	return text % args if "%" in text else text


## Belirli dilde (ekran dilinden bağımsız).
static func t_in(lang: StringName, key: StringName, args: Array = []) -> String:
	var previous: StringName = language
	language = lang
	var text: String = t(key, args)
	language = previous
	return text


static func stat_name(stat: StringName) -> String:
	return t(StringName("stat." + stat))


static func stat_format(stat: StringName) -> String:
	return raw(StringName("stat." + stat + ".format"))


static func stat_short(stat: StringName) -> String:
	return raw(StringName("stat." + stat + ".short"))


static func card_title(stat: StringName) -> String:
	return t(StringName("card." + stat))


static func category_name(category: StringName) -> String:
	return t(StringName("cat." + category))


static func tier_name(tier: int) -> String:
	return t(StringName("tier.%d" % tier))


static func item_name(id: StringName) -> String:
	return t(StringName("item." + id))


static func weapon_name(id: StringName) -> String:
	return t(StringName("weapon." + id))


static func enemy_name(id: StringName) -> String:
	return t(StringName("enemy." + id))


## Saniye -> "m:ss" (dile bağlı değil).
static func clock(seconds: float) -> String:
	var total: int = maxi(0, int(seconds))
	return "%d:%02d" % [total / 60, total % 60]
