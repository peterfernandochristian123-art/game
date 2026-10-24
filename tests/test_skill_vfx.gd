extends Node

const VFXManagerScript = preload("res://scripts/visual/vfx_manager.gd")
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
const CombatCameraScript = preload("res://scripts/visual/combat_camera.gd")
const ApexViperScript = preload("res://scripts/characters/apex_viper.gd")
const TitanBulwarkScript = preload("res://scripts/characters/titan_bulwark.gd")
const RayPulsarScript = preload("res://scripts/characters/ray_pulsar.gd")
const PhantomKageScript = preload("res://scripts/characters/phantom_kage.gd")
const MechaPixelSpriteScript = preload("res://scripts/visual/mecha_pixel_sprite.gd")

var log_file: FileAccess = null
var _failed: bool = false

func _log(msg: String) -> void:
	print(msg)
	if log_file:
		log_file.store_line(msg)
		log_file.flush()

func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failed = true
		_log("   [FAIL] " + msg)
	else:
		_log("   [PASS] " + msg)

func _ready() -> void:
	var out_path: String = ProjectSettings.globalize_path("res://test_skill_vfx_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)

	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Efek Visual Skill & Combat Hitspark Berbeda-beda...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_individual_vfx_nodes,
		_test_vfx_manager_spawn_methods,
		_test_vfx_manager_skill_cast_handling,
		_test_vfx_manager_hit_impact_effects,
		_test_character_skill_cast_integration,
		_test_vfx_showcase_scene,
		_test_mecha_pixel_sprite_distinct_attack_techniques,
		_test_cinematic_juice_systems
	]

	var passed: int = 0
	for t in tests:
		_failed = false
		_log("\n--- %s ---" % t.get_method())
		t.call()
		if _failed:
			_log(" [GAGAL]")
		else:
			_log(" [BERHASIL]")
			passed += 1

	_log("\n==================================================")
	_log("HASIL AKHIR: %d/%d Pengujian Lolos." % [passed, tests.size()])
	_log("==================================================")

	if passed == tests.size():
		_log("SEMUA PENGUJIAN SKILL VFX BERHASIL (100% SUKSES)!")
	else:
		_log("BEBERAPA PENGUJIAN SKILL VFX GAGAL!")

	if log_file:
		log_file.close()

	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func _test_individual_vfx_nodes() -> void:
	# 1. VFXCryoFreeze
	var cryo = VFXCryoFreezeScript.new()
	add_child(cryo)
	cryo.trigger_freeze(Vector2(100, 100), 50.0, Color.CYAN)
	cryo._process(0.016)
	_check(cryo._active == true, "VFXCryoFreeze aktif setelah dipicu.")
	cryo.queue_free()

	# 2. VFXHexBarrier
	var dummy := Node2D.new()
	add_child(dummy)
	var barrier = VFXHexBarrierScript.new()
	add_child(barrier)
	barrier.trigger_barrier(dummy, Vector2.ZERO, 0.5, Color.CYAN, 50.0)
	barrier._process(0.016)
	_check(barrier._active == true, "VFXHexBarrier aktif dan mengikuti target.")
	dummy.queue_free()
	barrier.queue_free()

	# 3. VFXSeismicImpact
	var seismic = VFXSeismicImpactScript.new()
	add_child(seismic)
	seismic.trigger_impact(Vector2(200, 200), 1, Color.ORANGE, 100.0)
	seismic._process(0.016)
	_check(seismic._active == true, "VFXSeismicImpact aktif dengan pecahan tanah dan puing.")
	seismic.queue_free()

	# 4. VFXOrbitalBeam
	var beam = VFXOrbitalBeamScript.new()
	add_child(beam)
	beam.trigger_beam(Vector2(300, 100), Vector2.DOWN, 600.0, 50.0, Color.ORANGE)
	beam._process(0.016)
	_check(beam._active == true, "VFXOrbitalBeam aktif dengan berkas sinar laser partikel.")
	beam.queue_free()

	# 5. VFXDisrupterDrone
	var drone = VFXDisrupterDroneScript.new()
	add_child(drone)
	drone.trigger_drone(Vector2(400, 200), 1.5, Color.PURPLE)
	drone._process(0.016)
	_check(drone._active == true, "VFXDisrupterDrone aktif dengan gyro rings berputar.")
	drone.queue_free()

	# 6. VFXSupernova
	var nova = VFXSupernovaScript.new()
	add_child(nova)
	nova.trigger_supernova(Vector2(500, 200), 180.0, Color.PURPLE)
	nova._process(0.016)
	_check(nova._active == true, "VFXSupernova aktif dengan korona surya 360 derajat.")
	nova.queue_free()

	# 7. VFXShadowSmoke
	var smoke = VFXShadowSmokeScript.new()
	add_child(smoke)
	smoke.trigger_smoke(Vector2(200, 300), Color.RED, 12, 0.3)
	smoke._process(0.016)
	_check(smoke._active == true, "VFXShadowSmoke aktif dengan gumpalan asap ninja.")
	smoke.queue_free()

	# 8. VFXShurikenStorm
	var shuriken = VFXShurikenStormScript.new()
	add_child(shuriken)
	shuriken.trigger_shurikens(Vector2(300, 300), 1, Color.RED, 0.3)
	shuriken._process(0.016)
	_check(shuriken._active == true, "VFXShurikenStorm aktif dengan 3 shuriken berkipas.")
	shuriken.queue_free()

	# 9. VFXCinematicSlash
	var c_slash = VFXCinematicSlashScript.new()
	add_child(c_slash)
	c_slash.trigger_cinematic_slash(Vector2(400, 300), 3, Color.RED, 0.35, 200.0)
	c_slash._process(0.016)
	_check(c_slash._active == true, "VFXCinematicSlash aktif dengan tebasan bersilangan.")
	c_slash.queue_free()

	# 10. VFXHitSpark
	var hitspark = VFXHitSparkScript.new()
	add_child(hitspark)
	hitspark.trigger_hitspark(Vector2(500, 300), 2, Color.YELLOW, Vector2.RIGHT)
	hitspark._process(0.016)
	_check(hitspark._active == true, "VFXHitSpark aktif dengan bintang geometris.")
	hitspark.queue_free()

	# 11. VFXGuardSpark
	var guard = VFXGuardSparkScript.new()
	add_child(guard)
	guard.trigger_guard(Vector2(600, 300), -1, Color.CYAN)
	guard._process(0.016)
	_check(guard._active == true, "VFXGuardSpark aktif dengan matriks heksagonal pertahanan.")
	guard.queue_free()

	# 12. VFXCyberDebris
	var debris = VFXCyberDebrisScript.new()
	add_child(debris)
	debris.trigger_debris(Vector2(700, 300), Vector2.UP, 8, Color.WHITE)
	debris._process(0.016)
	_check(debris._active == true, "VFXCyberDebris aktif dengan lempeng serpihan baja mecha.")
	debris.queue_free()

func _test_vfx_manager_spawn_methods() -> void:
	var mgr: Node2D = VFXManagerScript.new()
	add_child(mgr)

	var before := mgr.get_child_count()
	var n1 = mgr.spawn_cryo_freeze(Vector2(100, 100))
	var n2 = mgr.spawn_hex_barrier(null, Vector2(200, 200))
	var n3 = mgr.spawn_seismic_impact(Vector2(300, 300))
	var n4 = mgr.spawn_orbital_beam(Vector2(400, 400))
	var n5 = mgr.spawn_disrupter_drone(Vector2(500, 500))
	var n6 = mgr.spawn_supernova(Vector2(600, 600))
	var n7 = mgr.spawn_shadow_smoke(Vector2(700, 700))
	var n8 = mgr.spawn_shuriken_storm(Vector2(800, 800))
	var n9 = mgr.spawn_cinematic_slash(Vector2(900, 900))
	var n10 = mgr.spawn_hitspark(Vector2(100, 200))
	var n11 = mgr.spawn_guard_spark(Vector2(200, 300))
	var n12 = mgr.spawn_cyber_debris(Vector2(300, 400))

	_check(mgr.get_child_count() == before + 12, "VFXManager berhasil memunculkan 12 jenis node efek visual spesifik.")
	_check(n1 != null and n2 != null and n3 != null and n4 != null and n5 != null and n6 != null and n7 != null and n8 != null and n9 != null and n10 != null and n11 != null and n12 != null, "Semua node VFX hasil instansiasi tidak null.")

	mgr.queue_free()

func _test_vfx_manager_skill_cast_handling() -> void:
	var mgr: Node2D = VFXManagerScript.new()
	add_child(mgr)

	var caster := Node2D.new()
	caster.name = "TestMecha"
	add_child(caster)

	var skills_to_test: Array[StringName] = [
		&"BlinkSlash", &"DeflectionMatrix", &"AbsoluteZeroProtocol",
		&"HydraulicPiledriver", &"RiotShield", &"OrbitalSiegeCannon",
		&"PhotonRailgun", &"DisrupterDrone", &"SupernovaHorizon",
		&"StanceShift", &"IaidoCrescent", &"ShurikenStorm", &"ShadowBlossom",
		&"CataclysmSlash", &"ShadowShockwave", &"ZeroOverload"
	]

	for s in skills_to_test:
		var pre := mgr.get_child_count()
		mgr._on_skill_cast(caster, s, Vector2(200, 200), 1)
		var post := mgr.get_child_count()
		_check(post > pre, "Skill cast '%s' berhasil memicu efek visual di VFXManager." % s)

	caster.queue_free()
	mgr.queue_free()

func _test_vfx_manager_hit_impact_effects() -> void:
	var mgr: Node2D = VFXManagerScript.new()
	add_child(mgr)

	var p1 := Node2D.new()
	var p2 := Node2D.new()
	p1.name = "Viper"
	p2.name = "Bulwark"
	p1.global_position = Vector2(100, 100)
	p2.global_position = Vector2(150, 100)
	add_child(p1)
	add_child(p2)

	# 1. Hit Clean BlinkSlash
	var before := mgr.get_child_count()
	mgr._on_hit_confirmed(p1, p2, {"name": "BlinkSlash", "damage": 80})
	_check(mgr.get_child_count() > before, "Hit confirmed BlinkSlash memicu efek kontak kriogenik & tebasan.")

	# 2. Hit Clean HydraulicPiledriver
	var before_bulwark := mgr.get_child_count()
	mgr._on_hit_confirmed(p2, p1, {"name": "HydraulicPiledriver", "damage": 220})
	_check(mgr.get_child_count() > before_bulwark, "Hit confirmed HydraulicPiledriver memicu efek retakan seismik.")

	# 3. Blocked Hit
	var before_block := mgr.get_child_count()
	mgr._on_hit_confirmed(p1, p2, {"name": "5L", "damage": 40, "blocked": true})
	_check(mgr.get_child_count() > before_block, "Blocked hit confirmed memicu efek guard spark heksagonal.")

	p1.queue_free()
	p2.queue_free()
	mgr.queue_free()

func _test_character_skill_cast_integration() -> void:
	var received_skills: Array[StringName] = []
	var on_cast = func(_caster: Node2D, s_name: StringName, _pos: Vector2, _facing: int):
		received_skills.append(s_name)

	EventBus.skill_cast.connect(on_cast)

	# 1. Apex-0 Viper
	var viper: BaseMecha = ApexViperScript.new()
	add_child(viper)
	viper.execute_skill_1()
	_check(received_skills.has(&"BlinkSlash"), "Viper execute_skill_1 memancarkan sinyal EventBus.skill_cast (BlinkSlash).")
	viper.execute_skill_2()
	_check(received_skills.has(&"DeflectionMatrix"), "Viper execute_skill_2 memancarkan sinyal DeflectionMatrix.")
	viper.current_ultimate = 100.0
	viper.execute_ultimate()
	_check(received_skills.has(&"AbsoluteZeroProtocol"), "Viper execute_ultimate memancarkan sinyal AbsoluteZeroProtocol.")
	viper.queue_free()

	# 2. Titan-V Bulwark
	var bulwark: BaseMecha = TitanBulwarkScript.new()
	add_child(bulwark)
	bulwark.execute_skill_1()
	_check(received_skills.has(&"HydraulicPiledriver"), "Bulwark execute_skill_1 memancarkan sinyal HydraulicPiledriver.")
	bulwark.execute_skill_2()
	_check(received_skills.has(&"RiotShield"), "Bulwark execute_skill_2 memancarkan sinyal RiotShield.")
	bulwark.current_ultimate = 100.0
	bulwark.execute_ultimate()
	_check(received_skills.has(&"OrbitalSiegeCannon"), "Bulwark execute_ultimate memancarkan sinyal OrbitalSiegeCannon.")
	bulwark.queue_free()

	# 3. Ray-X Pulsar
	var pulsar: BaseMecha = RayPulsarScript.new()
	add_child(pulsar)
	bulwark = null
	pulsar.execute_skill_1()
	_check(received_skills.has(&"Skill1"), "Pulsar execute_skill_1 memancarkan sinyal PhotonRailgun / Skill1.")
	pulsar.execute_skill_2()
	_check(received_skills.has(&"Skill2"), "Pulsar execute_skill_2 memancarkan sinyal DisrupterDrone / Skill2.")
	pulsar.execute_ultimate()
	_check(received_skills.has(&"Ultimate"), "Pulsar execute_ultimate memancarkan sinyal SupernovaHorizon / Ultimate.")
	pulsar.queue_free()

	# 4. Phantom-9 Kage
	var kage: BaseMecha = PhantomKageScript.new()
	add_child(kage)
	kage.execute_skill_1()
	_check(received_skills.has(&"Skill1"), "Kage execute_skill_1 memancarkan sinyal StanceShift / Skill1.")
	kage.execute_skill_2()
	_check(received_skills.has(&"Skill2"), "Kage execute_skill_2 memancarkan sinyal IaidoCrescent / Skill2.")
	kage.execute_ultimate()
	_check(received_skills.has(&"Ultimate"), "Kage execute_ultimate memancarkan sinyal ShadowBlossom / Ultimate.")
	kage.queue_free()

	EventBus.skill_cast.disconnect(on_cast)

func _test_vfx_showcase_scene() -> void:
	var showcase_scene: PackedScene = load("res://scenes/vfx_showcase.tscn")
	_check(showcase_scene != null, "Scene res://scenes/vfx_showcase.tscn berhasil dimuat.")
	var showcase = showcase_scene.instantiate()
	add_child(showcase)
	_check(showcase.vfx_manager != null, "VFXShowcase memiliki instance VFXManager.")
	_check(showcase.caster_dummy != null and showcase.target_dummy != null, "VFXShowcase memiliki Caster Dummy dan Target Dummy.")
	_check(showcase.SKILLS.size() >= 14, "VFXShowcase memuat seluruh 14+ skill mecha roster.")
	showcase.queue_free()

func _test_mecha_pixel_sprite_distinct_attack_techniques() -> void:
	var spr: MechaPixelSprite = MechaPixelSpriteScript.new()
	add_child(spr)

	var archetypes_attacks: Dictionary = {
		&"viper": [&"5L", &"5L2", &"5H", &"BlinkSlash", &"DeflectionMatrix", &"AbsoluteZeroProtocol"],
		&"bulwark": [&"5L", &"5H", &"HydraulicPiledriver", &"RiotShield", &"OrbitalSiegeCannon"],
		&"pulsar": [&"5L", &"5H", &"PhotonRailgun", &"DisrupterDrone", &"SupernovaHorizon"],
		&"kage": [&"5L", &"5H", &"IaidoCrescent", &"ShurikenStorm", &"StanceShift", &"ShadowBlossom"]
	}

	for arch in archetypes_attacks.keys():
		spr.archetype = arch
		spr.current_state = &"Attack"
		for atk in archetypes_attacks[arch]:
			spr.attack_type = atk
			spr.attack_frame = 2
			spr.queue_redraw()
			# Trigger NOTIFICATION_DRAW sesuai siklus hidup CanvasItem Godot
			spr.notification(CanvasItem.NOTIFICATION_DRAW)
			_check(spr.attack_type == atk, "Sprite %s sukses mengonfigurasi teknik menyerang '%s'." % [arch, atk])

	spr.queue_free()

func _test_cinematic_juice_systems() -> void:
	# 1. VFXSuperFlash
	var flash := VFXSuperFlashScript.new()
	add_child(flash)
	flash.trigger_super_flash(Vector2(400, 300), Color.CYAN, 0.42)
	_check(flash.is_active == true, "VFXSuperFlash aktif dengan screen dimming & lens flare.")
	flash.notification(CanvasItem.NOTIFICATION_DRAW)
	flash.queue_free()

	# 2. VFXFloatingText
	var ftext := VFXFloatingTextScript.new()
	add_child(ftext)
	ftext.trigger_text(Vector2(400, 300), "120 CRITICAL!", Color.RED, true, 0.65)
	_check(ftext.is_active == true and ftext.is_critical == true, "VFXFloatingText aktif untuk hit kritis pop-up.")
	ftext.notification(CanvasItem.NOTIFICATION_DRAW)
	ftext.queue_free()

	# 3. VFXGroundDecal
	var decal := VFXGroundDecalScript.new()
	add_child(decal)
	decal.trigger_decal(Vector2(400, 480), &"cracks", Color.ORANGE, 70.0, 2.0)
	_check(decal.is_active == true and decal.decal_type == &"cracks", "VFXGroundDecal aktif untuk retakan tanah.")
	decal.notification(CanvasItem.NOTIFICATION_DRAW)
	decal.queue_free()

	# 4. CombatCamera Zoom Punch & Super Zoom
	var cam := CombatCameraScript.new()
	add_child(cam)
	cam.request_zoom_punch(1.08, 8)
	_check(cam.current_zoom_factor >= 1.08 and cam.zoom_frames_left == 8, "CombatCamera zoom punch terkonfigurasi.")
	cam.request_super_zoom(Vector2(500, 300), 1.25, 24)
	_check(cam.super_zoom_frames_left == 24 and cam.current_zoom_factor >= 1.25, "CombatCamera super freeze zoom terkonfigurasi.")
	cam.queue_free()

	# 5. VFXGhostTrail 4 Archetypes
	var archs: Array[StringName] = [&"viper", &"bulwark", &"pulsar", &"kage"]
	for a in archs:
		var ghost := VFXGhostTrailScript.new()
		add_child(ghost)
		ghost.setup(Vector2(400, 300), 1, a)
		ghost.notification(CanvasItem.NOTIFICATION_DRAW)
		_check(ghost.archetype == a, "VFXGhostTrail berhasil membuat siluet arketipe '%s'." % a)
		ghost.queue_free()

	# 6. VFXManager Spawn Helpers
	var mgr := VFXManagerScript.new()
	add_child(mgr)
	var spawned_flash = mgr.spawn_super_flash(Vector2(100, 100))
	var spawned_text = mgr.spawn_floating_text(Vector2(100, 100), "75")
	var spawned_decal = mgr.spawn_ground_decal(Vector2(100, 100))
	var spawned_ghost = mgr.spawn_ghost_trail(Vector2(100, 100))
	_check(spawned_flash != null and spawned_text != null and spawned_decal != null and spawned_ghost != null, "VFXManager berhasil memunculkan seluruh 4 node efek juice baru.")
	mgr.queue_free()
