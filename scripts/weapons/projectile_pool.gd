class_name ProjectilePool
extends Node3D
## Mermiler: sabit havuz, elle hareket, kare başına doğru parçası çarpışması
## (hızlı mermi zombinin içinden geçip gitmez).

signal impact(at: Vector3, direction: Vector2)

const PHYSICS_PRIORITY: int = 10
const TRACER_SHADER: Shader = preload("res://assets/shaders/tracer.gdshader")
const COLOR: Color = Color(1.0, 0.85, 0.4)
const EMISSION_ENERGY: float = 3.0

var enemies: EnemyManager

var _nodes: Array[MeshInstance3D] = []
var _pos: PackedVector2Array = PackedVector2Array()
var _dir: PackedVector2Array = PackedVector2Array()
var _speed: PackedFloat32Array = PackedFloat32Array()
var _damage: PackedFloat32Array = PackedFloat32Array()
var _knockback: PackedFloat32Array = PackedFloat32Array()
var _life: PackedFloat32Array = PackedFloat32Array()
var _active: PackedByteArray = PackedByteArray()
var _active_count: int = 0
var _mesh: BoxMesh
var _material: Material


func _ready() -> void:
	name = "Projectiles"
	process_physics_priority = PHYSICS_PRIORITY
	_mesh = BoxMesh.new()
	if Tuning.FEATURE_TRACERS:
		_mesh.size = Vector3(Tuning.TRACER_THICKNESS, Tuning.TRACER_THICKNESS, Tuning.TRACER_LENGTH)
		var tracer: ShaderMaterial = ShaderMaterial.new()
		tracer.shader = TRACER_SHADER
		tracer.set_shader_parameter(&"tracer_length", Tuning.TRACER_LENGTH)
		_material = tracer
	else:
		_mesh.size = Vector3(Tuning.PROJECTILE_THICKNESS, Tuning.PROJECTILE_THICKNESS, Tuning.PROJECTILE_LENGTH)
		var box: StandardMaterial3D = StandardMaterial3D.new()
		box.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		box.albedo_color = COLOR
		box.emission_enabled = true
		box.emission = COLOR
		box.emission_energy_multiplier = EMISSION_ENERGY
		_material = box
	_grow(Tuning.PROJECTILE_POOL_SIZE)


func active_count() -> int:
	return _active_count


func fire(origin: Vector2, direction: Vector2, speed: float, dmg: float, max_range: float, knockback: float = 0.0) -> void:
	var slot: int = _active.find(0)
	if slot < 0:
		slot = _nodes.size()
		_grow(1)
	_pos[slot] = origin
	_dir[slot] = direction
	_speed[slot] = speed
	_damage[slot] = dmg
	_knockback[slot] = knockback
	_life[slot] = max_range / speed * Tuning.PROJECTILE_LIFETIME_MARGIN
	_active[slot] = 1
	_active_count += 1
	var node: MeshInstance3D = _nodes[slot]
	node.position = Vector3(origin.x, Tuning.PROJECTILE_HEIGHT, origin.y)
	node.rotation.y = atan2(direction.x, direction.y)
	node.visible = true
	node.reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	for i in _nodes.size():
		if _active[i] == 0:
			continue
		var a: Vector2 = _pos[i]
		var b: Vector2 = a + _dir[i] * _speed[i] * delta
		var hit: int = enemies.find_segment_hit(a, b, Tuning.PROJECTILE_RADIUS)
		if hit >= 0:
			# Kıvılcım zombinin merminin geldiği yüzeyinde çıkar.
			var surface: Vector2 = enemies.enemy_position(hit) - _dir[i] * enemies.enemy_radius(hit)
			impact.emit(Vector3(surface.x, Tuning.PROJECTILE_HEIGHT, surface.y), _dir[i])
			enemies.damage(hit, _damage[i], _dir[i], _knockback[i])
			_release(i)
			continue
		_life[i] -= delta
		if _life[i] <= 0.0:
			_release(i)
			continue
		_pos[i] = b
		_nodes[i].position = Vector3(b.x, Tuning.PROJECTILE_HEIGHT, b.y)


func _release(i: int) -> void:
	_active[i] = 0
	_active_count -= 1
	_nodes[i].visible = false


func _grow(count: int) -> void:
	for _i in count:
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.mesh = _mesh
		mi.material_override = _material
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		add_child(mi)
		_nodes.append(mi)
		_pos.append(Vector2.ZERO)
		_dir.append(Vector2.ZERO)
		_speed.append(0.0)
		_damage.append(0.0)
		_knockback.append(0.0)
		_life.append(0.0)
		_active.append(0)
