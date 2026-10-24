extends Node

const FighterFactoryScript = preload("res://scripts/characters/fighter_factory.gd")
const MatchConfigScript = preload("res://scripts/core/match_config.gd")
const CharacterSelectScript = preload("res://scripts/ui/character_select.gd")
const CharacterSelectScene = preload("res://scenes/character_select.tscn")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_character_select_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 11.1: Character Select Screen...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_fighter_factory_roster_metadata,
		_test_fighter_factory_instantiation,
		_test_match_config_state,
		_test_character_select_scene_structure,
		_test_character_select_navigation_and_lock_in,
		_test_character_select_cancel_return
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

func _test_fighter_factory_roster_metadata() -> void:
	_check(FighterFactoryScript.get_roster_count() >= 3, "Roster memiliki minimal 3 mecha petarung.")
	
	var viper = FighterFactoryScript.get_character_info(&"viper")
	_check(viper["hp"] == 900, "Apex-0 Viper memiliki 900 HP.")
	_check(viper["speed_grade"] == "A+", "Apex-0 Viper kecepatan grade A+.")

	var bulwark = FighterFactoryScript.get_character_info(&"bulwark")
	_check(bulwark["hp"] == 1200, "Titan-V Bulwark memiliki 1200 HP.")
	_check(bulwark["defense_grade"] == "S+", "Titan-V Bulwark pertahanan grade S+.")

	var pulsar = FighterFactoryScript.get_character_info(&"pulsar")
	_check(pulsar["hp"] == 950, "Ray-X Pulsar memiliki 950 HP.")
	_check(pulsar["range_grade"] == "S+", "Ray-X Pulsar jangkauan grade S+.")

func _test_fighter_factory_instantiation() -> void:
	var ids: Array[StringName] = [&"viper", &"bulwark", &"pulsar"]
	for id in ids:
		var fighter: CharacterBody2D = FighterFactoryScript.create_fighter(id, 1)
		add_child(fighter)
		_check(fighter != null, "Fighter '%s' berhasil diinstansiasi." % id)
		_check(fighter.get("player_index") == 1, "Player index terkonfigurasi ke 1.")
		_check(fighter.has_node("CollisionShape2D"), "CollisionShape2D terpasang pada fighter.")
		_check(fighter.has_node("StateMachine"), "StateMachine terpasang pada fighter.")
		fighter.queue_free()

func _test_match_config_state() -> void:
	MatchConfigScript.reset_defaults()
	_check(MatchConfigScript.p1_character == &"viper", "Default P1 adalah viper.")
	_check(MatchConfigScript.p2_character == &"bulwark", "Default P2 adalah bulwark.")
	_check(MatchConfigScript.get_target_scene() == "res://scenes/versus_ai_mode.tscn", "Default target scene adalah versus_ai_mode.tscn.")

	MatchConfigScript.set_p1(&"pulsar")
	MatchConfigScript.set_p2(&"viper")
	MatchConfigScript.set_mode(&"local_2p")
	_check(MatchConfigScript.p1_character == &"pulsar", "Set P1 ke pulsar berhasil.")
	_check(MatchConfigScript.p2_character == &"viper", "Set P2 ke viper berhasil.")
	_check(MatchConfigScript.get_target_scene() == "res://scenes/local_versus_mode.tscn", "Target scene Local 2P valid.")

func _test_character_select_scene_structure() -> void:
	var screen: Control = CharacterSelectScene.instantiate()
	add_child(screen)

	_check(screen != null, "Scene character_select.tscn berhasil diinstansiasi.")
	_check(screen.get_node("RosterArea/CardsContainer").get_child_count() == FighterFactoryScript.get_roster_count(), "CardsContainer memuat seluruh kartu petarung.")
	_check(screen.get_node("DetailsArea/P1Panel/Margin/VBox/HBoxTop/SpriteMount").get_child_count() > 0, "P1 SpriteMount memiliki preview pixel sprite.")
	_check(screen.get_node("DetailsArea/P2Panel/Margin/VBox/HBoxTop/SpriteMount").get_child_count() > 0, "P2 SpriteMount memiliki preview pixel sprite.")

	screen.queue_free()

func _test_character_select_navigation_and_lock_in() -> void:
	var screen: Control = CharacterSelectScene.instantiate()
	add_child(screen)

	var p1_emitted: Dictionary = {"idx": -1, "id": &""}
	screen.p1_selection_changed.connect(func(i, id):
		p1_emitted["idx"] = i
		p1_emitted["id"] = id
	)

	# Geser P1 ke index 1 (Bulwark)
	screen._change_p1_index(1)
	_check(screen.p1_index == 1, "P1 berpindah ke index 1 (Bulwark).")
	_check(p1_emitted["id"] == &"bulwark", "Sinyal p1_selection_changed memancarkan bulwark.")

	# Geser P1 ke index 2 (Pulsar)
	screen._change_p1_index(1)
	_check(screen.p1_index == 2, "P1 berpindah ke index 2 (Pulsar).")
	_check(p1_emitted["id"] == &"pulsar", "Sinyal p1_selection_changed memancarkan pulsar.")

	# Geser P1 melewati seluruh roster hingga wraparound ke index 0 (Viper)
	while screen.p1_index != 0:
		screen._change_p1_index(1)
	_check(screen.p1_index == 0, "Wraparound ke index 0 (Viper) berhasil.")

	# Konfirmasi kunci P1 & P2
	var confirmed: Dictionary = {"p1": &"", "p2": &""}
	screen.selection_confirmed.connect(func(p1, p2):
		confirmed["p1"] = p1
		confirmed["p2"] = p2
	)

	MatchConfigScript.set_mode(&"versus_ai")
	screen._confirm_selection()
	_check(screen.p1_locked, "P1 berstatus locked setelah konfirmasi.")
	_check(screen.p2_locked, "P2 berstatus locked otomatis pada mode versus_ai.")

	screen.queue_free()

func _test_character_select_cancel_return() -> void:
	var screen: Control = CharacterSelectScene.instantiate()
	add_child(screen)

	screen.p1_locked = true
	screen.p2_locked = true

	# Cancel saat locked harus mengembalikan status ke unlocked
	screen._cancel_or_return()
	_check(not screen.p1_locked and not screen.p2_locked, "Batal membuka kembali status lock karakter.")

	screen.queue_free()
