extends Node

const MatchConfigScript = preload("res://scripts/core/match_config.gd")
const FighterFactoryScript = preload("res://scripts/characters/fighter_factory.gd")
const SteamVentHazardScript = preload("res://scripts/hazards/steam_vent_hazard.gd")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_underground_reactor_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 12.1: Underground Reactor Stage...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_reactor_scene_structure,
		_test_steam_vent_hazard_lifecycle,
		_test_steam_vent_heat_and_damage_application,
		_test_match_config_arena_routing,
		_test_character_select_stage_toggle
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
	get_tree().quit(0 if passed == tests.size() else 1)

func _test_reactor_scene_structure() -> void:
	var scene: PackedScene = load("res://scenes/arena_underground_reactor.tscn")
	_check(scene != null, "Scene arena_underground_reactor.tscn harus valid")
	var arena = scene.instantiate()
	add_child(arena)

	_check(arena.get_node_or_null("Platform") != null, "Platform lantai harus ada")
	_check(arena.get_node_or_null("LeftWall") != null, "LeftWall batas kiri harus ada")
	_check(arena.get_node_or_null("RightWall") != null, "RightWall batas kanan harus ada")
	_check(arena.get_node_or_null("VentLeft") != null, "VentLeft hazard harus ada")
	_check(arena.get_node_or_null("VentRight") != null, "VentRight hazard harus ada")

	var lw: StaticBody2D = arena.get_node("LeftWall") as StaticBody2D
	var rw: StaticBody2D = arena.get_node("RightWall") as StaticBody2D
	_check(lw.collision_layer == 1, "LeftWall harus berada pada Collision Layer 1 (World)")
	_check(rw.collision_layer == 1, "RightWall harus berada pada Collision Layer 1 (World)")

	arena.queue_free()

func _test_steam_vent_hazard_lifecycle() -> void:
	var vent = SteamVentHazardScript.new()
	add_child(vent)

	_check(vent.current_state == SteamVentHazardScript.VentState.DORMANT, "State awal vent harus DORMANT")
	_check(vent.vent_particles != null, "Partikel uap harus terinisialisasi")
	_check(not vent.vent_particles.emitting, "Partikel uap tidak boleh aktif saat DORMANT")

	# Transisi ke WARNING
	vent._advance_state()
	_check(vent.current_state == SteamVentHazardScript.VentState.WARNING, "State harus bertransisi ke WARNING")
	_check(not vent.vent_particles.emitting, "Partikel uap tidak boleh aktif saat WARNING")

	# Transisi ke ERUPTION
	vent._advance_state()
	_check(vent.current_state == SteamVentHazardScript.VentState.ERUPTION, "State harus bertransisi ke ERUPTION")
	_check(vent.vent_particles.emitting, "Partikel uap harus memancar aktif saat ERUPTION")

	# Transisi kembali ke DORMANT
	vent._advance_state()
	_check(vent.current_state == SteamVentHazardScript.VentState.DORMANT, "State harus kembali ke DORMANT")
	_check(not vent.vent_particles.emitting, "Partikel uap harus mati saat kembali ke DORMANT")

	vent.queue_free()

func _test_steam_vent_heat_and_damage_application() -> void:
	var fighter = FighterFactoryScript.create_fighter(&"viper", 1)
	add_child(fighter)
	var vent = SteamVentHazardScript.new()
	add_child(vent)

	var initial_hp: int = fighter.current_hp
	var initial_heat: float = fighter.heat_gauge

	# Maju ke ERUPTION
	vent._advance_state() # Warning
	vent._advance_state() # Eruption

	# Panggil _scorch_fighter
	vent._scorch_fighter(fighter)

	_check(fighter.heat_gauge >= initial_heat + 20.0, "Panas mecha harus bertambah minimal +20% setelah terkena semburan uap")
	_check(fighter.current_hp < initial_hp, "HP mecha harus berkurang (chip damage) setelah terkena semburan uap")

	# Pastikan tidak terjadi multihit ganda instan dalam 1 erupsi
	var hp_after_first = fighter.current_hp
	vent._scorch_fighter(fighter)
	_check(fighter.current_hp == hp_after_first, "Fighter tidak boleh terkena damage ganda beruntun dalam 1 siklus erupsi")

	fighter.queue_free()
	vent.queue_free()

func _test_match_config_arena_routing() -> void:
	MatchConfigScript.reset_defaults()
	_check(MatchConfigScript.selected_arena == &"skyscraper", "Arena default harus skyscraper")
	_check(MatchConfigScript.get_arena_scene() == "res://scenes/arena_skyscraper.tscn", "Target scene arena default harus arena_skyscraper.tscn")

	MatchConfigScript.set_arena(&"reactor")
	_check(MatchConfigScript.selected_arena == &"reactor", "Arena harus terset ke reactor")
	_check(MatchConfigScript.get_arena_scene() == "res://scenes/arena_underground_reactor.tscn", "Target scene arena harus arena_underground_reactor.tscn saat reactor aktif")

func _test_character_select_stage_toggle() -> void:
	MatchConfigScript.reset_defaults()
	var char_select_scene: PackedScene = load("res://scenes/character_select.tscn")
	var cs = char_select_scene.instantiate()
	add_child(cs)

	_check(MatchConfigScript.selected_arena == &"skyscraper", "Arena awal harus skyscraper")
	
	# Toggle stage
	cs.toggle_stage()
	_check(MatchConfigScript.selected_arena == &"reactor", "Setelah toggle, arena harus menjadi reactor")
	if cs.stage_label:
		_check(cs.stage_label.text.contains("REACTOR"), "Stage label harus menampilkan status UNDERGROUND REACTOR")

	# Toggle balik
	cs.toggle_stage()
	_check(MatchConfigScript.selected_arena == &"skyscraper", "Setelah toggle kedua, arena harus kembali ke skyscraper")

	cs.queue_free()
