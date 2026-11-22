class_name LowHealthRule
extends RefCounted
## Düşük can kalp atışı kuralı: can oranı eşik ve altındayken (ölü değilse) aralıkla "çal" der.
## İlk atış düşük cana girer girmez gelir; iyileşince ya da ölünce sıfırlanır. Sahneden bağımsız.

var _since: float = 0.0
var _was_low: bool = false


static func is_low(ratio: float, threshold: float) -> bool:
	return ratio > 0.0 and ratio <= threshold


## Her karede çağrılır; true dönerse bu karede bir atış çalınmalı.
func tick(delta: float, ratio: float, threshold: float, interval: float) -> bool:
	if not is_low(ratio, threshold):
		_was_low = false
		_since = 0.0
		return false
	if not _was_low:
		_was_low = true
		_since = 0.0
		return true
	_since += delta
	if _since >= interval:
		_since = fposmod(_since, interval)
		return true
	return false