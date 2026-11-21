class_name Zombie
extends Node3D
## Zombi gövdesi: yalnız konum, yön ve durum bildirimi. Can, hareket ve durum geçişleri
## EnemyManager'da; görüntü sinyalle haber alır.

signal state_changed(new_state: int, old_state: int)
signal event(event_name: StringName, data: Dictionary)
## Kovalarken gerçek yatay hız (m/sn); yalnız walk_ref_speed olan türlerde, yürüme klibi hızı için.
signal ground_speed(speed: float)

var state: ZombieRules.State = ZombieRules.State.INACTIVE
## Girilen durumun süresi (sn); görüntü animasyonu buna uydurur. Süresiz durumda 0.
var state_duration: float = 0.0


## Düğümün türü (modeli buna göre sabit); havuz türe göre tutulur.
var kind: StringName = EnemyData.WALKER


func _init(zombie_kind: StringName = EnemyData.WALKER) -> void:
	kind = zombie_kind
	visible = false
	var visual: ZombieVisual = ZombieVisual.new(EnemyData.get_row(kind)["model"])
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


## Asit topunun ağız noktası (dünya); modelde tanımlı değilse sıfır vektörü.
func mouth_position() -> Vector3:
	return ($Visual as ZombieVisual).mouth_position()


func notify_hit(amount: float) -> void:
	event.emit(&"hit", {"amount": amount})


func notify_burn(on: bool) -> void:
	event.emit(&"burn", {"on": on})


## Havuza dönüş: görünmez ve durgun.
func deactivate() -> void:
	visible = false
	enter_state(ZombieRules.State.INACTIVE)
