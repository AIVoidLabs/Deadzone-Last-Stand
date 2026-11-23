class_name BootLoader
extends CanvasLayer
## Açılış yükleme ekranı: motorun açılış görseliyle aynı yerde kask, altında dönen halka ve "YÜKLENİYOR".
## Sahneyi arka planda yükler (ResourceLoader.load_threaded_request); bitince sahneye geçer ve siyahtan açılır.
## Kapatma: Tuning.FEATURE_BOOT_LOADER (eski yol: doğrudan change_scene_to_file).

const HELMET_TEX: String = "res://assets/textures/ui/boot_helmet.png"
## Arayüz birimi; 1080p'de 384 px = project.godot açılış görselinin gerçek boyutu (geçiş kesintisiz görünsün).
const HELMET_SIZE: float = 256.0
const SPINNER_GAP: float = 36.0
const SPINNER_RADIUS: float = 15.0
const LABEL_GAP: float = 18.0
const LABEL_SIZE: int = 18
const LAYER: int = 50
const WARMUP_FRAMES: int = 2

var _path: String = ""
var _spinner: _Spinner


func _ready() -> void:
	layer = LAYER
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var bg: ColorRect = ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var helmet: TextureRect = TextureRect.new()
	helmet.texture = load(HELMET_TEX) as Texture2D
	helmet.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	helmet.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	helmet.set_anchors_preset(Control.PRESET_CENTER)
	helmet.offset_left = -HELMET_SIZE * 0.5
	helmet.offset_right = HELMET_SIZE * 0.5
	helmet.offset_top = -HELMET_SIZE * 0.5
	helmet.offset_bottom = HELMET_SIZE * 0.5
	root.add_child(helmet)
	_spinner = _Spinner.new()
	_spinner.radius = SPINNER_RADIUS
	_spinner.set_anchors_preset(Control.PRESET_CENTER)
	var spinner_y: float = HELMET_SIZE * 0.5 + SPINNER_GAP + SPINNER_RADIUS
	_spinner.offset_top = spinner_y
	_spinner.offset_bottom = spinner_y
	root.add_child(_spinner)
	var label: Label = Label.new()
	label.text = Loc.t(&"boot.loading")
	label.add_theme_font_override("font", UiFonts.bold())
	label.add_theme_font_size_override("font_size", LABEL_SIZE)
	label.add_theme_color_override("font_color", UiPalette.ASH)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	label.anchor_top = 0.5
	label.anchor_bottom = 0.5
	label.offset_left = -200.0
	label.offset_right = 200.0
	label.offset_top = spinner_y + SPINNER_RADIUS + LABEL_GAP
	label.offset_bottom = label.offset_top + LABEL_SIZE * 2.0
	root.add_child(label)


## Sahneyi arka planda yüklemeye başlar; istek reddedilirse doğrudan geçer.
## Önce halka ekrana çizilsin diye birkaç kare beklenir (script derlemesi ana iş parçacığını kısa süre tutar).
func load_scene(path: String) -> void:
	for i: int in WARMUP_FRAMES:
		await get_tree().process_frame
	_preload_scripts(path)
	_path = path
	if ResourceLoader.load_threaded_request(path) != OK:
		_finish()


## Sahnenin scriptleri ana iş parçacığında derlenir (sınıf bağımlılıkları da gelir); GDScript arka plan
## iş parçacığında derlenirse Godot kapanışta "ObjectDB instances leaked" basıyor. Ağır kısım (model, doku) arka planda kalır.
func _preload_scripts(path: String) -> void:
	for dep: String in ResourceLoader.get_dependencies(path):
		var dep_path: String = dep.get_slice("::", 2) if dep.contains("::") else dep
		if dep_path.ends_with(".gd"):
			load(dep_path)


func _process(_delta: float) -> void:
	if _path.is_empty():
		return
	match ResourceLoader.load_threaded_get_status(_path):
		ResourceLoader.THREAD_LOAD_LOADED, ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_finish()


## Yükleme bitti (ya da başarısız): isteği teslim alır ve sahneye yoldan geçer (yüklüyse önbellekten anında gelir).
func _finish() -> void:
	var path: String = _path
	_path = ""
	set_process(false)
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
		ResourceLoader.load_threaded_get(path)
	get_tree().change_scene_to_file.call_deferred(path)
	SceneFade.reveal_from_black()


## Dönen yay: soluk tam halka + turuncu kısa yay.
class _Spinner:
	extends Control

	const SPEED: float = 5.5
	const ARC: float = 1.9
	const WIDTH: float = 3.5
	const POINTS: int = 32

	var radius: float = 15.0
	var _angle: float = 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_angle = wrapf(_angle + SPEED * delta, 0.0, TAU)
		queue_redraw()

	func _draw() -> void:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, POINTS * 2, Color(UiPalette.ASH, 0.18), WIDTH, true)
		draw_arc(Vector2.ZERO, radius, _angle, _angle + ARC, POINTS, UiPalette.AMBER, WIDTH, true)
