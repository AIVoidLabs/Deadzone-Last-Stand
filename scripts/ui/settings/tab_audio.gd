class_name SettingsTabAudio
extends RefCounted
## SES sekmesi: ana, efekt, ortam, arayüz düzeyi; odak kaybında susturma. Müzik yok.


static func keys() -> Array[StringName]:
	return [&"audio"]


static func build(menu: SettingsMenu, list: VBoxContainer) -> void:
	for key: StringName in [&"audio/master", &"audio/sfx", &"audio/ambience", &"audio/ui"]:
		SettingsRows.slider(menu, list, key)
	SettingsRows.toggle(menu, list, &"audio/mute_on_focus_loss")
