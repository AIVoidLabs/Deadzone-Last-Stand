class_name CityProps
extends RefCounted
## Şehir kavşağı prop tablosu (8.1f): yeni prop = ROWS'a (ya da kol şablonlarına) bir satır.
## Satır: prop (glb adı), pos (x, z), rot_y (derece), collide; isteğe bağlı: scale, tilt (derece, yerel X), y.
## Model ekseni: x = genişlik, z = uzunluk (araç); rot_y 0'da araç Z boyunca durur.

const DIR: String = "res://assets/models/world/props/%s.glb"
## Çarpışma kutusu (genişlik x, yükseklik, uzunluk z): yalnız collide satırları için, modelden ölçülü.
const FOOT: Dictionary = {
	&"sedan_wreck": Vector3(1.8, 1.58, 4.49),
	&"taxi_wreck": Vector3(1.8, 1.65, 4.62),
	&"suv_burned": Vector3(1.8, 1.46, 4.49),
	&"van_burned": Vector3(1.73, 1.54, 4.73),
	&"trashbin_wreck": Vector3(1.76, 1.46, 0.93),
	&"sedan_wreck_b": Vector3(1.8, 1.56, 4.49),
	&"police_wreck": Vector3(1.8, 1.52, 4.35),
	&"delivery_wreck": Vector3(1.73, 1.81, 5.2),
	&"trash_pile_a": Vector3(1.96, 0.73, 1.34),
	&"trash_pile_b": Vector3(2.13, 0.71, 1.43),
	&"rubble_pile": Vector3(2.01, 1.07, 1.91),
	&"sandbag_wall": Vector3(3.62, 0.85, 0.48),
	&"tire_stack": Vector3(0.47, 0.88, 0.47),
}
## Gölge atmayan küçük proplar.
const NO_SHADOW: Array[StringName] = [&"traffic_barrier_wreck", &"paper_debris_a", &"paper_debris_b", &"paper_debris_c"]
const PAPERS: Array[StringName] = [&"paper_debris_a", &"paper_debris_b", &"paper_debris_c"]
const PAPER_Y: float = 0.05
## Yanan araç alevlerinin konumu (ROWS'taki *_burned araçların üstü; ateş ışığı da buradan).
const FIRE_SPOTS: Array[Vector3] = [Vector3(-9.7, 0.0, -22.0), Vector3(22.0, 0.0, 9.7)]

## Oyun alanı içi (kaldırım şeridinde park etmiş araçlar, konteynerler, köşe trafik lambaları).
const ROWS: Array[Dictionary] = [
	{"prop": &"suv_burned", "pos": Vector2(-9.7, -22.0), "rot_y": 3.0, "collide": true},
	{"prop": &"van_burned", "pos": Vector2(22.0, 9.7), "rot_y": 92.0, "collide": true},
	{"prop": &"sedan_wreck", "pos": Vector2(9.7, 24.0), "rot_y": 5.0, "collide": true},
	{"prop": &"taxi_wreck", "pos": Vector2(-22.0, -9.7), "rot_y": -88.0, "collide": true},
	{"prop": &"trashbin_wreck", "pos": Vector2(-10.3, 14.0), "rot_y": 90.0, "collide": true},
	{"prop": &"trashbin_wreck", "pos": Vector2(10.3, -15.0), "rot_y": 90.0, "collide": true},
	{"prop": &"trashbin_wreck", "pos": Vector2(14.0, 10.3), "rot_y": 0.0, "collide": true},
	{"prop": &"trashbin_wreck", "pos": Vector2(-14.0, -10.3), "rot_y": 0.0, "collide": true},
	{"prop": &"traffic_light_wreck", "pos": Vector2(10.3, 10.3), "rot_y": 0.0, "collide": false},
	{"prop": &"traffic_light_wreck", "pos": Vector2(-10.3, 10.3), "rot_y": -90.0, "collide": false, "tilt": 8.0},
	{"prop": &"traffic_light_wreck", "pos": Vector2(-10.3, -10.3), "rot_y": 180.0, "collide": false},
	{"prop": &"traffic_light_wreck", "pos": Vector2(10.3, -10.3), "rot_y": 90.0, "collide": false},
]

## Sokak ortası engel adaları (8.2, orta yoğunluk): merkez = ada orta noktası, parça = [prop, dx, dz, rot_y]; hepsi çarpışmalı.
## Adalar merkezden (0,0) CITY_ISLAND_CLEAR_RADIUS uzakta, sokak kollarında girdap düzeninde.
const ISLANDS: Array[Dictionary] = [
	{"center": Vector2(1.0, -16.0), "parts": [
		[&"police_wreck", 0.0, 0.0, 35.0], [&"sandbag_wall", 0.5, 3.4, 15.0], [&"trash_pile_a", -3.3, -1.0, 20.0]]},
	{"center": Vector2(16.0, -1.0), "parts": [
		[&"sedan_wreck_b", 0.0, 0.0, -100.0], [&"tire_stack", 2.4, -1.6, 0.0], [&"rubble_pile", -1.5, 3.0, 30.0]]},
	{"center": Vector2(-1.0, 15.0), "parts": [
		[&"trashbin_wreck", 0.0, 0.0, 20.0], [&"trashbin_wreck", 1.9, -1.4, -30.0], [&"trash_pile_b", -2.3, 0.9, 0.0],
		[&"trash_pile_a", 1.0, 2.3, 40.0], [&"sandbag_wall", -0.5, -2.8, 5.0]]},
	{"center": Vector2(-16.0, 1.0), "parts": [
		[&"delivery_wreck", 0.0, 0.0, 70.0], [&"rubble_pile", 2.4, -2.9, 100.0], [&"trash_pile_b", -2.2, 2.6, 60.0]]},
]
## Kaldırım ve bina diplerine çarpışmasız çöp / moloz / lastik: [prop, x, z, rot_y].
const PILES: Array = [
	[&"trash_pile_a", 9.9, 16.5, 10.0], [&"trash_pile_b", -9.8, 22.0, 80.0], [&"rubble_pile", 9.9, -8.0, 40.0],
	[&"trash_pile_b", 9.8, -26.0, 120.0], [&"rubble_pile", -9.9, 6.0, 200.0], [&"trash_pile_a", -9.7, -16.5, 300.0],
	[&"trash_pile_a", 18.0, -9.8, 15.0], [&"rubble_pile", -18.0, 9.8, 160.0], [&"trash_pile_b", 26.0, -9.8, 250.0],
	[&"trash_pile_a", -26.0, 9.8, 330.0], [&"tire_stack", -14.0, 9.9, 0.0], [&"tire_stack", 14.0, -9.9, 70.0],
]

## Kol şablonları (alan dışı, görsel): u = alan sınırından kol yönünde, v = yanal; kol k için 90 x k derece döner.
const ARM_A: Array = [
	[&"police_wreck", 36.0, -3.5, 78.0],
	[&"traffic_barrier_wreck", 33.4, 3.5, 90.0], [&"traffic_barrier_wreck", 33.6, 5.2, 84.0],
	[&"traffic_barrier_wreck", 33.3, -8.2, 95.0],
	[&"sedan_wreck_b", 47.0, -9.3, 90.0], [&"delivery_wreck", 58.0, 7.6, 70.0],
	[&"suv_wreck", 70.0, -2.0, 20.0], [&"van_burned", 72.5, -4.2, 82.0],
	[&"trashbin_wreck", 42.0, 10.3, 0.0],
]
const ARM_B: Array = [
	[&"police_wreck", 36.5, 5.0, -100.0],
	[&"traffic_barrier_wreck", 33.4, -3.6, 90.0], [&"traffic_barrier_wreck", 33.5, -5.4, 96.0],
	[&"traffic_barrier_wreck", 33.3, 8.0, 86.0],
	[&"taxi_wreck", 44.0, 9.2, 90.0], [&"van_wreck", 54.0, -8.8, 88.0],
	[&"sedan_burned", 63.0, 2.0, 35.0], [&"suv_burned", 65.0, 4.4, 100.0],
	[&"sedan_wreck", 78.0, -7.5, 60.0], [&"trashbin_wreck", 38.0, -10.3, 0.0],
]


## Tüm satırlar: alan içi + kol şablonları + barikat hatları + kâğıtlar.
static func rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = ROWS.duplicate()
	out.append_array(_arm_rows())
	out.append_array(_island_rows())
	out.append_array(_pile_rows())
	out.append_array(_barricade_rows())
	out.append_array(_paper_rows())
	return out


static func _island_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not Tuning.FEATURE_CITY_ISLANDS:
		return out
	for island: Dictionary in ISLANDS:
		var c: Vector2 = island["center"]
		for p: Array in island["parts"]:
			out.append({"prop": p[0], "pos": c + Vector2(p[1], p[2]), "rot_y": p[3], "collide": true})
	return out


static func _pile_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not Tuning.FEATURE_CITY_PILES:
		return out
	for p: Array in PILES:
		out.append({"prop": p[0], "pos": Vector2(p[1], p[2]), "rot_y": p[3], "collide": false})
	return out


static func _arm_to_world(k: int, u: float, v: float) -> Vector2:
	var a: float = deg_to_rad(90.0 * k)
	return Vector2(u * cos(a) + v * sin(a), -u * sin(a) + v * cos(a))


static func _arm_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for k: int in 4:
		for t: Array in (ARM_A if k % 2 == 0 else ARM_B):
			out.append({"prop": t[0], "pos": _arm_to_world(k, t[1], t[2]), "rot_y": t[3] + 90.0 * k, "collide": false})
	return out


## Kol ağzı (alan duvarı üstü) ve kol ucu: sokak boyunca dizili barikat parçaları.
static func _barricade_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var half: float = Tuning.ARENA_SIZE * 0.5
	var reach: float = Tuning.CITY_STREET_WIDTH * 0.5 - 0.3
	var lines: Array[float] = [half + Tuning.ARENA_WALL_THICKNESS * 0.5, half + Tuning.CITY_STREET_LENGTH - 2.0]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 21
	for k: int in 4:
		for u: float in lines:
			var v: float = -reach
			while v <= reach:
				var yaw: float = 90.0 * k + rng.randf_range(-1.0, 1.0) * Tuning.CITY_BARRICADE_YAW_JITTER
				out.append({"prop": &"barricade_wreck", "pos": _arm_to_world(k, u, v), "rot_y": yaw, "collide": false,
					"scale": Tuning.CITY_BARRICADE_PIECE_SCALE})
				v += Tuning.CITY_BARRICADE_STEP
	return out


## Sokaklara dağınık düz kâğıtlar (çarpışmasız).
static func _paper_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var span: float = Tuning.ARENA_SIZE * 0.5 + Tuning.CITY_STREET_LENGTH * 0.5
	var lane: float = Tuning.CITY_STREET_WIDTH * 0.5 - Tuning.CITY_SIDEWALK_WIDTH - 0.3
	for i: int in Tuning.CITY_PAPER_COUNT:
		var along: float = rng.randf_range(-span, span)
		var across: float = rng.randf_range(-lane, lane)
		var pos: Vector2 = Vector2(along, across) if i % 2 == 0 else Vector2(across, along)
		out.append({"prop": PAPERS[i % PAPERS.size()], "pos": pos, "rot_y": rng.randf_range(0.0, 360.0),
			"collide": false, "y": PAPER_Y})
	return out


## Satırın XZ kapsayan dikdörtgeni (döndürülmüş kutunun AABB'si); FOOT'u olmayan prop için boş.
static func rect_of(row: Dictionary) -> Rect2:
	if not FOOT.has(row["prop"]):
		return Rect2()
	var foot: Vector3 = FOOT[row["prop"]]
	var a: float = deg_to_rad(row["rot_y"])
	var hw: float = foot.x * 0.5
	var hl: float = foot.z * 0.5
	var ex: float = absf(cos(a)) * hw + absf(sin(a)) * hl
	var ez: float = absf(sin(a)) * hw + absf(cos(a)) * hl
	var pos: Vector2 = row["pos"]
	return Rect2(pos - Vector2(ex, ez), Vector2(ex, ez) * 2.0)


## Zombi itmesi için çarpışmalı satırların dikdörtgenleri.
static func collide_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for row: Dictionary in ROWS:
		if row["collide"]:
			out.append(rect_of(row))
	out.append_array(island_rects())
	return out


## Her ada için tek kapsayan çarpışma dikdörtgeni (proplar arası dar cep kalmaz; görsel proplar aynı).
static func island_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for row_set: Array[Dictionary] in _island_row_sets():
		var box: Rect2 = rect_of(row_set[0])
		for row: Dictionary in row_set:
			box = box.merge(rect_of(row))
		out.append(box)
	return out


static func _island_row_sets() -> Array[Array]:
	var sets: Array[Array] = []
	if not Tuning.FEATURE_CITY_ISLANDS:
		return sets
	for island: Dictionary in ISLANDS:
		var c: Vector2 = island["center"]
		var rows_of: Array[Dictionary] = []
		for p: Array in island["parts"]:
			rows_of.append({"prop": p[0], "pos": c + Vector2(p[1], p[2]), "rot_y": p[3], "collide": true})
		sets.append(rows_of)
	return sets
