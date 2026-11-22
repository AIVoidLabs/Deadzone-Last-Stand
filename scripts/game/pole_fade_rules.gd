class_name PoleFadeRules
extends RefCounted
## Direk askeri kameradan kapatıyor mu? Saf kural: kamera-hedef doğru parçasının direk yüksekliği içindeki kısmı
## direk eksenine (dikey silindir) yatayda `radius` kadar yaklaşıyorsa örter.


static func occludes(camera: Vector3, target: Vector3, base: Vector3, height: float, radius: float) -> bool:
	# doğru parçasının direk yüksekliği içinde kalan t aralığı
	var t0: float = 0.0
	var t1: float = 1.0
	var dy: float = target.y - camera.y
	var lo: float = base.y
	var hi: float = base.y + height
	if absf(dy) < 0.0001:
		if camera.y < lo or camera.y > hi:
			return false
	else:
		var ta: float = (lo - camera.y) / dy
		var tb: float = (hi - camera.y) / dy
		t0 = maxf(t0, minf(ta, tb))
		t1 = minf(t1, maxf(ta, tb))
		if t0 > t1:
			return false
	# yatay düzlemde alt parçanın direk eksenine en yakın noktası
	var a: Vector2 = Vector2(camera.x, camera.z).lerp(Vector2(target.x, target.z), t0)
	var b: Vector2 = Vector2(camera.x, camera.z).lerp(Vector2(target.x, target.z), t1)
	var axis: Vector2 = Vector2(base.x, base.z)
	var seg: Vector2 = b - a
	var len2: float = seg.length_squared()
	var u: float = 0.0 if len2 < 0.000001 else clampf((axis - a).dot(seg) / len2, 0.0, 1.0)
	return (a + seg * u).distance_to(axis) <= radius
