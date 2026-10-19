class_name CombatConstants
extends RefCounted

## Konstanta Tempur dan Fisika Terpusat untuk Fighting to Zero
## Menjamin determinisme frame rate dan sinkronisasi lintas komponen

const TICK_RATE: int = 60
const FRAME_DURATION: float = 1.0 / 60.0

# Kecepatan Pergerakan Mecha (px/s)
const DEFAULT_WALK_SPEED: float = 280.0
const MIN_WALK_SPEED: float = 260.0
const MAX_WALK_SPEED: float = 350.0

# Fisika Lompat dan Gravitasi
const JUMP_VELOCITY: float = -420.0
const GRAVITY: float = 980.0

# Parameter Dash 8-Arah
const DASH_SPEED: float = 750.0
const DASH_DURATION_FRAMES: int = 14
const DASH_COOLDOWN_FRAMES: int = 18

# Heat Gauge (Story 2.1 & 2.2)
const MAX_HEAT: float = 100.0
const DASH_HEAT_COST: float = 10.0
const SKILL_HEAT_MIN: float = 15.0
const SKILL_HEAT_MAX: float = 35.0
const PASSIVE_COOLING_PER_SECOND: float = 12.0
const PASSIVE_COOLING_PER_FRAME: float = PASSIVE_COOLING_PER_SECOND / 60.0 # 0.2 per physics frame

# Overclock & Meltdown Parameters (Story 2.2)
const OVERCLOCK_THRESHOLD: float = 80.0
const MELTDOWN_THRESHOLD: float = 100.0
const OVERCLOCK_DAMAGE_MULTIPLIER: float = 1.2
const MELTDOWN_DAMAGE_RECEIVED_MULTIPLIER: float = 1.25
const MELTDOWN_DURATION_FRAMES: int = 90

# Spark Parry & Ultimate Parameters (Story 2.3)
const SPARK_PARRY_STARTUP_FRAMES: int = 1
const SPARK_PARRY_ACTIVE_FRAMES: int = 4 # Window aktif: frame 2 hingga frame 5
const SPARK_PARRY_RECOVERY_FRAMES: int = 14 # Whiff recovery: frame 6 hingga frame 19
const SPARK_PARRY_TOTAL_FRAMES: int = 19
const SPARK_PARRY_HITSTOP_FRAMES: int = 12
const SPARK_PARRY_HEAT_COOLING: float = 20.0
const SPARK_PARRY_ULTIMATE_STEAL: float = 15.0
const MAX_ULTIMATE: float = 100.0

# Blocking & Chip Damage Parameters (Story 2.4)
const CHIP_DAMAGE_RATIO: float = 0.20 # 20% chip damage untuk serangan energi saat di-block
const DEFAULT_BLOCKSTUN_FRAMES: int = 10
const BLOCK_KNOCKBACK_MULTIPLIER: float = 0.60

# Combo & Target Chain Scaling Parameters (Story 3.1)
const COMBO_SCALING_HIT_1: float = 1.00
const COMBO_SCALING_HIT_2: float = 0.85
const COMBO_SCALING_HIT_3: float = 0.70
const COMBO_SCALING_HIT_4_PLUS_DECAY: float = 0.10
const COMBO_SCALING_FLOOR: float = 0.25
const MAX_GROUND_BOUNCES_PER_COMBO: int = 1
const MAX_WALL_BOUNCES_PER_COMBO: int = 1

static func calculate_combo_damage(base_dmg: int, hit_number: int) -> int:
	var multiplier: float = 1.0
	if hit_number <= 1:
		multiplier = COMBO_SCALING_HIT_1
	elif hit_number == 2:
		multiplier = COMBO_SCALING_HIT_2
	elif hit_number == 3:
		multiplier = COMBO_SCALING_HIT_3
	else:
		multiplier = maxf(COMBO_SCALING_FLOOR, COMBO_SCALING_HIT_3 - float(hit_number - 3) * COMBO_SCALING_HIT_4_PLUS_DECAY)
	return max(1, int(round(float(base_dmg) * multiplier)))

# Toleransi Input (Buffer & Coyote Time)
const INPUT_BUFFER_WINDOW_FRAMES: int = 5
const COYOTE_TIME_FRAMES: int = 5

# Batas Platform Arena (Zero-G Skyscraper)
const ARENA_PLATFORM_WIDTH: float = 1280.0
const ARENA_LEFT_BOUND: float = 64.0
const ARENA_RIGHT_BOUND: float = 1344.0

# Kategori Collision Layer
const LAYER_WORLD: int = 1
const LAYER_HURTBOX: int = 2
const LAYER_STRIKE_HITBOX: int = 3
const LAYER_GRAB_HITBOX: int = 4
const LAYER_LEDGE_SENSOR: int = 5

# Frame Data Serangan Normal Dasar (Story 1.4)
const LIGHT_ATTACK: Dictionary = {
	"name": &"5L",
	"startup": 5,
	"active": 3,
	"recovery": 8,
	"damage": 40,
	"hitstun": 14,
	"blockstun": 10,
	"knockback": 120.0
}

const HEAVY_ATTACK: Dictionary = {
	"name": &"5H",
	"startup": 10,
	"active": 4,
	"recovery": 16,
	"damage": 90,
	"hitstun": 22,
	"blockstun": 16,
	"knockback": 260.0
}

