extends Node3D
## Dil önizlemesi: zombi maketi (yürür/sallanır) dilini hareketli hedefe atar, tutar, çeker; her 3. turda ıskalar.
## Aç: godot --path . res://scenes/debug/tongue_preview.tscn [-- --close]
## Tuşlar: C kamera değiştir, Esc çıkış. Yalnız debug yapıda.

const MOUTH_HEIGHT: float = 1.55
const MOUTH_FORWARD: float = 0.45
const ZOMBIE_POS: Vector3 = Vector3(-3.0, 0.0, 0.0)
const WALK_AMPLITUDE: float = 0.5
const WALK_SPEED: float = 1.1
const BOB_AMOUNT: float = 0.05
const BOB_SPEED: float = 7.0
const DANGLE_LENGTH: float = 0.55
const TARGET_RADIUS: float = 6.0
const TARGET_SWING: float = 0.7
const TARGET_SPEED: float = 0.9
const TARGET_HIT_HEIGHT: float = 1.0
const MISS_OFFSET: Vector3 = Vector3(0.0, 0.0, 2.5)
const WAIT_TIME: float = 0.6
const TRAVEL_TIME: float = 0.28
const ATTACH_TIME: float = 1.2
const MISS_HOLD: float = 0.15
const MISS_EVERY: int = 3
const FAR_POS: Vector3 = Vector3(0.0, 8.5, 5.5)
const FAR_LOOK: Vector3 = Vector3(0.0, 0.6, 1.5)
const CLOSE_POS: Vector3 = Vector3(-0.5, 2.4, 3.2)
const CLOSE_LOOK: Vector3 = Vector3(-2.5, 1.2, 0.0)

enum Phase { WAIT, SHOOT, ATTACH, RETRACT, MISS_HOLD }

var _tongue: TongueRope
var _target: Node3D
var _zombie: Node3D
var _camera: Camera3D
var _close: bool = false
var _phase: Phase = Phase.WAIT
var _timer: float = 0.0
var _cycle: int = 0
var _clock: float = 0.0
var _miss: bool = false
var _miss_point: Vector3 = Vector3.ZERO


func _ready() -> void:
	if not OS.is_debug_build():
		get_tree().quit()
		return
	_close = "--close" in OS.get_cmdline_user_args()
	_build_world()
	_tongue = TongueRope.new()
	add_child(_tongue)
	_tongue.set_anchor(_mouth(), Vector3.RIGHT)
	_tongue.set_dangle(DANGLE_LENGTH)
	_tongue.reached.connect(_on_reached)
	_tongue.retracted.connect(_on_retracted)
	_apply_camera()


func _build_world() -> void:
	var ground: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(40.0, 40.0)
	ground.mesh = plane
	ground.material_override = _flat(Color(0.12, 0.12, 0.14))
	add_child(ground)
	_zombie = _capsule(0.4, 1.8, Color(0.16, 0.2, 0.17))
	add_child(_zombie)
	_target = _capsule(0.3, 1.5, Color(0.25, 0.4, 0.7))
	add_child(_target)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -30.0, 0.0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.06, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.38, 0.5)
	env.ambient_light_energy = 0.6
	var we: WorldEnvironment = WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_camera = Camera3D.new()
	_camera.fov = 45.0
	add_child(_camera)


func _capsule(radius: float, height: float, color: Color) -> MeshInstance3D:
	var m: MeshInstance3D = MeshInstance3D.new()
	var cm: CapsuleMesh = CapsuleMesh.new()
	cm.radius = radius
	cm.height = height
	m.mesh = cm
	m.material_override = _flat(color)
	return m


func _flat(color: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	return mat


func _apply_camera() -> void:
	_camera.position = CLOSE_POS if _close else FAR_POS
	_camera.look_at(CLOSE_LOOK if _close else FAR_LOOK)


## Zombi maketi yavaşça ileri geri yürür ve sallanır.
func _zombie_pos() -> Vector3:
	var walk: float = sin(_clock * WALK_SPEED) * WALK_AMPLITUDE
	var bob: float = absf(sin(_clock * BOB_SPEED)) * BOB_AMOUNT
	return ZOMBIE_POS + Vector3(walk, bob, 0.0)


func _mouth() -> Vector3:
	return _zombie_pos() + Vector3(MOUTH_FORWARD, MOUTH_HEIGHT, 0.0)


func _target_pos() -> Vector3:
	var a: float = sin(_clock * TARGET_SPEED) * TARGET_SWING
	return ZOMBIE_POS + Vector3(cos(a), 0.0, sin(a)) * TARGET_RADIUS


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: InputEventKey = event as InputEventKey
		if key.keycode == KEY_C:
			_close = not _close
			_apply_camera()
		elif key.keycode == KEY_ESCAPE:
			get_tree().quit()


func _process(delta: float) -> void:
	_clock += delta
	_timer += delta
	_zombie.position = _zombie_pos() + Vector3(0.0, 0.9, 0.0)
	_target.position = _target_pos() + Vector3(0.0, 0.75, 0.0)
	_tongue.set_anchor(_mouth(), Vector3.RIGHT)
	var aim: Vector3 = _target_pos() + Vector3(0.0, TARGET_HIT_HEIGHT, 0.0)
	match _phase:
		Phase.WAIT:
			if _timer >= WAIT_TIME:
				_start_shot(aim)
		Phase.ATTACH:
			_tongue.set_target(aim)
			if _timer >= ATTACH_TIME:
				_phase = Phase.RETRACT
				_tongue.retract()
		Phase.MISS_HOLD:
			if _timer >= MISS_HOLD:
				_phase = Phase.RETRACT
				_tongue.retract()


func _start_shot(aim: Vector3) -> void:
	_cycle += 1
	_miss = _cycle % MISS_EVERY == 0
	_miss_point = aim + MISS_OFFSET
	_phase = Phase.SHOOT
	_tongue.shoot(_mouth(), _miss_point if _miss else aim, TRAVEL_TIME)


func _on_reached() -> void:
	_timer = 0.0
	_phase = Phase.MISS_HOLD if _miss else Phase.ATTACH


func _on_retracted() -> void:
	_timer = 0.0
	_phase = Phase.WAIT

