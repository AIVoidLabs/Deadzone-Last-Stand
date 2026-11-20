class_name Player
extends CharacterBody3D
## Asker: hareket, dash, can, durum. Görüntüye dokunmaz; sinyalle haber verir.

signal state_changed(new_state: int, old_state: int)
signal event(event_name: StringName, data: Dictionary)
signal died

enum State { IDLE, MOVE, DASH, DEAD }

var state: State = State.IDLE
## Kartlardan gelen artışlar; temel değerler Tuning'de.
var stats: PlayerStats = PlayerStats.new()
var health: Health = Health.new(Tuning.PLAYER_MAX_HP)
var dash: Dash = Dash.new(Tuning.DASH_DURATION, Tuning.DASH_COOLDOWN)
## XZ düzleminde bakış yönü (Vector2.y = dünya Z).
var facing: Vector2 = Vector2(0.0, 1.0)
var god_mode: bool = false
## Debug/benchmark için klavye yerine kullanılan yön.
var use_input_override: bool = false
var input_override: Vector2 = Vector2.ZERO

var _iframes_left: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO
var _dash_requested: bool = false
## Vurulunca aldığı itme hızı (XZ); kendiliğinden söner.
var _knock: Vector2 = Vector2.ZERO
## Dilciyle bağlıyken kalan süre (sn): hareket ve dash yok, silahlar çalışır.
var _root_left: float = 0.0
var _rooted: bool = false
## Bağlıyken dilcinin bu kare uyguladığı çekiş hızı (XZ); her karede yeniden verilir.
var _pull: Vector2 = Vector2.ZERO


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
	stats.changed.connect(_on_stat_changed)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_iframes_left = maxf(0.0, _iframes_left - delta)
	health.heal(stats.regen_per_second() * delta)
	var input: Vector2 = _read_input()
	if _rooted:
		_root_left -= delta
		input = Vector2.ZERO
		if _root_left <= 0.0:
			release_root()
	if dash.tick(delta):
		_end_dash()
	if _wants_dash():
		_try_start_dash(input)
	var planar: Vector2
	if dash.is_active():
		planar = _dash_direction * stats.dash_speed()
	elif _rooted:
		# Dil çekerken: yürüme yok, asker dilciye dönük sürüklenir.
		planar = _pull + _knock
		if _pull != Vector2.ZERO:
			facing = _pull.normalized()
		_pull = Vector2.ZERO
		_knock = Knockback.decay(_knock, Tuning.PLAYER_KNOCKBACK_DAMPING, delta)
	else:
		planar = Locomotion.step(
			Vector2(velocity.x, velocity.z), input, stats.move_speed(), Tuning.PLAYER_ACCEL, Tuning.PLAYER_FRICTION, delta)
		if input != Vector2.ZERO:
			facing = input.normalized()
		planar += _knock
		_knock = Knockback.decay(_knock, Tuning.PLAYER_KNOCKBACK_DAMPING, delta)
	velocity = Vector3(planar.x, 0.0, planar.y)
	move_and_slide()
	global_position.y = 0.0
	if not dash.is_active():
		_set_state(State.MOVE if planar.length_squared() > 0.01 else State.IDLE)


func planar_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func position_2d() -> Vector2:
	return Vector2(global_position.x, global_position.z)


func is_dashing() -> bool:
	return state == State.DASH


func is_hittable() -> bool:
	return is_exposed() and not god_mode


## Dash, dokunulmazlık payı ve ölüm dışında vurulabilir durumda (ölümsüz modu hariç tutmadan; ölçümler için).
func is_exposed() -> bool:
	return state != State.DEAD and state != State.DASH and _iframes_left <= 0.0


## Klavye dışından dash isteği (debug araçları).
func request_dash() -> void:
	_dash_requested = true


## push: vuruşun geldiği yönde itme (zombiden askere); sıfırsa itilmez.
func take_hit(amount: float, push: Vector2 = Vector2.ZERO) -> void:
	if not is_hittable():
		return
	if Tuning.FEATURE_PLAYER_KNOCKBACK:
		_knock = Knockback.impulse(push, Tuning.PLAYER_HIT_KNOCKBACK, 1.0)
	var dealt: float = health.take_damage(CombatMath.mitigate(amount, stats.armor()))
	if Tuning.FEATURE_PLAYER_IFRAMES:
		_iframes_left = Tuning.PLAYER_HIT_IFRAMES
	event.emit(&"hit", {"amount": dealt, "hp": health.current, "iframes": _iframes_left})
	_die_if_dead()


## Sürekli hasar (asit havuzu): zırh azaltması uygulanır; dokunulmazlık vermez, itme ve vurulma animasyonu yok
## (`dot` olayı: yalnız hafif ekran kızarması). Dash ve dokunulmazlıkta hasar yok.
func take_dot(amount: float) -> void:
	if not is_hittable():
		return
	var dealt: float = health.take_damage(CombatMath.mitigate(amount, stats.armor()))
	event.emit(&"dot", {"amount": dealt, "hp": health.current})
	_die_if_dead()


func _die_if_dead() -> void:
	if health.is_dead():
		_rooted = false
		_set_state(State.DEAD)
		died.emit()


## Dilci askeri duration sn bağlar. Dash ya da dokunulmazlık payı sırasında tutmaz.
func root(duration: float) -> void:
	if not is_exposed() or not Tuning.FEATURE_ROOT:
		return
	_root_left = duration
	_rooted = true
	velocity = Vector3.ZERO
	_knock = Vector2.ZERO
	event.emit(&"rooted", {"duration": duration})


## Bağlıyken bu karenin çekiş hızı (m/sn, XZ); dilci her karede verir, verilmezse asker durur.
func pull(planar_velocity: Vector2) -> void:
	if _rooted:
		_pull = planar_velocity


## Bağ çözülür. broke_free=false: asker kendini koparmadı (dilci ısırıp bıraktı), break_free klibi oynamaz.
func release_root(broke_free: bool = true) -> void:
	if not _rooted:
		return
	_rooted = false
	_pull = Vector2.ZERO
	_root_left = 0.0
	event.emit(&"released", {"broke_free": broke_free})


func is_rooted() -> bool:
	return _rooted


func _wants_dash() -> bool:
	var wanted: bool = _dash_requested or (not use_input_override and Input.is_action_just_pressed(&"dash"))
	_dash_requested = false
	return wanted and Tuning.FEATURE_DASH and not _rooted


func _try_start_dash(input: Vector2) -> void:
	if not dash.start():
		return
	_dash_direction = input.normalized() if input != Vector2.ZERO else facing
	facing = _dash_direction
	_set_state(State.DASH)
	event.emit(&"dash_started", {"duration": Tuning.DASH_DURATION, "direction": _dash_direction})


func _end_dash() -> void:
	# Dash biter bitmez yakalanmasın diye kısa bir dokunulmazlık payı.
	_iframes_left = maxf(_iframes_left, Tuning.DASH_EXIT_IFRAMES)
	velocity = Vector3(_dash_direction.x, 0.0, _dash_direction.y) * stats.move_speed()
	_set_state(State.MOVE)
	event.emit(&"dash_ended", {})


func _on_stat_changed(stat: StringName, amount: float) -> void:
	match stat:
		StatData.MAX_HP:
			health.raise_maximum(amount)
		StatData.DASH_COOLDOWN:
			dash.cooldown = stats.dash_cooldown()


func _read_input() -> Vector2:
	var v: Vector2 = input_override if use_input_override else Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	return v.limit_length(1.0)


func _set_state(new_state: State) -> void:
	if new_state == state:
		return
	var old: State = state
	state = new_state
	state_changed.emit(new_state, old)
