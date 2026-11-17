class_name WeaponRig
extends Node3D
## Askerin silahları: en çok Tuning.WEAPON_SLOTS adet, askerin çevresinde bir çemberde süzülür.
## Dünya uzayında durur (askerin çocuğu değil) ama yuvalar askere sabit bağlıdır: hangi yöne koşarsa
## koşsun silah aynı yerde kalır. Süzülme hissi yalnız görüntüdeki salınımdan gelir.

## Asker hareket ettikten sonra, mermiler ilerlemeden önce çalışır.
const PHYSICS_PRIORITY: int = 5

## Herhangi bir silah ateş edince (ses vb. için); row: silahın WeaponData satırı.
signal weapon_fired(row: Dictionary)

var player: Player
var enemies: EnemyManager
var projectiles: ProjectilePool

var _weapons: Array[Weapon] = []
var _ring: EnergyRing


func _ready() -> void:
	name = "Weapons"
	process_physics_priority = PHYSICS_PRIORITY
	if Tuning.FEATURE_FLOATING_WEAPONS and Tuning.FEATURE_ENERGY_RING:
		_ring = EnergyRing.new()
		add_child(_ring)
		_place_ring()


func count() -> int:
	return _weapons.size()


## Boş yuva varsa silahı takar. Dönüş: takıldı mı.
func add_weapon(id: StringName) -> bool:
	if _weapons.size() >= Tuning.WEAPON_SLOTS:
		return false
	var weapon: Weapon = Weapon.new()
	weapon.setup(id, player, enemies, projectiles)
	weapon.fired.connect(func(_direction: Vector2) -> void: weapon_fired.emit(weapon.row))
	add_child(weapon)
	_weapons.append(weapon)
	weapon.global_position = _slot_position(_weapons.size() - 1)
	weapon.reset_physics_interpolation()
	if _ring != null:
		_ring.set_slot_count(_weapons.size())
	return true


func _physics_process(delta: float) -> void:
	_place_ring()
	for i: int in _weapons.size():
		var weapon: Weapon = _weapons[i]
		weapon.global_position = _slot_position(i)
		weapon.tick(delta)


func _slot_position(index: int) -> Vector3:
	var center: Vector3 = player.global_position
	if not Tuning.FEATURE_FLOATING_WEAPONS:
		return center + Vector3.UP * Tuning.PROJECTILE_HEIGHT
	var offset: Vector2 = WeaponSlots.offset(index, _weapons.size(), Tuning.WEAPON_ORBIT_RADIUS, deg_to_rad(Tuning.WEAPON_START_ANGLE_DEG))
	return center + Vector3(offset.x, Tuning.WEAPON_HOVER_HEIGHT, offset.y)


func _place_ring() -> void:
	if _ring != null:
		_ring.global_position = player.global_position + Vector3.UP * (Tuning.WEAPON_HOVER_HEIGHT - Tuning.ENERGY_RING_DROP)
