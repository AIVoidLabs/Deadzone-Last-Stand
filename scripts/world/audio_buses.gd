class_name AudioBuses
extends RefCounted
## Ses yolları: Master -> SFX, Ambience, UI, Music. default_bus_layout.tres yok; yollar çalışma anında kurulur
## (düzeyler Tuning'den, tek kod yolu). Birden çok kez çağrılabilir.

const NAMES: Array[StringName] = [&"SFX", &"Ambience", &"UI", &"Music"]


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
	for bus: StringName in NAMES:
		if AudioServer.get_bus_index(bus) >= 0:
			continue
		AudioServer.add_bus()
		var index: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus)
		AudioServer.set_bus_send(index, &"Master")
		AudioServer.set_bus_volume_db(index, volume_of(bus))
