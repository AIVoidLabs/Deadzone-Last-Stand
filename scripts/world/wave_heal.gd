class_name WaveHeal
extends Node
## Dalga bitince (CLEAR) askere WaveHealRules kadar can ekler. Kapalıyken (FEATURE_WAVE_END_HEAL) kurulmaz.

var _player: Player


static func install(host: Node, player: Player, director: SpawnDirector) -> void:
	if not Tuning.FEATURE_WAVE_END_HEAL:
		return
	var node: WaveHeal = WaveHeal.new()
	node.name = "WaveHeal"
	node._player = player
	host.add_child(node)
	director.phase_changed.connect(node._on_phase_changed)


func _on_phase_changed(phase: WaveRun.Phase, _wave_index: int) -> void:
	if phase != WaveRun.Phase.CLEAR:
		return
	var health: Health = _player.health
	health.heal(WaveHealRules.bonus(health.current, health.maximum, Tuning.WAVE_END_HEAL_FACTOR))
