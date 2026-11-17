class_name SoundData
extends RefCounted
## Ses tablosu. Yeni ses = tools/sfx/gen_sfx.py'de üret + buraya satır ekle.
## files: assets/audio/sfx/ altındaki dosya adları (çeşitler; her çalışta biri rastgele seçilir).
## volume_db: ses düzeyi. pitch_variance: perde ± payı (0.06 = ±%6).
## max_voices: aynı sesten aynı anda en çok kaç tane. min_interval: iki çalış arası en az süre (sn).

const DIR: String = "res://assets/audio/sfx/%s.wav"

const SHOT: StringName = &"shot"
const HIT: StringName = &"hit"
const ZOMBIE_DEATH: StringName = &"zombie_death"
const FOOTSTEP: StringName = &"footstep"
const DASH: StringName = &"dash"
const PLAYER_HURT: StringName = &"player_hurt"
const HORDE_GROAN: StringName = &"horde_groan"

const TABLE: Dictionary = {
	&"shot": {
		"enabled": Tuning.FEATURE_SFX_SHOT,
		"files": ["shot_1"],
		"volume_db": -9.0, "pitch_variance": 0.07, "max_voices": 6, "min_interval": 0.03,
	},
	&"hit": {
		"enabled": Tuning.FEATURE_SFX_HIT,
		"files": ["hit_1", "hit_2", "hit_3"],
		"volume_db": -10.0, "pitch_variance": 0.1, "max_voices": 4, "min_interval": 0.04,
	},
	&"zombie_death": {
		"enabled": Tuning.FEATURE_SFX_ZOMBIE_DEATH,
		"files": ["zombie_death_1", "zombie_death_2", "zombie_death_3"],
		"volume_db": -7.0, "pitch_variance": 0.08, "max_voices": 4, "min_interval": 0.08,
	},
	&"footstep": {
		"enabled": Tuning.FEATURE_SFX_FOOTSTEP,
		"files": ["footstep_1", "footstep_2", "footstep_3", "footstep_4"],
		"volume_db": -15.0, "pitch_variance": 0.06, "max_voices": 2, "min_interval": 0.1,
	},
	&"dash": {
		"enabled": Tuning.FEATURE_SFX_DASH,
		"files": ["dash_1", "dash_2", "dash_3"],
		"volume_db": -13.0, "pitch_variance": 0.05, "max_voices": 1, "min_interval": 0.2,
	},
	&"horde_groan": {
		"enabled": Tuning.FEATURE_SFX_HORDE_GROAN,
		"files": ["horde_groan_1", "horde_groan_2", "horde_groan_3", "horde_groan_4", "horde_groan_5"],
		"volume_db": -12.0, "pitch_variance": 0.12, "max_voices": 4, "min_interval": 0.15,
	},
	&"player_hurt": {
		"enabled": Tuning.FEATURE_SFX_PLAYER_HURT,
		"files": ["player_hurt_1"],
		"volume_db": -3.0, "pitch_variance": 0.05, "max_voices": 1, "min_interval": 0.15,
	},
}


static func get_row(id: StringName) -> Dictionary:
	assert(TABLE.has(id), "Bilinmeyen ses: %s" % id)
	return TABLE[id]


static func path_of(file: String) -> String:
	return DIR % file
