class_name WeaponSlots
extends RefCounted
## Süzülen silahların askerin çevresindeki yerleşimi. Silahlar eşit aralıkla bir çembere dizilir;
## silah sayısı değişince çember yeniden bölünür.


## index. silahın askere göre konumu (XZ, m). count: takılı silah sayısı.
static func offset(index: int, count: int, radius: float, start_angle: float) -> Vector2:
	if count <= 0:
		return Vector2.ZERO
	var angle: float = start_angle + TAU * float(posmod(index, count)) / float(count)
	return Vector2(cos(angle), sin(angle)) * radius
