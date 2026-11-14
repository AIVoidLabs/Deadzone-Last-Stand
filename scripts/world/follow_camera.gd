class_name FollowCamera
extends Camera3D
## Sabit açılı, hedefi yumuşakça izleyen kamera. Hedefin enterpolasyonlu
## konumunu okur; böylece yüksek yenileme hızında titremez.

var target: Node3D

var _offset: Vector3


func _ready() -> void:
	name = "Camera"
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	fov = Tuning.CAMERA_FOV
	var pitch: float = deg_to_rad(Tuning.CAMERA_PITCH_DEG)
	_offset = Vector3(0.0, sin(pitch), cos(pitch)) * Tuning.CAMERA_DISTANCE
	global_position = _target_point() + _offset
	look_at(_target_point(), Vector3.UP)
	make_current()


func _process(delta: float) -> void:
	var desired: Vector3 = _target_point() + _offset
	if Tuning.FEATURE_CAMERA_SMOOTHING:
		global_position = global_position.lerp(desired, 1.0 - exp(-Tuning.CAMERA_FOLLOW_SHARPNESS * delta))
	else:
		global_position = desired


func _target_point() -> Vector3:
	return target.get_global_transform_interpolated().origin
