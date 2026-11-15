class_name Tuning
extends RefCounted
## Tüm genel oynanış sayıları burada. İçerik satırları (zombi, silah) scripts/data/ tablolarında.

# --- Özellik anahtarları (her özellik tek sabitle kapanır) ---
const FEATURE_SEPARATION: bool = true
const FEATURE_CAMERA_SMOOTHING: bool = true
const FEATURE_HIT_FLASH: bool = true
const FEATURE_PLAYER_IFRAMES: bool = true
const FEATURE_SPAWN_RAMP: bool = true
const FEATURE_START_FULLSCREEN: bool = true

# --- Arena ---
const ARENA_SIZE: float = 60.0
const ARENA_WALL_HEIGHT: float = 1.2
const ARENA_WALL_THICKNESS: float = 1.0
const ARENA_GROUND_MARGIN: float = 30.0

# --- Asker ---
const PLAYER_SPEED: float = 6.0
const PLAYER_ACCEL: float = 60.0
const PLAYER_FRICTION: float = 45.0
const PLAYER_MAX_HP: float = 100.0
const PLAYER_ARMOR: float = 0.0
const PLAYER_RADIUS: float = 0.4
const PLAYER_HEIGHT: float = 1.8
const PLAYER_HIT_IFRAMES: float = 0.5
const PLAYER_TURN_SHARPNESS: float = 18.0

# --- Hasar ---
const MIN_DAMAGE_AFTER_ARMOR: float = 1.0

# --- Zombi sürüsü ---
const ENEMY_SEPARATION_STRENGTH: float = 7.0
const ENEMY_MAX_SPEED_FACTOR: float = 1.6

# --- Doğma ---
const SPAWN_INTERVAL_START: float = 1.0
const SPAWN_INTERVAL_MIN: float = 0.12
const SPAWN_INTERVAL_RAMP: float = 0.015
const SPAWN_BATCH_START: int = 1
const SPAWN_BATCH_GROWTH_SEC: float = 15.0
const SPAWN_MIN_PLAYER_DIST: float = 18.0
const SPAWN_EDGE_INSET: float = 1.0
const SPAWN_TRIES: int = 8

# --- Mermi ---
const PROJECTILE_POOL_SIZE: int = 128
const PROJECTILE_RADIUS: float = 0.12
const PROJECTILE_HEIGHT: float = 1.0
const PROJECTILE_LENGTH: float = 0.6
const PROJECTILE_THICKNESS: float = 0.1
const PROJECTILE_LIFETIME_MARGIN: float = 1.15

# --- Kamera ---
const CAMERA_PITCH_DEG: float = 55.0
const CAMERA_DISTANCE: float = 24.0
const CAMERA_FOV: float = 45.0
const CAMERA_FOLLOW_SHARPNESS: float = 8.0

# --- Uzay ızgarası ---
const GRID_CELL_SIZE: float = 1.5

# --- Geri bildirim ---
const HIT_FLASH_TIME: float = 0.08
const PLAYER_BLINK_RATE: float = 20.0

# --- Debug ---
const DEBUG_SPAWN_BATCH: int = 50
const DEBUG_PANEL_REFRESH: float = 0.25
const BENCH_STEP_ENEMIES: int = 50
const BENCH_STEP_TIME: float = 3.0
const BENCH_MEASURE_TIME: float = 2.0
const BENCH_TARGET_FPS: float = 60.0
const BENCH_MAX_ENEMIES: int = 2000
const BENCH_FAIL_STEPS: int = 2
const BENCH_TURN_RATE: float = 0.6
