class_name UiSounds
extends RefCounted
## Arayüz sesleri için tek giriş: FEATURE_SFX_UI kapalıysa hiçbir şey çalmaz. Satırlar UiSoundData'da.


static func play(id: StringName) -> void:
	if Tuning.FEATURE_SFX and Tuning.FEATURE_SFX_UI:
		Audio.play(id)


## Düğmeye üzerine gelme sesi (devre dışıysa çalmaz); click true ise basma sesi de ekler.
static func hook(button: BaseButton, click: bool = false) -> void:
	button.mouse_entered.connect(_on_hover.bind(button))
	if click:
		button.pressed.connect(play.bind(UiSoundData.CLICK))


static func _on_hover(button: BaseButton) -> void:
	if not button.disabled:
		play(UiSoundData.HOVER)