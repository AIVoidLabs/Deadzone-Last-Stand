extends Node3D
## Ana sahne: dünyayı kodla kurar ve parçaları birbirine bağlar.


func _ready() -> void:
	add_child(Arena.new())

	var player: Player = Player.new()
	add_child(player)

	var enemies: EnemyManager = EnemyManager.new()
	enemies.player = player
	add_child(enemies)

	var projectiles: ProjectilePool = ProjectilePool.new()
	projectiles.enemies = enemies
	add_child(projectiles)
	if Tuning.FEATURE_IMPACT_SPARKS:
		var sparks: ImpactSparks = ImpactSparks.new()
		add_child(sparks)
		projectiles.impact.connect(sparks.burst)

	var weapons: WeaponRig = WeaponRig.new()
	weapons.player = player
	weapons.enemies = enemies
	weapons.projectiles = projectiles
	add_child(weapons)
	weapons.add_weapon(WeaponData.PISTOL)

	var camera: FollowCamera = FollowCamera.new()
	camera.target = player
	camera.velocity_source = player.get_real_velocity
	add_child(camera)
	player.event.connect(func(event_name: StringName, _data: Dictionary) -> void:
		if event_name == &"hit":
			camera.add_trauma(Tuning.CAMERA_SHAKE_ON_PLAYER_HIT))

	_add_hit_feedback(enemies, camera)

	var hud: Hud = Hud.new()
	hud.setup(player, enemies)
	add_child(hud)

	player.died.connect(GameFlow.game_over)
	Quality.apply_to_viewport(get_viewport())

	if OS.is_debug_build():
		_add_debug_tools(player, enemies, projectiles, camera, weapons)


## Vuruş geri bildirimi: kan, lekeler, hasar sayıları, öldürmede duraksama ve sarsıntı.
func _add_hit_feedback(enemies: EnemyManager, camera: FollowCamera) -> void:
	if Tuning.FEATURE_BLOOD:
		var blood: BloodFx = BloodFx.new()
		add_child(blood)
		enemies.enemy_damaged.connect(blood.on_enemy_damaged)
	if Tuning.FEATURE_DAMAGE_NUMBERS:
		var numbers: DamageNumbers = DamageNumbers.new()
		add_child(numbers)
		enemies.enemy_damaged.connect(numbers.on_enemy_damaged)
	enemies.enemy_damaged.connect(func(_at: Vector3, _dir: Vector2, _amount: float, killed: bool) -> void:
		if not killed:
			return
		GameFlow.hit_stop(Tuning.HIT_STOP_KILL_TIME)
		if Tuning.FEATURE_KILL_SHAKE:
			camera.add_trauma(Tuning.CAMERA_SHAKE_ON_KILL))


func _add_debug_tools(player: Player, enemies: EnemyManager, projectiles: ProjectilePool, camera: FollowCamera, weapons: WeaponRig) -> void:
	var panel: DebugPanel = DebugPanel.new()
	panel.player = player
	panel.enemies = enemies
	panel.projectiles = projectiles
	panel.weapons = weapons
	add_child(panel)
	if Benchmark.requested():
		var bench: Benchmark = Benchmark.new()
		bench.player = player
		bench.enemies = enemies
		add_child(bench)
	elif Capture.requested():
		var capture: Capture = Capture.new()
		capture.player = player
		capture.enemies = enemies
		capture.debug_panel = panel
		capture.camera = camera
		capture.weapons = weapons
		add_child(capture)
