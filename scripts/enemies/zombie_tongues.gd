class_name ZombieTongues
extends RefCounted
## Dil görüntüsü kurucusu (ZombieVisual'in yardımcısı): yeni modelde Head kemiğine bağlı yordamsal dil, yoksa eski kutu dil.


## owner'ın çocuğu olarak dil düğümünü kurar ve döner.
static func make(owner: Node3D, body: Zombie, skeleton: Skeleton3D, own_clips: bool, height: float) -> Node:
	if own_clips:
		var rope: DilciTongue = DilciTongue.new()
		owner.add_child(rope)
		rope.setup(body, skeleton)
		return rope
	var beam: BeamTongue = BeamTongue.new()
	owner.add_child(beam)
	beam.setup(body, height)
	return beam
