class_name ZombieMouth
extends RefCounted
## Ağız (çıkış) noktası: satırdaki `spit_mouth` alanı (bone: kemik adı, offset: kemik yerel ofseti, m) iskeletin o anki pozundan
## dünya konumuna çevrilir. İskelet düğümü zombinin boy ölçeğini taşıdığından sonuç ölçeklidir.


static func world_position(skeleton: Skeleton3D, config: Dictionary) -> Vector3:
	var bone: int = skeleton.find_bone(config["bone"])
	var pose: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(bone)
	return pose * (config["offset"] as Vector3)
