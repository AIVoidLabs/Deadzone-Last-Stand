extends SceneTree
## İçe aktarım doğrulaması: manken iskeleti ve animasyon kütüphaneleri insansı profile eşlenmiş mi?
## Çalıştırma: godot --headless --path . -s res://tools/godot/check_anim_import.gd
## Çıkış kodu 0: her şey yerinde. Sorun varsa "HATA" satırları ve çıkış kodu 1.

const MANNEQUIN_PATH: String = "res://assets/models/characters/mannequin.glb"
const LIBRARY_PATHS: Array[String] = [
	"res://assets/models/anim/ual1.glb",
	"res://assets/models/anim/ual2.glb",
]
const SKELETON_NAME: String = "GeneralSkeleton"
const REQUIRED_BONES: Array[StringName] = [
	&"Root", &"Hips", &"Spine", &"Chest", &"UpperChest", &"Neck", &"Head",
	&"LeftShoulder", &"LeftUpperArm", &"LeftLowerArm", &"LeftHand",
	&"RightShoulder", &"RightUpperArm", &"RightLowerArm", &"RightHand",
	&"LeftUpperLeg", &"LeftLowerLeg", &"LeftFoot", &"LeftToes",
	&"RightUpperLeg", &"RightLowerLeg", &"RightFoot", &"RightToes",
]
const LOOP_SUFFIX: String = "_Loop"

var _errors: int = 0
var _mannequin_root: Node


func _init() -> void:
	var skeleton: Skeleton3D = _check_mannequin()
	for path: String in LIBRARY_PATHS:
		_check_library(path, skeleton)
	if _mannequin_root != null:
		_mannequin_root.free()
	print("SONUC: ", "tamam" if _errors == 0 else "%d hata" % _errors)
	quit(0 if _errors == 0 else 1)


func _fail(message: String) -> void:
	_errors += 1
	print("HATA: ", message)


func _check_mannequin() -> Skeleton3D:
	var scene: PackedScene = load(MANNEQUIN_PATH) as PackedScene
	if scene == null:
		_fail("manken yüklenemedi")
		return null
	var root: Node = scene.instantiate()
	_mannequin_root = root
	var skeleton: Skeleton3D = root.find_child(SKELETON_NAME, true, false) as Skeleton3D
	if skeleton == null:
		_fail("%s bulunamadı" % SKELETON_NAME)
		return null
	for bone: StringName in REQUIRED_BONES:
		if skeleton.find_bone(bone) < 0:
			_fail("kemik eksik: %s" % bone)
	var aabb: AABB = AABB()
	for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		aabb = aabb.merge(mesh.get_aabb())
	print("MANKEN: %d kemik, boyut %.2f x %.2f x %.2f m" % [skeleton.get_bone_count(), aabb.size.x, aabb.size.y, aabb.size.z])
	return skeleton


func _check_library(path: String, skeleton: Skeleton3D) -> void:
	var library: AnimationLibrary = load(path) as AnimationLibrary
	if library == null:
		_fail("kütüphane yüklenemedi: %s" % path)
		return
	var names: PackedStringArray = PackedStringArray()
	for clip: StringName in library.get_animation_list():
		var animation: Animation = library.get_animation(clip)
		var loops: bool = animation.loop_mode != Animation.LOOP_NONE
		if String(clip).ends_with(LOOP_SUFFIX) and not loops:
			_fail("%s döngü olarak işaretli değil" % clip)
		_check_tracks(clip, animation, skeleton)
		names.append("%s(%.2f%s)" % [clip, animation.length, " döngü" if loops else ""])
	print("KUTUPHANE %s: %d klip: %s" % [path.get_file(), names.size(), ", ".join(names)])


func _check_tracks(clip: StringName, animation: Animation, skeleton: Skeleton3D) -> void:
	for track: int in animation.get_track_count():
		var track_path: NodePath = animation.track_get_path(track)
		if not String(track_path).begins_with("%" + SKELETON_NAME):
			_fail("%s: beklenmeyen iz yolu %s" % [clip, track_path])
			return
		if skeleton != null and skeleton.find_bone(track_path.get_concatenated_subnames()) < 0:
			_fail("%s: iskelette olmayan kemik %s" % [clip, track_path])
			return
