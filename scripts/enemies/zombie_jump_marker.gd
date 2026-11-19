class_name ZombieJumpMarker
extends RefCounted
## Zıplayan zombinin iniş işareti (yerdeki daire): ZombieVisual'in yardımcısı, işaret düğümü sahibin çocuğudur.

const MARKER_SHADER: Shader = preload("res://assets/shaders/jump_marker.gdshader")
const MARKER_HEIGHT: float = 0.03

var _owner: Node3D
var _marker: MeshInstance3D
var _age: float = 0.0
var _total: float = 1.0


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
	var radius: float = float(data["radius"]) + Tuning.PLAYER_RADIUS
	_marker.scale = Vector3(radius, 1.0, radius)
	_marker.global_position = (data["pos"] as Vector3) + Vector3(0.0, MARKER_HEIGHT, 0.0)
	return started


func tick(delta: float) -> void:
	if not is_on():
		return
	_age += delta
	var material: ShaderMaterial = _marker.material_override as ShaderMaterial
	material.set_shader_parameter(&"age", _age)
	material.set_shader_parameter(&"urgency", clampf(_age / _total, 0.0, 1.0))


func _make_marker() -> MeshInstance3D:
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(2.0, 2.0)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = MARKER_SHADER
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = plane
	instance.material_override = material
	instance.top_level = true
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.visible = false
	_owner.add_child(instance)
	return instance
