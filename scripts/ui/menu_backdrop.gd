class_name MenuBackdrop
extends Node3D
## Ana menünün canlı 3B arka planı: oyunun şehir arenası, bekleyen asker, uzakta sürünen zombiler, yavaş süzülen kamera.
## Yalnız görüntü: oynanış yok. Kalite profiline saygılı (düşükte alan derinliği kapalı, ortam sesi yok).

const SOLDIER_MODEL: PackedScene = preload("res://assets/models/characters/soldier.glb")
## Asker (dünya, derece): kavşağın ortası, kameraya üç çeyrek dönük.
const SOLDIER_POSITION: Vector3 = Vector3(0.0, 0.0, 0.0)
const SOLDIER_YAW_DEG: float = 28.0
## Kamera: askerin etrafında yörünge. Odak noktası göğüs hizası.
const FOCUS_HEIGHT: float = 0.95
const CAMERA_DISTANCE: float = 5.6
const CAMERA_HEIGHT: float = 1.15
const CAMERA_YAW_DEG: float = 24.0
const CAMERA_FOV: float = 34.0
## Asker ekranın yarı genişliğinin bu kadarı kadar sağa oturur (en boy oranından bağımsız).
const SCREEN_X: float = 0.66
## Asker ışıkları: sıcak ana ışık (sol-ön) ve soğuk arka ışık (sağ-arka): konum, renk, enerji, menzil.
const KEY_LIGHT: Dictionary = {"at": Vector3(-2.2, 2.6, 2.4), "color": Color(1.0, 0.68, 0.38), "energy": 3.0, "range": 9.0}
const RIM_LIGHT: Dictionary = {"at": Vector3(2.4, 2.4, -2.6), "color": Color(0.45, 0.62, 1.0), "energy": 2.5, "range": 9.0}
## Yavaş süzülme: yaw salınımı (derece), uzaklık salınımı (metre), hız (rad/sn).
const DRIFT_YAW_DEG: float = 7.0
const DRIFT_DISTANCE: float = 0.5
const DRIFT_RATE: float = 0.11
## Uzak alan bulanıklığı (orta ve yüksek kalite).
const DOF_DISTANCE: float = 9.0
const DOF_TRANSITION: float = 22.0
const DOF_AMOUNT: float = 0.07
## Menüde ortam sesi bu kadar kısılır (dB).
const AMBIENCE_QUIET_DB: float = -10.0
## Zombiler: {kind, from, to (XZ), hız m/sn}. Kuzey sokakta askere doğru ağır ağır yürür; döngüde yerden çıkar / yere gömülür.
const SINK_DEPTH: float = 2.2
const SINK_ZONE: float = 0.09
const ZOMBIES: Array[Dictionary] = [
	{"kind": &"walker", "from": Vector2(-5.0, -22.0), "to": Vector2(-4.0, -9.0), "speed": 0.5},
	{"kind": &"walker", "from": Vector2(-2.0, -26.0), "to": Vector2(-2.0, -10.5), "speed": 0.45},
	{"kind": &"tank", "from": Vector2(-4.0, -30.0), "to": Vector2(-3.5, -12.0), "speed": 0.4},
	{"kind": &"runner", "from": Vector2(-7.0, -20.0), "to": Vector2(-6.0, -8.0), "speed": 0.55},
	{"kind": &"walker", "from": Vector2(0.5, -33.0), "to": Vector2(0.0, -13.5), "speed": 0.5},
]

var _camera: Camera3D = null
var _time: float = 0.0
var _walkers: Array[Dictionary] = []


func _ready() -> void:
	name = "MenuBackdrop"
	add_child(Arena.new())
	_add_soldier()
	_add_lights()
	_add_zombies()
	_add_camera()
	Quality.apply_to_viewport(get_viewport())
	if Tuning.FEATURE_SFX_AMBIENCE and not Settings.measurement:
		_add_ambience()
	_update_camera()


func _process(delta: float) -> void:
	_time += delta
	_update_camera()
	for w: Dictionary in _walkers:
		_step_walker(w, delta)


func _add_soldier() -> void:
	var holder: Node3D = Node3D.new()
	holder.name = "Soldier"
	holder.position = SOLDIER_POSITION
	holder.rotation_degrees.y = SOLDIER_YAW_DEG
	add_child(holder)
	var model: Node3D = SOLDIER_MODEL.instantiate() as Node3D
	holder.add_child(model)
	var tint: Color = Tuning.PLAYER_BRIGHT_ALBEDO_TINT if Tuning.FEATURE_PLAYER_BRIGHT_ALBEDO else Tuning.PLAYER_ALBEDO_TINT
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = PlayerVisual.FLASH_SHADER
		material.set_shader_parameter(&"albedo", tint)
		var source: BaseMaterial3D = mesh.mesh.surface_get_material(0) as BaseMaterial3D
		if source != null and source.albedo_texture != null:
			material.set_shader_parameter(&"albedo_texture", source.albedo_texture)
		if Tuning.FEATURE_PLAYER_BRIGHT_ALBEDO:
			material.set_shader_parameter(&"roughness", Tuning.PLAYER_BRIGHT_ROUGHNESS)
		mesh.material_override = material
	# Bekleme klibi: harman 0'da (hareket yok).
	var animator: PlayerAnimator = PlayerAnimator.new(model)
	animator.set_locomotion(0.0, 1.0)


func _add_lights() -> void:
	for spec: Dictionary in [KEY_LIGHT, RIM_LIGHT]:
		var light: OmniLight3D = OmniLight3D.new()
		light.position = SOLDIER_POSITION + (spec["at"] as Vector3)
		light.light_color = spec["color"]
		light.light_energy = spec["energy"]
		light.omni_range = spec["range"]
		light.shadow_enabled = false
		add_child(light)


func _add_zombies() -> void:
	for spec: Dictionary in ZOMBIES:
		var kind: StringName = spec["kind"]
		var zombie: Zombie = Zombie.new(kind)
		add_child(zombie)
		zombie.configure(EnemyData.get_row(kind))
		var from: Vector2 = spec["from"]
		zombie.activate(Vector3(from.x, 0.0, from.y))
		zombie.enter_state(ZombieRules.State.CHASE)
		_walkers.append({"node": zombie, "spec": spec, "t": randf()})


## Zombi from -> to arasında ağır ağır yürür; sonda başa sarar.
func _step_walker(w: Dictionary, delta: float) -> void:
	var spec: Dictionary = w["spec"]
	var from: Vector2 = spec["from"]
	var to: Vector2 = spec["to"]
	var length: float = from.distance_to(to)
	var speed: float = spec["speed"]
	w["t"] = fposmod(float(w["t"]) + speed * delta / length, 1.0)
	var at: Vector2 = from.lerp(to, w["t"])
	var zombie: Zombie = w["node"]
	var t: float = w["t"]
	var sink: float = maxf(smoothstep(1.0 - SINK_ZONE, 1.0, t), 1.0 - smoothstep(0.0, SINK_ZONE, t))
	zombie.position = Vector3(at.x, -SINK_DEPTH * sink, at.y)
	var heading: Vector2 = to - from
	zombie.rotation.y = atan2(heading.x, heading.y)
	zombie.ground_speed.emit(speed)


func _add_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "MenuCamera"
	_camera.fov = CAMERA_FOV
	add_child(_camera)
	_camera.make_current()
	if Quality.current != QualityProfiles.LOW:
		var attributes: CameraAttributesPractical = CameraAttributesPractical.new()
		attributes.dof_blur_far_enabled = true
		attributes.dof_blur_far_distance = DOF_DISTANCE
		attributes.dof_blur_far_transition = DOF_TRANSITION
		attributes.dof_blur_amount = DOF_AMOUNT
		_camera.attributes = attributes


func _update_camera() -> void:
	var swing: float = sin(_time * DRIFT_RATE * TAU)
	var yaw: float = deg_to_rad(CAMERA_YAW_DEG + swing * DRIFT_YAW_DEG)
	var distance: float = CAMERA_DISTANCE + cos(_time * DRIFT_RATE * TAU * 0.7) * DRIFT_DISTANCE
	var focus: Vector3 = SOLDIER_POSITION + Vector3(0.0, FOCUS_HEIGHT, 0.0)
	_camera.position = focus + Vector3(sin(yaw) * distance, CAMERA_HEIGHT - FOCUS_HEIGHT, cos(yaw) * distance)
	_camera.look_at(focus, Vector3.UP)
	var aspect: float = get_viewport().get_visible_rect().size.aspect()
	var half_width: float = distance * tan(deg_to_rad(CAMERA_FOV) * 0.5) * aspect
	_camera.look_at(focus - _camera.global_transform.basis.x * half_width * SCREEN_X, Vector3.UP)


func _add_ambience() -> void:
	var rig: AmbienceRig = AmbienceRig.new()
	add_child(rig)
	for child: Node in rig.get_children():
		if child is AudioStreamPlayer:
			(child as AudioStreamPlayer).volume_db += AMBIENCE_QUIET_DB
