class_name DilciTongue
extends Node
## Dilcinin yordamsal dili (TongueRope): ağız Head kemiğine bağlı; dururken sarkar, olaylarla fırlar,
## tutunur ve kırbaç gibi geri çekilir. Yalnız görüntü: isabet ve süreler SpecialAttacks'ta.
## Olay sözleşmesi ("tongue" olayı, BeamTongue ile aynı):
##   {"shoot": true, "to": Vector3, "time": sn, "hold": sn (eksi = olay bekler)}  ağızdan "to"ya fırlar
##   {"attach": true, "to": Vector3}  ucu askere tutunur      {"to": Vector3}  tutunulan nokta güncellenir
##   {"off": true}  geri çekilir

## Ağız noktası: modelin dinlenme pozunda (iskelet uzayı, m). Yarık çenenin arası, boğazın önü.
const MOUTH_REST: Vector3 = Vector3(0.0, 1.5, 0.46)
## Boştaki dil uzunluğu (m); hazırlıkta boğaza çekilir.
const DANGLE_LENGTH: float = 0.42
const WINDUP_DANGLE_LENGTH: float = 0.1
## Kemik pozu animasyondan sonra okunsun diye geç işlenir.
const PRIORITY: int = 50

var _rope: TongueRope
var _body: Node3D
var _skeleton: Skeleton3D
var _head: int = -1
var _mouth_local: Vector3 = Vector3.ZERO
var _hold: float = -1.0
var _hold_left: float = 0.0
var _active: bool = false


func setup(body: Node3D, skeleton: Skeleton3D) -> void:
	_body = body
	_skeleton = skeleton
	_head = skeleton.find_bone("Head")
	_mouth_local = skeleton.get_bone_global_rest(_head).affine_inverse() * MOUTH_REST
	_rope = TongueRope.new()
	_rope.process_priority = PRIORITY + 1
	add_child(_rope)
	_rope.reached.connect(_on_reached)
	process_priority = PRIORITY
	set_process(false)


## Zombi durumu: doğunca sarkar, hazırlıkta boğaza çekilir, ölünce toplanır, havuzda gizli.
func on_state(new_state: int, old_state: int) -> void:
	if new_state == ZombieRules.State.INACTIVE:
		set_active(false)
		return
	if old_state == ZombieRules.State.INACTIVE:
		set_active(true)
	if new_state == ZombieRules.State.WINDUP or old_state == ZombieRules.State.WINDUP:
		set_windup(new_state == ZombieRules.State.WINDUP)
	if new_state == ZombieRules.State.DYING:
		_rope.retract()


## Zombi doğdu (true) ya da havuza döndü (false).
func set_active(on: bool) -> void:
	_active = on
	set_process(on)
	if on:
		_follow_mouth()
		_rope.set_dangle(DANGLE_LENGTH)
	else:
		_rope.set_dangle(0.0)
		_rope.hide_now()


## Hazırlıkta dil boğaza çekilir (gırtlak şişerken), sonra yeniden sarkar.
func set_windup(on: bool) -> void:
	if _active:
		_rope.set_dangle(WINDUP_DANGLE_LENGTH if on else DANGLE_LENGTH)


func on_event(data: Dictionary) -> void:
	if not _active:
		return
	if data.get("off", false):
		_rope.retract()
		return
	if data.get("shoot", false):
		_follow_mouth()
		_hold = float(data.get("hold", -1.0))
		_hold_left = -1.0
		_rope.shoot(_mouth(), data["to"], float(data.get("time", 0.3)), true)
		return
	if data.has("to"):
		_rope.set_target(data["to"])
	if data.get("attach", false):
		_rope.attach()


func _process(delta: float) -> void:
	_follow_mouth()
	if _hold_left > 0.0:
		_hold_left -= delta
		if _hold_left <= 0.0:
			_rope.retract()


func _on_reached() -> void:
	if _hold >= 0.0:
		_hold_left = maxf(_hold, 0.001)


func _mouth() -> Vector3:
	var pose: Transform3D = _skeleton.global_transform * _skeleton.get_bone_global_pose(_head)
	return pose * _mouth_local


func _follow_mouth() -> void:
	_rope.set_anchor(_mouth(), _body.global_transform.basis.z)
