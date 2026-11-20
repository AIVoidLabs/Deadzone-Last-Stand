class_name ZombieJumpMarker
extends RefCounted
## Zıplayan zombinin iniş işareti (yerdeki daire): ZombieVisual'in yardımcısı, işaret düğümü sahibin çocuğudur.

const MARKER_SHADER: Shader = preload("res://assets/shaders/jump_marker.gdshader")
const SHADOW_SHADER: Shader = preload("res://assets/shaders/jump_shadow.gdshader")
const MARKER_HEIGHT: float = 0.03

var _owner: Node3D
var _marker: MeshInstance3D
var _age: float = 0.0
var _total: float = 1.0
var _lock_at: float = 0.0


func _init(owner: Node3D) -> void:
	_owner = owner


func is_on() -> bool:
	return _marker != null and _marker.visible


func hide_marker() -> void:
	if _marker != null:
		_marker.visible = false


## "marker" olayı. Dönüş: işaret bu çağrıda yeni göründüyse true (sahip _process'i açmalı).
func on_event(data: Dictionary, row: Dictionary) -> bool:
	if not data["on"]:
		hide_marker()
		return false
	if _marker == null:
		_marker = _make_marker()
	var started: bool = not _marker.visible
	if started:
		_age = 0.0
		_total = float(row.get("attack_windup", 0.7)) + float(row.get("jump_time", 0.9))
		_marker.visible = true
		# Yeniden kullanılan düğüm ilk karede önceki zıplamanın en koyu halini göstermesin.
		_apply(0.0, 0.0)
	var radius: float = float(data["radius"]) + Tuning.PLAYER_RADIUS
	_lock_at = maxf(float(row.get("attack_windup", 0.7)) - float(row.get("jump_lock_time", 0.3)), 0.0)
	_marker.scale = Vector3(radius, 1.0, radius)
	_marker.global_position = (data["pos"] as Vector3) + Vector3(0.0, MARKER_HEIGHT, 0.0)
	return started


func tick(delta: float) -> void:
	if not is_on():
		return
	_age += delta
	# Kilit anından sonra kenar çizgisi bir kez nabız atar (1 → 0).
	var since: float = _age - _lock_at
	var pulse: float = 0.0
	if since >= 0.0 and since < Tuning.JUMP_SHADOW_LOCK_PULSE_TIME:
		pulse = 1.0 - since / Tuning.JUMP_SHADOW_LOCK_PULSE_TIME
	_apply(clampf(_age / _total, 0.0, 1.0), pulse)


func _apply(urgency: float, pulse: float) -> void:
	var material: ShaderMaterial = _marker.material_override as ShaderMaterial
	material.set_shader_parameter(&"urgency", urgency)
	if Tuning.FEATURE_JUMP_SHADOW_MARKER:
		material.set_shader_parameter(&"lock_pulse", pulse)
	else:
		material.set_shader_parameter(&"age", _age)


func _make_marker() -> MeshInstance3D:
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(2.0, 2.0)
	var material: ShaderMaterial = ShaderMaterial.new()
	if Tuning.FEATURE_JUMP_SHADOW_MARKER:
		material.shader = SHADOW_SHADER
		material.set_shader_parameter(&"max_darkness", Tuning.JUMP_SHADOW_DARKNESS)
		material.set_shader_parameter(&"soft_start", Tuning.JUMP_SHADOW_SOFT_START)
		material.set_shader_parameter(&"soft_end", Tuning.JUMP_SHADOW_SOFT_END)
		material.set_shader_parameter(&"edge_width", Tuning.JUMP_SHADOW_EDGE_WIDTH)
		material.set_shader_parameter(&"edge_strength", Tuning.JUMP_SHADOW_EDGE_STRENGTH)
	else:
		material.shader = MARKER_SHADER
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = plane
	instance.material_override = material
	instance.top_level = true
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.visible = false
	_owner.add_child(instance)
	return instance
