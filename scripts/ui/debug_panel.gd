class_name DebugPanel
extends CanvasLayer
## F3 debug paneli ve debug tuşları. Yalnız debug yapıda eklenir (main.gd).

const LAYER: int = 10
const POSITION: Vector2 = Vector2(16.0, 52.0)
const FONT_SIZE: int = 15

var player: Player
var enemies: EnemyManager
var projectiles: ProjectilePool
var weapons: WeaponRig

var _panel: PanelContainer
var _label: Label
var _refresh_left: float = 0.0


func _ready() -> void:
	name = "DebugPanel"
	layer = LAYER
	_panel = PanelContainer.new()
	_panel.position = POSITION
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	add_child(_panel)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_panel.add_child(_label)


func set_panel_visible(value: bool) -> void:
	_panel.visible = value
	_refresh_left = 0.0


func _unhandled_input(input_event: InputEvent) -> void:
	if input_event.is_action_pressed(&"toggle_debug"):
		set_panel_visible(not _panel.visible)
	elif input_event.is_action_pressed(&"debug_spawn"):
		enemies.spawn_many(Tuning.DEBUG_SPAWN_BATCH)
	elif input_event.is_action_pressed(&"debug_god"):
		player.god_mode = not player.god_mode
	elif input_event.is_action_pressed(&"debug_quality"):
		Quality.cycle()
	elif input_event.is_action_pressed(&"debug_weapon"):
		weapons.add_weapon(Tuning.DEBUG_WEAPON)


func _process(delta: float) -> void:
	if not _panel.visible:
		return
	_refresh_left -= delta
	if _refresh_left > 0.0:
		return
	_refresh_left = Tuning.DEBUG_PANEL_REFRESH
	_label.text = _build_text()


func _build_text() -> String:
	var frame_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var physics_ms: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var draw_calls: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var lines: PackedStringArray = PackedStringArray([
		"FPS %d   işlem %.2f ms   fizik %.2f ms" % [Engine.get_frames_per_second(), frame_ms, physics_ms],
		"Zombi %d / %d (havuz %d)" % [enemies.active_count(), Quality.max_enemies(), enemies.pool_size()],
		"Mermi %d   draw call %d   silah %d / %d" % [projectiles.active_count(), draw_calls, weapons.count(), Tuning.WEAPON_SLOTS],
		"Can %.0f / %.0f   ölümsüz %s" % [player.health.current, player.health.maximum, "AÇIK" if player.god_mode else "kapalı"],
		"Profil %s" % Quality.current,
		"F4 +%d zombi · F5 ölümsüz · F6 profil · F7 +silah" % Tuning.DEBUG_SPAWN_BATCH,
		"(Fn gerekmeden: Ctrl+3 … Ctrl+7 aynı sırayla)",
	])
	return "\n".join(lines)
