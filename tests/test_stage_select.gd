extends Node

## Unit & Integration Test untuk Sistem 12 Stage & Stage Select Screen

const StageManagerScript = preload("res://scripts/core/stage_manager.gd")
const MatchConfigScript = preload("res://scripts/core/match_config.gd")
const ArenaStageScript = preload("res://scripts/arena/arena_stage.gd")
const StageSelectScript = preload("res://scripts/ui/stage_select.gd")

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
	var out_path: String = ProjectSettings.globalize_path("res://test_stage_select_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)

	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian 12 Stage & Stage Select...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_stage_manager_registry,
		_test_stage_textures_availability,
		_test_match_config_stage_integration,
		_test_stage_select_ui_and_navigation,
		_test_arena_stage_all_12_maps,
		_test_versus_ai_stage_swap_and_combat,
		_test_local_versus_and_training_stage_swap
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
		_log("SEMUA PENGUJIAN 12 STAGE BERHASIL (100% SUKSES)!")
	else:
		_log("BEBERAPA PENGUJIAN 12 STAGE GAGAL!")

	if log_file:
		log_file.close()

	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func _test_stage_manager_registry() -> void:
	var expected_stages = [
		"sakura_temple", "neon_city", "ruin_factory", "forest_shrine",
		"rooftop", "snow_field", "canyon", "moon_castle",
		"ancient_ruins", "space_station", "traditional_town", "hell_gate"
	]
	_check(StageManagerScript.get_count() == 12, "StageManager memiliki 12 stage.")
	for id in expected_stages:
		_check(StageManagerScript.has_stage(StringName(id)), "Stage terdaftar: " + id)
		var info = StageManagerScript.get_stage(StringName(id))
		_check(info.has("name") and info.has("tag") and info.has("accent"), "Metadata lengkap untuk " + id)

func _test_stage_textures_availability() -> void:
	var stages = StageManagerScript.get_stages()
	for s in stages:
		var s_id: StringName = s["id"]
		var bg_tex = StageManagerScript.get_background_texture(s_id)
		_check(bg_tex != null, "Background texture valid untuk " + String(s_id))
		var thumb_tex = StageManagerScript.get_thumbnail_texture(s_id)
		_check(thumb_tex != null, "Thumbnail texture valid untuk " + String(s_id))

func _test_match_config_stage_integration() -> void:
	MatchConfigScript.reset_defaults()
	_check(MatchConfigScript.selected_stage == &"sakura_temple", "Default stage adalah sakura_temple.")
	
	var ok = MatchConfigScript.set_stage(&"neon_city")
	_check(ok == true, "set_stage neon_city berhasil.")
	_check(MatchConfigScript.selected_stage == &"neon_city", "selected_stage menjadi neon_city.")
	_check(MatchConfigScript.selected_arena == &"stage", "selected_arena berubah menjadi &\"stage\".")
	_check(MatchConfigScript.get_arena_scene() == "res://scenes/arenas/arena_stage.tscn", "Scene arena yang dimuat adalah arena_stage.tscn.")
	
	var invalid_ok = MatchConfigScript.set_stage(&"non_existent_stage")
	_check(invalid_ok == false, "set_stage invalid mengembalikan false.")
	
	MatchConfigScript.reset_defaults()

func _test_stage_select_ui_and_navigation() -> void:
	var scene = load("res://scenes/menus/stage_select.tscn")
	_check(scene != null, "Scene stage_select.tscn berhasil dimuat.")
	
	var menu: StageSelect = scene.instantiate()
	menu.change_scene_enabled = false # cegah scene change saat pengujian
	add_child(menu)
	
	_check(menu.cards.size() == 12, "Tersedia 12 kartu stage pada UI.")
	_check(menu.name_label != null, "Label nama stage ada.")
	_check(menu.fight_button != null, "Tombol FIGHT ada.")
	_check(menu.back_button != null, "Tombol BACK ada.")
	
	# Test initial selection
	_check(menu.get_selected_stage_id() == MatchConfigScript.selected_stage, "Pilihan awal sesuai MatchConfig.")
	
	# Test keyboard navigation
	menu.move_selection(1, 0)
	_check(menu.selected_index == 1, "Navigasi kanan memindahkan index ke 1.")
	
	menu.move_selection(0, 1)
	_check(menu.selected_index == 1 + menu.columns, "Navigasi bawah memindahkan baris.")
	
	# Test Fight action
	var signal_box = [false]
	menu.fight_requested.connect(func(_id): signal_box[0] = true)
	menu._on_fight_pressed()
	_check(signal_box[0] == true, "Tombol FIGHT memancarkan sinyal fight_requested.")
	_check(MatchConfigScript.selected_arena == &"stage", "FIGHT mengatur MatchConfig ke &\"stage\".")
	
	# Test Back action
	var back_box = [false]
	menu.back_requested.connect(func(): back_box[0] = true)
	menu.is_transitioning = false
	menu._on_back_pressed()
	_check(back_box[0] == true, "Tombol BACK memancarkan sinyal back_requested.")
	
	menu.queue_free()
	MatchConfigScript.reset_defaults()

func _test_arena_stage_all_12_maps() -> void:
	var scene = load("res://scenes/arenas/arena_stage.tscn")
	_check(scene != null, "Scene arena_stage.tscn berhasil dimuat.")
	
	var stages = StageManagerScript.get_stages()
	for s in stages:
		var s_id: StringName = s["id"]
		MatchConfigScript.set_stage(s_id)
		var arena = scene.instantiate()
		add_child(arena)
		
		_check(arena is ArenaStageScript, "ArenaStage terinstansiasi untuk stage " + String(s_id))
		_check(arena.get_node_or_null("Platform") != null, "Platform fisik ada pada stage " + String(s_id))
		_check(arena.get("floor_visual") != null, "Visual lantai bertema ada pada stage " + String(s_id))
		var plats = arena.get("elevated_platforms")
		_check(plats != null and plats.size() >= 2, "Tersedia platform melayang bertema (>= 2) pada stage " + String(s_id))
		_check(plats != null and plats[0].stage_id == s_id, "Platform melayang sesuai tema stage " + String(s_id))
		_check(plats != null and plats[0].collision_shape.one_way_collision == true, "Platform melayang memiliki one_way_collision untuk " + String(s_id))
		_check(arena.get_node_or_null("LeftWall") != null, "Dinding kiri ada pada stage " + String(s_id))
		_check(arena.get_node_or_null("RightWall") != null, "Dinding kanan ada pada stage " + String(s_id))
		_check(arena.get_node_or_null("Camera2D") != null, "Camera2D ada pada stage " + String(s_id))
		_check(arena.background_sprite != null, "Background sprite terpasang pada stage " + String(s_id))
		_check(arena.ambience != null, "Ambience terpasang pada stage " + String(s_id))
		_check(arena.is_within_platform(704.0) == true, "Center x=704 dalam platform pada stage " + String(s_id))
		
		arena.queue_free()
	
	MatchConfigScript.reset_defaults()

func _test_versus_ai_stage_swap_and_combat() -> void:
	MatchConfigScript.reset_defaults()
	MatchConfigScript.set_mode(&"versus_ai")
	MatchConfigScript.set_stage(&"sakura_temple")
	
	var scene = load("res://scenes/versus_ai_mode.tscn")
	_check(scene != null, "Scene versus_ai_mode.tscn berhasil dimuat.")
	
	var v_ai = scene.instantiate()
	add_child(v_ai)
	
	# Tunggu inisialisasi ready
	var stage_arena = v_ai.get_node_or_null("ArenaStage")
	_check(stage_arena != null, "Versus AI berhasil mengganti arena ke ArenaStage.")
	
	var fighters = v_ai.get_node_or_null("Fighters")
	_check(fighters != null, "Container Fighters ditemukan.")
	var p1 = fighters.get_node_or_null("P1")
	var p2 = fighters.get_node_or_null("P2")
	_check(p1 != null and p2 != null, "Kedua petarung P1 dan P2 ada di scene.")
	
	# Jalankan beberapa tick fisika
	for frame in range(15):
		if v_ai.has_method("_physics_process"):
			v_ai._physics_process(1.0 / 60.0)
		if p1 and p1.has_method("_physics_process"):
			p1._physics_process(1.0 / 60.0)
		if p2 and p2.has_method("_physics_process"):
			p2._physics_process(1.0 / 60.0)
	
	_check(p1.is_on_floor() or p1.global_position.y >= 260.0, "P1 berdiri di atas lantai arena.")
	_check(p2.is_on_floor() or p2.global_position.y >= 260.0, "P2 berdiri di atas lantai arena.")
	_check(p1.facing_direction == 1, "P1 menghadap ke kanan (arah P2).")
	_check(p2.facing_direction == -1, "P2 menghadap ke kiri (arah P1).")
	_check(p1.current_hp > 0 and p2.current_hp > 0, "Kedua karakter memiliki HP valid.")
	
	v_ai.queue_free()
	MatchConfigScript.reset_defaults()

func _test_local_versus_and_training_stage_swap() -> void:
	MatchConfigScript.reset_defaults()
	MatchConfigScript.set_stage(&"neon_city")
	
	# 1. Local Versus Mode
	var l_scene = load("res://scenes/local_versus_mode.tscn")
	_check(l_scene != null, "Scene local_versus_mode.tscn berhasil dimuat.")
	var l_vs = l_scene.instantiate()
	add_child(l_vs)
	_check(l_vs.get_node_or_null("ArenaStage") != null, "Local Versus berhasil mengganti arena ke ArenaStage.")
	l_vs.queue_free()
	
	# 2. Training Mode
	var t_scene = load("res://scenes/training_mode.tscn")
	_check(t_scene != null, "Scene training_mode.tscn berhasil dimuat.")
	var t_mode = t_scene.instantiate()
	add_child(t_mode)
	_check(t_mode.get_node_or_null("ArenaStage") != null, "Training Mode berhasil mengganti arena ke ArenaStage.")
	t_mode.queue_free()
	
	MatchConfigScript.reset_defaults()
