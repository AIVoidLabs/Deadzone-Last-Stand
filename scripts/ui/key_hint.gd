class_name KeyHint
extends RefCounted
## Ekranda gösterilen tuş ipuçları: oyuncunun atadığı tuştan okunur (Ayarlar > Kontroller), sabit harf yazılmaz.


## Yeniden atanabilir eylemin (SettingsSchema.REBINDABLE) şu anki tuşunun kısa adı.
static func of(action: StringName) -> String:
	var code: int = int(Settings.bindings().get(action, SettingsSchema.DEFAULT_BINDINGS.get(action, 0)))
	return SettingsUiRules.key_label(code)
