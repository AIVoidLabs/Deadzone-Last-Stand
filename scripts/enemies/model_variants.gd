class_name ModelVariants
extends RefCounted
## Tek model dosyasında birden çok çeşit (ayrı ağ) varsa birini bırakır, ötekileri siler.


static func count(model: Node3D) -> int:
	return model.find_children("*", "MeshInstance3D", true, false).size()


## index çeşit sayısına göre sarılır. Dönüş: kalan ağ.
static func keep(model: Node3D, index: int) -> MeshInstance3D:
	var meshes: Array[Node] = model.find_children("*", "MeshInstance3D", true, false)
	var kept: MeshInstance3D = meshes[posmod(index, meshes.size())] as MeshInstance3D
	for node: Node in meshes:
		if node != kept:
			node.get_parent().remove_child(node)
			node.free()
	return kept
