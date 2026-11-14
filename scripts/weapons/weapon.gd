class_name Weapon
extends Node3D
## Otomatik silah: menzildeki en yakın zombiye kendisi nişan alıp ateş eder.
## Değerler WeaponData tablosundan.

signal fired(direction: Vector2)

const PHYSICS_PRIORITY: int = 0

var weapon_id: StringName
var enemies: EnemyManager
var projectiles: ProjectilePool

var _player: Player
var _damage: float
var _interval: float
var _range: float
var _projectile_speed: float
var _cooldown: float = 0.0


func setup(id: StringName, p_enemies: EnemyManager, p_projectiles: ProjectilePool) -> void:
	weapon_id = id
	enemies = p_enemies
	projectiles = p_projectiles
	var row: Dictionary = WeaponData.get_row(id)
	_damage = row["damage"]
	_interval = row["fire_interval"]
	_range = row["max_range"]
	_projectile_speed = row["projectile_speed"]


func _ready() -> void:
	name = "Weapon_%s" % weapon_id
	process_physics_priority = PHYSICS_PRIORITY
	_player = get_parent() as Player


func _physics_process(delta: float) -> void:
	if _player.state == Player.State.DEAD:
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	if _cooldown > 0.0:
		return
	var origin: Vector2 = _player.position_2d()
	var target: int = enemies.nearest_enemy(origin, _range)
	if target < 0:
		return
	var direction: Vector2 = Steering.seek(origin, enemies.enemy_position(target))
	if direction == Vector2.ZERO:
		return
	projectiles.fire(origin, direction, _projectile_speed, _damage, _range)
	_cooldown = _interval
	fired.emit(direction)
