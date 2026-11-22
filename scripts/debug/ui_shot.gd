class_name UiShot
extends Node
## Arayüz görüntü aracı (yalnız debug): bir ekranı kurar, bekler, PNG kaydeder ve çıkar.
## godot --path . -- --ui-shot=build/shots/x.png --ui-screen=<ad> [--ui-tab=N] [--ui-seconds=1.5] [--ui-lang=en]
##   [--ui-size=1920x1080] [--ui-focus=N]
## Ekran kaydı: SCREENS tablosuna kimlik -> betik yolu eklenir; betik şu statik işlevi sunar:
##   static func ui_shot(host: Node, opts: Dictionary) -> void   (host: tam ekran Control; opts: tab, focus, lang, seconds, size)
## Çalışma anında da UiShot.register(id, callable(host, opts)) ile eklenebilir.

const SCREENS: Dictionary = {
	&"main": "res://scripts/ui/main_menu.gd",
	&"settings": "res://scripts/ui/settings_menu.gd",
	&"pause": "res://scripts/ui/pause_menu.gd",
	&"records": "res://scripts/ui/records_screen.gd",
	&"credits": "res://scripts/ui/credits_screen.gd",
	&"perk": "res://scripts/ui/perk_screen.gd",
	&"shop": "res://scripts/ui/market_screen.gd",
	&"end_win": "res://scripts/ui/end_screen.gd",
	&"end_lose": "res://scripts/ui/end_screen.gd",
	&"hud": "res://scripts/ui/battle_hud.gd",
}
const DEFAULT_SECONDS: float = 1.5
const SETTLE_FRAMES: int = 3

static var _registered: Dictionary = {}


## Çalışma anı kaydı (SCREENS tablosuna ek). handler: Callable(host: Node, opts: Dictionary).
static func register(id: StringName, handler: Callable) -> void:
	_registered[id] = handler


static func requested() -> bool:
	return OS.is_debug_build() and not arg("--ui-shot=", "").is_empty()


static func arg(prefix: String, default: String) -> String:
	for item: String in OS.get_cmdline_user_args():
		if item.begins_with(prefix):
			return item.trim_prefix(prefix)
	return default


func _ready() -> void:
	name = "UiShot"
	_run.call_deferred()


func _run() -> void:
	var lang: String = arg("--ui-lang=", "tr")
	Settings.set_value(&"game/language", StringName(lang))
	_apply_size(arg("--ui-size=", ""))
	var host: Control = Control.new()
	host.name = "ShotHost"
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(host)
	var opts: Dictionary = {
		"tab": int(arg("--ui-tab=", "0")), "focus": int(arg("--ui-focus=", "-1")), "lang": lang,
		"seconds": float(arg("--ui-seconds=", str(DEFAULT_SECONDS))), "size": arg("--ui-size=", ""),
		"screen": arg("--ui-screen=", "main"),
	}
	_build(StringName(opts["screen"]), host, opts)
	await get_tree().create_timer(maxf(opts["seconds"], 0.0), true, false, true).timeout
	for i: int in SETTLE_FRAMES:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_save(arg("--ui-shot=", "build/shots/ui.png"))
	get_tree().quit()


func _apply_size(text: String) -> void:
	if text.is_empty() or DisplayServer.get_name() == "headless":
		return
	var size: Vector2i = SettingsSchema.parse_resolution(text)
	Settings.set_value(&"display/mode", &"windowed")
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(size)


func _build(id: StringName, host: Control, opts: Dictionary) -> void:
	if _registered.has(id):
		_registered[id].call(host, opts)
		return
	var path: String = SCREENS.get(id, "")
	var script: GDScript = load(path) as GDScript if not path.is_empty() and ResourceLoader.exists(path) else null
	if script == null or not script.has_method(&"ui_shot"):
		_placeholder(host, "UiShot: ekran kayıtlı değil: %s" % id)
		return
	script.call(&"ui_shot", host, opts)


func _placeholder(host: Control, text: String) -> void:
	push_warning(text)
	var label: Label = Label.new()
	label.text = text
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	host.add_child(label)


func _save(path: String) -> void:
	var absolute: String = ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var image: Image = get_viewport().get_texture().get_image()
	var error: int = image.save_png(absolute)
	print("UISHOT %s %dx%d %s" % [path, image.get_width(), image.get_height(), "ok" if error == OK else "hata %d" % error])
