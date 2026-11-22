class_name GrungeCard
extends Button
## Kanlı afiş kartı: kategori renginde alev zemini, amblem, fırça şeridinde ad, siyah lekede açıklama.
## setup(data) anahtarları (hepsi isteğe bağlı): category_id, category, title, emblem, lines [{text, color?, bold?}],
## tier (-1 yok), tier_name, hint, price (-1 yok), price_color, state (ok|poor|full|sold), state_text, locked, compact.

const DEFAULT_SIZE: Vector2 = Vector2(290, 430)
const REF_HEIGHT: float = 430.0
const MIN_FONT: int = 12
# Yerleşim (kart boyutunun kesirleri)
const CAT_RECT: Rect2 = Rect2(0.15, 0.03, 0.70, 0.075)
const EMBLEM_RECT: Rect2 = Rect2(0.13, 0.10, 0.74, 0.41)
const BAND_RECT: Rect2 = Rect2(0.025, 0.545, 0.95, 0.135)
const BLOT_RECT: Rect2 = Rect2(0.03, 0.685, 0.94, 0.295)
const LINES_RECT: Rect2 = Rect2(0.10, 0.705, 0.80, 0.19)
const STATE_RECT: Rect2 = Rect2(0.03, 0.385, 0.94, 0.125)
const HALO_CENTER: Vector2 = Vector2(0.5, 0.30)
const BAND_MASKS: Array[String] = ["band_a", "band_b", "band_c"]
const SPLAT_MASKS: Array[String] = ["splat_0", "splat_1", "splat_2", "splat_3"]
const TIER_INTENSITY: Array[float] = [0.82, 0.95, 1.08, 1.22]
const TIER_RIM: Array[float] = [0.3, 0.55, 0.75, 0.95]
const HOVER_LIFT: float = 16.0
const HOVER_SCALE: float = 0.05
const HOVER_TILT_DEG: float = -1.3
const HOVER_TIME: float = 0.16
const EMBLEM_GROW: float = 0.09
const INTRO_OFFSET: float = 240.0
const INTRO_TIME: float = 0.46
const PRESS_DROP: float = 0.04
const STATE_TILT_DEG: float = -5.0
const TITLE_SIZE: int = 24
const CATEGORY_SIZE: int = 15
const BODY_SIZE: int = 14

@export var card_size: Vector2 = DEFAULT_SIZE:
	set(v):
		card_size = v
		custom_minimum_size = v

var _data: Dictionary = {}
var _built: bool = false
var _visual: Control = null
var _shadow: TextureRect = null
var _bg: ColorRect = null
var _bg_mat: ShaderMaterial = null
var _splat: TextureRect = null
var _emblem_shadow: TextureRect = null
var _emblem: TextureRect = null
var _category: Label = null
var _band: TextureRect = null
var _title: Label = null
var _blot: TextureRect = null
var _lines: VBoxContainer = null
var _chalk: TextureRect = null
var _footer: GrungeCardFooter = null
var _state: Control = null
var _state_label: Label = null
var _hover: float = 0.0
var _press: float = 0.0
var _pick: float = 0.0
var _intro: float = 1.0
var _tween: Tween = null


func _init() -> void:
	custom_minimum_size = card_size
	flat = true
	focus_mode = Control.FOCUS_ALL
	clip_contents = false
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for st: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(st, StyleBoxEmpty.new())


func _ready() -> void:
	_build()
	resized.connect(_on_resized)
	mouse_entered.connect(_update_hover)
	mouse_exited.connect(_update_hover)
	focus_entered.connect(_update_hover)
	focus_exited.connect(_update_hover)
	button_down.connect(_on_down)
	_on_resized()
	_apply_data()


func setup(data: Dictionary) -> void:
	_data = data
	if _built:
		_apply_data()


# ------------------------------------------------------------------ kurulum
func _build() -> void:
	if _built:
		return
	_built = true
	_visual = _full(Control.new())
	_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visual.resized.connect(func() -> void: _visual.pivot_offset = _visual.size * 0.5)
	add_child(_visual)
	_shadow = _add_brush("card_mask", Color(0, 0, 0, 0.6), 0.0)
	_place(_shadow, Rect2(0.012, 0.016, 1.0, 1.0))
	_bg = ColorRect.new()
	_full(_bg)
	_bg_mat = UiAssets.mat("card_bg", "card_mask")
	_bg.material = _bg_mat
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visual.add_child(_bg)
	_splat = _add_brush("splat_0", Color.WHITE, 0.0)
	_emblem_shadow = _add_emblem(Color(0, 0, 0, 0.6))
	_emblem = _add_emblem(Color.WHITE)
	_category = _add_label(UiFonts.heading(), UiPalette.BONE, 2)
	_category.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(_category, CAT_RECT)
	_band = _add_brush("band_a", Color.WHITE, 0.7)
	_place(_band, BAND_RECT)
	_title = _add_label(UiFonts.heading(), UiPalette.BONE, 3)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(_title, Rect2(BAND_RECT.position.x + 0.04, BAND_RECT.position.y, BAND_RECT.size.x - 0.08, BAND_RECT.size.y))
	_blot = _add_brush("desc_blot", Color(0.02, 0.015, 0.012, 0.97), 0.25)
	_place(_blot, BLOT_RECT)
	_lines = VBoxContainer.new()
	_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lines.alignment = BoxContainer.ALIGNMENT_CENTER
	_lines.clip_contents = true
	_place(_lines, LINES_RECT)
	_visual.add_child(_lines)
	_footer = GrungeCardFooter.new()
	_full(_footer)
	_visual.add_child(_footer)
	_build_state()
	_chalk = _add_brush("chalk_frame", UiPalette.BONE, 0.0)
	(_chalk.material as ShaderMaterial).set_shader_parameter("wobble", 0.0035)
	_chalk.modulate.a = 0.0
	_full(_chalk)


func _build_state() -> void:
	_state = Control.new()
	_state.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_state, STATE_RECT)
	_state.resized.connect(func() -> void: _state.pivot_offset = _state.size * 0.5)
	_state.rotation_degrees = STATE_TILT_DEG
	_visual.add_child(_state)
	var plate: TextureRect = UiAssets.brush_rect("band_b", Color(0.02, 0.015, 0.012, 0.94), 0.3)
	_full(plate)
	_state.add_child(plate)
	_state_label = _add_label(UiFonts.heading(), UiPalette.BAD, 3)
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_full(_state_label)
	_visual.remove_child(_state_label)
	_state.add_child(_state_label)
	_state.visible = false


func _full(c: Control) -> Control:
	_place(c, Rect2(0, 0, 1, 1))
	return c


func _place(c: Control, r: Rect2) -> void:
	c.anchor_left = r.position.x
	c.anchor_top = r.position.y
	c.anchor_right = r.end.x
	c.anchor_bottom = r.end.y
	c.offset_left = 0.0
	c.offset_top = 0.0
	c.offset_right = 0.0
	c.offset_bottom = 0.0


func _add_brush(mask: String, tint: Color, detail: float) -> TextureRect:
	var r: TextureRect = UiAssets.brush_rect(mask, tint, detail)
	_full(r)
	_visual.add_child(r)
	return r


func _add_emblem(tint: Color) -> TextureRect:
	var e: TextureRect = TextureRect.new()
	e.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	e.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	e.mouse_filter = Control.MOUSE_FILTER_IGNORE
	e.modulate = tint
	_place(e, EMBLEM_RECT)
	e.resized.connect(func() -> void: e.pivot_offset = e.size * 0.5)
	_visual.add_child(e)
	return e


func _add_label(font: Font, col: Color, shadow: int) -> Label:
	var l: Label = Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", shadow)
	l.add_theme_constant_override("shadow_offset_y", shadow)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visual.add_child(l)
	return l


# ------------------------------------------------------------------ içerik
func _apply_data() -> void:
	var d: Dictionary = _data
	var cat: Dictionary = UiPalette.category(d.get("category_id", &"weapon"))
	var hot: Color = cat["hot"]
	var tier: int = d.get("tier", -1)
	var seed_val: int = hash(String(d.get("title", "")) + String(d.get("category_id", &"")))
	_bg_mat.set_shader_parameter("hot", hot)
	_bg_mat.set_shader_parameter("deep", cat["deep"])
	_bg_mat.set_shader_parameter("seed", float(seed_val % 97) * 0.173)
	_bg_mat.set_shader_parameter("halo_center", HALO_CENTER)
	_bg_mat.set_shader_parameter("intensity", TIER_INTENSITY[clampi(tier, 0, 3)] if tier >= 0 else 0.95)
	_bg_mat.set_shader_parameter("rim_mix", TIER_RIM[clampi(tier, 0, 3)] if tier >= 0 else 0.3)
	_bg_mat.set_shader_parameter("rim_color", UiPalette.tier_color(tier))
	_style_decor(cat, seed_val)
	_category.text = d.get("category", "")
	var tex: Texture2D = Emblems.tex(d.get("emblem", &""))
	_emblem.texture = tex
	_emblem_shadow.texture = tex
	_title.text = d.get("title", "")
	_footer.tier = tier
	_footer.tier_name = "" if d.get("compact", false) else d.get("tier_name", "")
	_footer.hint = d.get("hint", "")
	_footer.price = d.get("price", -1)
	_footer.price_color = d.get("price_color", UiPalette.GOLD)
	_build_lines(d.get("lines", []))
	_apply_state()
	_on_resized()


func _style_decor(cat: Dictionary, seed_val: int) -> void:
	var band_mask: String = BAND_MASKS[seed_val % BAND_MASKS.size()]
	var bm: ShaderMaterial = _band.material
	bm.set_shader_parameter("mask_tex", UiAssets.tex(band_mask))
	_band.texture = UiAssets.tex(band_mask)
	var band_col: Color = cat["band"]
	bm.set_shader_parameter("tint", Color(band_col, 0.96))
	bm.set_shader_parameter("tint_dark", band_col.darkened(0.6))
	var sm: ShaderMaterial = _splat.material
	var mask: String = SPLAT_MASKS[(seed_val >> 3) % SPLAT_MASKS.size()]
	sm.set_shader_parameter("mask_tex", UiAssets.tex(mask))
	_splat.texture = UiAssets.tex(mask)
	sm.set_shader_parameter("tint", Color((cat["deep"] as Color).darkened(0.5), 0.9))
	var fx: float = 0.38 + float((seed_val >> 6) % 30) * 0.01
	var fy: float = 0.44 + float((seed_val >> 9) % 14) * 0.01
	_place(_splat, Rect2(fx, fy, 0.62, 0.62 * card_size.x / card_size.y))


func _build_lines(lines: Array) -> void:
	for c: Node in _lines.get_children():
		c.queue_free()
		_lines.remove_child(c)
	for entry: Variant in lines:
		var e: Dictionary = entry
		var l: Label = Label.new()
		l.text = e.get("text", "")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.add_theme_font_override("font", UiFonts.bold() if e.get("bold", false) else UiFonts.body())
		l.add_theme_color_override("font_color", e.get("color", UiPalette.BONE))
		_lines.add_child(l)


func _apply_state() -> void:
	var st: StringName = _data.get("state", &"ok")
	var locked: bool = _data.get("locked", false)
	var txt: String = _data.get("state_text", "")
	var dim: float = 0.0
	var col: Color = UiPalette.BAD
	match st:
		&"poor":
			dim = 0.4
		&"full":
			dim = 0.35
			col = UiPalette.ASH
		&"sold":
			dim = 0.75
			col = UiPalette.BONE
	if locked:
		dim = maxf(dim, 0.6)
		col = UiPalette.ASH
	_bg_mat.set_shader_parameter("dim", dim)
	_visual.modulate = Color(1, 1, 1) if dim <= 0.0 else Color(0.82, 0.78, 0.78)
	_state.visible = txt != "" and (st != &"ok" or locked)
	_state_label.text = txt
	_state_label.add_theme_color_override("font_color", col)


# ------------------------------------------------------------------ yazı boyutları
func _scale_k() -> float:
	return card_size_now().y / REF_HEIGHT


func card_size_now() -> Vector2:
	return size if size.x > 1.0 else card_size


func _fs(base: int, k: float) -> int:
	return maxi(MIN_FONT, roundi(base * k))


func _on_resized() -> void:
	if not _built:
		return
	pivot_offset = size * 0.5
	var k: float = _scale_k()
	_category.add_theme_font_size_override("font_size", _fs(CATEGORY_SIZE, k))
	_footer.scale_k = k
	_footer.queue_redraw()
	_fit_title(k)
	_fit_lines(k)
	var h: float = card_size_now().y
	var w: float = card_size_now().x
	(_state_label).add_theme_font_size_override("font_size", _fs(22, k))
	_place(_splat, Rect2(_splat.anchor_left, _splat.anchor_top, 0.62, 0.62 * w / h))


## Başlık bantta tek satıra sığacak kadar küçülür; sığmazsa iki satır.
func _fit_title(k: float) -> void:
	var avail: float = card_size_now().x * (BAND_RECT.size.x - 0.12)
	var f: Font = UiFonts.heading()
	var fs: int = _fs(TITLE_SIZE, k)
	var min_fs: int = maxi(MIN_FONT, roundi(fs * 0.72))
	while fs > min_fs and f.get_string_size(_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > avail:
		fs -= 1
	_title.add_theme_font_size_override("font_size", fs)


## Açıklama satırları lekeye sığacak kadar küçülür (el ile ölçülür).
func _fit_lines(k: float) -> void:
	var avail_w: float = card_size_now().x * LINES_RECT.size.x
	var avail_h: float = card_size_now().y * LINES_RECT.size.y
	var fs: int = _fs(BODY_SIZE, k)
	var min_fs: int = MIN_FONT - 2
	while true:
		var total: float = 0.0
		for c: Node in _lines.get_children():
			var l: Label = c
			var f: Font = l.get_theme_font("font")
			total += f.get_multiline_string_size(l.text, HORIZONTAL_ALIGNMENT_CENTER, avail_w, fs).y + 3.0
		if total <= avail_h or fs <= min_fs:
			break
		fs -= 1
	for c: Node in _lines.get_children():
		(c as Label).add_theme_font_size_override("font_size", fs)


# ------------------------------------------------------------------ etkileşim
func _is_lit() -> bool:
	return (is_hovered() or has_focus()) and not disabled


func _update_hover() -> void:
	z_index = 4 if _is_lit() else 0
	_run(1.0 if _is_lit() else 0.0)


func _run(target: float) -> void:
	if _tween != null:
		_tween.kill()
	if not Tuning.FEATURE_UI_MOTION:
		_set_hover(target)
		return
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_method(_set_hover, _hover, target, HOVER_TIME * maxf(absf(target - _hover), 0.2)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _set_hover(t: float) -> void:
	_hover = t
	_chalk.modulate.a = t
	_apply_xform()


func _set_press(p: float) -> void:
	_press = p
	_apply_xform()


func _set_pick(p: float) -> void:
	_pick = p
	_apply_xform()


func _set_intro(i: float) -> void:
	_intro = i
	_apply_xform()


func _apply_xform() -> void:
	if _visual == null:
		return
	var k: float = _scale_k()
	var glow: float = maxf(_hover, _pick * 1.4)
	_visual.position = Vector2(0.0, -HOVER_LIFT * k * _hover + (1.0 - _intro) * INTRO_OFFSET * k)
	_visual.scale = Vector2.ONE * ((1.0 + HOVER_SCALE * _hover + 0.1 * _pick) * (1.0 - PRESS_DROP * _press))
	_visual.rotation_degrees = HOVER_TILT_DEG * _hover + (1.0 - _intro) * 5.0
	_visual.modulate.a = clampf(_intro * 2.2, 0.0, 1.0)
	_bg_mat.set_shader_parameter("glow", glow)
	_emblem.scale = Vector2.ONE * (1.0 + EMBLEM_GROW * glow)
	_emblem_shadow.scale = _emblem.scale


func _on_down() -> void:
	if not Tuning.FEATURE_UI_MOTION:
		return
	var t: Tween = create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_method(_set_press, 1.0, 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Aşağıdan savrularak gelir.
func play_intro(delay: float = 0.0) -> void:
	if not _built:
		_build()
	if not Tuning.FEATURE_UI_MOTION:
		_set_intro(1.0)
		return
	_set_intro(0.0)
	var t: Tween = create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_interval(delay)
	t.tween_method(_set_intro, 0.0, 1.0, INTRO_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Seçildiğinde parlama + büyüme vuruşu.
func play_picked() -> void:
	if not Tuning.FEATURE_UI_MOTION:
		return
	var t: Tween = create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_method(_set_pick, 0.0, 1.0, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_method(_set_pick, 1.0, 0.55, 0.3)
