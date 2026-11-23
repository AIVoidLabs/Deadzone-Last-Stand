class_name ZombieClips
extends RefCounted
## ZombieClipData tablosundan "zombie" animasyon kütüphanesini bir kez üretir; tüm zombiler paylaşır.

const LIBRARY_NAME: StringName = &"zombie"
const SOURCES: Dictionary = {
	&"ual1": preload("res://assets/models/anim/ual1.glb"),
	&"ual2": preload("res://assets/models/anim/ual2.glb"),
}

static var _library: AnimationLibrary


static func clear_cache() -> void:
	_library = null


## "zombie/klip" biçiminde tam ad.
static func full_name(clip: StringName) -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, clip])


## skeleton: ek dönüşleri model uzayında uygulamak için dinlenme pozu kaynağı.
static func library(skeleton: Skeleton3D) -> AnimationLibrary:
	if _library == null:
		_library = AnimationLibrary.new()
		for clip: StringName in ZombieClipData.TABLE:
			_library.add_animation(clip, _derive(ZombieClipData.TABLE[clip], skeleton))
	return _library


## Tablo satırından klip türetir (asker klipleri de aynı yöntemi kullanır).
static func derive(row: Dictionary, skeleton: Skeleton3D) -> Animation:
	return _derive(row, skeleton)


static func _derive(row: Dictionary, skeleton: Skeleton3D) -> Animation:
	var parts: PackedStringArray = String(row["source"]).split("/")
	var source: Animation = (SOURCES[StringName(parts[0])] as AnimationLibrary).get_animation(StringName(parts[1]))
	assert(source != null, "Klip bulunamadı: %s" % row["source"])
	if not (row.get("mirror", false) or row.get("reverse", false) or row.has("offsets") or row.has("loop")):
		return source
	var clip: Animation = source.duplicate(true) as Animation
	# Kaynak klibin döngü bayrağı kopyayla gelir; tek-sefer klipte açıkça kapatılmalı.
	if row.has("loop"):
		clip.loop_mode = Animation.LOOP_LINEAR if row["loop"] else Animation.LOOP_NONE
	if row.get("mirror", false):
		_mirror(clip, source)
	if row.has("offsets"):
		_apply_offsets(clip, row["offsets"], skeleton)
	if row.get("reverse", false):
		_reverse(clip)
	return clip


static func _bone_of(clip: Animation, track: int) -> String:
	return String(clip.track_get_path(track).get_concatenated_subnames())


static func _is_bone_track(clip: Animation, track: int) -> bool:
	var type: Animation.TrackType = clip.track_get_type(track)
	return type == Animation.TYPE_ROTATION_3D or type == Animation.TYPE_POSITION_3D


static func _clear(clip: Animation, track: int) -> void:
	while clip.track_get_key_count(track) > 0:
		clip.track_remove_key(track, 0)


## Her kemiğin anahtarlarını karşı taraftaki kemiğin aynalanmış anahtarlarıyla değiştirir.
static func _mirror(clip: Animation, source: Animation) -> void:
	var by_bone: Dictionary = {}
	for track: int in source.get_track_count():
		by_bone[[_bone_of(source, track), source.track_get_type(track)]] = track
	for track: int in clip.get_track_count():
		if not _is_bone_track(clip, track):
			continue
		var type: Animation.TrackType = clip.track_get_type(track)
		var other: int = by_bone.get([AnimDerive.mirror_bone_name(_bone_of(clip, track)), type], -1)
		if other < 0:
			continue
		_clear(clip, track)
		for key: int in source.track_get_key_count(other):
			var value: Variant = source.track_get_key_value(other, key)
			if type == Animation.TYPE_ROTATION_3D:
				value = AnimDerive.mirror_rotation(value as Quaternion)
			else:
				value = AnimDerive.mirror_position(value as Vector3)
			clip.track_insert_key(track, source.track_get_key_time(other, key), value)


static func _apply_offsets(clip: Animation, offsets: Dictionary, skeleton: Skeleton3D) -> void:
	for track: int in clip.get_track_count():
		if clip.track_get_type(track) != Animation.TYPE_ROTATION_3D:
			continue
		var bone_name: String = _bone_of(clip, track)
		if not offsets.has(bone_name):
			continue
		var parent: int = skeleton.get_bone_parent(skeleton.find_bone(bone_name))
		var parent_global: Quaternion = Quaternion.IDENTITY
		if parent >= 0:
			parent_global = skeleton.get_bone_global_rest(parent).basis.get_rotation_quaternion()
		var offset: Quaternion = AnimDerive.offset_from_degrees(offsets[bone_name])
		for key: int in clip.track_get_key_count(track):
			var local: Quaternion = clip.track_get_key_value(track, key)
			clip.track_set_key_value(track, key, AnimDerive.offset_rotation(local, parent_global, offset))


static func _reverse(clip: Animation) -> void:
	for track: int in clip.get_track_count():
		var keys: Array = []
		for key: int in clip.track_get_key_count(track):
			var time: float = AnimDerive.reversed_time(clip.track_get_key_time(track, key), clip.length)
			keys.append([time, clip.track_get_key_value(track, key)])
		_clear(clip, track)
		for entry: Array in keys:
			clip.track_insert_key(track, entry[0], entry[1])
