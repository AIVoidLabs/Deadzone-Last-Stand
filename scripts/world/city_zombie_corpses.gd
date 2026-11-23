class_name CityZombieCorpses
extends Node3D
## 8.3i: sokak cesetleri = oyunun kendi zombi modelleri, ölüm klibinin son karesinde dondurulmuş.
## Yalnız görüntü: çarpışma yok, zombi listesine girmezler. AnimationPlayer bir kez pozlar, sonra elle
## (işlemsiz) bırakılır; iskelet sabit. Kapatma: Tuning.FEATURE_CITY_ZOMBIE_CORPSES.

const KINDS: Array[StringName] = [&"walker", &"walker", &"runner", &"walker", &"jumper", &"tank", &"armored", &"walker", &"bloater", &"runner"]
const TINT_VARIANCE: float = 0.08
## Ölüm klibinin son karesinde zemine oturtma: en alçak köşe y=0'a iner, bu kadar (m) yukarıda durur.
const GROUND_LIFT: float = 0.01

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _corpses: Array[Node3D] = []
var _meshes: Array[MeshInstance3D] = []


func _init() -> void:
	name = "CityZombieCorpses"
	_rng.seed = Tuning.DRESS_SEED + 31


## Ceset ekler: konum (xz), yön (rad). Gövde çeşidi, renk şeması ve ölüm klibi seed'li rastgele.
func add_corpse(at: Vector3, yaw: float) -> void:
	var row: Dictionary = EnemyData.get_row(KINDS[_corpses.size() % KINDS.size()])
	if not ZombieVisual.VC_MODELS.has(row["model"]) or (row.get("anim_death", []) as Array).is_empty():
		return
	var source: Variant = ZombieVisual.VC_MODELS[row["model"]]
	var scene: PackedScene = (source as Array)[_rng.randi() % (source as Array).size()] as PackedScene if source is Array else source as PackedScene
	var model: Node3D = scene.instantiate() as Node3D
	add_child(model)
	var mesh: MeshInstance3D = ModelVariants.keep(model, _rng.randi())
	mesh.material_override = ZombieMaterials.vc_shared()
	var t: float = 1.0 + _rng.randf_range(-TINT_VARIANCE, TINT_VARIANCE)
	ZombieMaterials.apply_tint(mesh, row, true, Vector3(t, t * _rng.randf_range(0.97, 1.03), t))
	if not row.has("tint"):
		mesh.set_instance_shader_parameter(&"tint", Vector3(t, t, t))
	var model_height: float = mesh.get_aabb().end.y
	model.scale = Vector3.ONE * (float(row["height"]) / model_height)
	model.rotation.y = yaw
	model.position = Vector3(at.x, 0.0, at.z)
	var player: AnimationPlayer = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skeleton: Skeleton3D = model.find_child("GeneralSkeleton", true, false) as Skeleton3D
	var clips: Array = row["anim_death"]
	var clip: StringName = clips[_corpses.size() % clips.size()]
	if player != null and player.has_animation(clip):
		player.play(clip)
		player.seek(player.get_animation(clip).length, true)
		player.pause()
		player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	model.position.y = GROUND_LIFT - _lowest_y(mesh, skeleton)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if Quality.shadows_enabled() else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_corpses.append(model)
	_meshes.append(mesh)


## Pozlanmış iskeletle derili köşelerin dünya y'sinin en küçüğü (model y=0 iken).
func _lowest_y(mesh: MeshInstance3D, skeleton: Skeleton3D) -> float:
	var arrays: Array = mesh.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var skin: Skin = mesh.skin
	if skin == null or skeleton == null or bones.is_empty():
		return 0.0
	@warning_ignore("integer_division")
	var per_vertex: int = bones.size() / verts.size()
	var palette: Array[Transform3D] = []
	for b: int in skin.get_bind_count():
		var bone: int = skin.get_bind_bone(b)
		if bone < 0:
			bone = skeleton.find_bone(skin.get_bind_name(b))
		palette.append(skeleton.get_bone_global_pose(bone) * skin.get_bind_pose(b))
	var world: Transform3D = skeleton.global_transform
	var lowest: float = INF
	for i: int in verts.size():
		var p: Vector3 = Vector3.ZERO
		for k: int in per_vertex:
			var w: float = weights[i * per_vertex + k]
			if w > 0.0:
				p += (palette[bones[i * per_vertex + k]] * verts[i]) * w
		lowest = minf(lowest, (world * p).y)
	return lowest


func apply_quality(shadows: bool) -> void:
	for mesh: MeshInstance3D in _meshes:
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var factor: float = Quality.get_value("ground_dressing")
	for i: int in _corpses.size():
		_corpses[i].visible = i < int(ceilf(float(_corpses.size()) * factor))
