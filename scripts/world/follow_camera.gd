class_name FollowCamera
extends Camera3D
## Sabit açılı, hedefi yumuşakça izleyen kamera: hafif ileri bakış ve sarsıntı.
## Hedefin enterpolasyonlu konumunu okur; böylece yüksek yenileme hızında titremez.

var target: Node3D
## Hedefin XZ hızını veren çağrı (ileri bakış için); verilmezse ileri bakış olmaz.
var velocity_source: Callable

var _offset: Vector3
var _distance: float = Tuning.CAMERA_DISTANCE
## Dinamik açı ofseti (x: yaw derece, y: pitch derece), yumuşatılmış
var _dyn: Vector2 = Vector2.ZERO
var _pitch_deg: float = Tuning.CAMERA_PITCH_DEG
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
	var offset: Vector3 = _offset
	if Tuning.FEATURE_CAMERA_DYNAMIC_ANGLE:
		_dyn = _dyn.lerp(_dynamic_target(), 1.0 - exp(-Tuning.CAMERA_DYN_SHARPNESS * delta))
		offset = orbit_offset(_pitch_deg + _dyn.y, _dyn.x, _distance)
	global_position = _focus + offset + _shake_offset(delta)
	if Tuning.FEATURE_CAMERA_DYNAMIC_ANGLE:
		look_at(_focus, Vector3.UP)


## Kamera uzaklığını değiştirir (açı sabit kalır).
func set_distance(distance: float) -> void:
	_distance = distance
	_offset = orbit_offset(_pitch_deg, 0.0, distance)


## Kamera eğimini değiştirir (debug karşılaştırma); uzaklığı da yeniden verin.
func set_pitch(pitch_deg: float, distance: float) -> void:
	_pitch_deg = pitch_deg
	set_distance(distance)


## Sarsıntı ekler (0..1). Etki karesiyle büyür, kendiliğinden söner.
func add_trauma(amount: float) -> void:
	if Tuning.FEATURE_CAMERA_SHAKE:
		_trauma = minf(1.0, _trauma + amount)


## Odak noktasından kameraya ofset; yaw Y ekseni etrafında döndürür.
static func orbit_offset(pitch_deg: float, yaw_deg: float, distance: float) -> Vector3:
	var pitch: float = deg_to_rad(pitch_deg)
	return Vector3(0.0, sin(pitch), cos(pitch)).rotated(Vector3.UP, deg_to_rad(yaw_deg)) * distance


## Hıza göre hedef (yaw, pitch) ofseti; hız en çok normal koşu hızına kırpılır (dash sıçramaz).
static func dynamic_angle(velocity: Vector3, max_speed: float, yaw_deg: float, pitch_deg: float) -> Vector2:
	var v: Vector3 = Vector3(velocity.x, 0.0, velocity.z).limit_length(max_speed) / maxf(max_speed, 0.001)
	return Vector2(-v.x * yaw_deg, v.z * pitch_deg)


func _dynamic_target() -> Vector2:
	if not velocity_source.is_valid():
		return Vector2.ZERO
	return dynamic_angle(velocity_source.call(), Tuning.PLAYER_SPEED, Tuning.CAMERA_DYN_YAW_DEG, Tuning.CAMERA_DYN_PITCH_DEG)


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
