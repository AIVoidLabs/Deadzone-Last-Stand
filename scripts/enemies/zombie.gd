class_name Zombie
extends Node3D
## Zombi gövdesi: yalnız konum ve yön. Can ve hareket EnemyManager'da;
## görüntü sinyalle haber alır.

signal state_changed(new_state: int, old_state: int)
signal event(event_name: StringName, data: Dictionary)

enum State { INACTIVE, CHASE, DEAD }

var state: State = State.INACTIVE


func _init() -> void:
	visible = false
	var visual: ZombieVisual = ZombieVisual.new()
	visual.name = "Visual"
	add_child(visual)


func configure(row: Dictionary) -> void:
	event.emit(&"configure", row)


func activate(at: Vector3) -> void:
	position = at
	visible = true
	reset_physics_interpolation()
	_set_state(State.CHASE)


func notify_hit(amount: float) -> void:
	event.emit(&"hit", {"amount": amount})


func kill() -> void:
	visible = false
	_set_state(State.DEAD)


func _set_state(new_state: State) -> void:
	if new_state == state:
		return
	var old: State = state
	state = new_state
	state_changed.emit(new_state, old)
