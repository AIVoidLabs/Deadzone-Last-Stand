class_name Arena
extends Node3D
## Prototip arenası: ızgaralı zemin, kenar duvarları, ışık ve ortam.
## Aşama 6'da şehir sokağı ile değişir.

const GROUND_SHADER: Shader = preload("res://assets/shaders/ground_grid.gdshader")
const WALL_COLOR: Color = Color(0.42, 0.38, 0.33)
const SHADOW_MAX_DISTANCE: float = 60.0
const LIGHTING_ARG: String = "--lighting="

var _sun: DirectionalLight3D
var _preset: Dictionary


func _ready() -> void:
	name = "Arena"
	_preset = LightingData.get_preset(preset_id())
	_build_environment()
	_build_ground()
	_build_walls()
	_apply_quality(Quality.current)
	Quality.profile_changed.connect(_apply_quality)


## Etkin ışık ön ayarı; debug yapıda --lighting=<ad> ile değiştirilebilir (karşılaştırma görüntüleri).
static func preset_id() -> StringName:
	if OS.is_debug_build():
		for arg: String in OS.get_cmdline_user_args():
			if arg.begins_with(LIGHTING_ARG):
				return StringName(arg.trim_prefix(LIGHTING_ARG))
	return Tuning.LIGHTING_PRESET


func _build_environment() -> void:
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = _preset["background"]
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = _preset["ambient_color"]
	env.ambient_light_energy = _preset["ambient_energy"]
	env.tonemap_mode = _preset["tonemap"]
	env.tonemap_exposure = _preset["exposure"]
	env.adjustment_enabled = true
	env.adjustment_saturation = _preset["saturation"]
	env.adjustment_contrast = _preset["contrast"]
	var fog: float = _preset["fog_density"]
	if fog > 0.0:
		env.fog_enabled = true
		env.fog_light_color = _preset["fog_color"]
		env.fog_density = fog
		env.fog_sky_affect = 0.0
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = _preset["sun_rotation_deg"]
	_sun.light_color = _preset["sun_color"]
	_sun.light_energy = _preset["sun_energy"]
	_sun.directional_shadow_max_distance = SHADOW_MAX_DISTANCE
	add_child(_sun)
	if Tuning.FEATURE_CITY_GREYBOX:
		_apply_city_dark(env)
		add_child(CityGreybox.new())
		if Tuning.FEATURE_CITY_ATMOSPHERE:
			add_child(CityAtmosphere.new(env))


## Karanlık şehir önizlemesi: ortam ve güneşi kısar (FEATURE_CITY_GREYBOX kapalıyken çalışmaz).
func _apply_city_dark(env: Environment) -> void:
	env.background_color = Tuning.CITY_BACKGROUND
	env.ambient_light_color = Tuning.CITY_AMBIENT_COLOR
	env.ambient_light_energy = Tuning.CITY_AMBIENT_ENERGY
	_sun.light_color = Tuning.CITY_SUN_COLOR
	_sun.light_energy = Tuning.CITY_SUN_ENERGY


func _build_ground() -> void:
	if Tuning.FEATURE_CITY_GREYBOX:
		return  # zemini CityGreybox kurar (ıslak asfalt)
	var plane: PlaneMesh = PlaneMesh.new()
	var extent: float = Tuning.ARENA_SIZE + Tuning.ARENA_GROUND_MARGIN * 2.0
	plane.size = Vector2(extent, extent)
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = GROUND_SHADER
	mat.set_shader_parameter(&"arena_half", Tuning.ARENA_SIZE * 0.5)
	mat.set_shader_parameter(&"base_color", _preset["ground_base"])
	mat.set_shader_parameter(&"line_color", _preset["ground_line"])
	mat.set_shader_parameter(&"outside_color", _preset["ground_outside"])
	mat.set_shader_parameter(&"stains", _preset["ground_stains"])
	var ground: MeshInstance3D = MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = plane
	ground.material_override = mat
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ground)

func _build_walls() -> void:
	var half: float = Tuning.ARENA_SIZE * 0.5
	var t: float = Tuning.ARENA_WALL_THICKNESS
	var length: float = Tuning.ARENA_SIZE + t * 2.0
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = WALL_COLOR
	mat.roughness = 0.9
	_add_wall(Vector3(0.0, 0.0, -half - t * 0.5), Vector3(length, Tuning.ARENA_WALL_HEIGHT, t), mat)
	_add_wall(Vector3(0.0, 0.0, half + t * 0.5), Vector3(length, Tuning.ARENA_WALL_HEIGHT, t), mat)
	_add_wall(Vector3(-half - t * 0.5, 0.0, 0.0), Vector3(t, Tuning.ARENA_WALL_HEIGHT, length), mat)
	_add_wall(Vector3(half + t * 0.5, 0.0, 0.0), Vector3(t, Tuning.ARENA_WALL_HEIGHT, length), mat)


func _add_wall(at: Vector3, size: Vector3, mat: Material) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.position = at + Vector3(0.0, size.y * 0.5, 0.0)
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = size
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = box_shape
	body.add_child(collision)
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = size
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = box_mesh
	mi.material_override = mat
	body.add_child(mi)
	add_child(body)


func _apply_quality(_profile_id: StringName) -> void:
	_sun.shadow_enabled = Quality.shadows_enabled()
