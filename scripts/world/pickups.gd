class_name Pickups
extends Node3D
## Yerdeki kristaller: zombi ölünce sekerek düşer, asker yaklaşınca ona çekilir, değince toplanır.
## Tek MultiMesh; dizi sıkışık tutulur (silinen sondakiyle takaslanır). Dönme ve süzülme shader'da,
## CPU yalnız seken ve çekilenlerin konumunu yazar. Üst sınır dolunca yeni değer var olana eklenir.

## Bir kristal toplandı (value: kristal sayısı).
signal collected(value: int)

const SHADER: Shader = preload("res://assets/shaders/pickup.gdshader")

enum State { HOP, IDLE, PULL }

var player: Player
## true iken yerdeki her kristal askere çekilir (dalga sonu); yeni dalgada kapanır.
var pull_all: bool = false

var _mm: MultiMesh
var _pos: PackedVector2Array = PackedVector2Array()
## Sekmenin başladığı nokta (yalnız HOP).
var _from: PackedVector2Array = PackedVector2Array()
var _value: PackedInt32Array = PackedInt32Array()
var _state: PackedByteArray = PackedByteArray()
## HOP: geçen süre; PULL: hız.
var _t: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	name = "Pickups"
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_custom_data = true
	_mm.mesh = _build_crystal_mesh()
	_mm.instance_count = Tuning.PICKUP_MAX
	_mm.visible_instance_count = 0
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.multimesh = _mm
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("albedo", Tuning.PICKUP_COLOR)
	instance.material_override = material
	add_child(instance)


func count() -> int:
	return _pos.size()


## at: zombinin yerdeki konumu. Kristal biraz öteye seker.
func drop(at: Vector3, value: int) -> void:
	if value <= 0:
		return
	var origin: Vector2 = Vector2(at.x, at.z)
	if _pos.size() >= Tuning.PICKUP_MAX:
		# Üst sınır: değeri rastgele bir kristale ekle (o kristal büyür).
		var index: int = randi() % _pos.size()
		_value[index] += value
		_write(index, 0.0)
		return
	var offset: Vector2 = Vector2.from_angle(randf() * TAU) * randf() * Tuning.PICKUP_HOP_DISTANCE
	_pos.append(origin + offset)
	_from.append(origin)
	_value.append(value)
	_state.append(State.HOP)
	_t.append(0.0)
	var index: int = _pos.size() - 1
	_mm.visible_instance_count = _pos.size()
	_mm.set_instance_custom_data(index, Color(randf(), 0.0, 0.0, 0.0))
	_write(index, 0.0)


## Dalga sonu: hepsi askere çekilir; dalga bitene kadar yeni düşenler de çekilir (temizlikte
## devrilen zombilerin kristali yerde kalıp mağazayı/kartları bekletmesin).
func collect_all() -> void:
	pull_all = true
	for i in _pos.size():
		if _state[i] != State.PULL:
			_state[i] = State.PULL
			_t[i] = Tuning.PICKUP_COLLECT_ALL_SPEED


func _physics_process(delta: float) -> void:
	var target: Vector2 = player.position_2d()
	var magnet: float = player.stats.pickup_radius()
	var i: int = _pos.size() - 1
	# Sondan başa: toplanan sondakiyle takaslanır, takaslanan zaten işlenmiştir.
	while i >= 0:
		match _state[i]:
			State.HOP:
				_tick_hop(i, delta)
			State.IDLE:
				if pull_all:
					_state[i] = State.PULL
					_t[i] = Tuning.PICKUP_COLLECT_ALL_SPEED
				elif PickupRules.in_magnet(_pos[i], target, magnet):
					_state[i] = State.PULL
					_t[i] = Tuning.PICKUP_PULL_START_SPEED
			State.PULL:
				if _tick_pull(i, target, delta):
					collected.emit(_value[i])
					_remove(i)
		i -= 1


func _tick_hop(i: int, delta: float) -> void:
	var t: float = _t[i] + delta
	_t[i] = t
	if t >= Tuning.PICKUP_HOP_TIME:
		_state[i] = State.IDLE
		_write(i, 0.0)
		return
	var k: float = t / Tuning.PICKUP_HOP_TIME
	var to: Vector2 = _pos[i]
	var p: Vector2 = _from[i].lerp(to, k)
	_write_at(i, p, PickupRules.hop_height(t, Tuning.PICKUP_HOP_TIME, Tuning.PICKUP_HOP_HEIGHT))


## Dönüş: askere ulaştı (toplandı).
func _tick_pull(i: int, target: Vector2, delta: float) -> bool:
	var speed: float = PickupRules.pull_speed(_t[i], Tuning.PICKUP_PULL_ACCEL, Tuning.PICKUP_PULL_MAX_SPEED, delta)
	_t[i] = speed
	var p: Vector2 = PickupRules.pull_step(_pos[i], target, speed, delta)
	_pos[i] = p
	if p.distance_squared_to(target) <= Tuning.PICKUP_COLLECT_RADIUS * Tuning.PICKUP_COLLECT_RADIUS:
		return true
	_write(i, 0.0)
	return false


func _remove(i: int) -> void:
	var last: int = _pos.size() - 1
	if i != last:
		_pos[i] = _pos[last]
		_from[i] = _from[last]
		_value[i] = _value[last]
		_state[i] = _state[last]
		_t[i] = _t[last]
		_mm.set_instance_custom_data(i, _mm.get_instance_custom_data(last))
		_mm.set_instance_transform(i, _mm.get_instance_transform(last))
	_pos.resize(last)
	_from.resize(last)
	_value.resize(last)
	_state.resize(last)
	_t.resize(last)
	_mm.visible_instance_count = last


func _write(i: int, lift: float) -> void:
	_write_at(i, _pos[i], lift)


func _write_at(i: int, p: Vector2, lift: float) -> void:
	var s: float = Tuning.PICKUP_SIZE * PickupRules.value_scale(_value[i], Tuning.PICKUP_VALUE_SCALE, Tuning.PICKUP_MAX_SCALE)
	var basis: Basis = Basis.from_scale(Vector3(s, s, s))
	_mm.set_instance_transform(i, Transform3D(basis, Vector3(p.x, Tuning.PICKUP_HEIGHT + lift, p.y)))


## Taş kesimi çift piramit: üst ucu uzun, alt ucu kısa; düz yüzler (yüz başına normal).
static func _build_crystal_mesh() -> ArrayMesh:
	var top: Vector3 = Vector3(0.0, Tuning.PICKUP_CRYSTAL_TOP, 0.0)
	var bottom: Vector3 = Vector3(0.0, -Tuning.PICKUP_CRYSTAL_BOTTOM, 0.0)
	var sides: int = Tuning.PICKUP_CRYSTAL_SIDES
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in sides:
		var a: Vector3 = Vector3.RIGHT.rotated(Vector3.UP, -TAU * k / sides)
		var b: Vector3 = Vector3.RIGHT.rotated(Vector3.UP, -TAU * (k + 1) / sides)
		_add_face(st, top, b, a)
		_add_face(st, bottom, a, b)
	return st.commit()


static func _add_face(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal: Vector3 = (b - a).cross(c - a).normalized()
	for v: Vector3 in [a, b, c]:
		st.set_normal(normal)
		st.add_vertex(v)
