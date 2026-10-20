class_name VFXManager
extends Node2D

## Pengelola Sistem Partikel & Efek Visual Pertarungan (Story 6.2)
## Mendengarkan sinyal kontak dari EventBus dan memunculkan percikan las,
## tebasan energi neon 32-bit, dan semburan uap panas tanpa overhead memori

const VFXSparksScene = preload("res://scenes/vfx/vfx_welding_sparks.tscn")
const VFXSlashScene = preload("res://scenes/vfx/vfx_energy_slash.tscn")

@export var enabled: bool = true

func _ready() -> void:
	if is_instance_valid(EventBus):
		EventBus.hit_confirmed.connect(_on_hit_confirmed)
		if EventBus.has_signal("parry_triggered"):
			EventBus.parry_triggered.connect(_on_parry_triggered)

func _on_hit_confirmed(attacker: Node2D, victim: Node2D, hit_data: Variant) -> void:
	if not enabled or not is_instance_valid(attacker) or not is_instance_valid(victim):
		return

	# Hitung titik tengah benturan di antara kedua mecha
	var contact_pos: Vector2 = (attacker.global_position + victim.global_position) / 2.0
	contact_pos.y -= 10.0 # Posisi area dada / mecha core

	var dir_to_victim: float = 1.0 if victim.global_position.x > attacker.global_position.x else -1.0
	var spark_angle: float = 0.0 if dir_to_victim > 0.0 else 180.0

	var data_dict: Dictionary = {}
	if hit_data is Dictionary:
		data_dict = hit_data
	elif hit_data != null and hit_data.has_method("to_dict"):
		data_dict = hit_data.to_dict()

	var is_blocked: bool = data_dict.get("is_blocked", false)
	var is_energy: bool = data_dict.get("is_energy", false)
	var atk_name: String = str(data_dict.get("name", "5L"))

	# 1. Munculkan percikan api las logam
	spawn_sparks(contact_pos, spark_angle, false)

	# 2. Jika serangan tajam / slash atau energi, munculkan busur tebasan
	if not is_blocked and (is_energy or atk_name.contains("L") or atk_name.contains("H") or atk_name.contains("Skill")):
		var slash_col := Color(0.2, 0.95, 1.0) # Default Cyan (Apex Viper)
		if attacker.name.to_lower().contains("bulwark") or attacker.name.to_lower().contains("p2"):
			slash_col = Color(1.0, 0.45, 0.15) # Amber/Crimson (Titan Bulwark)
		var facing: int = int(dir_to_victim)
		spawn_slash(contact_pos, facing, slash_col)

func _on_parry_triggered(defender: Node2D, attacker: Node2D) -> void:
	if not enabled or not is_instance_valid(defender) or not is_instance_valid(attacker):
		return

	var contact_pos: Vector2 = (defender.global_position + attacker.global_position) / 2.0
	contact_pos.y -= 10.0

	# Pijaran las emas besar pada Spark Parry
	spawn_sparks(contact_pos, 0.0, true)

func spawn_sparks(pos: Vector2, dir_degrees: float = 0.0, parry_boost: bool = false) -> Node2D:
	var sparks = VFXSparksScene.instantiate()
	add_child(sparks)
	if sparks.has_method("trigger_sparks"):
		sparks.trigger_sparks(pos, dir_degrees, parry_boost)
	return sparks

func spawn_slash(pos: Vector2, facing_dir: int = 1, color_tint: Color = Color.TRANSPARENT) -> Node2D:
	var slash = VFXSlashScene.instantiate()
	add_child(slash)
	if slash.has_method("trigger_slash"):
		slash.trigger_slash(pos, facing_dir, color_tint)
	return slash
