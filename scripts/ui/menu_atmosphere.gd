class_name MenuAtmosphere
extends RefCounted
## Ana menünün zemin katmanları: sol/alt kenar gölgesi ve yükselen kül. Yalnız görüntü (MainMenu kurar).

const SHADE_LEFT: float = 0.62
const SHADE_BOTTOM: float = 0.6
const SHADE_COLOR: Color = Color(0.02, 0.015, 0.012)
const ASH_LIFETIME: float = 10.0
const ASH_SPEED: Vector2 = Vector2(18.0, 46.0)
const ASH_PER_LEVEL: int = 36
const ASH_COLORS: Array[Color] = [Color(1.0, 0.62, 0.22, 0.0), Color(1.0, 0.62, 0.22, 0.85), Color(0.7, 0.6, 0.5, 0.0)]


## Sol ve alt kenarı karartır: başlık ve kartlar okunaklı kalır, sağda asker açık.
static func shades() -> Control:
	var holder: Control = Control.new()
	UiAssets.fill(holder)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(_gradient(Vector2(0.0, 0.5), Vector2(1.0, 0.5), SHADE_LEFT, 0.0, 0.62))
	holder.add_child(_gradient(Vector2(0.5, 1.0), Vector2(0.5, 0.0), SHADE_BOTTOM, 0.0, 0.5))
	return holder


static func _gradient(from: Vector2, to: Vector2, alpha_start: float, alpha_end: float, reach: float) -> TextureRect:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, reach])
	gradient.colors = PackedColorArray([Color(SHADE_COLOR, alpha_start), Color(SHADE_COLOR, alpha_end)])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = from
	texture.fill_to = to
	var rect: TextureRect = TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiAssets.fill(rect)
	return rect


## Yükselen kül ve kıvılcım noktaları (kalite profilinin şehir efekti seviyesine göre; düşükte null).
static func ash(host: Control) -> CPUParticles2D:
	var level: int = int(Quality.get_value("city_fx"))
	if level <= 0:
		return null
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.amount = ASH_PER_LEVEL * level
	particles.lifetime = ASH_LIFETIME
	particles.preprocess = ASH_LIFETIME
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.direction = Vector2(0.25, -1.0)
	particles.spread = 25.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = ASH_SPEED.x
	particles.initial_velocity_max = ASH_SPEED.y
	particles.scale_amount_min = 1.5
	particles.scale_amount_max = 3.5
	var ramp: Gradient = Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	ramp.colors = PackedColorArray(ASH_COLORS)
	particles.color_ramp = ramp
	var follow: Callable = func() -> void:
		particles.position = Vector2(host.size.x * 0.5, host.size.y + 10.0)
		particles.emission_rect_extents = Vector2(host.size.x * 0.5, 6.0)
	host.resized.connect(follow)
	host.add_child(particles)
	follow.call()
	return particles
