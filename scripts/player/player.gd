class_name Player
extends CharacterBody3D
## Asker: hareket, can, durum. Görüntüye dokunmaz; sinyalle haber verir.

signal state_changed(new_state: int, old_state: int)
signal event(event_name: StringName, data: Dictionary)
signal died

enum State { IDLE, MOVE, DEAD }

var state: State = State.IDLE
var health: Health = Health.new(Tuning.PLAYER_MAX_HP)
## XZ düzleminde bakış yönü (Vector2.y = dünya Z).
var facing: Vector2 = Vector2(0.0, 1.0)
var god_mode: bool = false
## Debug/benchmark için klavye yerine kullanılan yön.
var use_input_override: bool = false
var input_override: Vector2 = Vector2.ZERO

var _iframes_left: float = 0.0


func _init() -> void:
	name = "Player"
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var shape: CapsuleShape3D = CapsuleShape3D.new()
	shape.radius = Tuning.PLAYER_RADIUS
	shape.height = Tuning.PLAYER_HEIGHT
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	collision.position.y = Tuning.PLAYER_HEIGHT * 0.5
	add_child(collision)
	var visual: PlayerVisual = PlayerVisual.new()
	visual.name = "Visual"
	add_child(visual)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_iframes_left = maxf(0.0, _iframes_left - delta)
	var input: Vector2 = _read_input()
	var planar: Vector2 = Vector2(velocity.x, velocity.z)
	var rate: float = Tuning.PLAYER_ACCEL if input != Vector2.ZERO else Tuning.PLAYER_FRICTION
	planar = planar.move_toward(input * Tuning.PLAYER_SPEED, rate * delta)
	velocity = Vector3(planar.x, 0.0, planar.y)
	move_and_slide()
	global_position.y = 0.0
	if input != Vector2.ZERO:
		facing = input.normalized()
	_set_state(State.MOVE if planar.length_squared() > 0.01 else State.IDLE)


func position_2d() -> Vector2:
	return Vector2(global_position.x, global_position.z)


func is_hittable() -> bool:
	return state != State.DEAD and _iframes_left <= 0.0 and not god_mode


func take_hit(amount: float) -> void:
	if not is_hittable():
		return
	var dealt: float = health.take_damage(CombatMath.mitigate(amount, Tuning.PLAYER_ARMOR))
	if Tuning.FEATURE_PLAYER_IFRAMES:
		_iframes_left = Tuning.PLAYER_HIT_IFRAMES
	event.emit(&"hit", {"amount": dealt, "hp": health.current, "iframes": _iframes_left})
	if health.is_dead():
		_set_state(State.DEAD)
		died.emit()


func _read_input() -> Vector2:
	var v: Vector2 = input_override if use_input_override else Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	return v.limit_length(1.0)


func _set_state(new_state: State) -> void:
	if new_state == state:
		return
	var old: State = state
	state = new_state
	state_changed.emit(new_state, old)
