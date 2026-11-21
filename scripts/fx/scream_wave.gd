class_name ScreamWave
extends Node3D
## Çığlıkçının ses dalgası (yalnız görüntü, havuzlu): yerde genişleyen ince soluk mor halka. `EnemyManager.scream_emitted`
## buraya bağlanır; en eski halka yerini verir. Süre ve boyut Tuning'den (SCREAM_WAVE_*).

const SHADER: Shader = preload("res://assets/shaders/scream_wave.gdshader")
const HEIGHT: float = 0.04

var _planes: Array[MeshInstance3D] = []
## Halka başına geçen süre (sn); < 0 boş.
var _age: PackedFloat32Array = PackedFloat32Array()
var _next: int = 0


func _ready() -> void:
	name = "ScreamWave"
	var mesh: PlaneMesh = PlaneMesh.new()
	mesh.size = Vector2(2.0, 2.0)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	for _i in Tuning.SCREAM_WAVE_POOL:
		var plane: MeshInstance3D = MeshInstance3D.new()
		plane.mesh = mesh
		plane.material_override = material
		plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		plane.visible = false
		add_child(plane)
		_planes.append(plane)
		_age.append(-1.0)
	set_process(false)


## at: çığlığın yeri; radius: çağrı halkası yarıçapı (dalga bunun SCREAM_WAVE_SCALE katına büyür).
func play(at: Vector3, radius: float) -> void:
	var index: int = _next
	_next = (_next + 1) % _planes.size()
	var plane: MeshInstance3D = _planes[index]
	var size: float = radius * Tuning.SCREAM_WAVE_SCALE
	plane.global_position = Vector3(at.x, HEIGHT + 0.0004 * index, at.z)
	plane.scale = Vector3(size, 1.0, size)
	plane.set_instance_shader_parameter(&"progress", 0.0)
	plane.visible = true
	_age[index] = 0.0
	set_process(true)


func _process(delta: float) -> void:
	var any: bool = false
	for i in _planes.size():
		if _age[i] < 0.0:
			continue
		_age[i] += delta
		if _age[i] >= Tuning.SCREAM_WAVE_TIME:
			_age[i] = -1.0
			_planes[i].visible = false
			continue
		any = true
		_planes[i].set_instance_shader_parameter(&"progress", _age[i] / Tuning.SCREAM_WAVE_TIME)
	if not any:
		set_process(false)
