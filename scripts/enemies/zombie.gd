class_name Zombie
extends Node3D
## Zombi gövdesi: yalnız konum, yön ve durum bildirimi. Can, hareket ve durum geçişleri
## EnemyManager'da; görüntü sinyalle haber alır.

signal state_changed(new_state: int, old_state: int)
signal event(event_name: StringName, data: Dictionary)

var state: ZombieRules.State = ZombieRules.State.INACTIVE
## Girilen durumun süresi (sn); görüntü animasyonu buna uydurur. Süresiz durumda 0.
var state_duration: float = 0.0


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


## restart: aynı duruma yeniden girişte de haber ver (üst üste sendeleme gibi).
func enter_state(new_state: ZombieRules.State, duration: float = 0.0, restart: bool = false) -> void:
	state_duration = duration
	if new_state == state and not restart:
		return
	var old: ZombieRules.State = state
	state = new_state
	state_changed.emit(new_state, old)


func notify_hit(amount: float) -> void:
	event.emit(&"hit", {"amount": amount})


func notify_burn(on: bool) -> void:
	event.emit(&"burn", {"on": on})


## Havuza dönüş: görünmez ve durgun.
func deactivate() -> void:
	visible = false
	enter_state(ZombieRules.State.INACTIVE)
