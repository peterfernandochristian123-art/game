class_name FrameInspector
extends Control

## Real-Time Frame Inspector untuk Training Mode (Story 5.4)
## Merekam metrik startup, active, recovery, dan frame advantage saat mecha mengeksekusi aksi

signal frame_data_recorded(move_name: String, startup: int, active: int, recovery: int, adv_hit: int, adv_block: int)

@onready var move_name_label: Label = $Panel/VBox/MoveNameLabel
@onready var frame_timeline_label: Label = $Panel/VBox/FrameTimelineLabel
@onready var advantage_label: Label = $Panel/VBox/AdvantageLabel
@onready var damage_heat_label: Label = $Panel/VBox/DamageHeatLabel

var last_move_name: String = "NO ATTACK YET"
var last_startup: int = 0
var last_active: int = 0
var last_recovery: int = 0
var last_advantage_on_hit: int = 0
var last_advantage_on_block: int = 0
var last_damage: int = 0
var last_heat: float = 0.0

func _ready() -> void:
	_update_display()

func record_attack(attack_data: Resource) -> void:
	if not attack_data:
		return

	last_move_name = attack_data.get("attack_name") if "attack_name" in attack_data else attack_data.resource_name
	if last_move_name == "":
		last_move_name = "CUSTOM ATTACK"

	last_startup = attack_data.get("startup_frames") if "startup_frames" in attack_data else 5
	last_active = attack_data.get("active_frames") if "active_frames" in attack_data else 3
	last_recovery = attack_data.get("recovery_frames") if "recovery_frames" in attack_data else 10
	last_damage = attack_data.get("damage") if "damage" in attack_data else 40
	last_heat = attack_data.get("heat_generated") if "heat_generated" in attack_data else 10.0

	var hitstun: int = attack_data.get("hitstun_frames") if "hitstun_frames" in attack_data else 14
	var blockstun: int = attack_data.get("blockstun_frames") if "blockstun_frames" in attack_data else 10

	# Frame advantage: durasi stun lawan dikurangi sisa recovery pemain
	last_advantage_on_hit = hitstun - last_recovery
	last_advantage_on_block = blockstun - last_recovery

	_update_display()
	frame_data_recorded.emit(last_move_name, last_startup, last_active, last_recovery, last_advantage_on_hit, last_advantage_on_block)

func record_manual_data(m_name: String, startup: int, active: int, recovery: int, adv_hit: int, adv_block: int, dmg: int = 0, heat: float = 0.0) -> void:
	last_move_name = m_name
	last_startup = startup
	last_active = active
	last_recovery = recovery
	last_advantage_on_hit = adv_hit
	last_advantage_on_block = adv_block
	last_damage = dmg
	last_heat = heat

	_update_display()
	frame_data_recorded.emit(last_move_name, last_startup, last_active, last_recovery, last_advantage_on_hit, last_advantage_on_block)

func _update_display() -> void:
	if move_name_label:
		move_name_label.text = "MOVE: " + last_move_name.to_upper()

	if frame_timeline_label:
		frame_timeline_label.text = "STARTUP: %df | ACTIVE: %df | RECOVERY: %df" % [
			last_startup, last_active, last_recovery
		]

	if advantage_label:
		var hit_sign: String = "+" if last_advantage_on_hit >= 0 else ""
		var block_sign: String = "+" if last_advantage_on_block >= 0 else ""
		advantage_label.text = "ADVANTAGE: ON HIT %s%df | ON BLOCK %s%df" % [
			hit_sign, last_advantage_on_hit, block_sign, last_advantage_on_block
		]
		# Hijau jika plus (aman), merah jika minus (punishable)
		if last_advantage_on_block >= 0:
			advantage_label.modulate = Color(0.2, 0.95, 0.4, 1.0)
		elif last_advantage_on_block >= -4:
			advantage_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
		else:
			advantage_label.modulate = Color(1.0, 0.3, 0.3, 1.0)

	if damage_heat_label:
		damage_heat_label.text = "DAMAGE: %d | HEAT: +%.1f%%" % [last_damage, last_heat]
