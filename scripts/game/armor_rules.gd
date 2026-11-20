class_name ArmorRules
extends RefCounted
## Zırhlının önden zırhı (saf): hasar kaynağı bakış yönünün front_half_rad açısı içindeyse hasar azalır (front),
## değilse artar (back). facing: zombinin baktığı yön, to_source: zombiden hasar kaynağına yön (mermide askere, patlamada merkeze).
## Yönlerden biri sıfırsa (kaynak belirsiz) çarpan 1'dir.


## Kaynak ön yarım koninin içinde mi (sınır dahil).
static func is_front(facing: Vector2, to_source: Vector2, front_half_rad: float) -> bool:
	if facing.length_squared() < 0.000001 or to_source.length_squared() < 0.000001:
		return false
	return absf(facing.angle_to(to_source)) <= front_half_rad


## Hasar çarpanı: önden front, yandan/arkadan back; yön belirsizse 1.
static func factor(facing: Vector2, to_source: Vector2, front_half_rad: float, front: float, back: float) -> float:
	if facing.length_squared() < 0.000001 or to_source.length_squared() < 0.000001:
		return 1.0
	return front if is_front(facing, to_source, front_half_rad) else back
