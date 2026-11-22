extends GutTest
## Direk örtme kuralı (PoleFadeRules). Kamera askerin +Z tarafında, yukarıda.

var _base: Vector3 = Vector3(10.0, 0.0, 6.0)
var _cam_offset: Vector3 = Vector3(0.0, 20.0, 12.0)


func _target(dz: float, dx: float = 0.0) -> Vector3:
	return Vector3(_base.x + dx, Tuning.POLE_FADE_TARGET_HEIGHT, _base.z + dz)


func _occ(target: Vector3) -> bool:
	return PoleFadeRules.occludes(target + _cam_offset, target, _base, Tuning.POLE_HEIGHT, Tuning.POLE_FADE_RADIUS)


func test_behind_pole_occludes() -> void:
	# asker direğin hemen -Z tarafında: ışın direk gövdesinden geçer
	var t: Vector3 = Vector3(_base.x, Tuning.POLE_FADE_TARGET_HEIGHT, _base.z - 0.7)
	assert_true(PoleFadeRules.occludes(t + Vector3(0.0, 20.0, 12.0), t, _base, Tuning.POLE_HEIGHT, Tuning.POLE_FADE_RADIUS))


func test_in_front_does_not_occlude() -> void:
	assert_false(_occ(_target(4.0)))


func test_far_to_the_side_does_not_occlude() -> void:
	assert_false(_occ(_target(-0.7, 6.0)))


func test_ray_above_pole_top_does_not_occlude() -> void:
	# asker çok uzakta, ışın direğin yatay izinden geçerken direk tepesinin üstünde
	var t: Vector3 = Vector3(_base.x, 1.0, _base.z - 30.0)
	var cam: Vector3 = Vector3(_base.x, 40.0, _base.z + 10.0)
	assert_false(PoleFadeRules.occludes(cam, t, _base, Tuning.POLE_HEIGHT, Tuning.POLE_FADE_RADIUS))


func test_flat_ray_inside_height_occludes() -> void:
	var cam: Vector3 = Vector3(_base.x, 3.0, _base.z + 5.0)
	var t: Vector3 = Vector3(_base.x, 3.0, _base.z - 5.0)
	assert_true(PoleFadeRules.occludes(cam, t, _base, Tuning.POLE_HEIGHT, Tuning.POLE_FADE_RADIUS))
