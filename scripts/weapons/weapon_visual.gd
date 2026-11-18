class_name WeaponVisual
extends Node3D
## Süzülen silahın görüntüsü: nişan yönüne yumuşak dönüş, hafif yukarı aşağı salınım, ateşte geri tepme.
## Silah mantığına dokunmaz; Weapon'ın aim değerini okur ve fired sinyalini dinler.

const FLASH_SHADER: Shader = preload("res://assets/shaders/flash_lit.gdshader")
const MODELS: PackedScene = preload("res://assets/models/weapons/weapons.glb")
const FLASH_SHADER_PATH: Shader = preload("res://assets/shaders/muzzle_flash.gdshader")
const MUZZLE_LIGHT_COLOR: Color = Color(1.0, 0.7, 0.35)
## Parlamanın namlu ucundan öne taşma payı (m).
const FLASH_FORWARD: float = 0.08
## Yakın dövüşte savurma sırasında öne atılma (m) ve dürtmede en çok atılma (m).
const MELEE_LUNGE: float = 0.3
const MELEE_THRUST_MAX: float = 0.9

var _weapon: Weapon
var _pivot: Node3D
var _recoil: float = 0.0
var _bob_phase: float = 0.0
var _time: float = 0.0
var _flash: MeshInstance3D
var _light: OmniLight3D
var _flash_left: float = 0.0
var _mesh: MeshInstance3D
var _merge_left: float = 0.0
## Yakın dövüş: savurma animasyonu (kalan süre, toplam, yön, yay, öne atılma) ve kesik izi.
var _melee: bool = false
var _swing_left: float = 0.0
var _swing_total: float = 0.1
var _swing_side: float = 1.0
var _swing_arc: float = 0.0
var _lunge: float = 0.0
var _slash: MeleeSlash


func _ready() -> void:
	_weapon = get_parent() as Weapon
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	add_child(_pivot)
	var behavior: StringName = _weapon.row["behavior"]
	_melee = behavior == &"melee"
	_build_model()
	if behavior != &"projectile" and Tuning.FEATURE_MELEE_SLASH_FX:
		_slash = MeleeSlash.new()
		_slash.position = Vector3(0.0, -0.3, 0.0)
		add_child(_slash)
		_slash.setup(_weapon.row["melee_arc_deg"], _weapon.row["slash_color"], behavior == &"burst")
	_weapon.fired.connect(_on_fired)
	_bob_phase = randf() * TAU
	rotation.y = atan2(_weapon.aim.x, _weapon.aim.y)
	if _weapon.just_merged and Tuning.FEATURE_MERGE_FX:
		_merge_left = Tuning.MERGE_FX_TIME
		var tint: Color = WeaponData.tier_row(_weapon.tier)["tint"]
		MergeBurst.play.call_deferred(_weapon, tint)


func _process(delta: float) -> void:
	_time += delta
	var target_yaw: float = atan2(_weapon.aim.x, _weapon.aim.y)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-Tuning.WEAPON_AIM_SHARPNESS * delta))
	_recoil = _recoil * exp(-Tuning.WEAPON_RECOIL_RECOVER * delta)
	var kick: float = float(_weapon.row["recoil"]) * _recoil
	var bob: float = sin(_time * Tuning.WEAPON_BOB_SPEED + _bob_phase) * Tuning.WEAPON_BOB_HEIGHT
	# Model +Z'ye bakar: geri tepme -Z yönünde, namlu yukarı kalkar (-X ekseninde dönüş).
	_pivot.position = Vector3(0.0, bob, -kick)
	_pivot.rotation.x = -deg_to_rad(Tuning.WEAPON_RECOIL_PITCH_DEG) * _recoil
	_update_swing(delta)
	_update_flash(delta)
	_update_merge(delta)


## Birleşme: silah küçükten başlayıp yaylanarak oturur, kademe renginde beyaza parlayıp söner.
func _update_merge(delta: float) -> void:
	if _merge_left <= 0.0:
		return
	_merge_left = maxf(0.0, _merge_left - delta)
	var t: float = 1.0 - _merge_left / Tuning.MERGE_FX_TIME
	var pop: float = 1.0 - exp(-7.0 * t) * cos(12.0 * t) * 0.7
	_pivot.scale = Vector3.ONE * (1.0 if _merge_left == 0.0 else pop)
	_mesh.set_instance_shader_parameter(&"flash", (1.0 - t) * (1.0 - t))


## Yakın dövüş savurması: kılıç kabzasından yayın bir ucundan öbür ucuna döner ve öne atılır; dürtmede yalnız öne atılır.
func _update_swing(delta: float) -> void:
	if _swing_left <= 0.0:
		_pivot.rotation.y = 0.0
		return
	_swing_left = maxf(0.0, _swing_left - delta)
	var t: float = 1.0 - _swing_left / _swing_total
	var eased: float = t * t * (3.0 - 2.0 * t)
	_pivot.rotation.y = _swing_side * lerpf(_swing_arc * 0.5, -_swing_arc * 0.5, eased)
	_pivot.position.z += sin(t * PI) * _lunge


func _on_fired(direction: Vector2) -> void:
	if _melee:
		_start_swing(direction)
		return
	if _slash != null:
		# İtme patlaması: iz merkezden dışa açılır (silah dönmez, geri teper).
		var yaw: float = wrapf(atan2(direction.x, direction.y) - rotation.y, -PI, PI)
		_slash.play(yaw, 1.0, _weapon.last_reach, float(_weapon.row["melee_swing_time"]))
	_recoil = 1.0
	if _flash == null:
		return
	_flash_left = Tuning.MUZZLE_FLASH_TIME
	_flash.visible = true
	_flash.set_instance_shader_parameter(&"angle", randf() * TAU)
	_flash.scale = Vector3.ONE * Tuning.MUZZLE_FLASH_SIZE * float(_weapon.row["flash_scale"]) * randf_range(0.8, 1.2)
	_light.visible = Quality.get_value("muzzle_light")


func _update_flash(delta: float) -> void:
	if _flash_left <= 0.0:
		return
	_flash_left -= delta
	var strength: float = clampf(_flash_left / Tuning.MUZZLE_FLASH_TIME, 0.0, 1.0)
	_flash.set_instance_shader_parameter(&"strength", strength)
	_light.light_energy = Tuning.MUZZLE_LIGHT_ENERGY * strength
	if _flash_left <= 0.0:
		_flash.visible = false
		_light.visible = false


## Namlu ucunda parlama karesi ve kısa nokta ışığı; ateşe kadar gizli.
func _build_flash(muzzle_z: float) -> void:
	var quad: QuadMesh = QuadMesh.new()
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = FLASH_SHADER_PATH
	quad.material = material
	_flash = MeshInstance3D.new()
	_flash.mesh = quad
	_flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flash.position = Vector3(0.0, 0.0, muzzle_z + FLASH_FORWARD)
	_flash.visible = false
	_pivot.add_child(_flash)
	_light = OmniLight3D.new()
	_light.light_color = MUZZLE_LIGHT_COLOR
	_light.omni_range = Tuning.MUZZLE_LIGHT_RANGE
	_light.shadow_enabled = false
	_light.position = _flash.position
	_light.visible = false
	_pivot.add_child(_light)


func _build_model() -> void:
	var scene: Node3D = MODELS.instantiate() as Node3D
	var source: MeshInstance3D = scene.find_child(String(_weapon.row["model"]), true, false) as MeshInstance3D
	assert(source != null, "Silah modeli bulunamadı: %s" % _weapon.row["model"])
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = source.mesh
	var tier_row: Dictionary = WeaponData.tier_row(_weapon.tier)
	mesh.scale = Vector3.ONE * float(_weapon.row["model_scale"]) * float(tier_row["scale"])
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = FLASH_SHADER
	material.set_shader_parameter(&"albedo", tier_row["tint"])
	material.set_shader_parameter(&"glow", maxf(float(tier_row["glow"]), float(_weapon.row["base_glow"])))
	material.set_shader_parameter(&"flash_color", (tier_row["tint"] as Color).lerp(Color.WHITE, 0.6))
	_mesh = mesh
	var base: BaseMaterial3D = source.mesh.surface_get_material(0) as BaseMaterial3D
	if base != null:
		material.set_shader_parameter(&"albedo_texture", base.albedo_texture)
	mesh.material_override = material
	_pivot.add_child(mesh)
	if Tuning.FEATURE_MUZZLE_FLASH and not _melee:
		_build_flash(source.mesh.get_aabb().end.z * mesh.scale.z)
	scene.free()


func _start_swing(direction: Vector2) -> void:
	var row: Dictionary = _weapon.row
	_swing_total = float(row["melee_swing_time"])
	_swing_left = _swing_total
	_swing_side = -_swing_side
	_swing_arc = deg_to_rad(row["melee_arc_deg"])
	_lunge = MELEE_LUNGE if _swing_arc > 0.0 else minf(_weapon.last_reach * 0.45, MELEE_THRUST_MAX)
	if _slash != null:
		var yaw: float = wrapf(atan2(direction.x, direction.y) - rotation.y, -PI, PI)
		_slash.play(yaw, _swing_side, _weapon.last_reach, _swing_total)
