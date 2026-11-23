class_name SettingsShot
extends RefCounted
## Ayarlar ekranının görüntü aracı (UiShot) düzeni ve örnekleri. Yalnız debug.


## Ekranı host içinde kurar: opts.tab sekmeyi, opts.focus satırı seçer; --ui-demo= örneği açar.
static func build(host: Node, opts: Dictionary) -> void:
	var back: ColorRect = ColorRect.new()
	back.color = Color(0.2, 0.17, 0.15)
	UiAssets.fill(back)
	host.add_child(back)
	var menu: SettingsMenu = SettingsMenu.open(host)
	menu.show_tab(clampi(int(opts.get("tab", 0)), 0, SettingsMenu.TABS.size() - 1))
	if int(opts.get("focus", -1)) >= 0:
		menu.focus_row.call_deferred(int(opts["focus"]))
	demo.call_deferred(menu, UiShot.arg("--ui-demo=", ""))


## Örnekler: keep (geri sayım), reset (onay), rebind (tuş bekleme), swap (takas bildirimi).
static func demo(menu: SettingsMenu, kind: String) -> void:
	match kind:
		"keep":
			menu.keep_guard.open({&"display/mode": Settings.get_value(&"display/mode")})
		"reset":
			menu.ask_reset()
		"rebind", "swap":
			menu.show_tab(3)
			menu.focus_row(0)
			var row: KeyBindRow = menu.find_children("*", "KeyBindRow", true, false)[0]
			row.start_listening()
			if kind == "swap":
				var key: InputEventKey = InputEventKey.new()
				key.physical_keycode = KEY_S
				key.pressed = true
				Input.parse_input_event(key)
