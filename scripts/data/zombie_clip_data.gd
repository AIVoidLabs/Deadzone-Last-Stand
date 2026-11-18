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
	# Koşucu: öne eğik, kollar önde koşu; ikincisi daha kambur.
	&"run_a": {"source": &"ual1/Sprint", "offsets": {
		"Spine": Vector3(14.0, 0.0, 0.0),
		"Chest": Vector3(10.0, 0.0, 0.0),
		"Head": Vector3(-14.0, 0.0, 6.0),
		"RightUpperArm": Vector3(-45.0, 0.0, 0.0),
		"LeftUpperArm": Vector3(-45.0, 0.0, 0.0),
	}},
	&"run_b": {"source": &"ual1/Sprint", "mirror": true, "offsets": {
		"Spine": Vector3(24.0, 0.0, -6.0),
		"Chest": Vector3(14.0, 0.0, 0.0),
		"Head": Vector3(-22.0, 0.0, -12.0),
		"RightUpperArm": Vector3(-70.0, 0.0, 0.0),
		"LeftUpperArm": Vector3(-20.0, 0.0, 0.0),
	}},
	# Atılma hazırlığı: derin çömelme, gövde önde, kollar geride, baş yükseltilmiş (uzaktan okunur).
	&"pounce_windup": {"source": &"ual2/Zombie_Idle", "offsets": {
		"Spine": Vector3(38.0, 0.0, 0.0),
		"Chest": Vector3(22.0, 0.0, 0.0),
		"Head": Vector3(-40.0, 0.0, 0.0),
		"LeftUpperLeg": Vector3(-38.0, 0.0, 0.0),
		"RightUpperLeg": Vector3(-38.0, 0.0, 0.0),
		"LeftLowerLeg": Vector3(55.0, 0.0, 0.0),
		"RightLowerLeg": Vector3(55.0, 0.0, 0.0),
		"LeftUpperArm": Vector3(35.0, 0.0, 0.0),
		"RightUpperArm": Vector3(35.0, 0.0, 0.0),
	}},
	# Atılış: gövde yatay, kollar ileri uzanmış.
	&"pounce": {"source": &"ual1/Sprint", "offsets": {
		"Spine": Vector3(40.0, 0.0, 0.0),
		"Chest": Vector3(20.0, 0.0, 0.0),
		"Head": Vector3(-35.0, 0.0, 0.0),
		"LeftUpperArm": Vector3(-110.0, 0.0, 0.0),
		"RightUpperArm": Vector3(-110.0, 0.0, 0.0),
	}},
	# Zıplayan havada: kollar yukarı, gövde hafif geride, bacaklar toplu (yükselirken okunur duruş).
	&"leap": {"source": &"ual1/Sprint", "offsets": {
		"Spine": Vector3(-8.0, 0.0, 0.0),
		"Chest": Vector3(-6.0, 0.0, 0.0),
		"Head": Vector3(-10.0, 0.0, 0.0),
		"LeftUpperArm": Vector3(-160.0, 0.0, 12.0),
		"RightUpperArm": Vector3(-160.0, 0.0, -12.0),
		"LeftUpperLeg": Vector3(-45.0, 0.0, 0.0),
		"RightUpperLeg": Vector3(-30.0, 0.0, 0.0),
		"LeftLowerLeg": Vector3(60.0, 0.0, 0.0),
		"RightLowerLeg": Vector3(40.0, 0.0, 0.0),
	}},
	# Dilci hazırlığı: baş geride, çene açık duruş, kollar yanda.
	&"tongue_windup": {"source": &"ual2/Zombie_Idle", "offsets": {
		"Spine": Vector3(-10.0, 0.0, 0.0),
		"Chest": Vector3(-10.0, 0.0, 0.0),
		"Head": Vector3(-38.0, 0.0, 0.0),
		"LeftUpperArm": Vector3(0.0, 0.0, 25.0),
		"RightUpperArm": Vector3(0.0, 0.0, -25.0),
	}},
	# Tank yürüyüşü: gövde daha dik, kollar iri gövdeden açık (kambur yürüyüşün düzeltilmişi).
	&"tank_walk_a": {"source": &"ual2/Zombie_Walk_Fwd", "offsets": {
		"Spine": Vector3(-30.0, 0.0, 0.0),
		"Chest": Vector3(-18.0, 0.0, 0.0),
		"Head": Vector3(-16.0, 0.0, 0.0),
		"LeftUpperArm": Vector3(0.0, 0.0, 14.0),
		"RightUpperArm": Vector3(0.0, 0.0, -14.0),
	}},
	&"tank_walk_b": {"source": &"ual2/Zombie_Walk_Fwd", "mirror": true, "offsets": {
		"Spine": Vector3(-26.0, 0.0, 4.0),
		"Chest": Vector3(-16.0, 0.0, 0.0),
		"Head": Vector3(-14.0, 0.0, 8.0),
		"LeftUpperArm": Vector3(0.0, 0.0, 14.0),
		"RightUpperArm": Vector3(0.0, 0.0, -14.0),
	}},
	# Tank: iki elle ağır savurma.
	&"tank_slam": {"source": &"ual2/Melee_Hook"},
	&"stagger": {"source": &"ual1/Hit_Chest"},
	&"death_a": {"source": &"ual1/Death01"},
	&"death_b": {"source": &"ual1/Death01", "mirror": true},
	&"death_c": {"source": &"ual2/Hit_Knockback"},
	&"spawn": {"source": &"ual2/LayToIdle"},
}
