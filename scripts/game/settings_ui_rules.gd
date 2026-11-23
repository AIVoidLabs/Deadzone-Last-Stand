class_name SettingsUiRules
extends RefCounted
## Ayarlar/duraklatma ekranının saf kuralları (sahneden bağımsız, GUT testli).

## Bu ayarlar değişince "bu ayarı koru?" geri sayımı açılır (tam ekran geçişlerinde kilitlenmeye karşı).
const KEEP_PROMPT_KEYS: Array[StringName] = [&"display/mode", &"display/resolution"]
const KEEP_SECONDS: float = 10.0
## Sekme kimlikleri (sıra = sekme sırası).
const TABS: Array[StringName] = [&"display", &"audio", &"game", &"controls"]
## Düğme ile atanamayan sabit tuşlar: [tuş etiketi, açıklama anahtarı].
const FIXED_KEYS: Array = [
	["ESC / P", &"set.fixed.pause"],
	["1 – 4", &"set.fixed.pick"],
	["F11", &"set.fixed.fullscreen"],
	["ENTER", &"set.fixed.accept"],
]


static func needs_keep_prompt(key: StringName) -> bool:
	return KEEP_PROMPT_KEYS.has(key)


## Kalan tam saniye (yukarı yuvarlanır; süre bitince 0).
static func seconds_left(elapsed: float, total: float = KEEP_SECONDS) -> int:
	return maxi(0, ceili(total - elapsed))


static func expired(elapsed: float, total: float = KEEP_SECONDS) -> bool:
	return elapsed >= total


## Çözünürlük yalnız pencere kipinde değişir.
static func resolution_editable(mode: StringName) -> bool:
	return mode == &"windowed"


## Sekme sırasında dir (+1/-1) kadar ilerler, uçlarda başa/sona sarar.
static func step_tab(index: int, dir: int, count: int = TABS.size()) -> int:
	return posmod(index + dir, count)


## Tuş kodunun ekranda görünen adı (ASCII; Türkçe harf dönüşümü gerekmez).
static func key_label(keycode: int) -> String:
	if keycode == KEY_SPACE:
		return "SPACE"
	if keycode <= 0:
		return "?"
	return OS.get_keycode_string(keycode as Key).to_upper()


## Seçenek listesindeki değerin Loc anahtarı: choice değerleri (StringName) için "set.val.<ayar>.<değer>".
static func choice_key(setting: StringName, value: Variant) -> StringName:
	return StringName("set.val.%s.%s" % [String(setting).get_slice("/", 1), str(value)])
