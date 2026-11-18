class_name WeaponMerge
extends RefCounted
## Silah yuvası kuralları (saf): yeni silah kademe 1 gelir; aynı silah + aynı kademe yuvada varsa
## ikisi birleşip bir üst kademe olur (zincirleme), en çok max_tier. Yuvalar dolunca birleşemeyen silah reddedilir.
## Yuva = {"id": StringName, "tier": int}. Girdi dizisi değiştirilmez.

## Dönüş: {"ok": bool, "merged": bool, "slots": Array[Dictionary]}. ok yoksa slots girdinin kopyasıdır.
static func add(slots: Array[Dictionary], id: StringName, max_slots: int, max_tier: int) -> Dictionary:
	var result: Array[Dictionary] = slots.duplicate()
	var tier: int = 1
	var merged: bool = false
	var insert_at: int = result.size()
	while tier < max_tier:
		var found: int = _find(result, id, tier)
		if found < 0:
			break
		result.remove_at(found)
		insert_at = found
		tier += 1
		merged = true
	if not merged and result.size() >= max_slots:
		return {"ok": false, "merged": false, "slots": slots.duplicate()}
	result.insert(insert_at, {"id": id, "tier": tier})
	return {"ok": true, "merged": merged, "slots": result}


static func _find(slots: Array[Dictionary], id: StringName, tier: int) -> int:
	for i: int in slots.size():
		if slots[i]["id"] == id and slots[i]["tier"] == tier:
			return i
	return -1
