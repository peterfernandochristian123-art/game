class_name VFXManager
extends Node2D

## Pengelola Sistem Partikel & Efek Visual Pertarungan (Enhanced Mecha Combat VFX Engine)
## Mendengarkan sinyal kontak tempur & aktivasi skill dari EventBus.
## Menghadirkan hitspark bintang geometris (✦) bergaya anime fighting game,
## guard spark matriks heksagonal (honeycomb barrier), puing lempeng baja mecha (cyber debris),
## tebasan energi neon, kristal es kriogenik, laser partikel, dan singularitas kosmik.

const VFXSparksScene = preload("res://scenes/vfx/vfx_welding_sparks.tscn")
const VFXSlashScene = preload("res://scenes/vfx/vfx_energy_slash.tscn")
const VFXCryoFreezeScript = preload("res://scripts/visual/vfx_cryo_freeze.gd")
const VFXHexBarrierScript = preload("res://scripts/visual/vfx_hex_barrier.gd")
const VFXSeismicImpactScript = preload("res://scripts/visual/vfx_seismic_impact.gd")
const VFXOrbitalBeamScript = preload("res://scripts/visual/vfx_orbital_beam.gd")
const VFXDisrupterDroneScript = preload("res://scripts/visual/vfx_disrupter_drone.gd")
const VFXSupernovaScript = preload("res://scripts/visual/vfx_supernova.gd")
const VFXShadowSmokeScript = preload("res://scripts/visual/vfx_shadow_smoke.gd")
const VFXShurikenStormScript = preload("res://scripts/visual/vfx_shuriken_storm.gd")
const VFXCinematicSlashScript = preload("res://scripts/visual/vfx_cinematic_slash.gd")
const VFXHitSparkScript = preload("res://scripts/visual/vfx_hitspark.gd")
const VFXGuardSparkScript = preload("res://scripts/visual/vfx_guard_spark.gd")
const VFXCyberDebrisScript = preload("res://scripts/visual/vfx_cyber_debris.gd")
const VFXSuperFlashScript = preload("res://scripts/visual/vfx_super_flash.gd")
const VFXFloatingTextScript = preload("res://scripts/visual/vfx_floating_text.gd")
const VFXGroundDecalScript = preload("res://scripts/visual/vfx_ground_decal.gd")
const VFXGhostTrailScript = preload("res://scripts/visual/vfx_ghost_trail.gd")
const VFXShockwaveScript = preload("res://scripts/visual/vfx_shockwave.gd")
const VFXLightningArcScript = preload("res://scripts/visual/vfx_lightning.gd")
const VFXDramaticFinishScript = preload("res://scripts/visual/vfx_dramatic_finish.gd")

@export var enabled: bool = true

func _ready() -> void:
	if is_instance_valid(EventBus):
		EventBus.hit_confirmed.connect(_on_hit_confirmed)
		if EventBus.has_signal("parry_triggered"):
			EventBus.parry_triggered.connect(_on_parry_triggered)
		if EventBus.has_signal("skill_cast"):
			EventBus.skill_cast.connect(_on_skill_cast)
		if EventBus.has_signal("dramatic_finish_triggered"):
			EventBus.dramatic_finish_triggered.connect(_on_dramatic_finish_triggered)
		if EventBus.has_signal("wall_splat_triggered"):
			EventBus.wall_splat_triggered.connect(_on_wall_splat_triggered)

func _trigger_camera_shake(intensity: float, frames: int) -> void:
	if is_instance_valid(EventBus) and EventBus.has_signal("screen_shake_requested"):
		EventBus.screen_shake_requested.emit(intensity, frames)

func _on_dramatic_finish_triggered(winner_id: int, reason: StringName) -> void:
	if not enabled:
		return
	var finish_layer := VFXDramaticFinishScript.new()
	finish_layer.setup_finish(winner_id, reason)
	add_child(finish_layer)

func _on_wall_splat_triggered(pos: Vector2, normal: Vector2) -> void:
	if not enabled:
		return
	_trigger_camera_shake(16.0, 16)
	spawn_shockwave(pos, 110.0, Color(1.0, 0.9, 0.7), 0.28, 4.0)
	spawn_ground_decal(pos, &"cracks", Color(0.9, 0.9, 1.0), 95.0, 2.5)
	spawn_cyber_debris(pos, normal, 14, Color(0.8, 0.85, 0.95))

func _on_skill_cast(caster: Node2D, skill_name: StringName, pos: Vector2, facing: int) -> void:
	if not enabled or not is_instance_valid(caster):
		return

	var s_name := String(skill_name)
	var caster_name := caster.name.to_lower()
	var is_ult: bool = (s_name == "Ultimate" or s_name.contains("Protocol") or s_name.contains("Cannon") or s_name.contains("Supernova") or s_name.contains("Blossom") or s_name.contains("Overload") or s_name.contains("HellZero") or s_name.contains("BulletHell"))

	# Tentukan warna aksen caster
	var caster_col := Color(0.2, 0.95, 1.0)
	if caster_name.contains("bulwark") or caster_name.contains("titan"):
		caster_col = Color(1.0, 0.55, 0.15)
	elif caster_name.contains("pulsar"):
		caster_col = Color(0.75, 0.25, 1.0)
	elif caster_name.contains("kage") or caster_name.contains("boss") or caster_name.contains("unit_zero"):
		caster_col = Color(1.0, 0.15, 0.25)
	elif caster_name.contains("trigger"):
		caster_col = Color(0.95, 0.65, 0.15)

	# 0. Efek Sinematik Super Flash pada Ultimate
	if is_ult:
		spawn_super_flash(pos, caster_col, 0.42)
		_trigger_camera_shake(15.0, 20)
		if is_instance_valid(EventBus) and EventBus.has_signal("hitstop_requested"):
			EventBus.hitstop_requested.emit(14)
	else:
		_trigger_camera_shake(6.0, 8)

	# 1. Viper Skills
	if s_name.contains("Blink") or s_name == "BlinkSlash":
		spawn_slash(pos, facing, Color(0.2, 0.95, 1.0))
		spawn_cryo_freeze(pos, 38.0, Color(0.2, 0.95, 1.0))
		spawn_ghost_trail(pos, facing, &"viper", Color(0.2, 0.95, 1.0))
		spawn_ground_decal(pos, &"frost", Color(0.2, 0.95, 1.0), 65.0)
		spawn_shockwave(pos, 95.0, Color(0.2, 0.95, 1.0), 0.28, 3.5)
		spawn_lightning(pos, pos + Vector2(facing * 90.0, -15.0), Color(0.35, 0.95, 1.0), 0.18)
	elif s_name.contains("Deflection") or s_name == "DeflectionMatrix":
		spawn_hex_barrier(caster, pos, 0.5, Color(0.2, 0.95, 1.0), 54.0)
		spawn_shockwave(pos, 75.0, Color(0.2, 0.95, 1.0), 0.24, 2.5)
	elif s_name.contains("AbsoluteZero") or s_name.contains("Protocol"):
		spawn_cryo_freeze(pos, 130.0, Color(0.3, 0.98, 1.0))
		spawn_ground_decal(pos, &"frost", Color(0.3, 0.98, 1.0), 120.0, 2.8)
		spawn_shockwave(pos, 190.0, Color(0.35, 0.98, 1.0), 0.45, 5.0)
		spawn_lightning(pos, pos + Vector2(randf_range(-120, 120), -90.0), Color(0.45, 0.98, 1.0), 0.26)

	# 2. Bulwark Skills
	elif s_name.contains("Piledriver") or s_name.contains("Hydraulic"):
		spawn_seismic_impact(pos + Vector2(facing * 35.0, 10.0), facing, Color(1.0, 0.55, 0.15), 110.0)
		spawn_ground_decal(pos + Vector2(facing * 35.0, 10.0), &"cracks", Color(1.0, 0.55, 0.15), 90.0)
		spawn_shockwave(pos + Vector2(facing * 35.0, 10.0), 125.0, Color(1.0, 0.55, 0.15), 0.32, 4.5)
		spawn_lightning(pos + Vector2(facing * 35.0, -35.0), pos + Vector2(facing * 35.0, 15.0), Color(1.0, 0.7, 0.2), 0.2)
	elif s_name.contains("RiotShield") or s_name.contains("Shield"):
		spawn_hex_barrier(caster, pos, 0.75, Color(1.0, 0.65, 0.2), 60.0)
		spawn_shockwave(pos, 85.0, Color(1.0, 0.65, 0.2), 0.25, 3.5)
	elif s_name.contains("Orbital") or s_name.contains("SiegeCannon"):
		spawn_orbital_beam(pos + Vector2(facing * 60.0, -320.0), Vector2.DOWN, 700.0, 60.0, Color(1.0, 0.6, 0.15))
		spawn_ground_decal(pos + Vector2(facing * 60.0, 10.0), &"cracks", Color(1.0, 0.6, 0.15), 110.0, 2.5)
		spawn_shockwave(pos + Vector2(facing * 60.0, 10.0), 180.0, Color(1.0, 0.6, 0.15), 0.45, 5.5)
		spawn_lightning(pos + Vector2(facing * 60.0, -250.0), pos + Vector2(facing * 60.0, 15.0), Color(1.0, 0.8, 0.25), 0.28)

	# 3. Pulsar Skills
	elif s_name.contains("Railgun") or s_name.contains("Photon"):
		spawn_orbital_beam(pos, Vector2(facing, 0.0), 750.0, 36.0, Color(0.75, 0.25, 1.0))
		spawn_ground_decal(pos + Vector2(facing * 60.0, 0.0), &"scorch", Color(0.75, 0.25, 1.0), 90.0)
		spawn_shockwave(pos, 105.0, Color(0.75, 0.25, 1.0), 0.3, 4.0)
		spawn_lightning(pos, pos + Vector2(facing * 280.0, 0.0), Color(0.85, 0.35, 1.0), 0.22)
	elif s_name.contains("Drone") or s_name.contains("Disrupter"):
		spawn_disrupter_drone(pos + Vector2(facing * 100.0, -40.0), 2.0, Color(0.7, 0.3, 1.0))
		spawn_shockwave(pos, 65.0, Color(0.7, 0.3, 1.0), 0.22, 2.5)
	elif s_name.contains("Supernova") or s_name.contains("Horizon"):
		spawn_supernova(pos, 200.0, Color(0.8, 0.25, 1.0))
		spawn_ground_decal(pos, &"scorch", Color(0.8, 0.25, 1.0), 130.0, 2.5)
		spawn_shockwave(pos, 210.0, Color(0.8, 0.25, 1.0), 0.5, 6.0)
		spawn_lightning(pos, pos + Vector2(randf_range(-140, 140), randf_range(-140, 140)), Color(0.95, 0.55, 1.0), 0.3)

	# 4. Kage Skills
	elif s_name.contains("Stance") or s_name == "StanceShift":
		spawn_shadow_smoke(pos, Color(0.95, 0.15, 0.25), 16, 0.4)
		spawn_ghost_trail(pos, facing, &"kage", Color(1.0, 0.15, 0.25))
		spawn_shockwave(pos, 80.0, Color(0.95, 0.15, 0.25), 0.24, 3.0)
	elif s_name.contains("Iaido") or s_name == "IaidoCrescent":
		spawn_cinematic_slash(pos, 1, Color(1.0, 0.15, 0.25), 0.35, 200.0)
		spawn_ground_decal(pos, &"slash", Color(1.0, 0.15, 0.25), 80.0)
		spawn_shockwave(pos, 115.0, Color(1.0, 0.15, 0.25), 0.3, 4.0)
	elif s_name.contains("Shuriken") or s_name == "ShurikenStorm":
		spawn_shuriken_storm(pos, facing, Color(1.0, 0.2, 0.3))
		spawn_shockwave(pos, 90.0, Color(1.0, 0.2, 0.3), 0.25, 3.0)
	elif s_name.contains("Blossom") or s_name == "ShadowBlossom":
		spawn_cinematic_slash(pos, 5, Color(1.0, 0.1, 0.25), 0.45, 260.0)
		spawn_ground_decal(pos, &"slash", Color(1.0, 0.1, 0.25), 120.0, 2.5)
		spawn_shockwave(pos, 195.0, Color(1.0, 0.1, 0.25), 0.45, 5.5)
		spawn_lightning(pos, pos + Vector2(randf_range(-110, 110), randf_range(-90, 90)), Color(1.0, 0.35, 0.45), 0.28)

	# 5. Unit-0 Boss Skills
	elif s_name.contains("Cataclysm"):
		spawn_cinematic_slash(pos, 3, Color(1.2, 0.1, 0.3), 0.4, 250.0)
		spawn_ground_decal(pos, &"slash", Color(1.2, 0.1, 0.3), 110.0)
		spawn_shockwave(pos, 150.0, Color(1.1, 0.1, 0.3), 0.35, 4.5)
	elif s_name.contains("Shockwave"):
		spawn_seismic_impact(pos, facing, Color(0.9, 0.1, 0.3), 120.0)
		spawn_ground_decal(pos, &"cracks", Color(0.9, 0.1, 0.3), 100.0)
		spawn_shockwave(pos, 140.0, Color(0.9, 0.1, 0.3), 0.35, 4.5)
	elif s_name.contains("Overload") or s_name.contains("Zero"):
		spawn_supernova(pos, 220.0, Color(1.1, 0.1, 0.3))
		spawn_ground_decal(pos, &"scorch", Color(1.1, 0.1, 0.3), 130.0)
		spawn_shockwave(pos, 220.0, Color(1.1, 0.1, 0.3), 0.5, 6.0)

	# 6. Trigger (Cyber-Gunslinger) Skills
	elif s_name.contains("Ricochet") or s_name == "RicochetShot":
		spawn_shockwave(pos, 95.0, Color(0.95, 0.65, 0.15), 0.25, 3.5)
		spawn_lightning(pos, pos + Vector2(facing * 260.0, -20.0), Color(1.0, 0.8, 0.25), 0.22, 2)
		spawn_lightning(pos + Vector2(facing * 260.0, -20.0), pos + Vector2(facing * 200.0, 60.0), Color(1.0, 0.7, 0.2), 0.22, 2)
		spawn_ground_decal(pos + Vector2(facing * 120.0, 10.0), &"scorch", Color(0.95, 0.65, 0.15), 75.0)
	elif s_name.contains("Roll") or s_name == "GunslingerRoll":
		spawn_ghost_trail(pos, facing, &"trigger", Color(0.95, 0.65, 0.15))
		spawn_shockwave(pos, 70.0, Color(0.95, 0.65, 0.15), 0.22, 2.5)
		spawn_ground_decal(pos, &"cracks", Color(0.95, 0.65, 0.15), 60.0)
	elif s_name.contains("BulletHell") or s_name.contains("HellZero"):
		spawn_super_flash(pos, Color(1.0, 0.7, 0.2), 0.45)
		spawn_shockwave(pos, 220.0, Color(1.0, 0.7, 0.2), 0.48, 5.5)
		spawn_ground_decal(pos, &"scorch", Color(1.0, 0.7, 0.2), 140.0, 2.6)
		for i in range(8):
			var ang := i * (PI / 4.0)
			var target_v := pos + Vector2(cos(ang), sin(ang)) * 260.0
			spawn_lightning(pos, target_v, Color(1.0, 0.85, 0.3), 0.3, 2)

	# Fallback untuk Skill1 / Skill2 umum
	elif s_name == "Skill1":
		spawn_shockwave(pos, 90.0, caster_col, 0.28, 3.5)
		if caster_name.contains("viper"):
			spawn_slash(pos, facing, Color(0.2, 0.95, 1.0))
			spawn_cryo_freeze(pos, 38.0, Color(0.2, 0.95, 1.0))
		elif caster_name.contains("bulwark"):
			spawn_seismic_impact(pos + Vector2(facing * 35.0, 10.0), facing, Color(1.0, 0.55, 0.15), 110.0)
		elif caster_name.contains("pulsar"):
			spawn_orbital_beam(pos, Vector2(facing, 0.0), 750.0, 36.0, Color(0.75, 0.25, 1.0))
		elif caster_name.contains("kage"):
			spawn_shadow_smoke(pos, Color(0.95, 0.15, 0.25), 16, 0.4)
		elif caster_name.contains("trigger"):
			spawn_lightning(pos, pos + Vector2(facing * 260.0, -20.0), Color(1.0, 0.8, 0.25), 0.22, 2)
	elif s_name == "Skill2":
		spawn_shockwave(pos, 85.0, caster_col, 0.26, 3.0)
		if caster_name.contains("viper"):
			spawn_hex_barrier(caster, pos, 0.5, Color(0.2, 0.95, 1.0), 54.0)
		elif caster_name.contains("bulwark"):
			spawn_hex_barrier(caster, pos, 0.75, Color(1.0, 0.65, 0.2), 60.0)
		elif caster_name.contains("pulsar"):
			spawn_disrupter_drone(pos + Vector2(facing * 100.0, -40.0), 2.0, Color(0.7, 0.3, 1.0))
		elif caster_name.contains("kage"):
			spawn_shuriken_storm(pos, facing, Color(1.0, 0.2, 0.3))
		elif caster_name.contains("trigger"):
			spawn_ghost_trail(pos, facing, &"trigger", Color(0.95, 0.65, 0.15))
	elif s_name == "Ultimate":
		spawn_shockwave(pos, 200.0, caster_col, 0.48, 5.5)
		if caster_name.contains("viper"):
			spawn_cryo_freeze(pos, 130.0, Color(0.3, 0.98, 1.0))
		elif caster_name.contains("bulwark"):
			spawn_orbital_beam(pos + Vector2(facing * 60.0, -320.0), Vector2.DOWN, 700.0, 60.0, Color(1.0, 0.6, 0.15))
		elif caster_name.contains("pulsar"):
			spawn_supernova(pos, 200.0, Color(0.8, 0.25, 1.0))
		elif caster_name.contains("kage"):
			spawn_cinematic_slash(pos, 5, Color(1.0, 0.1, 0.25), 0.45, 260.0)
		elif caster_name.contains("trigger"):
			spawn_super_flash(pos, Color(1.0, 0.7, 0.2), 0.45)

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

	var is_blocked: bool = data_dict.get("is_blocked", false) or data_dict.get("blocked", false)
	var is_energy: bool = data_dict.get("is_energy", false)
	var atk_name: String = str(data_dict.get("name", "5L"))
	var facing: int = int(dir_to_victim)

	# Tentukan warna aksen visual mecha penyerang
	var char_col := Color(0.2, 0.95, 1.0) # Default Cyan (Apex-0 Viper)
	var atk_owner: String = attacker.name.to_lower()
	if atk_owner.contains("bulwark") or atk_owner.contains("p2"):
		char_col = Color(1.0, 0.55, 0.15) # Amber/Crimson (Titan-V Bulwark)
	elif atk_owner.contains("pulsar"):
		char_col = Color(0.75, 0.25, 1.0) # Plasma Violet (Ray-X Pulsar)
	elif atk_owner.contains("kage") or atk_owner.contains("unit_zero") or atk_owner.contains("boss"):
		char_col = Color(1.0, 0.15, 0.25) # Ninja Crimson (Phantom-9 Kage / Unit-0)

	# 1. Jika Serangan DITANGKIS / BLOCKED:
	if is_blocked:
		# Munculkan riak guard spark matriks heksagonal pelindung
		spawn_guard_spark(contact_pos, -facing, Color(0.2, 0.85, 1.0))
		spawn_sparks(contact_pos, spark_angle, false)
		spawn_floating_text(contact_pos, "GUARD", Color(0.35, 0.85, 1.0), false)
		return

	# 2. Jika Serangan MASUK BERSIH / HIT CONFIRMED:
	# Evaluasi intensitas pukulan: 0 = Light, 1 = Medium, 2 = Heavy, 3 = Counter
	var hit_level := 0
	var is_counter: bool = data_dict.get("counter", false) or data_dict.get("is_counter", false)
	var dmg: float = float(data_dict.get("damage", 40.0))

	if is_counter or dmg >= 140.0:
		hit_level = 3
	elif atk_name.contains("H") or atk_name.contains("6H") or atk_name.contains("2H") or atk_name.contains("Skill") or atk_name.contains("Ultimate") or dmg >= 80.0:
		hit_level = 2
	elif atk_name.contains("M") or atk_name.contains("2M") or dmg >= 55.0:
		hit_level = 1
	else:
		hit_level = 0

	# Munculkan Hitspark Bintang Geometris Fighting Game (✦)
	spawn_hitspark(contact_pos, hit_level, char_col, Vector2(facing, 0.0))

	# Munculkan Angka Kerusakan & Status Pop-up Mengambang (Floating Damage Numbers)
	if is_counter:
		spawn_floating_text(contact_pos, "%d COUNTER!" % int(dmg), Color(1.0, 0.2, 0.15), true)
		spawn_shockwave(contact_pos, 115.0, char_col, 0.26, 4.0)
		spawn_lightning(contact_pos, contact_pos + Vector2(-facing * 55.0, randf_range(-30.0, 30.0)), char_col, 0.18)
	elif hit_level >= 2:
		spawn_floating_text(contact_pos, "%d CRITICAL!" % int(dmg), Color(1.0, 0.85, 0.2), true)
		spawn_shockwave(contact_pos, 75.0, char_col, 0.22, 3.0)
	else:
		spawn_floating_text(contact_pos, "%d" % int(dmg), Color(1.0, 0.95, 0.4), false)

	# Munculkan serpihan lempeng baja mecha (Cyber Debris) jika pukulan medium/heavy
	if hit_level >= 1:
		var shard_count := 6 if hit_level == 1 else (10 if hit_level == 2 else 14)
		spawn_cyber_debris(contact_pos, Vector2(-facing * 0.8, -0.6), shard_count, char_col)

	# Percikan api las logam tradisional
	spawn_sparks(contact_pos, spark_angle, false)

	# 3. Deteksi efek khusus skill saat kontak berhasil
	if atk_name.contains("Blink") or (atk_name.contains("Skill") and atk_owner.contains("viper")):
		spawn_cryo_freeze(contact_pos, 44.0, Color(0.2, 0.95, 1.0))
		spawn_ground_decal(contact_pos, &"frost", Color(0.2, 0.95, 1.0), 60.0)
	elif atk_name.contains("Piledriver") or (atk_name.contains("Skill") and atk_owner.contains("bulwark")):
		spawn_seismic_impact(victim.global_position, facing, Color(1.0, 0.55, 0.15), 80.0)
		spawn_ground_decal(victim.global_position, &"cracks", Color(1.0, 0.55, 0.15), 85.0)
	elif atk_name.contains("Railgun") or atk_name.contains("Supernova"):
		spawn_supernova(contact_pos, 80.0, Color(0.8, 0.25, 1.0), 0.3)
		spawn_ground_decal(contact_pos, &"scorch", Color(0.75, 0.25, 1.0), 75.0)
	elif atk_name.contains("Iaido") or atk_name.contains("Blossom"):
		spawn_cinematic_slash(contact_pos, 2, Color(1.0, 0.15, 0.25), 0.3, 160.0)
		spawn_ground_decal(contact_pos, &"slash", Color(1.0, 0.15, 0.25), 80.0)

	# 4. Busur tebasan energi bergradasi
	if is_energy or atk_name.contains("L") or atk_name.contains("M") or atk_name.contains("H") or atk_name.contains("Skill"):
		spawn_slash(contact_pos, facing, char_col)

func _on_parry_triggered(defender: Node2D, attacker: Node2D) -> void:
	if not enabled or not is_instance_valid(defender) or not is_instance_valid(attacker):
		return

	var contact_pos: Vector2 = (defender.global_position + attacker.global_position) / 2.0
	contact_pos.y -= 10.0

	# Pemicuan Spark Parry: Hitspark Emas Level 3, Guard Spark Emas, dan Lontaran Las Penuh
	spawn_hitspark(contact_pos, 3, Color(1.0, 0.85, 0.2), Vector2(0, -1.0))
	spawn_guard_spark(contact_pos, 1, Color(1.0, 0.85, 0.2))
	spawn_sparks(contact_pos, 0.0, true)
	spawn_floating_text(contact_pos, "★ PARRY! ★", Color(1.0, 0.9, 0.2), true)

func spawn_hitspark(pos: Vector2, level: int = 1, custom_color: Color = Color.TRANSPARENT, dir: Vector2 = Vector2.RIGHT) -> Node2D:
	var spark = VFXHitSparkScript.new()
	add_child(spark)
	spark.trigger_hitspark(pos, level, custom_color, dir)
	return spark

func spawn_guard_spark(pos: Vector2, facing: int = 1, custom_color: Color = Color.TRANSPARENT) -> Node2D:
	var guard = VFXGuardSparkScript.new()
	add_child(guard)
	guard.trigger_guard(pos, facing, custom_color)
	return guard

func spawn_cyber_debris(pos: Vector2, blast_dir: Vector2 = Vector2.UP, count: int = 6, custom_color: Color = Color.TRANSPARENT) -> Node2D:
	var debris = VFXCyberDebrisScript.new()
	add_child(debris)
	debris.trigger_debris(pos, blast_dir, count, custom_color)
	return debris

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

func spawn_cryo_freeze(pos: Vector2, burst_radius: float = 48.0, custom_color: Color = Color.TRANSPARENT) -> Node2D:
	var cryo = VFXCryoFreezeScript.new()
	add_child(cryo)
	cryo.trigger_freeze(pos, burst_radius, custom_color)
	return cryo

func spawn_hex_barrier(target: Node2D = null, at_pos: Vector2 = Vector2.ZERO, duration: float = 0.5, color_tint: Color = Color.TRANSPARENT, barrier_radius: float = 52.0) -> Node2D:
	var barrier = VFXHexBarrierScript.new()
	add_child(barrier)
	barrier.trigger_barrier(target, at_pos, duration, color_tint, barrier_radius)
	return barrier

func spawn_seismic_impact(pos: Vector2, facing_dir: int = 1, custom_color: Color = Color.TRANSPARENT, length: float = 90.0, duration: float = 0.45) -> Node2D:
	var seismic = VFXSeismicImpactScript.new()
	add_child(seismic)
	seismic.trigger_impact(pos, facing_dir, custom_color, length, duration)
	return seismic

func spawn_orbital_beam(origin: Vector2, dir: Vector2 = Vector2.DOWN, length: float = 700.0, width: float = 48.0, custom_color: Color = Color.TRANSPARENT, duration: float = 0.45) -> Node2D:
	var beam = VFXOrbitalBeamScript.new()
	add_child(beam)
	beam.trigger_beam(origin, dir, length, width, custom_color, duration)
	return beam

func spawn_disrupter_drone(pos: Vector2, duration: float = 2.0, custom_color: Color = Color.TRANSPARENT) -> Node2D:
	var drone = VFXDisrupterDroneScript.new()
	add_child(drone)
	drone.trigger_drone(pos, duration, custom_color)
	return drone

func spawn_supernova(pos: Vector2, radius: float = 190.0, custom_color: Color = Color.TRANSPARENT, duration: float = 0.55) -> Node2D:
	var nova = VFXSupernovaScript.new()
	add_child(nova)
	nova.trigger_supernova(pos, radius, custom_color, duration)
	return nova

func spawn_shadow_smoke(pos: Vector2, custom_color: Color = Color.TRANSPARENT, count: int = 14, duration: float = 0.38) -> Node2D:
	var smoke = VFXShadowSmokeScript.new()
	add_child(smoke)
	smoke.trigger_smoke(pos, custom_color, count, duration)
	return smoke

func spawn_shuriken_storm(pos: Vector2, facing_dir: int = 1, custom_color: Color = Color.TRANSPARENT, duration: float = 0.35) -> Node2D:
	var storm = VFXShurikenStormScript.new()
	add_child(storm)
	storm.trigger_shurikens(pos, facing_dir, custom_color, duration)
	return storm

func spawn_cinematic_slash(pos: Vector2, slash_count: int = 1, custom_color: Color = Color.TRANSPARENT, duration: float = 0.35, length: float = 220.0) -> Node2D:
	var c_slash = VFXCinematicSlashScript.new()
	add_child(c_slash)
	c_slash.trigger_cinematic_slash(pos, slash_count, custom_color, duration, length)
	return c_slash

func spawn_super_flash(pos: Vector2, custom_color: Color = Color.TRANSPARENT, duration: float = 0.42) -> Node2D:
	var flash = VFXSuperFlashScript.new()
	add_child(flash)
	flash.trigger_super_flash(pos, custom_color, duration)
	return flash

func spawn_floating_text(pos: Vector2, text: String, color: Color = Color.TRANSPARENT, critical: bool = false, duration: float = 0.65) -> Node2D:
	var ftext = VFXFloatingTextScript.new()
	add_child(ftext)
	ftext.trigger_text(pos, text, color, critical, duration)
	return ftext

func spawn_ground_decal(pos: Vector2, type: StringName = &"cracks", custom_color: Color = Color.TRANSPARENT, width: float = 60.0, duration: float = 2.0) -> Node2D:
	var decal = VFXGroundDecalScript.new()
	add_child(decal)
	decal.trigger_decal(pos, type, custom_color, width, duration)
	return decal

func spawn_ghost_trail(pos: Vector2, facing: int = 1, arch: StringName = &"viper", custom_color: Color = Color.TRANSPARENT) -> Node2D:
	var ghost = VFXGhostTrailScript.new()
	add_child(ghost)
	ghost.setup(pos, facing, arch, custom_color)
	return ghost

func spawn_shockwave(pos: Vector2, radius: float = 120.0, custom_color: Color = Color.TRANSPARENT, duration: float = 0.35, width: float = 4.0) -> Node2D:
	var sw = VFXShockwaveScript.new()
	add_child(sw)
	sw.trigger_shockwave(pos, radius, custom_color, duration, width)
	return sw

func spawn_lightning(start_pos: Vector2, end_pos: Vector2, custom_color: Color = Color.TRANSPARENT, duration: float = 0.22, fork_count: int = 3) -> Node2D:
	var arc = VFXLightningArcScript.new()
	add_child(arc)
	arc.trigger_arc(start_pos, end_pos, custom_color, duration, fork_count)
	return arc
