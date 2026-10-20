extends Node

const VFXWeldingSparksScript = preload("res://scripts/visual/vfx_sparks.gd")
const VFXEnergySlashScript = preload("res://scripts/visual/vfx_slash.gd")
const VFXSteamVentScript = preload("res://scripts/visual/vfx_steam_vent.gd")
const VFXManagerScript = preload("res://scripts/visual/vfx_manager.gd")
const ArenaSkyscraperScene = preload("res://scenes/arena_skyscraper.tscn")
const BaseMechaScript = preload("res://scripts/characters/base_mecha.gd")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_pixel_vfx_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 6.2: Pixel VFX & Sparks...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_welding_sparks_trigger,
		_test_energy_slash_render,
		_test_steam_vent_overclock_and_meltdown,
		_test_vfx_manager_hit_and_parry_dispatch,
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

func _test_welding_sparks_trigger() -> void:
	var sparks: CPUParticles2D = VFXWeldingSparksScript.new()
	sparks.auto_destroy = false
	add_child(sparks)

	# 1. Normal Hit Sparks
	sparks.trigger_sparks(Vector2(200, 200), 0.0, false)
	_check(sparks.emitting, "Partikel percikan las memancar saat dipicu.")
	_check(sparks.amount == 14, "Jumlah partikel normal adalah 14.")
	_check(sparks.one_shot, "Partikel diset ke mode one_shot.")

	# 2. Parry Boost Sparks
	sparks.trigger_sparks(Vector2(200, 200), 0.0, true)
	_check(sparks.amount == 28, "Spark Parry melipatgandakan jumlah partikel menjadi 28.")
	_check(sparks.initial_velocity_max >= 300.0, "Kecepatan lontaran parry lebih tinggi (>= 300 px/s).")

	sparks.queue_free()

func _test_energy_slash_render() -> void:
	var slash: Node2D = VFXEnergySlashScript.new()
	add_child(slash)

	slash.trigger_slash(Vector2(150, 150), 1, Color(0.2, 0.95, 1.0))
	_check(slash._active, "Tebasan energi aktif setelah trigger.")
	_check(slash.slash_color == Color(0.2, 0.95, 1.0), "Warna neon tebasan sesuai.")

	# Simulasikan setengah durasi
	slash._process(0.05)
	_check(slash._active, "Tebasan tetap aktif di frame awal.")

	# Simulasikan hingga selesai
	slash._process(0.10)
	_check(not slash._active, "Tebasan nonaktif setelah melampaui durasi.")

func _test_steam_vent_overclock_and_meltdown() -> void:
	var vent: CPUParticles2D = VFXSteamVentScript.new()
	add_child(vent)

	# 1. Suhu normal (50%) -> Tidak aktif
	vent.update_heat_visual(50.0)
	_check(not vent.emitting, "Uap ventilasi nonaktif saat suhu normal (50%).")

	# 2. Suhu Overclock (85%) -> Aktif uap kebiruan
	vent.update_heat_visual(85.0)
	_check(vent.emitting, "Uap ventilasi memancar di zona Overclock (85%).")
	_check(vent.color.b > 0.8, "Warna uap Overclock adalah putih kebiruan.")

	# 3. Suhu Meltdown Kritis (98%) -> Aktif uap merah membara
	vent.update_heat_visual(98.0)
	_check(vent.emitting, "Uap ventilasi memancar pada Meltdown (98%).")
	_check(vent.color.r > 0.8 and vent.color.b < 0.4, "Warna uap Meltdown adalah merah/oranye membara.")

	vent.queue_free()

func _create_dummy_mecha() -> CharacterBody2D:
	var m: CharacterBody2D = BaseMechaScript.new()
	var sm := Node.new()
	sm.name = "StateMachine"
	sm.set_script(preload("res://scripts/combat/fsm/state_machine.gd"))
	m.add_child(sm)
	return m

func _test_vfx_manager_hit_and_parry_dispatch() -> void:
	var vfx_mgr: Node2D = VFXManagerScript.new()
	add_child(vfx_mgr)

	var p1 := _create_dummy_mecha()
	var p2 := _create_dummy_mecha()
	p1.name = "P1_Apex"
	p2.name = "P2_Titan"
	p1.global_position = Vector2(200, 200)
	p2.global_position = Vector2(250, 200)
	add_child(p1)
	add_child(p2)

	var initial_children := vfx_mgr.get_child_count()

	# 1. Trigger Hit Confirmed
	vfx_mgr._on_hit_confirmed(p1, p2, {"name": "5L", "damage": 40})
	var count_after_hit := vfx_mgr.get_child_count()
	_check(count_after_hit > initial_children, "VFXManager memunculkan node efek visual saat hit terkonfirmasi.")

	# 2. Trigger Parry
	vfx_mgr._on_parry_triggered(p1, p2)
	var count_after_parry := vfx_mgr.get_child_count()
	_check(count_after_parry > count_after_hit, "VFXManager memunculkan efek percikan parry saat parry terpicu.")

	p1.queue_free()
	p2.queue_free()
	vfx_mgr.queue_free()

func _test_arena_skyscraper_vfx_integration() -> void:
	var arena: Node2D = ArenaSkyscraperScene.instantiate()
	add_child(arena)

	var vfx := arena.get_node_or_null("VFXManager")
	_check(vfx != null, "VFXManager terpasang di scene ArenaSkyscraper.")
	_check(vfx.has_method("spawn_sparks"), "VFXManager memiliki method spawn_sparks.")
	_check(vfx.has_method("spawn_slash"), "VFXManager memiliki method spawn_slash.")

	arena.queue_free()
