extends Node
## Aktif kalite profili. Varsayılanı Settings seçer (platform dalı SettingsSchema.defaults'ta: web -> low);
## ayar değişince profil canlı değişir, profile_changed dinleyenler (efekt, ışık, gölge) kendini günceller.

signal profile_changed(profile_id: StringName)

var current: StringName = QualityProfiles.HIGH


func _ready() -> void:
	current = Settings.get_value(&"graphics/quality")
	Settings.changed.connect(_on_setting_changed)
	if OS.is_debug_build():
		for arg: String in OS.get_cmdline_user_args():
			if arg.begins_with("--quality="):
				var wanted: StringName = StringName(arg.trim_prefix("--quality="))
				if QualityProfiles.TABLE.has(wanted):
					current = wanted


func _on_setting_changed(key: StringName, value: Variant) -> void:
	if key == &"graphics/quality":
		set_profile(value)


func get_value(key: String) -> Variant:
	return QualityProfiles.get_profile(current)[key]


func max_enemies() -> int:
	return get_value("max_enemies")


func shadows_enabled() -> bool:
	return get_value("shadows")


func set_profile(profile_id: StringName) -> void:
	if profile_id == current:
		return
	current = profile_id
	apply_to_viewport(get_viewport())
	profile_changed.emit(current)


func cycle() -> void:
	set_profile(QualityProfiles.next_after(current))


func apply_to_viewport(viewport: Viewport) -> void:
	var msaa: int = get_value("msaa")
	viewport.msaa_3d = msaa as Viewport.MSAA
