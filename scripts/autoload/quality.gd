extends Node
## Aktif kalite profili. Platforma özel tek dal burada: varsayılan profil seçimi.

signal profile_changed(profile_id: StringName)

var current: StringName = QualityProfiles.HIGH


func _ready() -> void:
	current = QualityProfiles.default_for(OS.has_feature("web"))


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
