class_name SettingsSchema
extends RefCounted
## Ayarların saf şeması: anahtarlar, varsayılanlar, sınırlar, doğrulama. Sahneden ve autoload'dan bağımsız (GUT testli).
## Anahtar biçimi "bölüm/ad". Seçimli ayarlar (choice) StringName, sayılar float/int, anahtar atamaları Dictionary döner.

const SECTIONS: Array[StringName] = [&"display", &"graphics", &"game", &"audio", &"input"]

const RESOLUTIONS: Array = ["1280x720", "1366x768", "1600x900", "1920x1080", "2560x1440"]
const FPS_CAPS: Array = [0, 30, 60, 120, 144, 240]
const LANGUAGES: Array = [&"tr", &"en"]

## Yeniden atanabilir eylemler (InputMap'teki ilk klavye tuşu değişir; ok tuşları ikinci tuş olarak kalır).
const REBINDABLE: Array[StringName] = [&"move_up", &"move_down", &"move_left", &"move_right", &"dash", &"restart"]
const DEFAULT_BINDINGS: Dictionary = {
	&"move_up": KEY_W, &"move_down": KEY_S, &"move_left": KEY_A, &"move_right": KEY_D,
	&"dash": KEY_SPACE, &"restart": KEY_R,
}
## Atanamayan tuşlar: duraklatma, debug tuşları, tam ekran.
const FORBIDDEN_KEYS: Array[int] = [
	KEY_ESCAPE, KEY_P, KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11, KEY_F12,
	KEY_ENTER, KEY_KP_ENTER, KEY_TAB,
]

## kind: choice | bool | float | bindings. float: min, max, step. choice: choices.
const DEFS: Dictionary = {
	&"display/mode": {"kind": &"choice", "default": &"fullscreen", "choices": [&"fullscreen", &"borderless", &"windowed"]},
	&"display/resolution": {"kind": &"choice", "default": "1600x900", "choices": RESOLUTIONS},
	&"display/vsync": {"kind": &"bool", "default": true},
	&"display/fps_cap": {"kind": &"choice", "default": 0, "choices": FPS_CAPS},
	&"display/render_scale": {"kind": &"float", "default": 1.0, "min": 0.5, "max": 1.0, "step": 0.05},
	&"display/brightness": {"kind": &"float", "default": 1.0, "min": 0.7, "max": 1.5, "step": 0.05},
	&"display/show_fps": {"kind": &"bool", "default": false},
	&"graphics/quality": {"kind": &"choice", "default": &"high", "choices": [&"low", &"medium", &"high"]},
	&"game/language": {"kind": &"choice", "default": &"tr", "choices": LANGUAGES},
	&"game/dynamic_camera": {"kind": &"bool", "default": true},
	&"game/screen_shake": {"kind": &"float", "default": 1.0, "min": 0.0, "max": 1.0, "step": 0.05},
	&"game/blood": {"kind": &"bool", "default": true},
	&"game/hurt_flash": {"kind": &"float", "default": 1.0, "min": 0.0, "max": 1.0, "step": 0.05},
	&"game/hud_scale": {"kind": &"float", "default": 1.0, "min": 0.8, "max": 1.3, "step": 0.05},
	&"game/pause_on_focus_loss": {"kind": &"bool", "default": true},
	&"audio/master": {"kind": &"float", "default": 1.0, "min": 0.0, "max": 1.0, "step": 0.05},
	&"audio/sfx": {"kind": &"float", "default": 1.0, "min": 0.0, "max": 1.0, "step": 0.05},
	&"audio/ambience": {"kind": &"float", "default": 1.0, "min": 0.0, "max": 1.0, "step": 0.05},
	&"audio/ui": {"kind": &"float", "default": 1.0, "min": 0.0, "max": 1.0, "step": 0.05},
	&"audio/mute_on_focus_loss": {"kind": &"bool", "default": false},
	&"input/bindings": {"kind": &"bindings", "default": DEFAULT_BINDINGS},
}

## Debug/ölçüm argümanları: kullanıcı ayarları okunmaz ve yazılmaz (ölçümler tekrarlanabilir).
const MEASURE_PREFIXES: Array[String] = ["--capture", "--bench", "--autoplay", "--arena", "--ui-shot"]
## Doğrudan oyuna giren (ana menüyü atlayan) debug argümanları: ölçümler + elle oynama bayrakları.
const DIRECT_PREFIXES: Array[String] = [
	"--wave", "--god", "--autopilot", "--weapons", "--levels", "--debug-panel", "--quality", "--lighting", "--camera-distance",
]


static func keys() -> Array[StringName]:
	var list: Array[StringName] = []
	for key: StringName in DEFS:
		list.append(key)
	return list


static func has_key(key: StringName) -> bool:
	return DEFS.has(key)


static func section_of(key: StringName) -> StringName:
	return StringName(String(key).get_slice("/", 0))


static func name_of(key: StringName) -> String:
	return String(key).get_slice("/", 1)


static func keys_in(section: StringName) -> Array[StringName]:
	var list: Array[StringName] = []
	for key: StringName in DEFS:
		if section_of(key) == section:
			list.append(key)
	return list


static func kind_of(key: StringName) -> StringName:
	return DEFS[key]["kind"]


static func choices_of(key: StringName) -> Array:
	return DEFS[key].get("choices", [])


## Tüm anahtarların varsayılanı. Platform ve özellik sabitleri parametreyle gelir.
static func defaults(start_fullscreen: bool = true, is_web: bool = false) -> Dictionary:
	var values: Dictionary = {}
	for key: StringName in DEFS:
		var value: Variant = DEFS[key]["default"]
		values[key] = value.duplicate() if value is Dictionary else value
	if not start_fullscreen:
		values[&"display/mode"] = &"windowed"
	if is_web:
		values[&"graphics/quality"] = &"low"
	return values


## Ham değeri şemaya uydurur: bilinmeyen/bozuk değer fallback'e (yoksa varsayılana) döner, sayılar sınırlanır.
static func sanitize(key: StringName, value: Variant, fallback: Variant = null) -> Variant:
	if not DEFS.has(key):
		return null
	var def: Dictionary = DEFS[key]
	var safe: Variant = fallback if fallback != null else def["default"]
	match def["kind"]:
		&"choice":
			for choice: Variant in def["choices"]:
				if str(choice) == str(value):
					return choice
			return safe
		&"bool":
			if value is bool:
				return value
			if value is int and (value == 0 or value == 1):
				return value == 1
			return safe
		&"float":
			if not (value is float or value is int) or is_nan(float(value)):
				return safe
			var number: float = clampf(float(value), def["min"], def["max"])
			var step: float = def.get("step", 0.0)
			# Üç ondalığa yuvarlama: 0.7000000000000001 gibi kayan nokta artığı kalmasın.
			var snapped_value: float = roundf(clampf(snappedf(number, step), def["min"], def["max"]) * 1000.0) / 1000.0 if step > 0.0 else number
			return snapped_value
		&"bindings":
			return _sanitize_bindings(value)
	return safe


## Bozuk/eksik tuş atamaları varsayılana döner; iki eylem aynı tuşu paylaşıyorsa hepsi varsayılana döner.
static func _sanitize_bindings(value: Variant) -> Dictionary:
	var out: Dictionary = DEFAULT_BINDINGS.duplicate()
	if not (value is Dictionary):
		return out
	var raw: Dictionary = value
	for action: StringName in REBINDABLE:
		var code: Variant = raw.get(action, raw.get(String(action), null))
		if (code is int or code is float) and is_bindable(int(code)):
			out[action] = int(code)
	var seen: Dictionary = {}
	for action: StringName in REBINDABLE:
		if seen.has(out[action]):
			return DEFAULT_BINDINGS.duplicate()
		seen[out[action]] = true
	return out


static func is_bindable(keycode: int) -> bool:
	return keycode > 0 and not FORBIDDEN_KEYS.has(keycode)


## Ham sözlükten (anahtar -> değer; eksikler olabilir) tam, geçerli bir ayar sözlüğü kurar.
static func resolve(raw: Dictionary, base: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: StringName in DEFS:
		out[key] = sanitize(key, raw.get(key, null), base.get(key, null)) if raw.has(key) else base.get(key, DEFS[key]["default"])
	return out


## Tuş atar. Aynı tuş başka eylemdeyse iki eylem tuşlarını takas eder.
## Dönüş: {ok, bindings, swapped (takas edilen eylem ya da &"")}.
static func rebind(bindings: Dictionary, action: StringName, keycode: int) -> Dictionary:
	var result: Dictionary = {"ok": false, "bindings": bindings.duplicate(), "swapped": &""}
	if not REBINDABLE.has(action) or not is_bindable(keycode):
		return result
	var out: Dictionary = bindings.duplicate()
	for other: StringName in REBINDABLE:
		if other != action and out.get(other, 0) == keycode:
			out[other] = out.get(action, DEFAULT_BINDINGS[action])
			result["swapped"] = other
	out[action] = keycode
	result["ok"] = true
	result["bindings"] = out
	return result


static func parse_resolution(text: String) -> Vector2i:
	var parts: PackedStringArray = text.split("x")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return Vector2i(1600, 900)
	return Vector2i(int(parts[0]), int(parts[1]))


## İşletim sistemi dili Türkçe ise tr, değilse en (ilk açılış).
static func language_for_locale(locale: String) -> StringName:
	return &"tr" if locale.to_lower().begins_with("tr") else &"en"


static func _has_prefix(args: PackedStringArray, prefixes: Array[String]) -> bool:
	for arg: String in args:
		for prefix: String in prefixes:
			if arg == prefix or arg.begins_with(prefix + "="):
				return true
	return false


## Kullanıcı ayarları okunmaz/yazılmaz: debug yapıda ölçüm argümanı varsa ya da GUT çalışıyorsa.
## user_args: -- sonrası argümanlar; all_args: tüm komut satırı.
static func skips_user_settings(user_args: PackedStringArray, all_args: PackedStringArray, is_debug: bool) -> bool:
	if not is_debug:
		return false
	for arg: String in all_args:
		if arg.ends_with("gut_cmdln.gd"):
			return true
	return _has_prefix(user_args, MEASURE_PREFIXES)


## Ana menü atlanır: ölçüm argümanları ve elle oynama bayrakları (yalnız debug yapıda).
static func skips_menu(user_args: PackedStringArray, is_debug: bool) -> bool:
	if not is_debug:
		return false
	return _has_prefix(user_args, MEASURE_PREFIXES) or _has_prefix(user_args, DIRECT_PREFIXES)
