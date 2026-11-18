class_name PlayerClipData
extends RefCounted
## Askerin ek klipleri: ortak kütüphane kliplerinden türetme tarifi (ZombieClipData ile aynı biçim).
## Dilciyle bağlanma: çırpınma (döngü) ve bırakılınca kollarını açarak kurtulma (tek sefer).
## offsets: kemik -> model uzayında ek dönüş (derece; x öne eğme, y sola dönme, z yana yatma).

const LIBRARY_NAME: StringName = &"pl"

const TABLE: Dictionary = {
	# Çırpınma: gövde geriye gerilir, kollar bağa karşı gövdeye çekilir (titreme kodla eklenir).
	&"struggle": {"source": &"ual1/Idle", "offsets": {
		"Spine": Vector3(-20.0, 0.0, 0.0),
		"Chest": Vector3(-14.0, 0.0, 6.0),
		"Head": Vector3(-26.0, 0.0, 0.0),
		"LeftUpperArm": Vector3(35.0, 0.0, 20.0),
		"RightUpperArm": Vector3(35.0, 0.0, -20.0),
		"LeftLowerArm": Vector3(-70.0, 0.0, 0.0),
		"RightLowerArm": Vector3(-70.0, 0.0, 0.0),
		"LeftUpperLeg": Vector3(-14.0, 0.0, 0.0),
		"RightUpperLeg": Vector3(14.0, 0.0, 0.0),
	}},
	# Kurtulma: kollar iki yana açık, göğüs ileri gergin (bağı koparmış duruş).
	&"break_free": {"source": &"ual1/Idle", "offsets": {
		"Spine": Vector3(-12.0, 0.0, 0.0),
		"Chest": Vector3(-10.0, 0.0, 0.0),
		"Head": Vector3(-10.0, 0.0, 0.0),
		"LeftUpperArm": Vector3(0.0, 0.0, 75.0),
		"RightUpperArm": Vector3(0.0, 0.0, -75.0),
		"LeftLowerArm": Vector3(0.0, 0.0, 10.0),
		"RightLowerArm": Vector3(0.0, 0.0, -10.0),
	}},
}


static func full_name(clip: StringName) -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, clip])


static func library(skeleton: Skeleton3D) -> AnimationLibrary:
	var library: AnimationLibrary = AnimationLibrary.new()
	for clip: StringName in TABLE:
		library.add_animation(clip, ZombieClips.derive(TABLE[clip], skeleton))
	return library
