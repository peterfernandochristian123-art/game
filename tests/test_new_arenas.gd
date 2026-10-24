extends Node

## Unit & Integration Test untuk Arena Baru: Orbital Station & Cyber Highway

const MatchConfigScript = preload("res://scripts/core/match_config.gd")
const ArenaOrbitalStationScript = preload("res://scripts/arena/arena_orbital_station.gd")
const ArenaCyberHighwayScript = preload("res://scripts/arena/arena_cyber_highway.gd")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_new_arenas_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)

	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Arena Baru (Orbital & Cyber Highway)...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_match_config_arena_cycling,
		_test_orbital_station_instantiation,
		_test_cyber_highway_instantiation,
		_test_character_select_stage_cycling,
		_test_arcade_ladder_multi_arena
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
		_log("SEMUA PENGUJIAN ARENA BARU BERHASIL (100% SUKSES)!")
	else:
		_log("BEBERAPA PENGUJIAN ARENA BARU GAGAL!")

	if log_file:
		log_file.close()

	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func _test_match_config_arena_cycling() -> void:
	MatchConfigScript.reset_defaults()
	_check(MatchConfigScript.selected_arena == &"skyscraper", "Default arena adalah skyscraper.")
	_check(MatchConfigScript.AVAILABLE_ARENAS.size() == 4, "Tersedia 4 arena di MatchConfig.")

	var a1 = MatchConfigScript.cycle_next_arena()
	_check(a1 == &"reactor" and MatchConfigScript.get_arena_scene().contains("reactor"), "Cycle ke-1: Underground Reactor.")

	var a2 = MatchConfigScript.cycle_next_arena()
	_check(a2 == &"orbital" and MatchConfigScript.get_arena_scene().contains("orbital"), "Cycle ke-2: Orbital Station.")

	var a3 = MatchConfigScript.cycle_next_arena()
	_check(a3 == &"highway" and MatchConfigScript.get_arena_scene().contains("highway"), "Cycle ke-3: Cyber Highway.")

	var a4 = MatchConfigScript.cycle_next_arena()
	_check(a4 == &"skyscraper" and MatchConfigScript.get_arena_scene().contains("skyscraper"), "Cycle ke-4: Kembali ke Skyscraper.")

	MatchConfigScript.reset_defaults()

func _test_orbital_station_instantiation() -> void:
	var scene = load("res://scenes/arena_orbital_station.tscn")
	_check(scene != null, "Scene arena_orbital_station.tscn berhasil dimuat.")
	
	var arena = scene.instantiate()
	add_child(arena)
	_check(arena is ArenaOrbitalStationScript, "Root node arena orbital adalah ArenaOrbitalStation.")
	_check(arena.get_node_or_null("Platform") != null, "Arena memiliki Platform fisika.")
	_check(arena.get_node_or_null("LeftLedgeSensor") != null, "Arena memiliki LeftLedgeSensor (Cliffhanger).")
	_check(arena.get_node_or_null("RightLedgeSensor") != null, "Arena memiliki RightLedgeSensor (Cliffhanger).")
	_check(arena.get_node_or_null("Camera2D") != null, "Arena memiliki Camera2D.")
	_check(arena.get_node_or_null("VFXManager") != null, "Arena memiliki VFXManager.")
	_check(arena.is_within_platform(704.0) == true, "Koordinat X=704 berada di dalam platform.")
	_check(arena.is_within_platform(10.0) == false, "Koordinat X=10 di luar platform.")
	
	arena.queue_free()

func _test_cyber_highway_instantiation() -> void:
	var scene = load("res://scenes/arena_cyber_highway.tscn")
	_check(scene != null, "Scene arena_cyber_highway.tscn berhasil dimuat.")
	
	var arena = scene.instantiate()
	add_child(arena)
	_check(arena is ArenaCyberHighwayScript, "Root node arena highway adalah ArenaCyberHighway.")
	_check(arena.get_node_or_null("Platform") != null, "Arena memiliki Platform aspal.")
	_check(arena.get_node_or_null("LeftWall") != null, "Arena memiliki LeftWall (Wall-Bounce).")
	_check(arena.get_node_or_null("RightWall") != null, "Arena memiliki RightWall (Wall-Bounce).")
	_check(arena.get_node_or_null("Camera2D") != null, "Arena memiliki Camera2D.")
	_check(arena.get_node_or_null("VFXManager") != null, "Arena memiliki VFXManager.")
	_check(arena.is_within_platform(704.0) == true, "Koordinat X=704 berada di dalam highway.")
	
	arena.queue_free()

func _test_character_select_stage_cycling() -> void:
	var scene = load("res://scenes/character_select.tscn")
	_check(scene != null, "Scene character_select.tscn berhasil dimuat.")
	
	var cs = scene.instantiate()
	add_child(cs)
	
	MatchConfigScript.set_arena(&"skyscraper")
	cs._update_stage_ui()
	_check(cs.stage_label.text.contains("SKYSCRAPER"), "Label awal menampilkan SKYSCRAPER.")
	
	cs.toggle_stage()
	_check(cs.stage_label.text.contains("REACTOR"), "Toggle ke-1 menampilkan REACTOR.")
	
	cs.toggle_stage()
	_check(cs.stage_label.text.contains("ORBITAL"), "Toggle ke-2 menampilkan ORBITAL.")
	
	cs.toggle_stage()
	_check(cs.stage_label.text.contains("HIGHWAY"), "Toggle ke-3 menampilkan HIGHWAY.")
	
	cs.toggle_stage()
	_check(cs.stage_label.text.contains("SKYSCRAPER"), "Toggle ke-4 kembali ke SKYSCRAPER.")
	
	cs.queue_free()
	MatchConfigScript.reset_defaults()

func _test_arcade_ladder_multi_arena() -> void:
	var scene = load("res://scenes/arcade_ladder_mode.tscn")
	_check(scene != null, "Scene arcade_ladder_mode.tscn berhasil dimuat.")
	
	var arcade = scene.instantiate()
	add_child(arcade)
	
	_check(arcade.stages_data.size() == 4, "Arcade Gauntlet memiliki 4 stage.")
	_check(arcade.stages_data[0]["arena"] == &"skyscraper", "Stage 1 berlangsung di Skyscraper.")
	_check(arcade.stages_data[1]["arena"] == &"highway", "Stage 2 berlangsung di Neo-Shibuya Highway.")
	_check(arcade.stages_data[2]["arena"] == &"reactor", "Stage 3 berlangsung di Underground Reactor.")
	_check(arcade.stages_data[3]["arena"] == &"orbital", "Stage 4 Boss berlangsung di Orbital Space Station.")
	
	arcade.queue_free()
