extends CanvasLayer
## Autoload SceneFade: sahne geçişlerinde siyah örtü (Tuning.FEATURE_SCENE_FADE; kapalıyken anında).
## Gerçek zamanla çalışır, oyun duraklıyken de işler. Örtü açıkken girdiyi yutar.

const LAYER: int = 100
const FADE_OUT_TIME: float = 0.22
const FADE_IN_TIME: float = 0.32
## Yeni sahnenin ilk karelerinin çizilmesi için beklenen kare sayısı.
const SETTLE_FRAMES: int = 2

var _rect: ColorRect
var _tween: Tween


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_rect.visible = false
	add_child(_rect)


## Örtü kapanır, action çağrılır (sahne değişimi), örtü açılır. await edilebilir.
func transition(action: Callable) -> void:
	if not Tuning.FEATURE_SCENE_FADE:
		action.call()
		return
	await _fade_to(1.0, FADE_OUT_TIME)
	action.call()
	for i: int in SETTLE_FRAMES:
		await get_tree().process_frame
	await _fade_to(0.0, FADE_IN_TIME)


## Ekran siyahtan açılır (ilk açılış).
func reveal_from_black() -> void:
	if not Tuning.FEATURE_SCENE_FADE:
		return
	_rect.modulate.a = 1.0
	_rect.visible = true
	for i: int in SETTLE_FRAMES:
		await get_tree().process_frame
	await _fade_to(0.0, FADE_IN_TIME)


func _fade_to(alpha: float, time: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_rect.visible = true
	_tween = create_tween().set_ignore_time_scale(true)
	_tween.tween_property(_rect, "modulate:a", alpha, time)
	await _tween.finished
	_rect.visible = alpha > 0.0
