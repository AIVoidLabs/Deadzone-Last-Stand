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
const DASH_ARMORED: StringName = &"dash_armored"
const PLAYER_HURT: StringName = &"player_hurt"
const HORDE_GROAN: StringName = &"horde_groan"
const PICKUP: StringName = &"pickup"
const PICKUP_DARK: StringName = &"pickup_dark"

const TABLE: Dictionary = {
	&"shot": {
		"enabled": Tuning.FEATURE_SFX_SHOT,
		"files": ["shot_1"],
		"volume_db": -9.0, "pitch_variance": 0.07, "max_voices": 6, "min_interval": 0.03,
	},
	&"shotgun": {
		"enabled": Tuning.FEATURE_SFX_SHOT,
		"files": ["shotgun_1"],
		"volume_db": -7.0, "pitch_variance": 0.05, "max_voices": 3, "min_interval": 0.05,
	},
	&"smg": {
		"enabled": Tuning.FEATURE_SFX_SHOT,
		"files": ["shot_1"],
		"volume_db": -14.0, "pitch_variance": 0.14, "max_voices": 5, "min_interval": 0.05,
	},
	&"plasma": {
		"enabled": Tuning.FEATURE_SFX_SHOT,
		"files": ["plasma_1", "plasma_2", "plasma_3"],
		"volume_db": -11.0, "pitch_variance": 0.06, "max_voices": 3, "min_interval": 0.08,
	},
	&"graviton": {
		"enabled": Tuning.FEATURE_SFX_SHOT,
		"files": ["graviton_1", "graviton_2"],
		"volume_db": -8.0, "pitch_variance": 0.05, "max_voices": 2, "min_interval": 0.15,
	},
	&"launcher": {
		"enabled": Tuning.FEATURE_SFX_SHOT,
		"files": ["launcher_1", "launcher_2"],
		"volume_db": -8.0, "pitch_variance": 0.05, "max_voices": 2, "min_interval": 0.15,
	},
	&"explosion": {
		"enabled": Tuning.FEATURE_SFX_SHOT,
		"files": ["explosion_1", "explosion_2", "explosion_3"],
		"volume_db": -6.0, "pitch_variance": 0.08, "max_voices": 3, "min_interval": 0.1,
	},
	&"swing_light": {
		"enabled": Tuning.FEATURE_SFX_SHOT,
		"files": ["swing_light_1", "swing_light_2", "swing_light_3"],
		"volume_db": -12.0, "pitch_variance": 0.08, "max_voices": 3, "min_interval": 0.06,
	},
	&"swing_medium": {
		"enabled": Tuning.FEATURE_SFX_SHOT,
		"files": ["swing_medium_1", "swing_medium_2", "swing_medium_3"],
		"volume_db": -10.0, "pitch_variance": 0.07, "max_voices": 3, "min_interval": 0.08,
	},
	&"swing_energy": {
		"enabled": Tuning.FEATURE_SFX_SHOT,
		"files": ["swing_energy_1", "swing_energy_2", "swing_energy_3"],
		"volume_db": -10.0, "pitch_variance": 0.06, "max_voices": 2, "min_interval": 0.1,
	},
	&"swing_fire": {
		"enabled": Tuning.FEATURE_SFX_SHOT,
		"files": ["swing_fire_1", "swing_fire_2", "swing_fire_3"],
		"volume_db": -10.0, "pitch_variance": 0.06, "max_voices": 2, "min_interval": 0.1,
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
	&"dash_armored": {
		"enabled": Tuning.FEATURE_SFX_DASH,
		"files": ["dash_armored_1", "dash_armored_2", "dash_armored_3"],
		"volume_db": -11.0, "pitch_variance": 0.04, "max_voices": 1, "min_interval": 0.2,
	},
	&"horde_groan": {
		"enabled": Tuning.FEATURE_SFX_HORDE_GROAN,
		"files": ["horde_groan_1", "horde_groan_2", "horde_groan_3", "horde_groan_4", "horde_groan_5"],
		"volume_db": -12.0, "pitch_variance": 0.12, "max_voices": 4, "min_interval": 0.15,
	},
	&"pickup": {
		"enabled": Tuning.FEATURE_SFX_PICKUP,
		"files": ["pickup_1", "pickup_2", "pickup_3"],
		"volume_db": -17.0, "pitch_variance": 0.08, "max_voices": 3, "min_interval": 0.035,
	},
	&"pickup_dark": {
		"enabled": Tuning.FEATURE_SFX_PICKUP,
		"files": ["pickup_dark_1", "pickup_dark_2", "pickup_dark_3"],
		"volume_db": -14.0, "pitch_variance": 0.08, "max_voices": 3, "min_interval": 0.035,
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
