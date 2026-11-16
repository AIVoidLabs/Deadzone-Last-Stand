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

	var weapon: Weapon = Weapon.new()
	weapon.setup(WeaponData.PISTOL, enemies, projectiles)
	player.add_child(weapon)

	var camera: FollowCamera = FollowCamera.new()
	camera.target = player
	camera.velocity_source = player.get_real_velocity
	add_child(camera)
	player.event.connect(func(event_name: StringName, _data: Dictionary) -> void:
		if event_name == &"hit":
			camera.add_trauma(Tuning.CAMERA_SHAKE_ON_PLAYER_HIT))

	var hud: Hud = Hud.new()
	hud.setup(player, enemies)
	add_child(hud)

	player.died.connect(GameFlow.game_over)
	Quality.apply_to_viewport(get_viewport())

	if OS.is_debug_build():
		_add_debug_tools(player, enemies, projectiles, camera)


func _add_debug_tools(player: Player, enemies: EnemyManager, projectiles: ProjectilePool, camera: FollowCamera) -> void:
	var panel: DebugPanel = DebugPanel.new()
	panel.player = player
	panel.enemies = enemies
	panel.projectiles = projectiles
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
		add_child(capture)
