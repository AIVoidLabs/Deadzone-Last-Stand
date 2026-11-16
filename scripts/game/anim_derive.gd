class_name AnimDerive
extends RefCounted
## Mevcut kliplerden yeni klip türetmenin saf hesapları: ayna, model uzayında ek dönüş, ters çevirme.
## Model +Z'ye bakar, +Y yukarı, +X modelin solu; iskelet sağ-sol simetrik varsayılır.

const LEFT: String = "Left"
const RIGHT: String = "Right"


## Yerel dönüşün YZ düzlemine göre aynası (karşı taraftaki kemiğe yazılır).
static func mirror_rotation(rotation: Quaternion) -> Quaternion:
	return Quaternion(rotation.x, -rotation.y, -rotation.z, rotation.w)


static func mirror_position(position: Vector3) -> Vector3:
	return Vector3(-position.x, position.y, position.z)


## "LeftHand" <-> "RightHand"; ortadaki kemikler aynı kalır.
static func mirror_bone_name(bone: String) -> String:
	if bone.begins_with(LEFT):
		return RIGHT + bone.trim_prefix(LEFT)
	if bone.begins_with(RIGHT):
		return LEFT + bone.trim_prefix(RIGHT)
	return bone


## Kemiğe model uzayında tanımlı bir ek dönüş uygular. parent_global: ebeveynin model uzayındaki dönüşü.
static func offset_rotation(local: Quaternion, parent_global: Quaternion, offset_global: Quaternion) -> Quaternion:
	return (parent_global.inverse() * offset_global * parent_global * local).normalized()


## Derece cinsinden (x, y, z) model uzayı açılarından dönüş.
static func offset_from_degrees(degrees: Vector3) -> Quaternion:
	return Quaternion.from_euler(Vector3(deg_to_rad(degrees.x), deg_to_rad(degrees.y), deg_to_rad(degrees.z)))


## Klip ters oynatılırken anahtarın yeni zamanı.
static func reversed_time(time: float, length: float) -> float:
	return clampf(length - time, 0.0, length)
