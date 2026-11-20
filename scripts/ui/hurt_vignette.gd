class_name HurtVignette
extends CanvasLayer
## Asker vurulunca ekran kenarı kızarır ve söner; can azken kenar hafifçe nabız gibi atar.
## Yalnız görüntü; askerin event sinyalini dinler.

const SHADER: Shader = preload("res://assets/shaders/hurt_vignette.gdshader")
## HUD (katman 1) kızarmanın üstünde kalsın.
const LAYER: int = 0

var _player: Player
var _rect: ColorRect
var _material: ShaderMaterial
var _flash: float = 0.0
var _time: float = 0.0


func setup(player: Player) -> void:
	_player = player


func _ready() -> void:
	name = "HurtVignette"
	layer = LAYER
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_rect = ColorRect.new()
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _material
	add_child(_rect)
	_player.event.connect(_on_player_event)
	_apply(0.0)


func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(0.0, _flash - delta / Tuning.HURT_VIGNETTE_FADE_TIME)
	var low: float = 0.0
	var ratio: float = _player.health.ratio()
	if ratio < Tuning.LOW_HP_THRESHOLD and _player.state != Player.State.DEAD:
		var pulse: float = 0.5 + 0.5 * sin(_time * TAU * Tuning.LOW_HP_PULSE_RATE)
		low = Tuning.LOW_HP_VIGNETTE * (1.0 - ratio / Tuning.LOW_HP_THRESHOLD) * (0.6 + 0.4 * pulse)
	_apply(maxf(_flash * Tuning.HURT_VIGNETTE_STRENGTH, low))


func _on_player_event(event_name: StringName, _data: Dictionary) -> void:
	if event_name == &"hit":
		_flash = 1.0
	elif event_name == &"dot":
		_flash = maxf(_flash, Tuning.ACID_VIGNETTE_FLASH)


func _apply(strength: float) -> void:
	_material.set_shader_parameter(&"strength", strength)
	_rect.visible = strength > 0.001
