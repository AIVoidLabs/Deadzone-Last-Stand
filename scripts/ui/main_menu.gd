class_name MainMenu
extends Control
## GEÇİCİ ÇEKİRDEK STUB'I: tek düğme, GameFlow.start_run'ı çağırır. Menü ajanı bu dosyanın yerine gerçek menüyü yazar.


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var play: Button = Button.new()
	play.text = Loc.t(&"common.play")
	play.custom_minimum_size = Vector2(240.0, 64.0)
	play.pressed.connect(GameFlow.start_run)
	center.add_child(play)
	play.grab_focus()


## Görüntü aracı (UiShot) için: ekranı host içinde kurar.
static func ui_shot(host: Node, _opts: Dictionary) -> void:
	host.add_child(MainMenu.new())
