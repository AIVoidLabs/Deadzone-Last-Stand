class_name AudioBuses
extends RefCounted
## Ses yolları: Master -> SFX, Ambience, UI, Music. default_bus_layout.tres yok; yollar çalışma anında kurulur
## (düzeyler Tuning'den, tek kod yolu). Birden çok kez çağrılabilir.
## Kullanıcı ses düzeyi (audio/*, 0..1) tablo dB'sinin ÜSTÜNE eklenir; 1 = değişiklik yok, 0 = sessiz.

const NAMES: Array[StringName] = [&"SFX", &"Ambience", &"UI", &"Music"]
## Yol -> ayar anahtarı (Music için ayar yok).
const SETTING_OF: Dictionary = {&"SFX": &"audio/sfx", &"Ambience": &"audio/ambience", &"UI": &"audio/ui"}
const MASTER: StringName = &"Master"
const SILENT_DB: float = -80.0


## Tablo dB'si + kullanıcı düzeyi (0..1 doğrusal). 1 -> base_db aynen; 0 -> sessiz.
static func level_db(base_db: float, level: float) -> float:
	if level <= 0.0:
		return SILENT_DB
	return base_db + linear_to_db(level)


## Ayar düzeylerini yollara uygular. focus_muted: odak kaybında sessize alma (Master).
static func apply_settings(focus_muted: bool = false) -> void:
	var master: int = AudioServer.get_bus_index(MASTER)
	if master >= 0:
		var level: float = Settings.get_value(&"audio/master")
		AudioServer.set_bus_volume_db(master, level_db(0.0, level))
		AudioServer.set_bus_mute(master, level <= 0.0 or focus_muted)
	for bus: StringName in SETTING_OF:
		var index: int = AudioServer.get_bus_index(bus)
		if index < 0:
			continue
		var user_level: float = Settings.get_value(SETTING_OF[bus])
		AudioServer.set_bus_volume_db(index, level_db(volume_of(bus), user_level))
		AudioServer.set_bus_mute(index, user_level <= 0.0)


static func volume_of(bus: StringName) -> float:
	match bus:
		&"SFX":
			return Tuning.BUS_VOLUME_SFX_DB
		&"Ambience":
			return Tuning.BUS_VOLUME_AMBIENCE_DB
		&"UI":
			return Tuning.BUS_VOLUME_UI_DB
		&"Music":
			return Tuning.BUS_VOLUME_MUSIC_DB
	return 0.0


static func ensure() -> void:
	var created: bool = false
	for bus: StringName in NAMES:
		if AudioServer.get_bus_index(bus) >= 0:
			continue
		created = true
		AudioServer.add_bus()
		var index: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus)
		AudioServer.set_bus_send(index, &"Master")
		AudioServer.set_bus_volume_db(index, volume_of(bus))
	if created:
		apply_settings()
