class_name FollowCamera
extends Camera3D
## Sabit açılı, hedefi yumuşakça izleyen kamera: hafif ileri bakış ve sarsıntı.
## Hedefin enterpolasyonlu konumunu okur; böylece yüksek yenileme hızında titremez.

var target: Node3D
## Hedefin XZ hızını veren çağrı (ileri bakış için); verilmezse ileri bakış olmaz.
var velocity_source: Callable

var _offset: Vector3
var _focus: Vector3
var _look_ahead: Vector3 = Vector3.ZERO
var _trauma: float = 0.0
var _shake_time: float = 0.0
var _noise: FastNoiseLite = FastNoiseLite.new()


func _ready() -> void:
	name = "Camera"
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	fov = Tuning.CAMERA_FOV
	_noise.frequency = Tuning.CAMERA_SHAKE_FREQUENCY
	set_distance(Tuning.CAMERA_DISTANCE)
	_focus = _target_point()
	global_position = _focus + _offset
	look_at(_focus, Vector3.UP)
	make_current()


func _process(delta: float) -> void:
	var desired: Vector3 = _target_point() + _desired_look_ahead(delta)
	if Tuning.FEATURE_CAMERA_SMOOTHING:
		_focus = _focus.lerp(desired, 1.0 - exp(-Tuning.CAMERA_FOLLOW_SHARPNESS * delta))
	else:
		_focus = desired
	global_position = _focus + _offset + _shake_offset(delta)


## Kamera uzaklığını değiştirir (açı sabit kalır).
func set_distance(distance: float) -> void:
	var pitch: float = deg_to_rad(Tuning.CAMERA_PITCH_DEG)
	_offset = Vector3(0.0, sin(pitch), cos(pitch)) * distance


## Sarsıntı ekler (0..1). Etki karesiyle büyür, kendiliğinden söner.
func add_trauma(amount: float) -> void:
	if Tuning.FEATURE_CAMERA_SHAKE:
		_trauma = minf(1.0, _trauma + amount)


func _target_point() -> Vector3:
	return target.get_global_transform_interpolated().origin


func _desired_look_ahead(delta: float) -> Vector3:
	var wanted: Vector3 = Vector3.ZERO
	if Tuning.FEATURE_CAMERA_LOOK_AHEAD and velocity_source.is_valid():
		var velocity: Vector3 = velocity_source.call()
		wanted = Vector3(velocity.x, 0.0, velocity.z).limit_length(Tuning.PLAYER_SPEED) * Tuning.CAMERA_LOOK_AHEAD_TIME
	_look_ahead = _look_ahead.lerp(wanted, 1.0 - exp(-Tuning.CAMERA_LOOK_AHEAD_SHARPNESS * delta))
	return _look_ahead


func _shake_offset(delta: float) -> Vector3:
	if _trauma <= 0.0:
		return Vector3.ZERO
	_shake_time += delta
	_trauma = maxf(0.0, _trauma - Tuning.CAMERA_SHAKE_DECAY * delta)
	var strength: float = _trauma * _trauma * Tuning.CAMERA_SHAKE_MAX_OFFSET
	return Vector3(_noise.get_noise_2d(_shake_time, 0.0), 0.0, _noise.get_noise_2d(0.0, _shake_time)) * strength
