class_name RunRecorder
extends Node
## Turun sayaçlarını (RunStats) oyun sinyallerinden toplar; tur bitince özeti SaveGame'e yazar.
## Yalnız mevcut sinyallere bağlanır (ek tarama yok); sürü yolundaki maliyet olay başına bir toplamadır.
## HUD'dan ÖNCE eklenmeli: son ekran GameFlow.last_summary / last_new_records'u hazır bulsun.

var stats: RunStats
var player: Player
var enemies: EnemyManager
var weapons: WeaponRig
var director: SpawnDirector
## Kristaller kapalıyken null.
var pickups: Pickups
var loot: RunLoot


func _ready() -> void:
	name = "RunRecorder"
	stats = RunStats.new()
	GameFlow.run_stats = stats
	GameFlow.last_summary = {}
	GameFlow.last_new_records = []
	enemies.enemy_killed.connect(func(_at: Vector3, row: Dictionary) -> void:
		stats.on_kill(row.get("id", &"walker")))
	enemies.enemy_damaged.connect(func(_at: Vector3, _direction: Vector2, amount: float, _killed: bool) -> void:
		stats.on_damage_dealt(amount))
	player.event.connect(_on_player_event)
	weapons.weapon_fired.connect(func(_row: Dictionary) -> void: stats.on_shot())
	if pickups != null:
		pickups.collected.connect(stats.on_crystal)
	director.phase_changed.connect(func(_phase: WaveRun.Phase, wave_index: int) -> void:
		stats.set_wave(wave_index + 1))
	GameFlow.game_over_started.connect(_finish.bind(false), CONNECT_ONE_SHOT)
	GameFlow.victory_started.connect(_finish.bind(true), CONNECT_ONE_SHOT)


func _process(delta: float) -> void:
	if GameFlow.state == GameFlow.State.PLAYING:
		stats.tick(delta)


func _on_player_event(event_name: StringName, data: Dictionary) -> void:
	match event_name:
		&"hit", &"dot":
			stats.on_damage_taken(data.get("amount", 0.0))
		&"dash_started":
			stats.on_dash()


func _finish(won: bool) -> void:
	stats.set_level(loot.level)
	stats.set_weapons(weapons.slot_list())
	stats.finish(won)
	GameFlow.last_summary = stats.summary()
	GameFlow.last_new_records = SaveGame.record(GameFlow.last_summary)
