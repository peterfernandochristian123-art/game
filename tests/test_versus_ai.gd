extends Node

const AIControllerScript = preload("res://scripts/ai/ai_controller.gd")
const VersusAIModeScene = preload("res://scenes/versus_ai_mode.tscn")
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
	var out_path: String = ProjectSettings.globalize_path("res://test_versus_ai_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 5.5: Versus AI Controller...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_difficulty_profiles_parameters,
		_test_versus_ai_scene_initialization,
		_test_ai_spacing_and_approach,
		_test_ai_defense_reaction,
		_test_ai_whiff_punish_reaction,
		_test_ai_difficulty_runtime_switching
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

func _test_difficulty_profiles_parameters() -> void:
	var ai: Node = AIControllerScript.new()
	add_child(ai)

	# 1. Novice Profile
	ai.set_difficulty(AIControllerScript.Difficulty.NOVICE)
	_check(ai.reaction_delay_frames == 24, "Novice reaction delay adalah 24 frame.")
	_check(is_equal_approx(ai.block_chance, 0.20), "Novice block chance adalah 20%.")
	_check(is_equal_approx(ai.parry_chance, 0.05), "Novice parry chance adalah 5%.")
	_check(not ai.overclock_focus, "Novice tidak memiliki overclock focus.")

	# 2. Veteran Profile
	ai.set_difficulty(AIControllerScript.Difficulty.VETERAN)
	_check(ai.reaction_delay_frames == 12, "Veteran reaction delay adalah 12 frame.")
	_check(is_equal_approx(ai.block_chance, 0.70), "Veteran block chance adalah 70%.")
	_check(is_equal_approx(ai.parry_chance, 0.35), "Veteran parry chance adalah 35%.")

	# 3. Ace Profile
	ai.set_difficulty(AIControllerScript.Difficulty.ACE)
	_check(ai.reaction_delay_frames == 6, "Ace reaction delay adalah 6 frame (presisi tinggi).")
	_check(is_equal_approx(ai.block_chance, 0.95), "Ace block chance adalah 95%.")
	_check(is_equal_approx(ai.parry_chance, 0.85), "Ace parry chance adalah 85%.")
	_check(ai.overclock_focus, "Ace memiliki overclock focus aktif.")

	ai.queue_free()

func _test_versus_ai_scene_initialization() -> void:
	var scene = VersusAIModeScene.instantiate()
	add_child(scene)

	_check(scene.p1 != null, "Petarung P1 terpasang.")
	_check(scene.p2 != null, "Petarung P2 (AI) terpasang.")
	_check(scene.ai_controller != null, "Komponen AIController terpasang.")
	_check(scene.match_manager != null, "Komponen MatchManager terpasang.")
	_check(scene.hud != null, "CombatHUD terpasang.")
	_check(scene.btn_novice != null and scene.btn_veteran != null and scene.btn_ace != null, "Tombol pemilihan difficulty tersedia.")

	scene.queue_free()

func _test_ai_spacing_and_approach() -> void:
	var scene = VersusAIModeScene.instantiate()
	add_child(scene)

	var ai = scene.ai_controller
	var p1 = scene.p1
	var p2 = scene.p2

	# Tempatkan P1 di X=200, P2 di X=700 (jarak = 500px, jauh melampaui preferred_spacing)
	p1.global_position = Vector2(200, 288)
	p2.global_position = Vector2(700, 288)

	ai._process_spacing_and_approach()

	# P2 harus mengarah ke kiri (dir_to_opp = -1.0) untuk mendekati P1
	_check(p2.simulated_horizontal_input < 0.0, "AI bergerak mendekat (input negatif ke arah P1) saat jarak jauh.")

	# Tempatkan P1 dan P2 sangat dekat (jarak = 30px, di bawah preferred_spacing - 25px)
	p1.global_position = Vector2(500, 288)
	p2.global_position = Vector2(530, 288)
	p2.simulated_horizontal_input = 0.0

	ai._process_spacing_and_approach()
	# AI harus mundur atau melancarkan aksi
	_check(p2.simulated_horizontal_input >= 0.0 or p2.is_simulated_action_pressed(&"attack_light") or p2.is_simulated_action_pressed(&"attack_heavy"), "AI merespons saat terlalu dekat (mundur atau serang).")

	scene.queue_free()

func _test_ai_defense_reaction() -> void:
	var scene = VersusAIModeScene.instantiate()
	add_child(scene)

	var ai = scene.ai_controller
	var p1 = scene.p1
	var p2 = scene.p2

	ai.set_difficulty(AIControllerScript.Difficulty.ACE)

	# Tempatkan kedua petarung dalam jangkauan ancaman (jarak = 120px)
	p1.global_position = Vector2(500, 288)
	p2.global_position = Vector2(620, 288)

	# Ubah P1 ke AttackState
	if p1.state_machine:
		p1.state_machine.change_state(&"Attack")

	# Jalankan evaluasi pertahanan AI
	ai._process_defense_reaction()

	_check(ai._reaction_timer == 5, "Ace memulai hitung mundur reaksi (6-1=5 frame pada tick pertama).")
	_check(ai._pending_defense_action != &"", "AI telah memutuskan tindakan pertahanan (parry / block).")

	# Simulasikan berjalannya 5 frame countdown yang tersisa
	for i in range(5):
		ai._process_defense_reaction()

	# Pada akhir countdown, aksi defensif harus dieksekusi dan _defending_active menjadi true
	_check(ai._reaction_timer == 0, "Countdown reaksi AI selesai.")
	_check(ai._defending_active, "AI mengeksekusi aksi defensif aktif.")

	scene.queue_free()

func _test_ai_whiff_punish_reaction() -> void:
	var scene = VersusAIModeScene.instantiate()
	add_child(scene)

	var ai = scene.ai_controller
	var p1 = scene.p1
	var p2 = scene.p2

	ai.set_difficulty(AIControllerScript.Difficulty.ACE)
	p1.global_position = Vector2(500, 288)
	p2.global_position = Vector2(580, 288)

	# Atur P1 dalam status Hitstun / recovery whiff
	if p1.state_machine:
		p1.state_machine.change_state(&"Hitstun")

	var punished: bool = ai._try_whiff_punish()
	_check(punished, "AI mendeteksi status recovery/hitstun lawan dan memicu whiff punish.")
	_check(p2.is_simulated_action_pressed(&"attack_light") or p2.is_simulated_action_pressed(&"attack_heavy"), "AI mengeksekusi serangan punish.")

	scene.queue_free()

func _test_ai_difficulty_runtime_switching() -> void:
	var scene = VersusAIModeScene.instantiate()
	add_child(scene)

	var signal_received: Dictionary = {"count": 0, "last_diff": -1}
	scene.ai_controller.difficulty_changed.connect(func(diff):
		signal_received["count"] += 1
		signal_received["last_diff"] = diff
	)

	# Trigger tombol Novice
	scene.btn_novice.emit_signal("pressed")
	_check(scene.ai_controller.difficulty == AIControllerScript.Difficulty.NOVICE, "Klik tombol Novice mengubah kesulitan ke Novice.")
	_check(scene.difficulty_label.text.contains("NOVICE"), "Label UI diperbarui ke NOVICE.")

	# Trigger tombol Ace
	scene.btn_ace.emit_signal("pressed")
	_check(scene.ai_controller.difficulty == AIControllerScript.Difficulty.ACE, "Klik tombol Ace mengubah kesulitan ke Ace.")
	_check(scene.difficulty_label.text.contains("ACE"), "Label UI diperbarui ke ACE.")
	_check(signal_received["count"] >= 2, "Sinyal difficulty_changed terpancar dengan benar.")

	scene.queue_free()
