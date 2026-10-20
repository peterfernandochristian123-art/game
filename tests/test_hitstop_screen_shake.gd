extends Node

const HitstopComponentScript = preload("res://scripts/combat/components/hitstop_component.gd")
const CombatCameraScript = preload("res://scripts/visual/combat_camera.gd")
const SettingsManagerScript = preload("res://scripts/core/settings_manager.gd")
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
	var out_path: String = ProjectSettings.globalize_path("res://test_hitstop_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 6.1: Hitstop & Screen Shake...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_hitstop_component_light_heavy_calculation,
		_test_parry_hitstop_and_shake,
		_test_combat_camera_shake_decay,
		_test_screen_shake_disabled_setting,
		_test_arena_skyscraper_integration
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

func _create_dummy_mecha() -> CharacterBody2D:
	var m: CharacterBody2D = BaseMechaScript.new()
	var sm := Node.new()
	sm.name = "StateMachine"
	sm.set_script(preload("res://scripts/combat/fsm/state_machine.gd"))
	m.add_child(sm)
	return m

func _test_hitstop_component_light_heavy_calculation() -> void:
	var hitstop_comp: Node = HitstopComponentScript.new()
	add_child(hitstop_comp)

	var p1 := _create_dummy_mecha()
	var p2 := _create_dummy_mecha()
	add_child(p1)
	add_child(p2)

	# 1. Uji Light Attack (5L, damage 40) -> 4 frames hitstop
	p1.hitstop_frames = 0
	p2.hitstop_frames = 0
	hitstop_comp._on_hit_confirmed(p1, p2, {"name": "5L", "damage": 40})
	_check(p1.hitstop_frames == 4, "Penyerang menerima 4 frame hitstop pada Light Attack.")
	_check(p2.hitstop_frames == 4, "Korban menerima 4 frame hitstop pada Light Attack.")

	# 2. Uji Heavy Attack (5H, damage 70) -> 8 frames hitstop
	p1.hitstop_frames = 0
	p2.hitstop_frames = 0
	hitstop_comp._on_hit_confirmed(p1, p2, {"name": "5H", "damage": 70})
	_check(p1.hitstop_frames == 8, "Penyerang menerima 8 frame hitstop pada Heavy Attack.")
	_check(p2.hitstop_frames == 8, "Korban menerima 8 frame hitstop pada Heavy Attack.")

	# 3. Uji Skill Attack (damage 100) -> 10 frames hitstop
	p1.hitstop_frames = 0
	p2.hitstop_frames = 0
	hitstop_comp._on_hit_confirmed(p1, p2, {"name": "Skill1", "damage": 100})
	_check(p1.hitstop_frames == 10, "Penyerang menerima 10 frame hitstop pada Skill Attack.")
	_check(p2.hitstop_frames == 10, "Korban menerima 10 frame hitstop pada Skill Attack.")

	# 4. Uji Ultimate Attack (damage 180) -> 16 frames hitstop
	p1.hitstop_frames = 0
	p2.hitstop_frames = 0
	hitstop_comp._on_hit_confirmed(p1, p2, {"name": "Ultimate", "damage": 180})
	_check(p1.hitstop_frames == 16, "Penyerang menerima 16 frame hitstop pada Ultimate Attack.")
	_check(p2.hitstop_frames == 16, "Korban menerima 16 frame hitstop pada Ultimate Attack.")

	p1.queue_free()
	p2.queue_free()
	hitstop_comp.queue_free()

func _test_parry_hitstop_and_shake() -> void:
	var hitstop_comp: Node = HitstopComponentScript.new()
	add_child(hitstop_comp)

	var p1 := _create_dummy_mecha()
	var p2 := _create_dummy_mecha()
	add_child(p1)
	add_child(p2)

	# Simulasikan p1 sebagai defender, p2 sebagai attacker yang kena parry
	var shake_received: Dictionary = {"intensity": 0.0, "frames": 0}
	var callable := func(intensity: float, frames: int):
		shake_received["intensity"] = intensity
		shake_received["frames"] = frames

	if is_instance_valid(EventBus):
		EventBus.screen_shake_requested.connect(callable)

	hitstop_comp._on_parry_triggered(p1, p2)

	_check(p2.hitstop_frames == 12, "Penyerang dibekukan 12 frame pada Spark Parry sukses.")
	_check(shake_received["intensity"] >= 10.0, "Spark Parry memicu screen shake intensitas tinggi (>= 10.0).")
	_check(shake_received["frames"] >= 16, "Durasi getaran Spark Parry terpicu 16 frame.")

	if is_instance_valid(EventBus):
		EventBus.screen_shake_requested.disconnect(callable)

	p1.queue_free()
	p2.queue_free()
	hitstop_comp.queue_free()

func _test_combat_camera_shake_decay() -> void:
	var cam: Camera2D = CombatCameraScript.new()
	add_child(cam)

	# Pemicu getaran 8.0 pixel selama 5 frame
	cam.request_shake(8.0, 5)
	_check(cam.current_shake_intensity >= 8.0, "Kamera menerima permintaan guncangan intensitas 8.0.")
	_check(cam.shake_frames_left == 5, "Durasi guncangan kamera diatur ke 5 frame.")

	# Simulasikan 1 frame proses
	cam._process(1.0 / 60.0)
	_check(cam.offset != Vector2.ZERO, "Kamera menghasilkan offset getaran dinamis.")
	_check(cam.shake_frames_left == 4, "Timer frame berkurang menjadi 4.")

	# Simulasikan sisa 4 frame hingga selesai
	for i in range(4):
		cam._process(1.0 / 60.0)

	_check(cam.shake_frames_left == 0, "Durasi guncangan selesai.")
	_check(cam.offset == Vector2.ZERO, "Offset kamera kembali ke (0, 0) setelah getaran selesai.")

	cam.queue_free()

func _test_screen_shake_disabled_setting() -> void:
	var cam: Camera2D = CombatCameraScript.new()
	add_child(cam)

	# Nonaktifkan shake secara langsung pada kamera
	cam.shake_enabled = false
	cam.request_shake(10.0, 10)

	_check(cam.shake_frames_left == 0, "Permintaan guncangan diabaikan saat shake_enabled = false.")
	cam._process(1.0 / 60.0)
	_check(cam.offset == Vector2.ZERO, "Offset tetap (0, 0) tanpa getaran.")

	cam.queue_free()

func _test_arena_skyscraper_integration() -> void:
	var arena: Node2D = ArenaSkyscraperScene.instantiate()
	add_child(arena)

	var cam := arena.get_node_or_null("Camera2D")
	_check(cam != null, "Node Camera2D terpasang di ArenaSkyscraper.")
	_check(cam.get_script() != null, "Camera2D memiliki script terikat.")
	_check(cam.has_method("request_shake"), "Camera2D memiliki method request_shake (CombatCamera).")

	var hitstop := arena.get_node_or_null("HitstopComponent")
	_check(hitstop != null, "HitstopComponent terpasang di ArenaSkyscraper.")

	arena.queue_free()
