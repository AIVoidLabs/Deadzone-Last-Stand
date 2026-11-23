extends SceneTree
## Açılış görseli ve uygulama ikonunu menüdeki kask ambleminden üretir (bir kez çalıştırılır, çıktılar repoda).
## godot --headless --path . -s res://tools/godot/make_boot_assets.gd

const SOURCE: String = "res://assets/textures/ui/emblems/menu_play.png"
## 1080p'de yükleme ekranındaki kaskla aynı piksel boyutu (256 arayüz birimi x 1.5).
const SPLASH_SIZE: int = 384
const ICON_SIZE: int = 256


func _initialize() -> void:
	var src: Image = Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	_save_scaled(src, SPLASH_SIZE, "res://assets/textures/ui/boot_helmet.png")
	_save_scaled(src, ICON_SIZE, "res://assets/icon.png")
	print("BOOT_ASSETS ok")
	quit()


func _save_scaled(src: Image, px: int, path: String) -> void:
	var img: Image = src.duplicate() as Image
	img.resize(px, px, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path(path))
