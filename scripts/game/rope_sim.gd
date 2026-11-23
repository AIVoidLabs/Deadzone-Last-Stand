class_name RopeSim
extends RefCounted
## Saf Verlet halat: nokta 0 sabit çapa, segment uzunluğu gevşetme, yerçekimi, sönüm.
## Düğüm ve autoload bilmez; dil, ip ve benzeri görseller kullanır.

const DEFAULT_COUNT: int = 20
const MIN_LENGTH: float = 0.001
const WAVE_ENVELOPE_END: float = 0.35

var gravity: Vector3 = Vector3(0.0, -6.0, 0.0)
var damping: float = 0.96
var iterations: int = 8

var _pos: PackedVector3Array = PackedVector3Array()
var _prev: PackedVector3Array = PackedVector3Array()
var _out: PackedVector3Array = PackedVector3Array()
var _anchor: Vector3 = Vector3.ZERO
var _rest_total: float = 1.0
var _tip_target: Vector3 = Vector3.ZERO
var _tip_weight: float = 0.0
var _wave_axis: Vector3 = Vector3.ZERO
var _wave_amp: float = 0.0
var _wave_len: float = 1.0
var _wave_phase: float = 0.0


func setup(anchor: Vector3, point_count: int = DEFAULT_COUNT) -> void:
	_anchor = anchor
	_pos.resize(maxi(point_count, 2))
	_prev.resize(_pos.size())
	_out.resize(_pos.size())
	for i: int in _pos.size():
		_pos[i] = anchor
		_prev[i] = anchor
		_out[i] = anchor
	_tip_weight = 0.0
	_wave_amp = 0.0


## Noktaları çapadan dir yönünde düz bir çizgiye dizer (hız sıfır).
func reset_line(anchor: Vector3, dir: Vector3, length: float) -> void:
	_anchor = anchor
	_rest_total = maxf(length, MIN_LENGTH)
	var d: Vector3 = dir.normalized() if dir.length() > 0.0001 else Vector3.DOWN
	for i: int in _pos.size():
		var p: Vector3 = anchor + d * (_rest_total * float(i) / float(_pos.size() - 1))
		_pos[i] = p
		_prev[i] = p
		_out[i] = p
	_tip_weight = 0.0
	_wave_amp = 0.0


## Noktaları çapadan dir yönündeki düz çizgiye doğru amount kadar yaklaştırır (hızı korur).
func blend_toward_line(dir: Vector3, length: float, amount: float) -> void:
	var d: Vector3 = dir.normalized()
	for i: int in range(1, _pos.size()):
		var goal: Vector3 = _anchor + d * (length * float(i) / float(_pos.size() - 1))
		var shift: Vector3 = (goal - _pos[i]) * amount
		_pos[i] += shift
		_prev[i] += shift


func set_anchor(p: Vector3) -> void:
	_anchor = p


func set_rest_length(total: float) -> void:
	_rest_total = maxf(total, MIN_LENGTH)


func rest_length() -> float:
	return _rest_total


## Uç noktayı hedefe çeker; weight 0 = serbest, 1 = sabitlenmiş.
func drive_tip(target: Vector3, weight: float) -> void:
	_tip_target = target
	_tip_weight = clampf(weight, 0.0, 1.0)


## Uzunlamasına zarf: çapada 0, ucuna doğru tam genlik. Genlik 0 dalgayı kapatır.
func add_lateral_wave(axis: Vector3, amplitude: float, wavelength: float, phase: float) -> void:
	_wave_axis = axis
	_wave_amp = amplitude
	_wave_len = maxf(wavelength, MIN_LENGTH)
	_wave_phase = phase


func count() -> int:
	return _pos.size()


func step(delta: float) -> void:
	if _pos.size() < 2:
		return
	var dt: float = clampf(delta, 0.0001, 0.05)
	_integrate(dt)
	var seg: float = _rest_total / float(_pos.size() - 1)
	for _it: int in iterations:
		_relax(seg)
	_build_output()


func points() -> PackedVector3Array:
	return _out


func _integrate(dt: float) -> void:
	_pos[0] = _anchor
	_prev[0] = _anchor
	for i: int in range(1, _pos.size()):
		var vel: Vector3 = (_pos[i] - _prev[i]) * damping
		_prev[i] = _pos[i]
		_pos[i] += vel + gravity * dt * dt


func _relax(seg: float) -> void:
	var last: int = _pos.size() - 1
	_pos[0] = _anchor
	var tip_inv: float = 1.0 - _tip_weight
	for i: int in last:
		var a: Vector3 = _pos[i]
		var b: Vector3 = _pos[i + 1]
		var d: Vector3 = b - a
		var seg_len: float = d.length()
		if seg_len < 0.00001:
			continue
		var diff: float = (seg_len - seg) / seg_len
		var wa: float = 0.0 if i == 0 else 1.0
		var wb: float = tip_inv if i + 1 == last else 1.0
		var total: float = wa + wb
		if total <= 0.0:
			continue
		_pos[i] = a + d * diff * (wa / total)
		_pos[i + 1] = b - d * diff * (wb / total)
	if _tip_weight > 0.0:
		_pos[last] = _pos[last].lerp(_tip_target, _tip_weight)


func _build_output() -> void:
	var n: int = _pos.size()
	for i: int in n:
		var p: Vector3 = _pos[i]
		if _wave_amp != 0.0 and i > 0:
			var t: float = float(i) / float(n - 1)
			var env: float = smoothstep(0.0, WAVE_ENVELOPE_END, t)
			var arg: float = TAU * (t * _rest_total / _wave_len) - _wave_phase
			p += _wave_axis * (_wave_amp * env * sin(arg))
		_out[i] = p
