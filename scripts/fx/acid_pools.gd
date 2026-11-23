class_name AcidPools
extends Node3D
## Tükürücünün asit havuzları (yalnız görüntü): havuzdan gelen yer daireleri (Tuning.ACID_POOL_MAX), kabarcıklı
## yeşil shader, son ACID_FADE_TIME sn'de söner. Gerçek alan hasarı LobAttack'ta; sıra (en eski önce yerini verir)
## orada da aynı olduğundan ikisi birlikte yürür (en az ömrü kalan havuz yerini verir). `EnemyManager.acid_pool_started` buraya bağlanır.

const SHADER: Shader = preload("res://assets/shaders/acid_pool.gdshader")
const HEIGHT: float = 0.025

var _planes: Array[MeshInstance3D] = []
## Havuz başına kalan süre (sn); <= 0 boş.
var _left: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	name = "AcidPools"
	var mesh: PlaneMesh = PlaneMesh.new()
	mesh.size = Vector2(2.0, 2.0)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	for _i in Tuning.ACID_POOL_MAX:
		var plane: MeshInstance3D = MeshInstance3D.new()
		plane.mesh = mesh
		plane.material_override = material
		plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		plane.visible = false
		add_child(plane)
		_planes.append(plane)
		_left.append(0.0)
	set_process(false)


## Yeni havuz: boş yuva, yoksa kalan süresi en az olan yuva yerini verir. LobAttack aynı kuralla (en çabuk sönecek havuz)
## aynı time değerleriyle havuz atar; görüntü ile gerçek alan karışık ömürlerde de aynı havuzu bırakır.
func add_pool(at: Vector3, radius: float, time: float) -> void:
	var index: int = 0
	for k in _planes.size():
		if _left[k] < _left[index]:
			index = k
	var plane: MeshInstance3D = _planes[index]
	plane.global_position = Vector3(at.x, HEIGHT + 0.0004 * index, at.z)
	plane.scale = Vector3(radius, 1.0, radius)
	plane.set_instance_shader_parameter(&"seed", randf())
	plane.set_instance_shader_parameter(&"fade", 1.0)
	plane.visible = true
	_left[index] = time
	set_process(true)


func _process(delta: float) -> void:
	var any: bool = false
	for i in _planes.size():
		if _left[i] <= 0.0:
			continue
		_left[i] -= delta
		if _left[i] <= 0.0:
			_planes[i].visible = false
			continue
		any = true
		_planes[i].set_instance_shader_parameter(&"fade", clampf(_left[i] / Tuning.ACID_FADE_TIME, 0.0, 1.0))
	if not any:
		set_process(false)
