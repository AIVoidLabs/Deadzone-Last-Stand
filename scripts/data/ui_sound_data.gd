class_name UiSoundData
extends RefCounted
## Arayüz ve akış sesleri (UI yolu). SoundData ile aynı satır biçimi + 'bus'; SoundData.get_row bu tabloya da bakar.
## Yeni ses = tools/sfx altında üret + buraya satır ekle. Hepsi Tuning.FEATURE_SFX_UI ile kapanır.

const CLICK: StringName = &"ui_click"
const HOVER: StringName = &"ui_hover"
const BUY: StringName = &"ui_buy"
const SELL: StringName = &"ui_sell"
const MERGE: StringName = &"ui_merge"
const DENY: StringName = &"ui_deny"
const CARD_OPEN: StringName = &"ui_card_open"
const CARD_PICK: StringName = &"ui_card_pick"
const LEVEL_UP: StringName = &"ui_level_up"
const WAVE_START: StringName = &"ui_wave_start"
const WAVE_END: StringName = &"ui_wave_end"
const PLAYER_DEATH: StringName = &"ui_player_death"
const GAME_OVER: StringName = &"ui_game_over"
const VICTORY: StringName = &"ui_victory"
const LOW_HEALTH: StringName = &"ui_low_health"

const UI_BUS: StringName = &"UI"

const TABLE: Dictionary = {
	&"ui_click": {
		"enabled": Tuning.FEATURE_SFX_UI, "bus": UI_BUS,
		"files": ["ui_click_1", "ui_click_2"],
		"volume_db": -16.0, "pitch_variance": 0.04, "max_voices": 2, "min_interval": 0.04,
	},
	&"ui_hover": {
		"enabled": Tuning.FEATURE_SFX_UI, "bus": UI_BUS,
		"files": ["ui_hover_1"],
		"volume_db": -24.0, "pitch_variance": 0.03, "max_voices": 1, "min_interval": 0.05,
	},
	&"ui_buy": {
		"enabled": Tuning.FEATURE_SFX_UI, "bus": UI_BUS,
		"files": ["ui_buy_1", "ui_buy_2"],
		"volume_db": -12.0, "pitch_variance": 0.03, "max_voices": 2, "min_interval": 0.06,
	},
	&"ui_sell": {
		"enabled": Tuning.FEATURE_SFX_UI, "bus": UI_BUS,
		"files": ["ui_sell_1"],
		"volume_db": -13.0, "pitch_variance": 0.03, "max_voices": 1, "min_interval": 0.06,
	},
	&"ui_merge": {
		"enabled": Tuning.FEATURE_SFX_UI, "bus": UI_BUS,
		"files": ["ui_merge_1"],
		"volume_db": -11.0, "pitch_variance": 0.02, "max_voices": 1, "min_interval": 0.1,
	},
	&"ui_deny": {
		"enabled": Tuning.FEATURE_SFX_UI, "bus": UI_BUS,
		"files": ["ui_deny_1"],
		"volume_db": -14.0, "pitch_variance": 0.02, "max_voices": 1, "min_interval": 0.1,
	},
	&"ui_card_open": {
		"enabled": Tuning.FEATURE_SFX_UI, "bus": UI_BUS,
		"files": ["ui_card_open_1"],
		"volume_db": -14.0, "pitch_variance": 0, "max_voices": 1, "min_interval": 0.1,
	},
	&"ui_card_pick": {
		"enabled": Tuning.FEATURE_SFX_UI, "bus": UI_BUS,
		"files": ["ui_card_pick_1"],
		"volume_db": -12.0, "pitch_variance": 0.02, "max_voices": 1, "min_interval": 0.1,
	},
	&"ui_level_up": {
		"enabled": Tuning.FEATURE_SFX_UI, "bus": UI_BUS,
		"files": ["ui_level_up_1"],
		"volume_db": -11.0, "pitch_variance": 0, "max_voices": 1, "min_interval": 0.2,
	},
	&"ui_wave_start": {
		"enabled": Tuning.FEATURE_SFX_UI, "bus": UI_BUS,
		"files": ["ui_wave_start_1"],
		"volume_db": -9.0, "pitch_variance": 0, "max_voices": 1, "min_interval": 0.5,
	},
	&"ui_wave_end": {
		"enabled": Tuning.FEATURE_SFX_UI, "bus": UI_BUS,
		"files": ["ui_wave_end_1"],
		"volume_db": -11.0, "pitch_variance": 0, "max_voices": 1, "min_interval": 0.5,
	},
	&"ui_player_death": {
		"enabled": Tuning.FEATURE_SFX_UI, "bus": UI_BUS,
		"files": ["ui_player_death_1"],
		"volume_db": -7.0, "pitch_variance": 0, "max_voices": 1, "min_interval": 0.5,
	},
	&"ui_game_over": {
		"enabled": Tuning.FEATURE_SFX_UI, "bus": UI_BUS,
		"files": ["ui_game_over_1"],
		"volume_db": -9.0, "pitch_variance": 0, "max_voices": 1, "min_interval": 0.5,
	},
	&"ui_victory": {
		"enabled": Tuning.FEATURE_SFX_UI, "bus": UI_BUS,
		"files": ["ui_victory_1"],
		"volume_db": -9.0, "pitch_variance": 0, "max_voices": 1, "min_interval": 0.5,
	},
	&"ui_low_health": {
		"enabled": Tuning.FEATURE_SFX_UI and Tuning.FEATURE_SFX_LOW_HEALTH, "bus": UI_BUS,
		"files": ["ui_low_health_1"],
		"volume_db": -12.0, "pitch_variance": 0, "max_voices": 2, "min_interval": 0.3,
	},
}
