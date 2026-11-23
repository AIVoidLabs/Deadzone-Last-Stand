class_name SettingsRows
extends RefCounted
## Ayar satırı kurucuları: kit satırlarını Settings anahtarına bağlar (değişim anında uygulanır, açıklama odakta görünür).
## Her kurucu satırı listeye ekler ve menüye eşitleme işlevi kaydeder (varsayılana dönünce / geri alınca değer tazelenir).


## Seçimli satır: seçenek metni text_fn(değer) -> String.
static func choice(menu: SettingsMenu, list: Control, key: StringName, text_fn: Callable) -> ChoiceRow:
	var row: ChoiceRow = ChoiceRow.new()
	var values: Array = SettingsSchema.choices_of(key)
	var labels: Array = []
	for v: Variant in values:
		labels.append(text_fn.call(v))
	row.setup(Loc.t(_label_key(key)), labels, values.find(Settings.get_value(key)))
	row.value_changed.connect(func(i: int) -> void:
		UiSounds.play(UiSoundData.CLICK)
		menu.apply_setting(key, values[i]))
	menu.add_sync(func() -> void: row.set_index(values.find(Settings.get_value(key))))
	menu.add_row(list, row, _desc_key(key))
	return row


static func slider(menu: SettingsMenu, list: Control, key: StringName) -> SliderRow:
	var def: Dictionary = SettingsSchema.DEFS[key]
	var row: SliderRow = SliderRow.new()
	row.setup(Loc.t(_label_key(key)), Settings.get_value(key), def["min"], def["max"], def["step"], &"percent")
	row.value_changed.connect(func(v: float) -> void: menu.apply_setting(key, v))
	menu.add_sync(func() -> void: row.set_value(Settings.get_value(key)))
	menu.add_row(list, row, _desc_key(key))
	return row


static func toggle(menu: SettingsMenu, list: Control, key: StringName) -> ToggleRow:
	var row: ToggleRow = ToggleRow.new()
	row.setup(Loc.t(_label_key(key)), Settings.get_value(key), Loc.t(&"common.on"), Loc.t(&"common.off"))
	row.value_changed.connect(func(v: bool) -> void:
		UiSounds.play(UiSoundData.CLICK)
		menu.apply_setting(key, v))
	menu.add_sync(func() -> void: row.set_value(Settings.get_value(key)))
	menu.add_row(list, row, _desc_key(key))
	return row


## Anahtar -> satır etiketi / açıklaması. Ayar adından türer; ayrı eşleme gerekenler ALIASES'ta.
const ALIASES: Dictionary = {
	&"audio/mute_on_focus_loss": &"mute_focus",
	&"game/pause_on_focus_loss": &"pause_focus",
}


static func _id(key: StringName) -> String:
	return String(ALIASES.get(key, String(key).get_slice("/", 1)))


static func _label_key(key: StringName) -> StringName:
	return StringName("set." + _id(key))


static func _desc_key(key: StringName) -> StringName:
	return StringName("set." + _id(key) + ".desc")
