class_name ProjectilePool
extends Node3D
## Mermiler: sabit havuz, elle hareket, kare başına doğru parçası çarpışması
## (hızlı mermi zombinin içinden geçip gitmez).

signal impact(at: Vector3, direction: Vector2)
## Patlayan mermi (bomba) patladı: at yerde, radius patlama yarıçapı (m).
signal explosion(at: Vector3, radius: float)

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
## Delip geçme: kalan ek isabet; patlama yarıçapı (0 = patlamaz); toplam ömür ve yay yüksekliği (bomba).
var _pierce: PackedInt32Array = PackedInt32Array()
var _explode: PackedFloat32Array = PackedFloat32Array()
var _life_total: PackedFloat32Array = PackedFloat32Array()
var _arc: PackedFloat32Array = PackedFloat32Array()
var _hits: Array[PackedInt32Array] = []
var _active_count: int = 0
var _sight_blocks: Array[Rect2] = []
var _mesh: BoxMesh
var _material: Material


func _ready() -> void:
	name = "Projectiles"
	process_physics_priority = PHYSICS_PRIORITY
	_mesh = BoxMesh.new()
	if Tuning.FEATURE_BUILDING_LOS:
		_sight_blocks = CityLayout.block_rects(Tuning.ARENA_SIZE, Tuning.CITY_STREET_WIDTH)
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


## opts: length (boy çarpanı; bomba kısa ve tıknaz), pierce (ek isabet sayısı), explode_radius (m), color (parlak uç rengi; alfa 0 = varsayılan), size (çarpan), arc (yay yüksekliği, m).
func fire(origin: Vector2, direction: Vector2, speed: float, dmg: float, max_range: float, knockback: float = 0.0, opts: Dictionary = {}) -> void:
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
	_life_total[slot] = _life[slot]
	_pierce[slot] = opts.get("pierce", 0)
	_explode[slot] = opts.get("explode_radius", 0.0)
	_arc[slot] = opts.get("arc", 0.0)
	_hits[slot] = PackedInt32Array()
	_active[slot] = 1
	_active_count += 1
	var node: MeshInstance3D = _nodes[slot]
	node.position = Vector3(origin.x, Tuning.PROJECTILE_HEIGHT, origin.y)
	node.rotation.y = atan2(direction.x, direction.y)
	var size: float = opts.get("size", 1.0)
	node.scale = Vector3(size, size, size * float(opts.get("length", 1.0)))
	if Tuning.FEATURE_TRACERS:
		node.set_instance_shader_parameter(&"tint", opts.get("color", Color(0.0, 0.0, 0.0, 0.0)))
	node.visible = true
	node.reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	for i in _nodes.size():
		if _active[i] == 0:
			continue
		var a: Vector2 = _pos[i]
		var b: Vector2 = a + _dir[i] * _speed[i] * delta
		var wall: Vector3 = CityLayout.first_hit(a, b, 0.0, _sight_blocks)
		var reach: Vector2 = b if wall.x < 0.0 else a.lerp(b, wall.x)
		var hit: int = enemies.find_segment_hit(a, reach, Tuning.PROJECTILE_RADIUS, _hits[i])
		if hit < 0 and wall.x >= 0.0:
			# Bina: mermi duvarda durur (patlayan orada patlar).
			impact.emit(Vector3(reach.x, Tuning.PROJECTILE_HEIGHT, reach.y), _dir[i])
			if _explode[i] > 0.0:
				_detonate(i, reach)
			_release(i)
			continue
		if hit >= 0:
			# Kıvılcım zombinin merminin geldiği yüzeyinde çıkar.
			var surface: Vector2 = enemies.enemy_position(hit) - _dir[i] * enemies.enemy_radius(hit)
			impact.emit(Vector3(surface.x, Tuning.PROJECTILE_HEIGHT, surface.y), _dir[i])
			if _explode[i] > 0.0:
				_detonate(i, surface)
				_release(i)
				continue
			enemies.damage(hit, _damage[i], _dir[i], _knockback[i])
			if _pierce[i] > 0:
				# Delip geçer: aynı zombiye bir daha çarpmaz, hasar her zombide aynı.
				_pierce[i] -= 1
				_hits[i].append(hit)
			else:
				_release(i)
				continue
		_life[i] -= delta
		if _life[i] <= 0.0:
			if _explode[i] > 0.0:
				_detonate(i, b)
			_release(i)
			continue
		_pos[i] = b
		var rise: float = 0.0
		if _arc[i] > 0.0:
			rise = sin(PI * (1.0 - _life[i] / _life_total[i])) * _arc[i]
		_nodes[i].position = Vector3(b.x, Tuning.PROJECTILE_HEIGHT + rise, b.y)


## Patlama: yarıçaptaki herkese tam hasar, merkezden dışa itme.
func _detonate(i: int, at: Vector2) -> void:
	var radius: float = _explode[i]
	explosion.emit(Vector3(at.x, 0.1, at.y), radius)
	for index in enemies.query_circle(at, radius):
		var away: Vector2 = enemies.enemy_position(index) - at
		enemies.damage(index, _damage[i], away.normalized() if away.length_squared() > 0.0001 else _dir[i], _knockback[i])


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
		_pierce.append(0)
		_explode.append(0.0)
		_life_total.append(1.0)
		_arc.append(0.0)
		_hits.append(PackedInt32Array())
