extends Node

const VFXGhostTrailScript = preload("res://scripts/visual/vfx_ghost_trail.gd")
const DashTrailComponentScript = preload("res://scripts/visual/dash_trail_component.gd")
const VFXCoreRuptureScript = preload("res://scripts/visual/vfx_core_rupture.gd")
const CyberCityBackgroundScript = preload("res://scripts/arena/cyber_city_background.gd")
const ArenaSkyscraperScene = preload("res://scenes/arena_skyscraper.tscn")
const ApexViperScript = preload("res://scripts/characters/apex_viper.gd")
const TitanBulwarkScript = preload("res://scripts/characters/titan_bulwark.gd")

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

func _ready() -> void:
	var out_path: String = ProjectSettings.globalize_path("res://test_ghost_trail_and_stage_vfx_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 7.2: Ghost Trail, Core Rupture & Stage VFX...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_vfx_ghost_trail_decay_and_cleanup,
		_test_dash_trail_component_spawning,
		_test_vfx_core_rupture_lifecycle,
		_test_cyber_city_background_generation,
		_test_arena_skyscraper_vfx_integration
	]

	var passed: int = 0
	for t in tests:
		_failed = false
		_log("\n--- %s ---" % t.get_method())
		t.call()
		if _failed:
			_log(" [GAGAL]")
		else:
			passed += 1
			_log(" [LULUS]")

	_log("\n==================================================")
	_log("HASIL: %d/%d pengujian lulus." % [passed, tests.size()])
	_log("==================================================")

	if log_file:
		log_file.close()

	if passed == tests.size():
		get_tree().quit(0)
	else:
		get_tree().quit(1)

func _test_vfx_ghost_trail_decay_and_cleanup() -> void:
	var ghost = VFXGhostTrailScript.new()
	add_child(ghost)
	ghost.setup(Vector2(200, 200), 1, &"viper")

	_check(ghost.trail_color.a > 0.65, "Alpha awal ghost trail harus >= 0.65")
	_check(ghost.archetype == &"viper", "Archetype harus viper")

	ghost._physics_process(1.0 / 60.0)
	_check(ghost.frames_alive == 1, "frames_alive harus bertambah")
	var alpha_1 = ghost.trail_color.a

	ghost._physics_process(1.0 / 60.0)
	var alpha_2 = ghost.trail_color.a
	_check(alpha_2 < alpha_1, "Alpha harus memudar seiring frame berjalan")

	# Simulasikan hingga masa hidup selesai
	for i in range(10):
		ghost._physics_process(1.0 / 60.0)

	_check(ghost.is_queued_for_deletion(), "Ghost trail harus queue_free saat lifetime habis")

func _test_dash_trail_component_spawning() -> void:
	var viper = ApexViperScript.new()
	add_child(viper)
	viper._ready()

	var dt = viper.get_node_or_null("DashTrailComponent") as DashTrailComponentScript
	_check(dt != null, "DashTrailComponent harus otomatis terpasang pada ApexViper")

	# Panggil spawn ghost manual
	dt._spawn_ghost()
	var spawned: bool = false
	for child in get_children():
		if child is VFXGhostTrailScript:
			spawned = true
			child.queue_free()
			break
	_check(spawned, "DashTrailComponent harus berhasil memunculkan instance VFXGhostTrail")

	viper.queue_free()

func _test_vfx_core_rupture_lifecycle() -> void:
	var rupture = VFXCoreRuptureScript.new()
	add_child(rupture)
	rupture.trigger_at(Vector2(400, 250))

	_check(rupture.sparks_particles != null, "Partikel sparks_particles harus ada")
	_check(rupture.sparks_particles.emitting, "Partikel ledakan reaktor harus aktif memancar")
	_check(rupture.sparks_particles.spread >= 170.0, "Spread harus radial (360 derajat)")

	# Majukan frame hingga shockwave selesai
	for i in range(36):
		rupture._physics_process(1.0 / 60.0)

	_check(rupture.is_queued_for_deletion(), "VFXCoreRupture harus membersihkan diri setelah max_frames")

func _test_cyber_city_background_generation() -> void:
	var bg = CyberCityBackgroundScript.new()
	add_child(bg)
	bg._ready()

	_check(bg.window_grid.size() > 20, "Window grid kota New Babel-01 harus terisi jendela pixel")
	
	var initial_x = bg.hovercraft_pos.x
	bg._physics_process(0.1)
	_check(bg.hovercraft_pos.x > initial_x, "Hovercraft harus melaju ke kanan secara horizontal")

	bg.queue_free()

func _test_arena_skyscraper_vfx_integration() -> void:
	var arena = ArenaSkyscraperScene.instantiate()
	add_child(arena)

	var bg_node = arena.get_node_or_null("Background")
	_check(bg_node != null, "Arena harus memiliki node Background")

	var city_layer = bg_node.get_node_or_null("CyberCityLayer") if bg_node else null
	_check(city_layer != null, "Background harus memiliki CyberCityLayer dinamis")
	_check(city_layer is CyberCityBackgroundScript, "CyberCityLayer harus berinstansiasi CyberCityBackground")

	arena.queue_free()
