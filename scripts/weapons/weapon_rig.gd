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
var _debug_index: int = 1


func _ready() -> void:
	name = "Weapons"
	process_physics_priority = PHYSICS_PRIORITY
	if Tuning.FEATURE_FLOATING_WEAPONS and Tuning.FEATURE_ENERGY_RING:
		_ring = EnergyRing.new()
		add_child(_ring)
		_place_ring()


func count() -> int:
	return _weapons.size()


## Silahı yuvaya ekler; aynı silah + aynı kademe varsa birleşir (WeaponMerge). Dönüş: kabul edildi mi
## (yuvalar doluysa ve birleşemiyorsa false).
func add_weapon(id: StringName) -> bool:
	var max_tier: int = WeaponData.max_tier() if Tuning.FEATURE_WEAPON_MERGE else 1
	var plan: Dictionary = WeaponMerge.add(_slot_list(), id, Tuning.WEAPON_SLOTS, max_tier)
	if not plan["ok"]:
		return false
	_apply(plan["slots"], plan["merged"])
	return true


## Mevcut silahları yeni yuva listesine göre eşler: aynı silah + kademe korunur (bekleme süresi bozulmaz),
## eksik olanlar yeni yaratılır, artanlar silinir.
func _apply(slots: Array[Dictionary], merged: bool = false) -> void:
	var pool: Array[Weapon] = _weapons.duplicate()
	var result: Array[Weapon] = []
	for slot: Dictionary in slots:
		var reuse: Weapon = null
		for weapon: Weapon in pool:
			if weapon.weapon_id == slot["id"] and weapon.tier == slot["tier"]:
				reuse = weapon
				break
		if reuse != null:
			pool.erase(reuse)
			result.append(reuse)
		else:
			result.append(_create(slot["id"], slot["tier"], merged))
	for leftover: Weapon in pool:
		leftover.queue_free()
	_weapons = result
	for i: int in _weapons.size():
		_weapons[i].global_position = _slot_position(i)
		_weapons[i].reset_physics_interpolation()
	if _ring != null:
		_ring.set_slot_count(_weapons.size())


func _create(id: StringName, tier: int, merged: bool) -> Weapon:
	var weapon: Weapon = Weapon.new()
	weapon.just_merged = merged
	weapon.setup(id, tier, player, enemies, projectiles)
	weapon.fired.connect(func(_direction: Vector2) -> void: weapon_fired.emit(weapon.row))
	add_child(weapon)
	return weapon


func _slot_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for weapon: Weapon in _weapons:
		list.append({"id": weapon.weapon_id, "tier": weapon.tier})
	return list


## Debug: Tuning.DEBUG_WEAPONS listesinden sırayla bir silah ekler (F7, --weapons=N).
func add_debug_weapon() -> bool:
	var list: Array[StringName] = Tuning.DEBUG_WEAPONS
	var id: StringName = list[_debug_index % list.size()]
	_debug_index += 1
	return add_weapon(id)


## Debug: yuvaları "silah:kademe" listesiyle doğrudan kurar (--tiers=pistol:1,shotgun:3).
func debug_set_slots(spec: String) -> void:
	var slots: Array[Dictionary] = []
	for part: String in spec.split(",", false):
		var bits: PackedStringArray = part.split(":")
		slots.append({"id": StringName(bits[0]), "tier": clampi(bits[1].to_int(), 1, WeaponData.max_tier())})
	_apply(slots)


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
