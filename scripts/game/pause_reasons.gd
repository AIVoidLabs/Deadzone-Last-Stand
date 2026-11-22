class_name PauseReasons
extends RefCounted
## Duraklatma nedenleri kümesi (saf). Ağaç yalnızca küme boş değilken durur.

var _reasons: Dictionary = {}


## Küme değiştiyse true.
func add(reason: StringName) -> bool:
	if _reasons.has(reason):
		return false
	_reasons[reason] = true
	return true


func remove(reason: StringName) -> bool:
	return _reasons.erase(reason)


func has(reason: StringName) -> bool:
	return _reasons.has(reason)


func is_paused() -> bool:
	return not _reasons.is_empty()


## Başka neden var mı (verilen hariç).
func has_other_than(reason: StringName) -> bool:
	for key: StringName in _reasons:
		if key != reason:
			return true
	return false


## Küme dolu muydu (temizlenince değişiklik bildirmek için).
func clear() -> bool:
	var had: bool = not _reasons.is_empty()
	_reasons.clear()
	return had
