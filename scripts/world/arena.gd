class_name Arena
extends Node3D
## Prototip arenası: ızgaralı zemin, kenar duvarları, ışık ve ortam.
## Aşama 6'da şehir sokağı ile değişir.

const GROUND_SHADER: Shader = preload("res://assets/shaders/ground_grid.gdshader")
const WALL_COLOR: Color = Color(0.42, 0.38, 0.33)
const BACKGROUND_COLOR: Color = Color(0.09, 0.1, 0.12)
const AMBIENT_COLOR: Color = Color(0.55, 0.6, 0.7)
const AMBIENT_ENERGY: float = 0.6
const SUN_ROTATION_DEG: Vector3 = Vector3(-55.0, -35.0, 0.0)
const SUN_ENERGY: float = 1.2
const SHADOW_MAX_DISTANCE: float = 60.0

var _sun: DirectionalLight3D


func _ready() -> void:
	name = "Arena"
	_build_environment()
	_build_ground()
	_build_walls()
	_apply_quality(Quality.current)
	Quality.profile_changed.connect(_apply_quality)


func _build_environment() -> void:
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BACKGROUND_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = AMBIENT_COLOR
	env.ambient_light_energy = AMBIENT_ENERGY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = SUN_ROTATION_DEG
	_sun.light_energy = SUN_ENERGY
	_sun.directional_shadow_max_distance = SHADOW_MAX_DISTANCE
	add_child(_sun)


func _build_ground() -> void:
	var plane: PlaneMesh = PlaneMesh.new()
	var extent: float = Tuning.ARENA_SIZE + Tuning.ARENA_GROUND_MARGIN * 2.0
	plane.size = Vector2(extent, extent)
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = GROUND_SHADER
	mat.set_shader_parameter(&"arena_half", Tuning.ARENA_SIZE * 0.5)
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
