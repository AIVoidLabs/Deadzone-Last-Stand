extends GutTest

const COUNT: int = 20
const ANCHOR: Vector3 = Vector3(0.0, 1.5, 0.0)


func _rope(length: float) -> RopeSim:
	var r: RopeSim = RopeSim.new()
	r.setup(ANCHOR, COUNT)
	r.set_rest_length(length)
	return r


func _run(r: RopeSim, steps: int) -> void:
	for _i: int in steps:
		r.step(1.0 / 60.0)


func test_segments_stay_near_rest() -> void:
	var r: RopeSim = _rope(3.0)
	r.drive_tip(ANCHOR + Vector3(3.0, 0.0, 0.0), 1.0)
	_run(r, 120)
	var pts: PackedVector3Array = r.points()
	var seg: float = 3.0 / float(COUNT - 1)
	for i: int in COUNT - 1:
		assert_almost_eq(pts[i].distance_to(pts[i + 1]), seg, seg * 0.35)


func test_driven_tip_reaches_target() -> void:
	var r: RopeSim = _rope(4.0)
	var target: Vector3 = ANCHOR + Vector3(2.0, -0.5, 2.0)
	r.drive_tip(target, 1.0)
	_run(r, 60)
	assert_lt(r.points()[COUNT - 1].distance_to(target), 0.05)


func test_shortening_returns_to_anchor() -> void:
	var r: RopeSim = _rope(4.0)
	r.drive_tip(ANCHOR + Vector3(4.0, 0.0, 0.0), 1.0)
	_run(r, 60)
	r.drive_tip(ANCHOR, 0.0)
	r.set_rest_length(0.0)
	_run(r, 120)
	for p: Vector3 in r.points():
		assert_lt(p.distance_to(ANCHOR), 0.2)


func test_wave_displaces_middle_not_anchor() -> void:
	var r: RopeSim = _rope(4.0)
	r.gravity = Vector3.ZERO
	r.drive_tip(ANCHOR + Vector3(4.0, 0.0, 0.0), 1.0)
	_run(r, 60)
	r.add_lateral_wave(Vector3(0.0, 0.0, 1.0), 0.3, 2.0, 0.0)
	r.step(1.0 / 60.0)
	var pts: PackedVector3Array = r.points()
	assert_eq(pts[0], ANCHOR)
	var max_z: float = 0.0
	for i: int in range(5, 15):
		max_z = maxf(max_z, absf(pts[i].z))
	assert_gt(max_z, 0.1)


func test_blend_toward_line_straightens() -> void:
	var r: RopeSim = _rope(2.0)
	r.reset_line(ANCHOR, Vector3.DOWN, 2.0)
	r.blend_toward_line(Vector3.RIGHT, 2.0, 1.0)
	assert_almost_eq(r.count(), COUNT, 0)
	r.step(1.0 / 60.0)
	assert_gt(r.points()[COUNT - 1].x, 1.5)


func test_dangle_hangs_and_lags_anchor() -> void:
	var r: RopeSim = _rope(0.5)
	r.reset_line(ANCHOR, Vector3(1.0, -0.5, 0.0), 0.5)
	_run(r, 60)
	var tip: Vector3 = r.points()[COUNT - 1]
	assert_lt(tip.y, ANCHOR.y - 0.3)
	r.set_anchor(ANCHOR + Vector3(0.0, 0.0, 1.0))
	r.step(1.0 / 60.0)
	assert_lt(r.points()[COUNT - 1].z, 0.5)
