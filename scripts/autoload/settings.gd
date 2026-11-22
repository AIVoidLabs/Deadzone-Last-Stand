extends Node
## Kullanıcı ayarları (user://settings.cfg). Şema ve doğrulama saf SettingsSchema'da.
## set_value anında uygular (changed sinyali + doğrudan uygulananlar), diske gecikmeli yazar.
## Ekran/ses/kalite gibi uygulayıcılar changed sinyalini dinler (WindowManager, Quality, AudioBuses, kamera...).
## Debug/ölçüm argümanı varken (ya da GUT) dosya okunmaz/yazılmaz, varsayılanlar kullanılır (dil tr).

signal changed(key: StringName, value: Variant)

const PATH: String = "user://settings.cfg"
const SAVE_DELAY: float = 0.6

## true: ölçüm/test çalışması; kullanıcı ayarlarına dokunulmaz.
var measurement: bool = false

var _values: Dictionary = {}
var _persistent: bool = false
var _save_pending: bool = false
var _focus_muted: bool = false
var _fps: FpsCounter


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	measurement = SettingsSchema.skips_user_settings(OS.get_cmdline_user_args(), OS.get_cmdline_args(), OS.is_debug_build())
	_persistent = Tuning.FEATURE_SETTINGS and not measurement
	_values = SettingsSchema.defaults(Tuning.FEATURE_START_FULLSCREEN, OS.has_feature("web"))
	var first_run: bool = true
	if _persistent:
		first_run = not _load()
	if first_run and _persistent:
		_values[&"game/language"] = SettingsSchema.language_for_locale(OS.get_locale())
	if not Tuning.FEATURE_LANGUAGE:
		_values[&"game/language"] = &"tr"
	Loc.set_language(_values[&"game/language"])
	apply_bindings()
	_apply_show_fps()
	if first_run and _persistent:
		_save_now()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		flush()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and _values.get(&"audio/mute_on_focus_loss", false):
		_set_focus_muted(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN and _focus_muted:
		_set_focus_muted(false)


func get_value(key: StringName) -> Variant:
	if not _values.has(key):
		push_error("Bilinmeyen ayar: %s" % key)
		return null
	return _values[key]


## Değeri şemaya uydurur, uygular, sinyal yayar, gecikmeli kaydeder. Geçersiz değer yok sayılır.
func set_value(key: StringName, value: Variant) -> void:
	if not _values.has(key):
		push_error("Bilinmeyen ayar: %s" % key)
		return
	var safe: Variant = SettingsSchema.sanitize(key, value, _values[key])
	if typeof(safe) == typeof(_values[key]) and safe == _values[key]:
		return
	_values[key] = safe
	_after_change(key)
	changed.emit(key, safe)
	_schedule_save()


func default_of(key: StringName) -> Variant:
	return SettingsSchema.defaults(Tuning.FEATURE_START_FULLSCREEN, OS.has_feature("web"))[key]


func reset_section(section: StringName) -> void:
	for key: StringName in SettingsSchema.keys_in(section):
		if key == &"game/language" and not Tuning.FEATURE_LANGUAGE:
			continue
		set_value(key, default_of(key))


func reset_all() -> void:
	for section: StringName in SettingsSchema.SECTIONS:
		reset_section(section)


## Eylem için yeni klavye tuşu (fiziksel tuş kodu). Çakışırsa iki eylem takas edilir.
## Dönüş: SettingsSchema.rebind sonucu {ok, bindings, swapped}.
func rebind(action: StringName, keycode: int) -> Dictionary:
	var result: Dictionary = SettingsSchema.rebind(_values[&"input/bindings"], action, keycode)
	if result["ok"]:
		set_value(&"input/bindings", result["bindings"])
	return result


func bindings() -> Dictionary:
	return _values[&"input/bindings"]


## Atamaları InputMap'e işler: eylemin ilk klavye olayının tuşu değişir (ok tuşları vb. kalır).
func apply_bindings() -> void:
	var map: Dictionary = bindings()
	for action: StringName in SettingsSchema.REBINDABLE:
		if not InputMap.has_action(action):
			continue
		var done: bool = false
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey and not done:
				var key: InputEventKey = event
				done = true
				if key.physical_keycode == map[action]:
					continue
				var replaced: InputEventKey = key.duplicate()
				replaced.physical_keycode = map[action] as Key
				InputMap.action_erase_event(action, key)
				InputMap.action_add_event(action, replaced)
		if not done:
			var added: InputEventKey = InputEventKey.new()
			added.physical_keycode = map[action] as Key
			InputMap.action_add_event(action, added)


func flush() -> void:
	if _save_pending:
		_save_now()


func _after_change(key: StringName) -> void:
	match key:
		&"game/language":
			Loc.set_language(_values[key])
		&"input/bindings":
			apply_bindings()
		&"display/show_fps":
			_apply_show_fps()
		&"audio/master", &"audio/sfx", &"audio/ambience", &"audio/ui":
			AudioBuses.apply_settings(_focus_muted)


func _apply_show_fps() -> void:
	var on: bool = _values[&"display/show_fps"]
	if on and _fps == null:
		_fps = FpsCounter.new()
		add_child(_fps)
	elif not on and _fps != null:
		_fps.queue_free()
		_fps = null


func _set_focus_muted(muted: bool) -> void:
	_focus_muted = muted
	AudioBuses.apply_settings(muted)


func _schedule_save() -> void:
	if not _persistent or _save_pending:
		return
	_save_pending = true
	await get_tree().create_timer(SAVE_DELAY, true, false, true).timeout
	if _save_pending:
		_save_now()


## true: geçerli bir dosya okundu.
func _load() -> bool:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(PATH) != OK:
		return false
	var raw: Dictionary = {}
	for key: StringName in SettingsSchema.keys():
		var section: String = String(SettingsSchema.section_of(key))
		var item: String = SettingsSchema.name_of(key)
		if cfg.has_section_key(section, item):
			raw[key] = cfg.get_value(section, item)
	_values = SettingsSchema.resolve(raw, _values)
	return true


func _save_now() -> void:
	_save_pending = false
	if not _persistent:
		return
	var cfg: ConfigFile = ConfigFile.new()
	for key: StringName in SettingsSchema.keys():
		var value: Variant = _values[key]
		if value is StringName:
			value = String(value)
		elif value is Dictionary:
			var plain: Dictionary = {}
			for action: Variant in value:
				plain[String(action)] = value[action]
			value = plain
		cfg.set_value(String(SettingsSchema.section_of(key)), SettingsSchema.name_of(key), value)
	if cfg.save(PATH) != OK:
		push_warning("Ayarlar yazılamadı: %s" % PATH)
