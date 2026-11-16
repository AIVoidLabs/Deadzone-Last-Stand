extends GutTest

const EPSILON: float = 0.0001


func _assert_same_rotation(a: Quaternion, b: Quaternion) -> void:
	assert_almost_eq(absf(a.dot(b)), 1.0, EPSILON)


func test_mirror_bone_name_swaps_sides_only() -> void:
	assert_eq(AnimDerive.mirror_bone_name("LeftUpperArm"), "RightUpperArm")
	assert_eq(AnimDerive.mirror_bone_name("RightFoot"), "LeftFoot")
	assert_eq(AnimDerive.mirror_bone_name("Spine"), "Spine")


func test_mirror_rotation_keeps_pitch_and_flips_yaw_and_roll() -> void:
	var pitch: Quaternion = Quaternion(Vector3.RIGHT, 0.6)
	_assert_same_rotation(AnimDerive.mirror_rotation(pitch), pitch)
	var yaw: Quaternion = Quaternion(Vector3.UP, 0.6)
	_assert_same_rotation(AnimDerive.mirror_rotation(yaw), Quaternion(Vector3.UP, -0.6))
	var roll: Quaternion = Quaternion(Vector3.BACK, 0.6)
	_assert_same_rotation(AnimDerive.mirror_rotation(roll), Quaternion(Vector3.BACK, -0.6))


func test_mirror_twice_is_identity() -> void:
	var rotation: Quaternion = Quaternion(Vector3(0.3, -0.5, 0.8).normalized(), 1.1)
	_assert_same_rotation(AnimDerive.mirror_rotation(AnimDerive.mirror_rotation(rotation)), rotation)
	var position: Vector3 = Vector3(0.4, 1.0, -0.2)
	assert_eq(AnimDerive.mirror_position(AnimDerive.mirror_position(position)), position)
	assert_eq(AnimDerive.mirror_position(position).x, -position.x)


func test_offset_is_applied_in_model_space() -> void:
	# Ebeveyn 90 derece yana dönük olsa da ek dönüş model eksenine göre uygulanmalı.
	var parent: Quaternion = Quaternion(Vector3.UP, PI * 0.5)
	var local: Quaternion = Quaternion(Vector3.BACK, 0.4)
	var offset: Quaternion = AnimDerive.offset_from_degrees(Vector3(30.0, 0.0, 0.0))
	var result: Quaternion = AnimDerive.offset_rotation(local, parent, offset)
	_assert_same_rotation(parent * result, offset * parent * local)


func test_zero_offset_changes_nothing() -> void:
	var parent: Quaternion = Quaternion(Vector3(1.0, 1.0, 0.0).normalized(), 0.7)
	var local: Quaternion = Quaternion(Vector3.RIGHT, 0.2)
	_assert_same_rotation(AnimDerive.offset_rotation(local, parent, AnimDerive.offset_from_degrees(Vector3.ZERO)), local)


func test_reversed_time_maps_ends() -> void:
	assert_almost_eq(AnimDerive.reversed_time(0.0, 2.0), 2.0, EPSILON)
	assert_almost_eq(AnimDerive.reversed_time(2.0, 2.0), 0.0, EPSILON)
	assert_almost_eq(AnimDerive.reversed_time(0.5, 2.0), 1.5, EPSILON)
