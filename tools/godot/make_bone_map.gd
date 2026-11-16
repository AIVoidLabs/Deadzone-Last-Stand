extends SceneTree
## Oyun iskeleti (Quaternius UAL adları) -> Godot insansı profil eşlemesini üretir.
## Çalıştırma: godot --headless --path . -s res://tools/godot/make_bone_map.gd
## Çıktı: res://assets/models/humanoid_bone_map.tres (içe aktarım ayarları bunu kullanır).

const OUTPUT_PATH: String = "res://assets/models/humanoid_bone_map.tres"

## Profil kemiği -> iskeletteki kemik adı. Eşlenmeyen kemik (ball_leaf) kendi adıyla kalır.
const CENTER: Dictionary = {
	&"Root": &"root",
	&"Hips": &"pelvis",
	&"Spine": &"spine_01",
	&"Chest": &"spine_02",
	&"UpperChest": &"spine_03",
	&"Neck": &"neck_01",
	&"Head": &"Head",
}
## Yan kemikler: profil adı "Left"/"Right" ile, iskelet adı "_l"/"_r" ile biter.
const SIDED: Dictionary = {
	"Shoulder": "clavicle",
	"UpperArm": "upperarm",
	"LowerArm": "lowerarm",
	"Hand": "hand",
	"UpperLeg": "thigh",
	"LowerLeg": "calf",
	"Foot": "foot",
	"Toes": "ball",
}
const SIDES: Dictionary = {"Left": "_l", "Right": "_r"}


func _init() -> void:
	var map: BoneMap = BoneMap.new()
	map.profile = SkeletonProfileHumanoid.new()
	for profile_bone: StringName in CENTER:
		map.set_skeleton_bone_name(profile_bone, CENTER[profile_bone])
	for side: String in SIDES:
		for part: String in SIDED:
			map.set_skeleton_bone_name(StringName(side + part), StringName(SIDED[part] + SIDES[side]))
	var error: Error = ResourceSaver.save(map, OUTPUT_PATH)
	print("bone map: ", OUTPUT_PATH, " -> ", error_string(error))
	quit(0 if error == OK else 1)
