class_name BossFx
extends Node3D
## Boss Yığın'ın dünya efektleri (yalnız görüntü ve sarsıntı; kurallar BossAttack'te). EnemyManager.boss_event'i dinler:
## yer dövmesi -> havuzlu şok halkası + çatlak izi (boss_ring shader) + toz + sarsıntı; hücum hazırlığı -> yerde kırmızı şerit
## (son 0.3 sn kilitli parlak); hücum -> toz izi; duvara çarpma / çağrı -> toz + sarsıntı; kükreme -> büyük ses dalgası halkası.
## Boss ölümü (enemy_killed, satırda boss): kristal yağmuru, sarsıntı, kısa vuruş duraksaması, çöküşte ikinci toz.

const RING_SHADER: Shader = preload("res://assets/shaders/boss_ring.gdshader")
const STRIP_SHADER: Shader = preload("res://assets/shaders/boss_strip.gdshader")
const RING_HEIGHT: float = 0.045
const STRIP_HEIGHT: float = 0.05
## Halka düzleminin yarı boyu, son yarıçaptan bu kadar (m) büyüktür (kenar çizgisi kesilmesin).
const RING_MARGIN: float = 1.0
## Ölüm klibinde gövdenin çöktüğü an (sn) ve o andaki toz yarıçapı.
const DEATH_COLLAPSE_AT: float = 2.2
const DEATH_DUST_RADIUS: float = 4.0
const SLAM_DUST_RADIUS: float = 2.6

var _enemies: EnemyManager
var _camera: FollowCamera
var _pickups: Pickups
var _rings: Array[MeshInstance3D] = []
## Halka başına: yaş (sn; < 0 boş), hız, son yarıçap, kalınlık.
var _age: PackedFloat32Array = PackedFloat32Array()
var _speed: PackedFloat32Array = PackedFloat32Array()
var _max: PackedFloat32Array = PackedFloat32Array()
var _width: PackedFloat32Array = PackedFloat32Array()
var _next_ring: int = 0
var _strip: MeshInstance3D
var _wave: ScreamWave


func setup(enemies: EnemyManager, camera: FollowCamera, pickups: Pickups) -> void:
	_enemies = enemies
	_camera = camera
	_pickups = pickups


func _ready() -> void:
	name = "BossFx"
	var ring_mesh: PlaneMesh = PlaneMesh.new()
	ring_mesh.size = Vector2(2.0, 2.0)
	var ring_material: ShaderMaterial = ShaderMaterial.new()
	ring_material.shader = RING_SHADER
	for _i in Tuning.BOSS_RING_POOL:
		var plane: MeshInstance3D = MeshInstance3D.new()
		plane.mesh = ring_mesh
		plane.material_override = ring_material
		plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		plane.visible = false
		add_child(plane)
		_rings.append(plane)
		_age.append(-1.0)
		_speed.append(1.0)
		_max.append(1.0)
		_width.append(0.5)
	var strip_mesh: PlaneMesh = PlaneMesh.new()
	strip_mesh.size = Vector2.ONE
	var strip_material: ShaderMaterial = ShaderMaterial.new()
	strip_material.shader = STRIP_SHADER
	_strip = MeshInstance3D.new()
	_strip.mesh = strip_mesh
	_strip.material_override = strip_material
	_strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_strip.visible = false
	add_child(_strip)
	_wave = ScreamWave.new()
	add_child(_wave)
	_enemies.boss_event.connect(_on_boss_event)
	_enemies.enemy_killed.connect(_on_enemy_killed)
	set_process(false)


func _process(delta: float) -> void:
	var any: bool = false
	for i in _rings.size():
		if _age[i] < 0.0:
			continue
		_age[i] += delta
		var expand: float = _max[i] / _speed[i]
		if _age[i] >= expand + Tuning.BOSS_RING_SCAR_TIME:
			_age[i] = -1.0
			_rings[i].visible = false
			continue
		any = true
		var half: float = _max[i] + RING_MARGIN
		var plane: MeshInstance3D = _rings[i]
		plane.set_instance_shader_parameter(&"front", minf(_speed[i] * _age[i], _max[i]) / half)
		plane.set_instance_shader_parameter(&"scar", 1.0 - clampf((_age[i] - expand) / Tuning.BOSS_RING_SCAR_TIME, 0.0, 1.0))
	if not any:
		set_process(false)


func _on_boss_event(event_name: StringName, data: Dictionary) -> void:
	match event_name:
		&"slam":
			if int(data["index"]) == 0:
				LandingFx.play(self, data["at"], SLAM_DUST_RADIUS)
				_shake(Tuning.CAMERA_SHAKE_ON_BOSS_SLAM)
				if not Tuning.FEATURE_SFX_ZOMBIES:
					Audio.play(&"explosion")
			_start_ring(data)
		&"charge_marker":
			_show_strip(data)
		&"charge_start":
			_shake(Tuning.CAMERA_SHAKE_ON_BOSS_CHARGE)
		&"charge_dust":
			LandingFx.play(self, data["at"], 0.9)
		&"stun":
			LandingFx.play(self, data["at"], SLAM_DUST_RADIUS)
			_shake(Tuning.CAMERA_SHAKE_ON_BOSS_STUN)
			if not Tuning.FEATURE_SFX_ZOMBIES:
				Audio.play(&"explosion")
		&"summon":
			LandingFx.play(self, data["at"], 1.8)
		&"roar":
			_wave.play(data["at"], float(data["radius"]))
			_shake(Tuning.CAMERA_SHAKE_ON_BOSS_ROAR)


func _on_enemy_killed(at: Vector3, row: Dictionary) -> void:
	if not row.get("boss", false):
		return
	_shake(Tuning.CAMERA_SHAKE_ON_BOSS_DEATH)
	if Tuning.FEATURE_BOSS_HITSTOP:
		GameFlow.hit_stop(Tuning.BOSS_HITSTOP_TIME, true)
	if _pickups != null:
		_pickups.rain(at, int(row.get("drop_value", 0)), Tuning.BOSS_CRYSTAL_PIECES)
	get_tree().create_timer(DEATH_COLLAPSE_AT).timeout.connect(func() -> void:
		LandingFx.play(self, Vector3(at.x, 0.1, at.z), DEATH_DUST_RADIUS)
		_shake(Tuning.CAMERA_SHAKE_ON_BOSS_STUN))


func _shake(amount: float) -> void:
	if _camera != null:
		_camera.add_trauma(amount)


func _start_ring(data: Dictionary) -> void:
	var i: int = _next_ring
	_next_ring = (_next_ring + 1) % _rings.size()
	_age[i] = 0.0
	_speed[i] = float(data["speed"])
	_max[i] = float(data["max"])
	_width[i] = float(data["width"])
	var half: float = _max[i] + RING_MARGIN
	var at: Vector3 = data["at"]
	var plane: MeshInstance3D = _rings[i]
	plane.global_position = Vector3(at.x, RING_HEIGHT + 0.0005 * i, at.z)
	plane.scale = Vector3(half, 1.0, half)
	plane.set_instance_shader_parameter(&"width", _width[i] / half)
	plane.set_instance_shader_parameter(&"front", 0.0)
	plane.set_instance_shader_parameter(&"scar", 1.0)
	plane.visible = true
	set_process(true)


## Hücum şeridi: başlangıçtan dir yönünde length m, boss gövdesi genişliğinde.
func _show_strip(data: Dictionary) -> void:
	if not data["on"]:
		_strip.visible = false
		return
	var dir: Vector2 = data["dir"]
	var from: Vector3 = data["from"]
	var length: float = float(data["length"])
	_strip.visible = true
	_strip.global_position = from + Vector3(dir.x, 0.0, dir.y) * length * 0.5 + Vector3(0.0, STRIP_HEIGHT, 0.0)
	_strip.rotation.y = atan2(dir.x, dir.y)
	_strip.scale = Vector3(float(data["half_width"]) * 2.0, 1.0, length)
	_strip.set_instance_shader_parameter(&"len", length)
	_strip.set_instance_shader_parameter(&"locked", 1.0 if data["locked"] else 0.0)
