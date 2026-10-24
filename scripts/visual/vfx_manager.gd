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

@export var enabled: bool = true

func _ready() -> void:
	if is_instance_valid(EventBus):
		EventBus.hit_confirmed.connect(_on_hit_confirmed)
		if EventBus.has_signal("parry_triggered"):
			EventBus.parry_triggered.connect(_on_parry_triggered)
		if EventBus.has_signal("skill_cast"):
			EventBus.skill_cast.connect(_on_skill_cast)

func _on_skill_cast(caster: Node2D, skill_name: StringName, pos: Vector2, facing: int) -> void:
	if not enabled or not is_instance_valid(caster):
		return

	var s_name := String(skill_name)
	var caster_name := caster.name.to_lower()

	# 1. Viper Skills
	if s_name.contains("Blink") or s_name == "BlinkSlash":
		spawn_slash(pos, facing, Color(0.2, 0.95, 1.0))
		spawn_cryo_freeze(pos, 38.0, Color(0.2, 0.95, 1.0))
	elif s_name.contains("Deflection") or s_name == "DeflectionMatrix":
		spawn_hex_barrier(caster, pos, 0.5, Color(0.2, 0.95, 1.0), 54.0)
	elif s_name.contains("AbsoluteZero") or s_name.contains("Protocol"):
		spawn_cryo_freeze(pos, 130.0, Color(0.3, 0.98, 1.0))

	# 2. Bulwark Skills
	elif s_name.contains("Piledriver") or s_name.contains("Hydraulic"):
		spawn_seismic_impact(pos + Vector2(facing * 35.0, 10.0), facing, Color(1.0, 0.55, 0.15), 110.0)
	elif s_name.contains("RiotShield") or s_name.contains("Shield"):
		spawn_hex_barrier(caster, pos, 0.75, Color(1.0, 0.65, 0.2), 60.0)
	elif s_name.contains("Orbital") or s_name.contains("SiegeCannon"):
		spawn_orbital_beam(pos + Vector2(facing * 60.0, -320.0), Vector2.DOWN, 700.0, 60.0, Color(1.0, 0.6, 0.15))

	# 3. Pulsar Skills
	elif s_name.contains("Railgun") or s_name.contains("Photon"):
		spawn_orbital_beam(pos, Vector2(facing, 0.0), 750.0, 36.0, Color(0.75, 0.25, 1.0))
	elif s_name.contains("Drone") or s_name.contains("Disrupter"):
		spawn_disrupter_drone(pos + Vector2(facing * 100.0, -40.0), 2.0, Color(0.7, 0.3, 1.0))
	elif s_name.contains("Supernova") or s_name.contains("Horizon"):
		spawn_supernova(pos, 200.0, Color(0.8, 0.25, 1.0))

	# 4. Kage Skills
	elif s_name.contains("Stance") or s_name == "StanceShift":
		spawn_shadow_smoke(pos, Color(0.95, 0.15, 0.25), 16, 0.4)
	elif s_name.contains("Iaido") or s_name == "IaidoCrescent":
		spawn_cinematic_slash(pos, 1, Color(1.0, 0.15, 0.25), 0.35, 200.0)
	elif s_name.contains("Shuriken") or s_name == "ShurikenStorm":
		spawn_shuriken_storm(pos, facing, Color(1.0, 0.2, 0.3))
	elif s_name.contains("Blossom") or s_name == "ShadowBlossom":
		spawn_cinematic_slash(pos, 5, Color(1.0, 0.1, 0.25), 0.45, 260.0)

	# 5. Unit-0 Boss Skills
	elif s_name.contains("Cataclysm"):
		spawn_cinematic_slash(pos, 3, Color(1.2, 0.1, 0.3), 0.4, 250.0)
	elif s_name.contains("Shockwave"):
		spawn_seismic_impact(pos, facing, Color(0.9, 0.1, 0.3), 120.0)
	elif s_name.contains("Overload") or s_name.contains("Zero"):
		spawn_supernova(pos, 220.0, Color(1.1, 0.1, 0.3))

	# Fallback untuk Skill1 / Skill2 umum
	elif s_name == "Skill1":
		if caster_name.contains("viper"):
			spawn_slash(pos, facing, Color(0.2, 0.95, 1.0))
			spawn_cryo_freeze(pos, 38.0, Color(0.2, 0.95, 1.0))
		elif caster_name.contains("bulwark"):
			spawn_seismic_impact(pos + Vector2(facing * 35.0, 10.0), facing, Color(1.0, 0.55, 0.15), 110.0)
		elif caster_name.contains("pulsar"):
			spawn_orbital_beam(pos, Vector2(facing, 0.0), 750.0, 36.0, Color(0.75, 0.25, 1.0))
		elif caster_name.contains("kage"):
			spawn_shadow_smoke(pos, Color(0.95, 0.15, 0.25), 16, 0.4)
	elif s_name == "Skill2":
		if caster_name.contains("viper"):
			spawn_hex_barrier(caster, pos, 0.5, Color(0.2, 0.95, 1.0), 54.0)
		elif caster_name.contains("bulwark"):
			spawn_hex_barrier(caster, pos, 0.75, Color(1.0, 0.65, 0.2), 60.0)
		elif caster_name.contains("pulsar"):
			spawn_disrupter_drone(pos + Vector2(facing * 100.0, -40.0), 2.0, Color(0.7, 0.3, 1.0))
		elif caster_name.contains("kage"):
			spawn_shuriken_storm(pos, facing, Color(1.0, 0.2, 0.3))
	elif s_name == "Ultimate":
		if caster_name.contains("viper"):
			spawn_cryo_freeze(pos, 130.0, Color(0.3, 0.98, 1.0))
		elif caster_name.contains("bulwark"):
			spawn_orbital_beam(pos + Vector2(facing * 60.0, -320.0), Vector2.DOWN, 700.0, 60.0, Color(1.0, 0.6, 0.15))
		elif caster_name.contains("pulsar"):
			spawn_supernova(pos, 200.0, Color(0.8, 0.25, 1.0))
		elif caster_name.contains("kage"):
			spawn_cinematic_slash(pos, 5, Color(1.0, 0.1, 0.25), 0.45, 260.0)

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

	# Munculkan serpihan lempeng baja mecha (Cyber Debris) jika pukulan medium/heavy
	if hit_level >= 1:
		var shard_count := 6 if hit_level == 1 else (10 if hit_level == 2 else 14)
		spawn_cyber_debris(contact_pos, Vector2(-facing * 0.8, -0.6), shard_count, char_col)

	# Percikan api las logam tradisional
	spawn_sparks(contact_pos, spark_angle, false)

	# 3. Deteksi efek khusus skill saat kontak berhasil
	if atk_name.contains("Blink") or (atk_name.contains("Skill") and atk_owner.contains("viper")):
		spawn_cryo_freeze(contact_pos, 44.0, Color(0.2, 0.95, 1.0))
	elif atk_name.contains("Piledriver") or (atk_name.contains("Skill") and atk_owner.contains("bulwark")):
		spawn_seismic_impact(victim.global_position, facing, Color(1.0, 0.55, 0.15), 80.0)
	elif atk_name.contains("Railgun") or atk_name.contains("Supernova"):
		spawn_supernova(contact_pos, 80.0, Color(0.8, 0.25, 1.0), 0.3)
	elif atk_name.contains("Iaido") or atk_name.contains("Blossom"):
		spawn_cinematic_slash(contact_pos, 2, Color(1.0, 0.15, 0.25), 0.3, 160.0)

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
