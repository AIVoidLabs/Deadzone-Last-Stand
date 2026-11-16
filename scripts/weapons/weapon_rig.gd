class_name WeaponRig
extends Node3D
## Askerin silahları: en çok Tuning.WEAPON_SLOTS adet, askerin çevresinde bir çemberde süzülür.
## Dünya uzayında durur (askerin çocuğu değil); askeri biraz geriden izler, böylece süzülme hissi olur.

## Asker hareket ettikten sonra, mermiler ilerlemeden önce çalışır.
const PHYSICS_PRIORITY: int = 5

var player: Player
var enemies: EnemyManager
var projectiles: ProjectilePool

var _weapons: Array[Weapon] = []


func _ready() -> void:
	name = "Weapons"
	process_physics_priority = PHYSICS_PRIORITY


func count() -> int:
	return _weapons.size()


## Boş yuva varsa silahı takar. Dönüş: takıldı mı.
func add_weapon(id: StringName) -> bool:
	if _weapons.size() >= Tuning.WEAPON_SLOTS:
		return false
	var weapon: Weapon = Weapon.new()
	weapon.setup(id, player, enemies, projectiles)
	add_child(weapon)
	_weapons.append(weapon)
	weapon.global_position = _slot_position(_weapons.size() - 1)
	weapon.reset_physics_interpolation()
	return true


func _physics_process(delta: float) -> void:
	var weight: float = 1.0 - exp(-Tuning.WEAPON_FOLLOW_SHARPNESS * delta)
	for i: int in _weapons.size():
		var weapon: Weapon = _weapons[i]
		var target: Vector3 = _slot_position(i)
		if Tuning.FEATURE_FLOATING_WEAPONS:
			weapon.global_position = weapon.global_position.lerp(target, weight)
		else:
			weapon.global_position = target
		weapon.tick(delta)


func _slot_position(index: int) -> Vector3:
	var center: Vector3 = player.global_position
	if not Tuning.FEATURE_FLOATING_WEAPONS:
		return center + Vector3.UP * Tuning.PROJECTILE_HEIGHT
	var offset: Vector2 = WeaponSlots.offset(index, _weapons.size(), Tuning.WEAPON_ORBIT_RADIUS, deg_to_rad(Tuning.WEAPON_START_ANGLE_DEG))
	return center + Vector3(offset.x, Tuning.WEAPON_HOVER_HEIGHT, offset.y)
