class_name ZombieClipData
extends RefCounted
## Zombi klip seti: kütüphane kliplerinden türetme tarifi. Yeni klip = yeni satır.
## source: "kütüphane/klip". mirror: sağ-sol ayna. reverse: ters oynat.
## offsets: kemik -> model uzayında ek dönüş (derece; x öne eğme, y sola dönme, z yana yatma).
## Model +Z'ye bakar; kolu öne kaldırmak için x eksi olur.

const TABLE: Dictionary = {
	&"idle": {"source": &"ual2/Zombie_Idle"},
	&"walk_a": {"source": &"ual2/Zombie_Walk_Fwd"},
	# Kollar öne uzanmış, baş yana düşük.
	&"walk_b": {"source": &"ual2/Zombie_Walk_Fwd", "offsets": {
		"RightUpperArm": Vector3(-60.0, 0.0, 0.0),
		"LeftUpperArm": Vector3(-40.0, 0.0, 0.0),
		"Head": Vector3(0.0, 0.0, 18.0),
	}},
	# Kambur, baş önde, gövde bir yana yatık; ayna alındığı için öbür ayağını sürür.
	&"walk_c": {"source": &"ual2/Zombie_Walk_Fwd", "mirror": true, "offsets": {
		"Spine": Vector3(16.0, 0.0, 8.0),
		"Chest": Vector3(12.0, 0.0, 0.0),
		"Head": Vector3(-18.0, 0.0, -10.0),
		"LeftUpperArm": Vector3(15.0, 0.0, 0.0),
	}},
	&"attack": {"source": &"ual2/Zombie_Scratch"},
	&"stagger": {"source": &"ual1/Hit_Chest"},
	&"death_a": {"source": &"ual1/Death01"},
	&"death_b": {"source": &"ual1/Death01", "mirror": true},
	&"death_c": {"source": &"ual2/Hit_Knockback"},
	&"spawn": {"source": &"ual2/LayToIdle"},
}
