class_name HitstopComponent
extends Node

## Komponen Manajemen Local Frame-Hitstop & Pemicu Screen Shake (Story 6.1)
## Membekukan logika frame karakter pada kontak serangan / parry tanpa memblokir thread engine atau background VFX

const SettingsManagerScript = preload("res://scripts/core/settings_manager.gd")

@export var enabled: bool = true

# Durasi frame hitstop dasar terkalibrasi
const HITSTOP_LIGHT_FRAMES: int = 4
const HITSTOP_HEAVY_FRAMES: int = 8
const HITSTOP_SKILL_FRAMES: int = 10
const HITSTOP_ULTIMATE_FRAMES: int = 16
const HITSTOP_PARRY_FRAMES: int = 12

# Intensitas screen shake (pixel offset) & durasi frame
const SHAKE_LIGHT_INTENSITY: float = 2.5
const SHAKE_LIGHT_FRAMES: int = 6

const SHAKE_HEAVY_INTENSITY: float = 6.0
const SHAKE_HEAVY_FRAMES: int = 12

const SHAKE_SKILL_INTENSITY: float = 8.0
const SHAKE_SKILL_FRAMES: int = 14

const SHAKE_PARRY_INTENSITY: float = 10.0
const SHAKE_PARRY_FRAMES: int = 16

const SHAKE_ULTIMATE_INTENSITY: float = 12.0
const SHAKE_ULTIMATE_FRAMES: int = 18

func _ready() -> void:
	if is_instance_valid(EventBus):
		EventBus.hit_confirmed.connect(_on_hit_confirmed)
		if EventBus.has_signal("parry_triggered"):
			EventBus.parry_triggered.connect(_on_parry_triggered)
		if EventBus.has_signal("hitstop_requested"):
			EventBus.hitstop_requested.connect(_on_hitstop_requested)

func _on_hit_confirmed(attacker: Node2D, victim: Node2D, hit_data: Variant) -> void:
	if not enabled:
		return

	var multiplier: float = 1.0
	var sm = get_node_or_null("/root/SettingsManager")
	if sm and sm.has_method("get_setting"):
		multiplier = sm.get_setting("display", "hitstop_multiplier", 1.0)

	var data_dict: Dictionary = {}
	if hit_data is Dictionary:
		data_dict = hit_data
	elif hit_data != null and hit_data.has_method("to_dict"):
		data_dict = hit_data.to_dict()

	var is_blocked: bool = data_dict.get("is_blocked", false)
	var damage: int = data_dict.get("damage", 40)
	var atk_name: String = str(data_dict.get("name", "5L"))

	var base_frames: int = HITSTOP_LIGHT_FRAMES
	var shake_intensity: float = SHAKE_LIGHT_INTENSITY
	var shake_duration: int = SHAKE_LIGHT_FRAMES

	if atk_name.to_lower().contains("ult") or damage >= 150:
		base_frames = HITSTOP_ULTIMATE_FRAMES
		shake_intensity = SHAKE_ULTIMATE_INTENSITY
		shake_duration = SHAKE_ULTIMATE_FRAMES
	elif atk_name.to_lower().contains("skill") or damage >= 90:
		base_frames = HITSTOP_SKILL_FRAMES
		shake_intensity = SHAKE_SKILL_INTENSITY
		shake_duration = SHAKE_SKILL_FRAMES
	elif damage >= 60 or atk_name == "5H":
		base_frames = HITSTOP_HEAVY_FRAMES
		shake_intensity = SHAKE_HEAVY_INTENSITY
		shake_duration = SHAKE_HEAVY_FRAMES

	if is_blocked:
		base_frames = maxi(2, int(base_frames * 0.6))
		shake_intensity *= 0.5
		shake_duration = maxi(3, int(shake_duration * 0.6))

	var final_frames: int = maxi(1, int(round(base_frames * multiplier)))

	# 1. Bekukan frame lokal karakter yang terlibat
	if attacker and attacker.has_method("apply_hitstop"):
		attacker.apply_hitstop(final_frames)
	if victim and victim.has_method("apply_hitstop"):
		victim.apply_hitstop(final_frames)

	# 2. Pemicu Screen Shake ke EventBus
	if is_instance_valid(EventBus) and EventBus.has_signal("screen_shake_requested"):
		EventBus.screen_shake_requested.emit(shake_intensity, shake_duration)

func _on_parry_triggered(defender: Node2D, attacker: Node2D) -> void:
	if not enabled:
		return

	# Pada Spark Parry, penyerang dibekukan selama 12 frame
	if attacker and attacker.has_method("apply_hitstop"):
		attacker.apply_hitstop(HITSTOP_PARRY_FRAMES)
	if defender and defender.has_method("apply_hitstop"):
		defender.apply_hitstop(2) # Micro hitstop defender untuk feedback

	if is_instance_valid(EventBus) and EventBus.has_signal("screen_shake_requested"):
		EventBus.screen_shake_requested.emit(SHAKE_PARRY_INTENSITY, SHAKE_PARRY_FRAMES)

func _on_hitstop_requested(frames: int) -> void:
	if not enabled:
		return
	# Sinyal hitstop generik jika dipanggil langsung
	if is_instance_valid(EventBus) and EventBus.has_signal("screen_shake_requested"):
		var intensity: float = SHAKE_LIGHT_INTENSITY if frames <= 6 else SHAKE_HEAVY_INTENSITY
		EventBus.screen_shake_requested.emit(intensity, frames)
