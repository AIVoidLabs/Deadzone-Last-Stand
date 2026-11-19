class_name TongueRope
extends MeshInstance3D
## Prosedürel dil: Verlet halat (RopeSim) + her karede yeniden kurulan sivrilen tüp.
## Sahip her karede set_anchor çağırır. Dangle uzunluğu varsa boştaki dil de budur (sarkar, sallanır).
## Görsel sabitler; oynanış ayarı değil.

signal reached
signal retracted

enum State { IDLE, DANGLE, SHOOTING, ATTACHED, RETRACTING }

const SHADER: Shader = preload("res://assets/shaders/tongue.gdshader")
const ROPE_POINTS: int = 20
const SAMPLES: int = 44
const RADIAL: int = 10
const CAP_RINGS: int = 4
const RADIUS_BASE: float = 0.06
const RADIUS_TIP: float = 0.018
const BULB_AT: float = 0.9
const BULB_SIZE: float = 0.014
const BULB_WIDTH: float = 0.05
const SHORT_FULL_RADIUS_LENGTH: float = 0.5
const RETRACT_TIME: float = 0.25
const OVERSHOOT: float = 0.05
const WAVE_AMP_RATIO: float = 0.2
const WAVE_AMP_MAX: float = 0.9
const WAVE_LENGTH: float = 1.5
const WAVE_LENGTH_RATIO: float = 0.5
const WAVE_LENGTH_MIN: float = 0.6
const SEED_BLEND_TIME: float = 0.08
const SEED_BLEND_RATE: float = 0.03
const DANGLE_UP_RESET_TIME: float = 0.15
const DANGLE_INIT_FORWARD: float = 0.3
const WAVE_SPEED: float = 2.0
const WAVE_VERTICAL: float = 0.4
const WHIP_AMP: float = 0.25
const ATTACH_SLACK: float = 1.05
const ATTACH_WOBBLE: float = 0.035
const ATTACH_KICK: float = 0.12
const ATTACH_KICK_DECAY: float = 5.0
const TIP_DRIVE_SHOOT: float = 0.85
const TIP_DRIVE_RAMP: float = 0.2
const GRAVITY_FLY: Vector3 = Vector3(0.0, -6.0, 0.0)
const GRAVITY_DANGLE: float = 9.0
const DANGLE_FORWARD_PUSH: float = 3.5
const DANGLE_START_DOWN: float = 0.6
const DANGLE_DAMPING: float = 0.93
const FLY_DAMPING: float = 0.96
const RETRACT_ITERATIONS: int = 16
const SHOOT_ITERATIONS: int = 24

var state: State = State.IDLE

var _sim: RopeSim = RopeSim.new()
var _anchor: Vector3 = Vector3.ZERO
var _forward: Vector3 = Vector3.RIGHT
var _target: Vector3 = Vector3.ZERO
var _t: float = 0.0
var _dur: float = 0.3
var _clock: float = 0.0
var _up_time: float = 0.0
var _retract_len: float = 0.0
var _dangle_len: float = 0.0
var _side: Vector3 = Vector3.RIGHT
## Doğrusal uçuş: uç sabit hızla ilerler (oynanıştaki dil ucuyla aynı yerde olsun diye).
var _linear: bool = false
var _mesh: ArrayMesh = ArrayMesh.new()


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	mesh = _mesh
	custom_aabb = AABB(Vector3(-200, -50, -200), Vector3(400, 100, 400))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = SHADER
	material_override = mat
	_sim.setup(Vector3.ZERO, ROPE_POINTS)
	visible = false


## Boştaki sarkan dil uzunluğu; 0 = gizli.
func set_dangle(length: float) -> void:
	_dangle_len = maxf(length, 0.0)
	if state == State.IDLE and _dangle_len > 0.0:
		_enter_dangle(true)
	elif state == State.DANGLE and _dangle_len <= 0.0:
		state = State.IDLE
		visible = false


## linear: uç sabit hızla gider (oynanış ucuyla eşleşir); değilse hızlı başlayıp yavaşlar.
func shoot(from: Vector3, to: Vector3, travel_time: float, linear: bool = false) -> void:
	_linear = linear
	_anchor = from
	_target = to
	_dur = maxf(travel_time, 0.05)
	_t = 0.0
	_clock = 0.0
	if state != State.DANGLE:
		_sim.setup(from, ROPE_POINTS)
		_sim.set_rest_length(maxf(_dangle_len, 0.05))
	_set_physics(GRAVITY_FLY, FLY_DAMPING)
	_sim.iterations = SHOOT_ITERATIONS
	var dir: Vector3 = _flat_dir(from, to)
	_side = dir.cross(Vector3.UP).normalized()
	state = State.SHOOTING
	visible = true
	_update(0.0)


## forward verilirse (sıfır değilse) sarkan dilin yönü için saklanır.
func set_anchor(from: Vector3, forward: Vector3 = Vector3.ZERO) -> void:
	_anchor = from
	if forward.length() > 0.001:
		_forward = Vector3(forward.x, 0.0, forward.z).normalized()
		if _forward.length() < 0.001:
			_forward = Vector3.RIGHT


func set_target(to: Vector3) -> void:
	_target = to


func attach() -> void:
	if state == State.IDLE or state == State.DANGLE:
		return
	state = State.ATTACHED
	_t = 0.0


func retract() -> void:
	if state == State.IDLE or state == State.DANGLE or state == State.RETRACTING:
		return
	_retract_len = _sim.rest_length()
	_sim.iterations = RETRACT_ITERATIONS
	state = State.RETRACTING
	_t = 0.0


## Anında gizle (havuza dönüş); sonraki set_dangle dili yeniden kurar.
func hide_now() -> void:
	state = State.IDLE
	visible = false


func _enter_dangle(reset: bool) -> void:
	state = State.DANGLE
	visible = true
	_set_physics(Vector3.DOWN * GRAVITY_DANGLE + _forward * DANGLE_FORWARD_PUSH, DANGLE_DAMPING)
	_sim.drive_tip(_anchor, 0.0)
	_sim.add_lateral_wave(Vector3.UP, 0.0, 1.0, 0.0)
	var pts: PackedVector3Array = _sim.points()
	_up_time = 0.0
	if reset or pts[pts.size() - 1].y > _anchor.y - 0.1:
		_sim.reset_line(_anchor, _forward * DANGLE_INIT_FORWARD + Vector3.DOWN, _dangle_len)
	_update(0.0)


func _set_physics(gravity: Vector3, damping: float) -> void:
	_sim.iterations = 8
	_sim.gravity = gravity
	_sim.damping = damping


func _process(delta: float) -> void:
	if state == State.IDLE:
		return
	_update(delta)


func _update(delta: float) -> void:
	_clock += delta
	_t += delta
	_sim.set_anchor(_anchor)
	match state:
		State.DANGLE:
			_step_dangle(delta)
		State.SHOOTING:
			_step_shooting(delta)
		State.ATTACHED:
			_step_attached(delta)
		State.RETRACTING:
			_step_retracting(delta)
	if state != State.IDLE:
		_build_mesh()


func _wave_axis() -> Vector3:
	return (_side + Vector3.UP * WAVE_VERTICAL).normalized()


func _step_dangle(delta: float) -> void:
	_sim.gravity = Vector3.DOWN * GRAVITY_DANGLE + _forward * DANGLE_FORWARD_PUSH
	_sim.set_rest_length(_dangle_len)
	var pts: PackedVector3Array = _sim.points()
	if pts[pts.size() - 1].y > _anchor.y + 0.02:
		_up_time += delta
		if _up_time > DANGLE_UP_RESET_TIME:
			_enter_dangle(true)
			return
	else:
		_up_time = 0.0
	_sim.step(delta)


func _step_shooting(delta: float) -> void:
	var u: float = clampf(_t / _dur, 0.0, 1.0)
	var dist: float = _anchor.distance_to(_target)
	var start_len: float = maxf(_dangle_len, 0.05)
	var length: float
	if _linear:
		length = lerpf(start_len, dist, u)
	else:
		var ease_out: float = 1.0 - pow(1.0 - u, 3.0)
		length = lerpf(start_len, dist, ease_out) + dist * OVERSHOOT * sin(PI * u) * u
	_sim.set_rest_length(length)
	var dir: Vector3 = (_target - _anchor).normalized()
	# Uçuş boyunca düz çizgiye güçlü çekim: hızla uzayan halat sıkışık noktalardan rastgele yöne
	# açılıp (atış başı kıvrımı) başın üstünden dolanmasın; canlılığı yanal dalga verir.
	var seed_dir: Vector3 = dir
	if _t < SEED_BLEND_TIME:
		seed_dir = _forward.slerp(dir, smoothstep(0.0, SEED_BLEND_TIME, _t))
	_sim.blend_toward_line(seed_dir, length, clampf(delta / SEED_BLEND_RATE, 0.0, 1.0))
	_sim.drive_tip(_anchor + dir * length, TIP_DRIVE_SHOOT * smoothstep(0.0, TIP_DRIVE_RAMP, u))
	var amp: float = minf(length * WAVE_AMP_RATIO, WAVE_AMP_MAX) * pow(1.0 - u, 1.3)
	_sim.add_lateral_wave(_wave_axis(), amp, maxf(length * WAVE_LENGTH_RATIO, WAVE_LENGTH_MIN), _clock * WAVE_SPEED * TAU * 0.5)
	_sim.step(delta)
	if u >= 1.0:
		state = State.ATTACHED
		_t = 0.0
		reached.emit()


func _step_attached(delta: float) -> void:
	var dist: float = _anchor.distance_to(_target)
	_sim.set_rest_length(dist * ATTACH_SLACK)
	_sim.drive_tip(_target, 1.0)
	var amp: float = ATTACH_WOBBLE + ATTACH_KICK * exp(-_t * ATTACH_KICK_DECAY)
	_sim.add_lateral_wave(_wave_axis(), amp, WAVE_LENGTH * 0.8, _clock * 14.0)
	_sim.step(delta)


func _step_retracting(delta: float) -> void:
	var u: float = clampf(_t / RETRACT_TIME, 0.0, 1.0)
	var end_len: float = maxf(_dangle_len, 0.02)
	var length: float = lerpf(end_len, _retract_len, pow(1.0 - u, 1.3))
	_sim.set_rest_length(length)
	var pts: PackedVector3Array = _sim.points()
	var tip: Vector3 = pts[pts.size() - 1]
	var dir: Vector3 = (tip - _anchor).normalized()
	_sim.drive_tip(_anchor + dir * length, 0.8 * smoothstep(0.4, 1.0, u))
	_sim.add_lateral_wave(_wave_axis(), WHIP_AMP * sin(PI * u), maxf(length * WAVE_LENGTH_RATIO, WAVE_LENGTH_MIN), -_clock * WAVE_SPEED * TAU)
	_sim.step(delta)
	if u >= 1.0:
		if _dangle_len > 0.0:
			_enter_dangle(false)
		else:
			state = State.IDLE
			visible = false
		retracted.emit()


func _flat_dir(from: Vector3, to: Vector3) -> Vector3:
	var d: Vector3 = to - from
	d.y = 0.0
	return d.normalized() if d.length() > 0.001 else Vector3.FORWARD


func _radius_at(t: float, length: float) -> float:
	var r: float = lerpf(RADIUS_BASE, RADIUS_TIP, pow(t, 0.9))
	r += BULB_SIZE * exp(-pow((t - BULB_AT) / BULB_WIDTH, 2.0))
	return r * clampf(length / SHORT_FULL_RADIUS_LENGTH, 0.35, 1.0)


## Catmull-Rom ile halat noktalarından düzgün eğri.
func _curve(pts: PackedVector3Array, f: float) -> Vector3:
	var n: int = pts.size()
	var x: float = f * float(n - 1)
	var i: int = mini(int(x), n - 2)
	var s: float = x - float(i)
	var p0: Vector3 = pts[maxi(i - 1, 0)]
	var p1: Vector3 = pts[i]
	var p2: Vector3 = pts[i + 1]
	var p3: Vector3 = pts[mini(i + 2, n - 1)]
	return 0.5 * ((2.0 * p1) + (p2 - p0) * s + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * s * s + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * s * s * s)


func _build_mesh() -> void:
	var pts: PackedVector3Array = _sim.points()
	var length: float = _sim.rest_length()
	var rings: int = SAMPLES + CAP_RINGS
	var centers: PackedVector3Array = PackedVector3Array()
	var radii: PackedFloat32Array = PackedFloat32Array()
	for i: int in SAMPLES:
		var t: float = float(i) / float(SAMPLES - 1)
		centers.append(_curve(pts, t))
		radii.append(_radius_at(t, length))
	var tip_tan: Vector3 = (centers[SAMPLES - 1] - centers[SAMPLES - 2]).normalized()
	var r_tip: float = radii[SAMPLES - 1]
	for k: int in range(1, CAP_RINGS + 1):
		var a: float = float(k) / float(CAP_RINGS) * PI * 0.5
		centers.append(centers[SAMPLES - 1] + tip_tan * (sin(a) * r_tip))
		radii.append(maxf(cos(a) * r_tip, 0.0005))
	var verts: PackedVector3Array = PackedVector3Array()
	var norms: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	# UV2.x: kökten metre (shader dokusu dilin boyuyla gerilmesin).
	var uv2s: PackedVector2Array = PackedVector2Array()
	var arc: float = 0.0
	var idx: PackedInt32Array = PackedInt32Array()
	var normal_ref: Vector3 = Vector3.UP
	var tan0: Vector3 = (centers[1] - centers[0]).normalized()
	if absf(tan0.dot(normal_ref)) > 0.95:
		normal_ref = Vector3.RIGHT
	var nrm: Vector3 = (normal_ref - tan0 * tan0.dot(normal_ref)).normalized()
	var prev_tan: Vector3 = tan0
	for i: int in rings:
		var tan: Vector3 = tan0
		if i > 0 and i < rings - 1:
			tan = (centers[i + 1] - centers[i - 1]).normalized()
		elif i == rings - 1:
			tan = (centers[i] - centers[i - 1]).normalized()
		# Paralel taşıma: önceki tanjant -> yeni tanjant dönüşü.
		var axis: Vector3 = prev_tan.cross(tan)
		if axis.length() > 0.00001:
			nrm = nrm.rotated(axis.normalized(), prev_tan.angle_to(tan))
		nrm = (nrm - tan * tan.dot(nrm)).normalized()
		prev_tan = tan
		if i > 0:
			arc += centers[i].distance_to(centers[i - 1])
		var bin: Vector3 = tan.cross(nrm)
		var v: float = minf(float(i) / float(SAMPLES - 1), 1.0)
		var cap: float = 0.0
		if i >= SAMPLES:
			cap = float(i - SAMPLES + 1) / float(CAP_RINGS) * PI * 0.5
		for j: int in RADIAL + 1:
			var ang: float = float(j) / float(RADIAL) * TAU
			var radial: Vector3 = nrm * cos(ang) + bin * sin(ang)
			verts.append(centers[i] + radial * radii[i])
			norms.append((radial * cos(cap) + tan * sin(cap)).normalized())
			uvs.append(Vector2(float(j) / float(RADIAL), v))
			uv2s.append(Vector2(arc, 0.0))
	for i: int in rings - 1:
		for j: int in RADIAL:
			var a0: int = i * (RADIAL + 1) + j
			var b0: int = a0 + RADIAL + 1
			idx.append_array([a0, b0, a0 + 1, a0 + 1, b0, b0 + 1])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = uv2s
	arrays[Mesh.ARRAY_INDEX] = idx
	_mesh.clear_surfaces()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


