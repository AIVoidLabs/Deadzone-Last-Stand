class_name BossMind
extends RefCounted
## Boss'un çalışma zamanı durumu (BossAttack'in tek örnek verisi): saldırı geçmişi, bekleme süreleri, öfke, hücum isabet kayıtları.

## Şu anki ve bir önceki saldırı (tekrarsız seçim için).
var attack: BossRules.Attack = BossRules.Attack.NONE
var last: BossRules.Attack = BossRules.Attack.NONE
## Saldırılar arası bekleme (yalnız CHASE'de akar) ve çağrının kalan bekleme süresi (her karede akar).
var pause_left: float = 0.0
var summon_left: float = 0.0
## Öfke: can eşiğinin altına inildi (kükreme bekliyor) / kükreme başladı.
var rage_pending: bool = false
var raged: bool = false
## Yer dövmesinin sıradaki halkaları: kalan halka sayısı ve sonraki halkaya kalan süre.
var rings_left: int = 0
var ring_gap_left: float = 0.0
## Hücum: asker bu hücumda vuruldu mu, vurulan zombi düğümleri (her zombi bir kez).
var charge_hit_player: bool = false
var charge_hit_nodes: Dictionary = {}
## Hücum izi toz zamanlayıcısı.
var dust_left: float = 0.0


func _init(row: Dictionary) -> void:
	pause_left = float(row["boss_pause"])
	summon_left = float(row["summon_first_delay"])
