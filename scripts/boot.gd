extends Node
## Açılış: debug/ölçüm argümanı varsa ya da ana menü kapalıysa doğrudan oyun sahnesi, yoksa ana menü.
## Argüman listeleri SettingsSchema'da (MEASURE_PREFIXES, DIRECT_PREFIXES); yayın yapıda argümanlar yok sayılır.


func _ready() -> void:
	if UiShot.requested():
		add_child(UiShot.new())
		return
	var go_menu: bool = Tuning.FEATURE_MAIN_MENU and not SettingsSchema.skips_menu(OS.get_cmdline_user_args(), OS.is_debug_build())
	if go_menu:
		GameFlow.state = GameFlow.State.MENU
		if Tuning.FEATURE_BOOT_LOADER:
			var loader: BootLoader = BootLoader.new()
			add_child(loader)
			loader.load_scene(GameFlow.MENU_SCENE)
			return
		get_tree().change_scene_to_file.call_deferred(GameFlow.MENU_SCENE)
		SceneFade.reveal_from_black()
	else:
		get_tree().change_scene_to_file.call_deferred(GameFlow.MAIN_SCENE)
